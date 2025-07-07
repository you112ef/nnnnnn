from fastapi import APIRouter, HTTPException, File, UploadFile, Depends, BackgroundTasks
from fastapi.responses import JSONResponse
from typing import Optional
import os
import uuid
import asyncio
from datetime import datetime
import logging

from ..models.analysis_models import (
    AnalysisResult, AnalysisRequest, AnalysisProgress, 
    SuccessResponse, ErrorResponse
)
from ..services.sperm_analyzer import SpermAnalyzer
from ..utils.file_utils import validate_file, save_upload_file

router = APIRouter()
logger = logging.getLogger(__name__)

# متغير شامل للمحلل (سيتم حقنه)
analyzer: Optional[SpermAnalyzer] = None

def get_analyzer():
    """الحصول على محلل الحيوانات المنوية"""
    global analyzer
    if analyzer is None:
        analyzer = SpermAnalyzer()
    return analyzer

@router.post("/upload", response_model=SuccessResponse)
async def upload_file_for_analysis(
    file: UploadFile = File(...),
    analyzer: SpermAnalyzer = Depends(get_analyzer)
):
    """
    رفع ملف للتحليل
    
    يدعم التطبيق الصيغ التالية:
    - الصور: JPG, PNG, BMP
    - الفيديو: MP4, AVI, MOV, MKV
    """
    try:
        # التحقق من الملف
        validation_result = await validate_file(file)
        if not validation_result['valid']:
            raise HTTPException(
                status_code=400,
                detail=validation_result['error']
            )
        
        # إنشاء معرف فريد
        analysis_id = str(uuid.uuid4())
        
        # حفظ الملف
        file_path = await save_upload_file(file, analysis_id)
        
        logger.info(f"تم رفع الملف بنجاح: {file.filename} -> {analysis_id}")
        
        return SuccessResponse(
            message="تم رفع الملف بنجاح",
            data={
                "analysis_id": analysis_id,
                "filename": file.filename,
                "file_size": validation_result['size'],
                "file_type": validation_result['type']
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في رفع الملف: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في رفع الملف"
        )

@router.post("/analyze", response_model=AnalysisResult)
async def analyze_sample(
    request: AnalysisRequest,
    background_tasks: BackgroundTasks,
    analyzer: SpermAnalyzer = Depends(get_analyzer)
):
    """
    تحليل عينة الحيوانات المنوية
    
    يستخدم نموذج YOLOv8 المتقدم لكشف وتتبع الحيوانات المنوية
    وحساب جميع مؤشرات CASA المطلوبة
    """
    try:
        analysis_id = request.analysis_id
        
        # البحث عن الملف
        file_path = await _find_uploaded_file(analysis_id)
        if not file_path:
            raise HTTPException(
                status_code=404,
                detail="الملف غير موجود"
            )
        
        # بدء التحليل
        logger.info(f"بدء تحليل العينة: {analysis_id}")
        
        try:
            # التحليل الفعلي
            result = await analyzer.analyze_sample(file_path, analysis_id)
            
            # حفظ النتائج في الخلفية
            background_tasks.add_task(_save_results, analysis_id, result)
            
            return result
            
        except Exception as analysis_error:
            logger.error(f"خطأ في تحليل العينة {analysis_id}: {analysis_error}")
            raise HTTPException(
                status_code=500,
                detail=f"فشل في تحليل العينة: {str(analysis_error)}"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ عام في التحليل: {e}")
        raise HTTPException(
            status_code=500,
            detail="خطأ في خدمة التحليل"
        )

@router.get("/analyze/{analysis_id}/progress", response_model=AnalysisProgress)
async def get_analysis_progress(
    analysis_id: str,
    analyzer: SpermAnalyzer = Depends(get_analyzer)
):
    """
    جلب تقدم التحليل الحالي
    """
    try:
        progress = analyzer.get_analysis_progress(analysis_id)
        
        if not progress:
            raise HTTPException(
                status_code=404,
                detail="التحليل غير موجود"
            )
        
        return progress
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في جلب تقدم التحليل: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب تقدم التحليل"
        )

@router.post("/analyze/batch", response_model=SuccessResponse)
async def analyze_batch(
    analysis_ids: list[str],
    background_tasks: BackgroundTasks,
    analyzer: SpermAnalyzer = Depends(get_analyzer)
):
    """
    تحليل دفعة من العينات
    """
    try:
        valid_files = []
        
        # التحقق من وجود جميع الملفات
        for analysis_id in analysis_ids:
            file_path = await _find_uploaded_file(analysis_id)
            if file_path:
                valid_files.append((analysis_id, file_path))
        
        if not valid_files:
            raise HTTPException(
                status_code=404,
                detail="لم يتم العثور على أي ملفات صالحة"
            )
        
        # بدء التحليل في الخلفية
        for analysis_id, file_path in valid_files:
            background_tasks.add_task(_analyze_in_background, analyzer, file_path, analysis_id)
        
        logger.info(f"بدء تحليل دفعة من {len(valid_files)} عينة")
        
        return SuccessResponse(
            message=f"تم بدء تحليل {len(valid_files)} عينة",
            data={
                "total_files": len(valid_files),
                "analysis_ids": [aid for aid, _ in valid_files]
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في التحليل المجمع: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في بدء التحليل المجمع"
        )

@router.delete("/analyze/{analysis_id}", response_model=SuccessResponse)
async def cancel_analysis(
    analysis_id: str,
    analyzer: SpermAnalyzer = Depends(get_analyzer)
):
    """
    إلغاء تحليل جاري
    """
    try:
        # مسح ذاكرة التخزين المؤقت
        analyzer.clear_analysis_cache(analysis_id)
        
        # حذف الملفات المرتبطة
        await _cleanup_analysis_files(analysis_id)
        
        logger.info(f"تم إلغاء التحليل: {analysis_id}")
        
        return SuccessResponse(
            message="تم إلغاء التحليل بنجاح",
            data={"analysis_id": analysis_id}
        )
        
    except Exception as e:
        logger.error(f"خطأ في إلغاء التحليل: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في إلغاء التحليل"
        )

async def _find_uploaded_file(analysis_id: str) -> Optional[str]:
    """البحث عن الملف المرفوع"""
    possible_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.mp4', '.avi', '.mov', '.mkv']
    
    for ext in possible_extensions:
        file_path = f"uploads/{analysis_id}{ext}"
        if os.path.exists(file_path):
            return file_path
    
    return None

async def _save_results(analysis_id: str, result: AnalysisResult):
    """حفظ نتائج التحليل"""
    try:
        import json
        
        os.makedirs("results", exist_ok=True)
        result_path = f"results/{analysis_id}.json"
        
        with open(result_path, "w", encoding="utf-8") as f:
            json.dump(result.dict(), f, ensure_ascii=False, indent=2, default=str)
        
        logger.info(f"تم حفظ نتائج التحليل: {analysis_id}")
        
    except Exception as e:
        logger.error(f"خطأ في حفظ النتائج: {e}")

async def _analyze_in_background(analyzer: SpermAnalyzer, file_path: str, analysis_id: str):
    """تحليل في الخلفية"""
    try:
        result = await analyzer.analyze_sample(file_path, analysis_id)
        await _save_results(analysis_id, result)
        
    except Exception as e:
        logger.error(f"خطأ في التحليل الخلفي للعينة {analysis_id}: {e}")

async def _cleanup_analysis_files(analysis_id: str):
    """تنظيف ملفات التحليل"""
    try:
        # حذف الملف المرفوع
        uploaded_file = await _find_uploaded_file(analysis_id)
        if uploaded_file and os.path.exists(uploaded_file):
            os.remove(uploaded_file)
        
        # حذف نتائج التحليل
        result_file = f"results/{analysis_id}.json"
        if os.path.exists(result_file):
            os.remove(result_file)
        
        # حذف ملف CSV إن وجد
        csv_file = f"results/{analysis_id}.csv"
        if os.path.exists(csv_file):
            os.remove(csv_file)
            
    except Exception as e:
        logger.warning(f"خطأ في تنظيف الملفات: {e}")

# Webhooks للإشعارات
@router.post("/analyze/{analysis_id}/webhook")
async def analysis_webhook(analysis_id: str, webhook_url: str):
    """
    تسجيل webhook للإشعار عند اكتمال التحليل
    """
    # TODO: تطبيق نظام webhooks
    return SuccessResponse(
        message="سيتم إضافة نظام الـ webhooks في الإصدار القادم",
        data={"analysis_id": analysis_id, "webhook_url": webhook_url}
    )
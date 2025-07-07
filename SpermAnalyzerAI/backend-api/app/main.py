from fastapi import FastAPI, HTTPException, File, UploadFile, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
import uvicorn
import os
import uuid
import asyncio
from pathlib import Path
from datetime import datetime
from typing import Optional, List
import logging

from .routes import analysis, results, status
from .services.sperm_analyzer import SpermAnalyzer
from .models.analysis_models import AnalysisResult, AnalysisStatus
from .utils.config import settings
from .utils.logger import setup_logger
from .database import DatabaseManager

# إعداد التسجيل
logger = setup_logger(__name__)

# إنشاء التطبيق
app = FastAPI(
    title="Sperm Analyzer AI API",
    description="API متقدم لتحليل الحيوانات المنوية باستخدام الذكاء الاصطناعي",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# إعداد CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # في الإنتاج، يجب تحديد المصادر المسموحة
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# إضافة الملفات الثابتة
app.mount("/static", StaticFiles(directory="static"), name="static")

# إنشاء مجلدات مطلوبة
os.makedirs("uploads", exist_ok=True)
os.makedirs("results", exist_ok=True)
os.makedirs("models", exist_ok=True)
os.makedirs("static", exist_ok=True)

# متغير شامل لمحلل الحيوانات المنوية
sperm_analyzer = None

@app.on_event("startup")
async def startup_event():
    """إعداد التطبيق عند البدء"""
    global sperm_analyzer
    logger.info("🚀 بدء تشغيل Sperm Analyzer AI API")
    
    try:
        # تهيئة قاعدة البيانات
        logger.info("🔧 تهيئة قاعدة البيانات...")
        DatabaseManager.init_database()
        logger.info("✅ تم تهيئة قاعدة البيانات بنجاح")
        
        # تهيئة محلل الحيوانات المنوية
        logger.info("🤖 تحميل نموذج YOLOv8...")
        sperm_analyzer = SpermAnalyzer()
        await sperm_analyzer.initialize()
        logger.info("✅ تم تحميل نموذج YOLOv8 بنجاح")
        
    except Exception as e:
        logger.error(f"❌ فشل في التهيئة: {e}")
        # يمكن للتطبيق العمل بدون النموذج للاختبار
        sperm_analyzer = None

@app.on_event("shutdown")
async def shutdown_event():
    """تنظيف الموارد عند الإغلاق"""
    logger.info("🛑 إيقاف تشغيل Sperm Analyzer AI API")

# تضمين المسارات
app.include_router(analysis.router, prefix="/api/v1", tags=["Analysis"])
app.include_router(results.router, prefix="/api/v1", tags=["Results"])
app.include_router(status.router, prefix="/api/v1", tags=["Status"])

@app.get("/", response_class=JSONResponse)
async def root():
    """الصفحة الرئيسية للAPI"""
    return {
        "message": "مرحباً بك في Sperm Analyzer AI API",
        "version": "1.0.0",
        "developer": "يوسف الشتيوي",
        "docs": "/docs",
        "status": "running",
        "model_loaded": sperm_analyzer is not None
    }

@app.get("/health", response_class=JSONResponse)
async def health_check():
    """فحص صحة النظام"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "model_status": "loaded" if sperm_analyzer else "not_loaded",
        "uptime": "running"
    }

@app.post("/upload", response_class=JSONResponse)
async def upload_file(file: UploadFile = File(...)):
    """رفع ملف للتحليل"""
    try:
        # التحقق من نوع الملف
        allowed_types = [
            "image/jpeg", "image/png", "image/bmp",
            "video/mp4", "video/avi", "video/mov", "video/mkv"
        ]
        
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=f"نوع الملف غير مدعوم: {file.content_type}"
            )
        
        # التحقق من حجم الملف (100 MB حد أقصى)
        file_size = 0
        content = await file.read()
        file_size = len(content)
        
        if file_size > 100 * 1024 * 1024:  # 100 MB
            raise HTTPException(
                status_code=400,
                detail="حجم الملف كبير جداً (حد أقصى 100 MB)"
            )
        
        # إنشاء معرف فريد للتحليل
        analysis_id = str(uuid.uuid4())
        
        # حفظ الملف
        file_extension = Path(file.filename).suffix
        file_path = f"uploads/{analysis_id}{file_extension}"
        
        with open(file_path, "wb") as f:
            f.write(content)
        
        logger.info(f"تم رفع الملف بنجاح: {file.filename} (ID: {analysis_id})")
        
        return {
            "analysis_id": analysis_id,
            "filename": file.filename,
            "file_size": file_size,
            "status": "uploaded",
            "message": "تم رفع الملف بنجاح"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في رفع الملف: {e}")
        raise HTTPException(status_code=500, detail="فشل في رفع الملف")

@app.post("/analyze", response_class=JSONResponse)
async def analyze_sample(analysis_id: str):
    """تحليل العينة"""
    try:
        # البحث عن الملف
        file_path = None
        for ext in [".jpg", ".jpeg", ".png", ".bmp", ".mp4", ".avi", ".mov", ".mkv"]:
            potential_path = f"uploads/{analysis_id}{ext}"
            if os.path.exists(potential_path):
                file_path = potential_path
                break
        
        if not file_path:
            raise HTTPException(
                status_code=404,
                detail="الملف غير موجود"
            )
        
        # التحقق من وجود المحلل
        if sperm_analyzer is None:
            # محاكاة التحليل للاختبار
            logger.warning("محاكاة التحليل - النموذج غير محمل")
            result = await simulate_analysis(analysis_id, file_path)
        else:
            # التحليل الفعلي
            logger.info(f"بدء تحليل العينة: {analysis_id}")
            result = await sperm_analyzer.analyze_sample(file_path, analysis_id)
        
        # حفظ النتائج
        result_path = f"results/{analysis_id}.json"
        with open(result_path, "w", encoding="utf-8") as f:
            import json
            json.dump(result.dict(), f, ensure_ascii=False, indent=2)
        
        logger.info(f"تم تحليل العينة بنجاح: {analysis_id}")
        
        return result
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في التحليل: {e}")
        raise HTTPException(status_code=500, detail="فشل في تحليل العينة")

@app.get("/results/{analysis_id}", response_class=JSONResponse)
async def get_results(analysis_id: str):
    """جلب نتائج التحليل"""
    try:
        result_path = f"results/{analysis_id}.json"
        
        if not os.path.exists(result_path):
            raise HTTPException(
                status_code=404,
                detail="النتائج غير موجودة"
            )
        
        with open(result_path, "r", encoding="utf-8") as f:
            import json
            result_data = json.load(f)
        
        return result_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في جلب النتائج: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب النتائج")

@app.get("/export/{analysis_id}")
async def export_results(analysis_id: str, format: str = "json"):
    """تصدير النتائج"""
    try:
        result_path = f"results/{analysis_id}.json"
        
        if not os.path.exists(result_path):
            raise HTTPException(
                status_code=404,
                detail="النتائج غير موجودة"
            )
        
        if format.lower() == "json":
            return FileResponse(
                result_path,
                media_type="application/json",
                filename=f"analysis_{analysis_id}.json"
            )
        elif format.lower() == "csv":
            # تحويل إلى CSV
            csv_path = f"results/{analysis_id}.csv"
            await convert_to_csv(result_path, csv_path)
            return FileResponse(
                csv_path,
                media_type="text/csv",
                filename=f"analysis_{analysis_id}.csv"
            )
        else:
            raise HTTPException(
                status_code=400,
                detail="صيغة التصدير غير مدعومة"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في التصدير: {e}")
        raise HTTPException(status_code=500, detail="فشل في التصدير")

async def simulate_analysis(analysis_id: str, file_path: str) -> AnalysisResult:
    """محاكاة التحليل للاختبار"""
    import random
    from .models.analysis_models import (
        AnalysisResult, CasaParameters, SpermMorphology, 
        VelocityDataPoint, AnalysisMetadata
    )
    
    # محاكاة وقت التحليل
    await asyncio.sleep(2)
    
    # إنتاج بيانات محاكاة واقعية
    return AnalysisResult(
        id=analysis_id,
        fileName=os.path.basename(file_path),
        fileSize=os.path.getsize(file_path),
        analysisDate=datetime.now(),
        spermCount=random.randint(20, 80),
        motility=random.uniform(40, 85),
        concentration=random.uniform(15, 40),
        casaParameters=CasaParameters(
            vcl=random.uniform(60, 120),
            vsl=random.uniform(30, 80),
            vap=random.uniform(45, 95),
            lin=random.uniform(40, 80),
            str=random.uniform(60, 90),
            wob=random.uniform(50, 85),
            alh=random.uniform(2, 8),
            bcf=random.uniform(8, 25),
            mot=random.uniform(40, 85)
        ),
        morphology=SpermMorphology(
            normal=random.uniform(60, 90),
            abnormal=random.uniform(10, 40),
            headDefects=random.uniform(5, 20),
            tailDefects=random.uniform(3, 15),
            neckDefects=random.uniform(1, 8)
        ),
        velocityDistribution=[
            VelocityDataPoint(timePoint=i, velocity=random.uniform(40, 80))
            for i in range(10)
        ],
        metadata=AnalysisMetadata(
            modelVersion="YOLOv8-mock",
            confidence=random.uniform(0.85, 0.98),
            processingTime=random.randint(1500, 3000),
            additionalData={"simulation": True}
        )
    )

async def convert_to_csv(json_path: str, csv_path: str):
    """تحويل JSON إلى CSV"""
    import json
    import csv
    
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        
        # كتابة العناوين
        writer.writerow(["Parameter", "Value", "Unit"])
        
        # الكتابة البيانات الأساسية
        writer.writerow(["Sperm Count", data.get("spermCount", 0), "count"])
        writer.writerow(["Motility", data.get("motility", 0), "%"])
        writer.writerow(["Concentration", data.get("concentration", 0), "M/ml"])
        
        # مؤشرات CASA
        casa = data.get("casaParameters", {})
        for param, value in casa.items():
            unit = "μm/s" if param in ["vcl", "vsl", "vap"] else "%" if param in ["lin", "str", "wob", "mot"] else "μm" if param == "alh" else "Hz" if param == "bcf" else ""
            writer.writerow([param.upper(), value, unit])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
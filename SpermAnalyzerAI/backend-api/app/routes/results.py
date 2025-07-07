from fastapi import APIRouter, HTTPException, Response
from fastapi.responses import JSONResponse, FileResponse
from typing import Optional, List
import os
import json
import csv
import io
from datetime import datetime
import logging

from ..models.analysis_models import AnalysisResult, SuccessResponse

router = APIRouter()
logger = logging.getLogger(__name__)

@router.get("/results/{analysis_id}", response_model=AnalysisResult)
async def get_analysis_results(analysis_id: str):
    """
    جلب نتائج التحليل بالمعرف
    """
    try:
        result_path = f"results/{analysis_id}.json"
        
        if not os.path.exists(result_path):
            raise HTTPException(
                status_code=404,
                detail="نتائج التحليل غير موجودة"
            )
        
        with open(result_path, "r", encoding="utf-8") as f:
            result_data = json.load(f)
        
        # تحويل التاريخ من string إلى datetime إذا لزم الأمر
        if isinstance(result_data.get('analysis_date'), str):
            result_data['analysis_date'] = datetime.fromisoformat(
                result_data['analysis_date'].replace('Z', '+00:00')
            )
        
        return AnalysisResult(**result_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في جلب النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب نتائج التحليل"
        )

@router.get("/results", response_model=List[dict])
async def list_all_results(
    limit: int = 50,
    offset: int = 0,
    sort_by: str = "analysis_date",
    order: str = "desc"
):
    """
    قائمة بجميع نتائج التحليل
    """
    try:
        results_dir = "results"
        if not os.path.exists(results_dir):
            return []
        
        # جلب جميع ملفات النتائج
        result_files = []
        for filename in os.listdir(results_dir):
            if filename.endswith('.json'):
                file_path = os.path.join(results_dir, filename)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        result_data = json.load(f)
                        result_data['file_path'] = file_path
                        result_files.append(result_data)
                except Exception as e:
                    logger.warning(f"خطأ في قراءة ملف النتائج {filename}: {e}")
                    continue
        
        # ترتيب النتائج
        reverse_order = order.lower() == "desc"
        try:
            if sort_by == "analysis_date":
                result_files.sort(
                    key=lambda x: datetime.fromisoformat(
                        x.get('analysis_date', '').replace('Z', '+00:00')
                    ) if x.get('analysis_date') else datetime.min,
                    reverse=reverse_order
                )
            elif sort_by == "sperm_count":
                result_files.sort(
                    key=lambda x: x.get('sperm_count', 0),
                    reverse=reverse_order
                )
            elif sort_by == "motility":
                result_files.sort(
                    key=lambda x: x.get('motility', 0),
                    reverse=reverse_order
                )
        except Exception as e:
            logger.warning(f"خطأ في ترتيب النتائج: {e}")
        
        # تطبيق التقسيم
        paginated_results = result_files[offset:offset + limit]
        
        # إزالة file_path قبل الإرجاع
        for result in paginated_results:
            result.pop('file_path', None)
        
        return paginated_results
        
    except Exception as e:
        logger.error(f"خطأ في جلب قائمة النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب قائمة النتائج"
        )

@router.get("/results/{analysis_id}/summary")
async def get_results_summary(analysis_id: str):
    """
    ملخص نتائج التحليل
    """
    try:
        result_path = f"results/{analysis_id}.json"
        
        if not os.path.exists(result_path):
            raise HTTPException(
                status_code=404,
                detail="نتائج التحليل غير موجودة"
            )
        
        with open(result_path, "r", encoding="utf-8") as f:
            result_data = json.load(f)
        
        # استخراج الملخص
        summary = {
            "analysis_id": analysis_id,
            "file_name": result_data.get("file_name", "غير معروف"),
            "analysis_date": result_data.get("analysis_date"),
            "sperm_count": result_data.get("sperm_count", 0),
            "motility": result_data.get("motility", 0),
            "concentration": result_data.get("concentration", 0),
            "normal_morphology": result_data.get("morphology", {}).get("normal", 0),
            "quality_assessment": _assess_quality(result_data),
            "key_casa_parameters": {
                "vcl": result_data.get("casa_parameters", {}).get("vcl", 0),
                "vsl": result_data.get("casa_parameters", {}).get("vsl", 0),
                "lin": result_data.get("casa_parameters", {}).get("lin", 0),
                "mot": result_data.get("casa_parameters", {}).get("mot", 0)
            }
        }
        
        return summary
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في جلب ملخص النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب ملخص النتائج"
        )

@router.get("/results/{analysis_id}/export")
async def export_results(
    analysis_id: str,
    format: str = "json",
    include_metadata: bool = True
):
    """
    تصدير نتائج التحليل بصيغ مختلفة
    
    الصيغ المدعومة:
    - json: ملف JSON كامل
    - csv: ملف CSV مبسط
    - txt: تقرير نصي
    """
    try:
        result_path = f"results/{analysis_id}.json"
        
        if not os.path.exists(result_path):
            raise HTTPException(
                status_code=404,
                detail="نتائج التحليل غير موجودة"
            )
        
        format = format.lower()
        
        if format == "json":
            return await _export_json(result_path, analysis_id, include_metadata)
        elif format == "csv":
            return await _export_csv(result_path, analysis_id)
        elif format == "txt":
            return await _export_txt(result_path, analysis_id)
        else:
            raise HTTPException(
                status_code=400,
                detail="صيغة التصدير غير مدعومة. الصيغ المدعومة: json, csv, txt"
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في تصدير النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في تصدير النتائج"
        )

@router.delete("/results/{analysis_id}", response_model=SuccessResponse)
async def delete_analysis_results(analysis_id: str):
    """
    حذف نتائج التحليل
    """
    try:
        result_path = f"results/{analysis_id}.json"
        csv_path = f"results/{analysis_id}.csv"
        
        deleted_files = []
        
        if os.path.exists(result_path):
            os.remove(result_path)
            deleted_files.append("JSON")
        
        if os.path.exists(csv_path):
            os.remove(csv_path)
            deleted_files.append("CSV")
        
        if not deleted_files:
            raise HTTPException(
                status_code=404,
                detail="نتائج التحليل غير موجودة"
            )
        
        logger.info(f"تم حذف نتائج التحليل: {analysis_id}")
        
        return SuccessResponse(
            message="تم حذف نتائج التحليل بنجاح",
            data={
                "analysis_id": analysis_id,
                "deleted_files": deleted_files
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في حذف النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في حذف نتائج التحليل"
        )

@router.post("/results/compare")
async def compare_results(analysis_ids: List[str]):
    """
    مقارنة نتائج عدة تحليلات
    """
    try:
        if len(analysis_ids) < 2:
            raise HTTPException(
                status_code=400,
                detail="يجب تقديم معرفين على الأقل للمقارنة"
            )
        
        results = []
        for analysis_id in analysis_ids:
            result_path = f"results/{analysis_id}.json"
            if os.path.exists(result_path):
                with open(result_path, "r", encoding="utf-8") as f:
                    result_data = json.load(f)
                    results.append({
                        "analysis_id": analysis_id,
                        "data": result_data
                    })
        
        if len(results) < 2:
            raise HTTPException(
                status_code=404,
                detail="لم يتم العثور على نتائج كافية للمقارنة"
            )
        
        # إنشاء مقارنة
        comparison = _create_comparison(results)
        
        return comparison
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"خطأ في مقارنة النتائج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في مقارنة النتائج"
        )

async def _export_json(result_path: str, analysis_id: str, include_metadata: bool) -> FileResponse:
    """تصدير JSON"""
    if not include_metadata:
        # إزالة البيانات الإضافية
        with open(result_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        # إزالة البيانات غير الأساسية
        data.pop("metadata", None)
        data.pop("tracking_data", None)
        
        # حفظ نسخة مبسطة
        simplified_path = f"results/{analysis_id}_simplified.json"
        with open(simplified_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2, default=str)
        
        return FileResponse(
            simplified_path,
            media_type="application/json",
            filename=f"analysis_{analysis_id}_simplified.json"
        )
    
    return FileResponse(
        result_path,
        media_type="application/json",
        filename=f"analysis_{analysis_id}.json"
    )

async def _export_csv(result_path: str, analysis_id: str) -> FileResponse:
    """تصدير CSV"""
    with open(result_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    csv_path = f"results/{analysis_id}.csv"
    
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        
        # العناوين
        writer.writerow(["Parameter", "Value", "Unit", "Normal_Range"])
        
        # البيانات الأساسية
        writer.writerow(["Sperm_Count", data.get("sperm_count", 0), "count", "≥15M"])
        writer.writerow(["Motility", data.get("motility", 0), "%", "≥40%"])
        writer.writerow(["Concentration", data.get("concentration", 0), "M/ml", "≥15M/ml"])
        
        # مؤشرات CASA
        casa = data.get("casa_parameters", {})
        casa_params = [
            ("VCL", casa.get("vcl", 0), "μm/s", "25-150"),
            ("VSL", casa.get("vsl", 0), "μm/s", "15-75"),
            ("VAP", casa.get("vap", 0), "μm/s", "20-100"),
            ("LIN", casa.get("lin", 0), "%", "40-85"),
            ("STR", casa.get("str", 0), "%", "60-90"),
            ("WOB", casa.get("wob", 0), "%", "50-80"),
            ("ALH", casa.get("alh", 0), "μm", "2-7"),
            ("BCF", casa.get("bcf", 0), "Hz", "5-45"),
            ("MOT", casa.get("mot", 0), "%", "≥40")
        ]
        
        for param, value, unit, normal_range in casa_params:
            writer.writerow([param, f"{value:.2f}", unit, normal_range])
        
        # الشكل
        morphology = data.get("morphology", {})
        writer.writerow(["Normal_Morphology", f"{morphology.get('normal', 0):.1f}", "%", "≥4%"])
        writer.writerow(["Head_Defects", f"{morphology.get('head_defects', 0):.1f}", "%", "<20%"])
        writer.writerow(["Tail_Defects", f"{morphology.get('tail_defects', 0):.1f}", "%", "<15%"])
        writer.writerow(["Neck_Defects", f"{morphology.get('neck_defects', 0):.1f}", "%", "<10%"])
    
    return FileResponse(
        csv_path,
        media_type="text/csv",
        filename=f"analysis_{analysis_id}.csv"
    )

async def _export_txt(result_path: str, analysis_id: str) -> FileResponse:
    """تصدير تقرير نصي"""
    with open(result_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    txt_path = f"results/{analysis_id}.txt"
    
    with open(txt_path, "w", encoding="utf-8") as f:
        f.write("تقرير تحليل الحيوانات المنوية\n")
        f.write("="*50 + "\n\n")
        
        f.write(f"معرف التحليل: {analysis_id}\n")
        f.write(f"اسم الملف: {data.get('file_name', 'غير معروف')}\n")
        f.write(f"تاريخ التحليل: {data.get('analysis_date', 'غير معروف')}\n\n")
        
        f.write("النتائج الأساسية:\n")
        f.write("-"*20 + "\n")
        f.write(f"عدد الحيوانات المنوية: {data.get('sperm_count', 0)}\n")
        f.write(f"نسبة الحركة: {data.get('motility', 0):.1f}%\n")
        f.write(f"التركيز: {data.get('concentration', 0):.1f} مليون/مل\n\n")
        
        f.write("مؤشرات CASA:\n")
        f.write("-"*15 + "\n")
        casa = data.get("casa_parameters", {})
        f.write(f"السرعة المنحنية (VCL): {casa.get('vcl', 0):.1f} μm/s\n")
        f.write(f"السرعة المستقيمة (VSL): {casa.get('vsl', 0):.1f} μm/s\n")
        f.write(f"متوسط سرعة المسار (VAP): {casa.get('vap', 0):.1f} μm/s\n")
        f.write(f"الخطية (LIN): {casa.get('lin', 0):.1f}%\n")
        f.write(f"الاستقامة (STR): {casa.get('str', 0):.1f}%\n")
        f.write(f"التذبذب (WOB): {casa.get('wob', 0):.1f}%\n\n")
        
        f.write("تحليل الشكل:\n")
        f.write("-"*12 + "\n")
        morphology = data.get("morphology", {})
        f.write(f"الشكل الطبيعي: {morphology.get('normal', 0):.1f}%\n")
        f.write(f"الشكل غير الطبيعي: {morphology.get('abnormal', 0):.1f}%\n")
        f.write(f"عيوب الرأس: {morphology.get('head_defects', 0):.1f}%\n")
        f.write(f"عيوب الذيل: {morphology.get('tail_defects', 0):.1f}%\n")
        f.write(f"عيوب الرقبة: {morphology.get('neck_defects', 0):.1f}%\n\n")
        
        f.write("التقييم العام:\n")
        f.write("-"*12 + "\n")
        quality = _assess_quality(data)
        f.write(f"جودة العينة: {quality}\n")
        
        f.write("\n" + "="*50 + "\n")
        f.write("تم إنشاء هذا التقرير بواسطة Sperm Analyzer AI\n")
        f.write("المطور: يوسف الشتيوي\n")
    
    return FileResponse(
        txt_path,
        media_type="text/plain",
        filename=f"analysis_report_{analysis_id}.txt"
    )

def _assess_quality(data: dict) -> str:
    """تقييم جودة العينة"""
    motility = data.get("motility", 0)
    concentration = data.get("concentration", 0)
    normal_morphology = data.get("morphology", {}).get("normal", 0)
    
    scores = []
    
    # تقييم الحركة
    if motility >= 60:
        scores.append(100)
    elif motility >= 40:
        scores.append(75)
    elif motility >= 20:
        scores.append(50)
    else:
        scores.append(25)
    
    # تقييم التركيز
    if concentration >= 20:
        scores.append(100)
    elif concentration >= 15:
        scores.append(75)
    elif concentration >= 10:
        scores.append(50)
    else:
        scores.append(25)
    
    # تقييم الشكل
    if normal_morphology >= 70:
        scores.append(100)
    elif normal_morphology >= 50:
        scores.append(75)
    elif normal_morphology >= 30:
        scores.append(50)
    else:
        scores.append(25)
    
    average_score = sum(scores) / len(scores)
    
    if average_score >= 80:
        return "ممتازة"
    elif average_score >= 60:
        return "جيدة"
    elif average_score >= 40:
        return "متوسطة"
    else:
        return "ضعيفة"

def _create_comparison(results: List[dict]) -> dict:
    """إنشاء مقارنة بين النتائج"""
    comparison = {
        "comparison_date": datetime.now().isoformat(),
        "total_analyses": len(results),
        "analyses": [],
        "summary": {
            "avg_sperm_count": 0,
            "avg_motility": 0,
            "avg_concentration": 0,
            "avg_normal_morphology": 0
        }
    }
    
    totals = {"sperm_count": 0, "motility": 0, "concentration": 0, "normal_morphology": 0}
    
    for result in results:
        data = result["data"]
        analysis_summary = {
            "analysis_id": result["analysis_id"],
            "sperm_count": data.get("sperm_count", 0),
            "motility": data.get("motility", 0),
            "concentration": data.get("concentration", 0),
            "normal_morphology": data.get("morphology", {}).get("normal", 0),
            "quality": _assess_quality(data)
        }
        
        comparison["analyses"].append(analysis_summary)
        
        totals["sperm_count"] += analysis_summary["sperm_count"]
        totals["motility"] += analysis_summary["motility"]
        totals["concentration"] += analysis_summary["concentration"]
        totals["normal_morphology"] += analysis_summary["normal_morphology"]
    
    # حساب المتوسطات
    count = len(results)
    comparison["summary"]["avg_sperm_count"] = totals["sperm_count"] / count
    comparison["summary"]["avg_motility"] = totals["motility"] / count
    comparison["summary"]["avg_concentration"] = totals["concentration"] / count
    comparison["summary"]["avg_normal_morphology"] = totals["normal_morphology"] / count
    
    return comparison
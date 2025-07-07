from fastapi import APIRouter, HTTPException
from fastapi.responses import JSONResponse
import os
import psutil
import platform
from datetime import datetime, timedelta
import logging
from typing import Dict, Any

router = APIRouter()
logger = logging.getLogger(__name__)

# متغير لتتبع وقت بدء التشغيل
startup_time = datetime.now()

@router.get("/status", response_class=JSONResponse)
async def get_system_status():
    """
    فحص حالة النظام العامة
    """
    try:
        # معلومات النظام
        system_info = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "uptime": str(datetime.now() - startup_time),
            "version": "1.0.0",
            "api_version": "v1"
        }
        
        # معلومات الأجهزة
        hardware_info = await _get_hardware_info()
        system_info.update(hardware_info)
        
        # حالة الخدمات
        services_status = await _check_services_status()
        system_info["services"] = services_status
        
        # إحصائيات الملفات
        files_stats = await _get_files_statistics()
        system_info["storage"] = files_stats
        
        return system_info
        
    except Exception as e:
        logger.error(f"خطأ في فحص حالة النظام: {e}")
        return {
            "status": "error",
            "timestamp": datetime.now().isoformat(),
            "error": str(e)
        }

@router.get("/status/health", response_class=JSONResponse)
async def health_check():
    """
    فحص سريع لصحة النظام
    """
    try:
        health_status = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "checks": {
                "api": True,
                "storage": os.path.exists("uploads") and os.path.exists("results"),
                "memory": psutil.virtual_memory().percent < 90,
                "disk": psutil.disk_usage("/").percent < 90
            }
        }
        
        # تحديد الحالة العامة
        all_healthy = all(health_status["checks"].values())
        health_status["status"] = "healthy" if all_healthy else "degraded"
        
        return health_status
        
    except Exception as e:
        logger.error(f"خطأ في فحص الصحة: {e}")
        return {
            "status": "unhealthy",
            "timestamp": datetime.now().isoformat(),
            "error": str(e)
        }

@router.get("/status/performance", response_class=JSONResponse)
async def get_performance_metrics():
    """
    مقاييس الأداء التفصيلية
    """
    try:
        # معلومات المعالج
        cpu_info = {
            "usage_percent": psutil.cpu_percent(interval=1),
            "count": psutil.cpu_count(),
            "frequency": psutil.cpu_freq()._asdict() if psutil.cpu_freq() else None
        }
        
        # معلومات الذاكرة
        memory = psutil.virtual_memory()
        memory_info = {
            "total": memory.total,
            "available": memory.available,
            "used": memory.used,
            "usage_percent": memory.percent
        }
        
        # معلومات القرص
        disk = psutil.disk_usage("/")
        disk_info = {
            "total": disk.total,
            "used": disk.used,
            "free": disk.free,
            "usage_percent": (disk.used / disk.total) * 100
        }
        
        # معلومات الشبكة
        network = psutil.net_io_counters()
        network_info = {
            "bytes_sent": network.bytes_sent,
            "bytes_recv": network.bytes_recv,
            "packets_sent": network.packets_sent,
            "packets_recv": network.packets_recv
        }
        
        return {
            "timestamp": datetime.now().isoformat(),
            "cpu": cpu_info,
            "memory": memory_info,
            "disk": disk_info,
            "network": network_info
        }
        
    except Exception as e:
        logger.error(f"خطأ في جلب مقاييس الأداء: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب مقاييس الأداء"
        )

@router.get("/status/model", response_class=JSONResponse)
async def get_model_status():
    """
    حالة نموذج الذكاء الاصطناعي
    """
    try:
        model_status = {
            "timestamp": datetime.now().isoformat(),
            "yolo_model": {
                "available": os.path.exists("models/sperm_yolov8.pt"),
                "path": "models/sperm_yolov8.pt",
                "size": _get_file_size("models/sperm_yolov8.pt") if os.path.exists("models/sperm_yolov8.pt") else 0,
                "last_modified": _get_file_modified_time("models/sperm_yolov8.pt")
            },
            "dependencies": {
                "ultralytics": _check_package_availability("ultralytics"),
                "opencv": _check_package_availability("cv2"),
                "deep_sort": _check_package_availability("deep_sort_realtime"),
                "torch": _check_package_availability("torch")
            },
            "gpu_available": _check_gpu_availability(),
            "model_loaded": False  # سيتم تحديثه بواسطة المحلل
        }
        
        return model_status
        
    except Exception as e:
        logger.error(f"خطأ في فحص حالة النموذج: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في فحص حالة النموذج"
        )

@router.get("/status/storage", response_class=JSONResponse)
async def get_storage_status():
    """
    حالة مساحة التخزين
    """
    try:
        storage_status = {
            "timestamp": datetime.now().isoformat(),
            "uploads": {
                "path": "uploads",
                "exists": os.path.exists("uploads"),
                "file_count": len(os.listdir("uploads")) if os.path.exists("uploads") else 0,
                "total_size": _get_directory_size("uploads")
            },
            "results": {
                "path": "results",
                "exists": os.path.exists("results"),
                "file_count": len(os.listdir("results")) if os.path.exists("results") else 0,
                "total_size": _get_directory_size("results")
            },
            "models": {
                "path": "models",
                "exists": os.path.exists("models"),
                "file_count": len(os.listdir("models")) if os.path.exists("models") else 0,
                "total_size": _get_directory_size("models")
            },
            "disk_usage": {
                "total": psutil.disk_usage("/").total,
                "used": psutil.disk_usage("/").used,
                "free": psutil.disk_usage("/").free,
                "percent": psutil.disk_usage("/").percent
            }
        }
        
        return storage_status
        
    except Exception as e:
        logger.error(f"خطأ في فحص حالة التخزين: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في فحص حالة التخزين"
        )

@router.get("/status/analysis", response_class=JSONResponse)
async def get_analysis_statistics():
    """
    إحصائيات التحليل
    """
    try:
        results_dir = "results"
        if not os.path.exists(results_dir):
            return {
                "timestamp": datetime.now().isoformat(),
                "total_analyses": 0,
                "successful_analyses": 0,
                "failed_analyses": 0,
                "recent_analyses": []
            }
        
        result_files = [f for f in os.listdir(results_dir) if f.endswith('.json')]
        
        # تحليل الملفات
        successful_analyses = 0
        failed_analyses = 0
        recent_analyses = []
        
        for filename in result_files[-10:]:  # آخر 10 تحليلات
            file_path = os.path.join(results_dir, filename)
            try:
                import json
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    
                successful_analyses += 1
                recent_analyses.append({
                    "analysis_id": filename.replace('.json', ''),
                    "file_name": data.get("file_name", "غير معروف"),
                    "analysis_date": data.get("analysis_date"),
                    "sperm_count": data.get("sperm_count", 0),
                    "motility": data.get("motility", 0)
                })
                
            except Exception:
                failed_analyses += 1
                recent_analyses.append({
                    "analysis_id": filename.replace('.json', ''),
                    "status": "failed",
                    "error": "فشل في قراءة البيانات"
                })
        
        # ترتيب حسب التاريخ
        recent_analyses.sort(
            key=lambda x: x.get("analysis_date", ""),
            reverse=True
        )
        
        return {
            "timestamp": datetime.now().isoformat(),
            "total_analyses": len(result_files),
            "successful_analyses": successful_analyses,
            "failed_analyses": failed_analyses,
            "success_rate": (successful_analyses / len(result_files) * 100) if result_files else 0,
            "recent_analyses": recent_analyses[:5]  # أحدث 5 تحليلات
        }
        
    except Exception as e:
        logger.error(f"خطأ في جلب إحصائيات التحليل: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في جلب إحصائيات التحليل"
        )

@router.post("/status/cleanup", response_class=JSONResponse)
async def cleanup_old_files(
    days_old: int = 7,
    cleanup_uploads: bool = True,
    cleanup_results: bool = False
):
    """
    تنظيف الملفات القديمة
    """
    try:
        cleaned_files = []
        cutoff_date = datetime.now() - timedelta(days=days_old)
        
        if cleanup_uploads and os.path.exists("uploads"):
            for filename in os.listdir("uploads"):
                file_path = os.path.join("uploads", filename)
                if os.path.isfile(file_path):
                    file_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                    if file_time < cutoff_date:
                        os.remove(file_path)
                        cleaned_files.append(f"uploads/{filename}")
        
        if cleanup_results and os.path.exists("results"):
            for filename in os.listdir("results"):
                file_path = os.path.join("results", filename)
                if os.path.isfile(file_path):
                    file_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                    if file_time < cutoff_date:
                        os.remove(file_path)
                        cleaned_files.append(f"results/{filename}")
        
        logger.info(f"تم تنظيف {len(cleaned_files)} ملف قديم")
        
        return {
            "timestamp": datetime.now().isoformat(),
            "cleaned_files_count": len(cleaned_files),
            "cleaned_files": cleaned_files,
            "cutoff_date": cutoff_date.isoformat()
        }
        
    except Exception as e:
        logger.error(f"خطأ في تنظيف الملفات: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في تنظيف الملفات القديمة"
        )

# دوال مساعدة
async def _get_hardware_info() -> Dict[str, Any]:
    """جلب معلومات الأجهزة"""
    try:
        return {
            "platform": platform.system(),
            "platform_version": platform.version(),
            "architecture": platform.architecture()[0],
            "processor": platform.processor(),
            "cpu_count": psutil.cpu_count(),
            "memory_total": psutil.virtual_memory().total,
            "python_version": platform.python_version()
        }
    except Exception as e:
        logger.warning(f"خطأ في جلب معلومات الأجهزة: {e}")
        return {}

async def _check_services_status() -> Dict[str, bool]:
    """فحص حالة الخدمات"""
    try:
        return {
            "upload_service": os.path.exists("uploads"),
            "analysis_service": True,  # سيتم التحقق من خلال المحلل
            "results_service": os.path.exists("results"),
            "storage_service": True
        }
    except Exception as e:
        logger.warning(f"خطأ في فحص الخدمات: {e}")
        return {}

async def _get_files_statistics() -> Dict[str, Any]:
    """إحصائيات الملفات"""
    try:
        uploads_count = len(os.listdir("uploads")) if os.path.exists("uploads") else 0
        results_count = len(os.listdir("results")) if os.path.exists("results") else 0
        
        return {
            "uploads_count": uploads_count,
            "results_count": results_count,
            "uploads_size": _get_directory_size("uploads"),
            "results_size": _get_directory_size("results")
        }
    except Exception as e:
        logger.warning(f"خطأ في جلب إحصائيات الملفات: {e}")
        return {}

def _get_file_size(file_path: str) -> int:
    """حجم الملف بالبايت"""
    try:
        return os.path.getsize(file_path) if os.path.exists(file_path) else 0
    except Exception:
        return 0

def _get_file_modified_time(file_path: str) -> str:
    """وقت آخر تعديل للملف"""
    try:
        if os.path.exists(file_path):
            return datetime.fromtimestamp(os.path.getmtime(file_path)).isoformat()
        return ""
    except Exception:
        return ""

def _get_directory_size(directory: str) -> int:
    """حجم المجلد بالبايت"""
    try:
        total_size = 0
        if os.path.exists(directory):
            for dirpath, dirnames, filenames in os.walk(directory):
                for filename in filenames:
                    file_path = os.path.join(dirpath, filename)
                    if os.path.exists(file_path):
                        total_size += os.path.getsize(file_path)
        return total_size
    except Exception:
        return 0

def _check_package_availability(package_name: str) -> bool:
    """فحص توفر الحزمة"""
    try:
        if package_name == "cv2":
            import cv2
            return True
        elif package_name == "ultralytics":
            import ultralytics
            return True
        elif package_name == "deep_sort_realtime":
            import deep_sort_realtime
            return True
        elif package_name == "torch":
            import torch
            return True
        else:
            __import__(package_name)
            return True
    except ImportError:
        return False

def _check_gpu_availability() -> bool:
    """فحص توفر GPU"""
    try:
        import torch
        return torch.cuda.is_available()
    except ImportError:
        return False
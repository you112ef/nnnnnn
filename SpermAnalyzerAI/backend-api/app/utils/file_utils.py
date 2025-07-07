import os
import magic
import hashlib
from fastapi import UploadFile, HTTPException
from pathlib import Path
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

# أنواع الملفات المدعومة
SUPPORTED_IMAGE_TYPES = {
    'image/jpeg': ['.jpg', '.jpeg'],
    'image/png': ['.png'],
    'image/bmp': ['.bmp'],
    'image/tiff': ['.tiff', '.tif']
}

SUPPORTED_VIDEO_TYPES = {
    'video/mp4': ['.mp4'],
    'video/avi': ['.avi'],
    'video/quicktime': ['.mov'],
    'video/x-msvideo': ['.avi'],
    'video/x-matroska': ['.mkv']
}

ALL_SUPPORTED_TYPES = {**SUPPORTED_IMAGE_TYPES, **SUPPORTED_VIDEO_TYPES}

# حدود الحجم (بالبايت)
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB
MAX_VIDEO_SIZE = 100 * 1024 * 1024  # 100 MB
MAX_FILE_SIZE = 100 * 1024 * 1024   # 100 MB عام

async def validate_file(file: UploadFile) -> Dict[str, Any]:
    """
    التحقق من صحة الملف المرفوع
    
    Args:
        file: الملف المرفوع
        
    Returns:
        dict: نتيجة التحقق
    """
    try:
        # قراءة محتوى الملف
        content = await file.read()
        file_size = len(content)
        
        # إعادة تعيين مؤشر الملف
        await file.seek(0)
        
        # التحقق من حجم الملف
        if file_size == 0:
            return {
                'valid': False,
                'error': 'الملف فارغ',
                'size': file_size
            }
        
        if file_size > MAX_FILE_SIZE:
            return {
                'valid': False,
                'error': f'حجم الملف كبير جداً (حد أقصى {MAX_FILE_SIZE // (1024*1024)} MB)',
                'size': file_size
            }
        
        # التحقق من نوع الملف باستخدام magic
        try:
            file_type = magic.from_buffer(content, mime=True)
        except Exception as e:
            logger.warning(f"فشل في تحديد نوع الملف باستخدام magic: {e}")
            # التراجع إلى content_type
            file_type = file.content_type or 'application/octet-stream'
        
        # التحقق من دعم نوع الملف
        if file_type not in ALL_SUPPORTED_TYPES:
            return {
                'valid': False,
                'error': f'نوع الملف غير مدعوم: {file_type}',
                'size': file_size,
                'type': file_type
            }
        
        # التحقق من امتداد الملف
        file_extension = Path(file.filename or '').suffix.lower()
        expected_extensions = ALL_SUPPORTED_TYPES[file_type]
        
        if file_extension not in expected_extensions:
            logger.warning(f"امتداد الملف {file_extension} لا يتطابق مع النوع {file_type}")
        
        # التحقق من حدود الحجم حسب النوع
        if file_type in SUPPORTED_IMAGE_TYPES and file_size > MAX_IMAGE_SIZE:
            return {
                'valid': False,
                'error': f'حجم الصورة كبير جداً (حد أقصى {MAX_IMAGE_SIZE // (1024*1024)} MB)',
                'size': file_size,
                'type': file_type
            }
        
        if file_type in SUPPORTED_VIDEO_TYPES and file_size > MAX_VIDEO_SIZE:
            return {
                'valid': False,
                'error': f'حجم الفيديو كبير جداً (حد أقصى {MAX_VIDEO_SIZE // (1024*1024)} MB)',
                'size': file_size,
                'type': file_type
            }
        
        # التحقق من سلامة الملف
        validation_result = await _validate_file_integrity(content, file_type)
        if not validation_result['valid']:
            return validation_result
        
        return {
            'valid': True,
            'size': file_size,
            'type': file_type,
            'extension': file_extension,
            'hash': hashlib.md5(content).hexdigest()
        }
        
    except Exception as e:
        logger.error(f"خطأ في التحقق من الملف: {e}")
        return {
            'valid': False,
            'error': f'خطأ في التحقق من الملف: {str(e)}',
            'size': 0
        }

async def save_upload_file(file: UploadFile, analysis_id: str) -> str:
    """
    حفظ الملف المرفوع
    
    Args:
        file: الملف المرفوع
        analysis_id: معرف التحليل
        
    Returns:
        str: مسار الملف المحفوظ
    """
    try:
        # إنشاء مجلد uploads إذا لم يكن موجوداً
        uploads_dir = Path("uploads")
        uploads_dir.mkdir(exist_ok=True)
        
        # تحديد امتداد الملف
        file_extension = Path(file.filename or '').suffix.lower()
        if not file_extension:
            # تحديد الامتداد من نوع الملف
            content = await file.read()
            await file.seek(0)
            
            try:
                file_type = magic.from_buffer(content, mime=True)
                if file_type in ALL_SUPPORTED_TYPES:
                    file_extension = ALL_SUPPORTED_TYPES[file_type][0]
                else:
                    file_extension = '.unknown'
            except:
                file_extension = '.unknown'
        
        # إنشاء مسار الملف
        file_path = uploads_dir / f"{analysis_id}{file_extension}"
        
        # حفظ الملف
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        logger.info(f"تم حفظ الملف: {file_path}")
        return str(file_path)
        
    except Exception as e:
        logger.error(f"خطأ في حفظ الملف: {e}")
        raise HTTPException(
            status_code=500,
            detail="فشل في حفظ الملف"
        )

async def _validate_file_integrity(content: bytes, file_type: str) -> Dict[str, Any]:
    """
    التحقق من سلامة الملف
    
    Args:
        content: محتوى الملف
        file_type: نوع الملف
        
    Returns:
        dict: نتيجة التحقق
    """
    try:
        if file_type in SUPPORTED_IMAGE_TYPES:
            return await _validate_image_integrity(content)
        elif file_type in SUPPORTED_VIDEO_TYPES:
            return await _validate_video_integrity(content)
        else:
            return {'valid': True}
            
    except Exception as e:
        logger.warning(f"خطأ في التحقق من سلامة الملف: {e}")
        return {'valid': True}  # السماح بالمرور في حالة الخطأ

async def _validate_image_integrity(content: bytes) -> Dict[str, Any]:
    """التحقق من سلامة الصورة"""
    try:
        import cv2
        import numpy as np
        
        # تحويل البايتات إلى مصفوفة numpy
        nparr = np.frombuffer(content, np.uint8)
        
        # محاولة قراءة الصورة
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if image is None:
            return {
                'valid': False,
                'error': 'الصورة تالفة أو غير قابلة للقراءة'
            }
        
        # التحقق من أبعاد الصورة
        height, width = image.shape[:2]
        
        if height < 50 or width < 50:
            return {
                'valid': False,
                'error': 'الصورة صغيرة جداً (الحد الأدنى 50x50 بكسل)'
            }
        
        if height > 10000 or width > 10000:
            return {
                'valid': False,
                'error': 'الصورة كبيرة جداً (الحد الأقصى 10000x10000 بكسل)'
            }
        
        return {
            'valid': True,
            'dimensions': {'width': width, 'height': height}
        }
        
    except ImportError:
        logger.warning("OpenCV غير متوفر للتحقق من سلامة الصورة")
        return {'valid': True}
    except Exception as e:
        logger.warning(f"خطأ في التحقق من سلامة الصورة: {e}")
        return {'valid': True}

async def _validate_video_integrity(content: bytes) -> Dict[str, Any]:
    """التحقق من سلامة الفيديو"""
    try:
        import cv2
        import tempfile
        import os
        
        # حفظ مؤقت للفيديو
        with tempfile.NamedTemporaryFile(delete=False, suffix='.mp4') as temp_file:
            temp_file.write(content)
            temp_path = temp_file.name
        
        try:
            # محاولة فتح الفيديو
            cap = cv2.VideoCapture(temp_path)
            
            if not cap.isOpened():
                return {
                    'valid': False,
                    'error': 'الفيديو تالف أو غير قابل للقراءة'
                }
            
            # جلب معلومات الفيديو
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            fps = cap.get(cv2.CAP_PROP_FPS)
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            
            cap.release()
            
            # التحقق من صحة المعلومات
            if frame_count <= 0:
                return {
                    'valid': False,
                    'error': 'الفيديو لا يحتوي على إطارات'
                }
            
            if fps <= 0 or fps > 120:
                logger.warning(f"معدل إطارات غير طبيعي: {fps}")
            
            if width < 100 or height < 100:
                return {
                    'valid': False,
                    'error': 'دقة الفيديو منخفضة جداً (الحد الأدنى 100x100)'
                }
            
            duration = frame_count / fps if fps > 0 else 0
            if duration > 300:  # 5 دقائق
                return {
                    'valid': False,
                    'error': 'الفيديو طويل جداً (الحد الأقصى 5 دقائق)'
                }
            
            return {
                'valid': True,
                'properties': {
                    'frame_count': frame_count,
                    'fps': fps,
                    'width': width,
                    'height': height,
                    'duration': duration
                }
            }
            
        finally:
            # حذف الملف المؤقت
            if os.path.exists(temp_path):
                os.unlink(temp_path)
                
    except ImportError:
        logger.warning("OpenCV غير متوفر للتحقق من سلامة الفيديو")
        return {'valid': True}
    except Exception as e:
        logger.warning(f"خطأ في التحقق من سلامة الفيديو: {e}")
        return {'valid': True}

def get_file_info(file_path: str) -> Dict[str, Any]:
    """
    جلب معلومات الملف
    
    Args:
        file_path: مسار الملف
        
    Returns:
        dict: معلومات الملف
    """
    try:
        if not os.path.exists(file_path):
            return {'exists': False}
        
        stat = os.stat(file_path)
        file_size = stat.st_size
        
        # تحديد نوع الملف
        try:
            with open(file_path, 'rb') as f:
                header = f.read(1024)
                file_type = magic.from_buffer(header, mime=True)
        except:
            file_type = 'unknown'
        
        return {
            'exists': True,
            'size': file_size,
            'type': file_type,
            'extension': Path(file_path).suffix.lower(),
            'created': stat.st_ctime,
            'modified': stat.st_mtime,
            'name': Path(file_path).name
        }
        
    except Exception as e:
        logger.error(f"خطأ في جلب معلومات الملف: {e}")
        return {'exists': False, 'error': str(e)}

def cleanup_old_files(directory: str, days_old: int = 7) -> int:
    """
    تنظيف الملفات القديمة
    
    Args:
        directory: مسار المجلد
        days_old: عمر الملفات بالأيام
        
    Returns:
        int: عدد الملفات المحذوفة
    """
    try:
        import time
        
        if not os.path.exists(directory):
            return 0
        
        cutoff_time = time.time() - (days_old * 24 * 60 * 60)
        deleted_count = 0
        
        for filename in os.listdir(directory):
            file_path = os.path.join(directory, filename)
            
            if os.path.isfile(file_path):
                if os.path.getmtime(file_path) < cutoff_time:
                    try:
                        os.remove(file_path)
                        deleted_count += 1
                        logger.info(f"تم حذف الملف القديم: {file_path}")
                    except Exception as e:
                        logger.warning(f"فشل في حذف الملف {file_path}: {e}")
        
        return deleted_count
        
    except Exception as e:
        logger.error(f"خطأ في تنظيف الملفات القديمة: {e}")
        return 0

def ensure_directory_exists(directory: str) -> bool:
    """
    التأكد من وجود المجلد
    
    Args:
        directory: مسار المجلد
        
    Returns:
        bool: هل تم إنشاء/التأكد من المجلد بنجاح
    """
    try:
        Path(directory).mkdir(parents=True, exist_ok=True)
        return True
    except Exception as e:
        logger.error(f"فشل في إنشاء المجلد {directory}: {e}")
        return False
# SpermAnalyzerAI - Logger Configuration
import sys
import os
from pathlib import Path
from loguru import logger
from .config import settings

def setup_logger(name: str = "sperm_analyzer"):
    """إعداد نظام التسجيل"""
    
    # إزالة المعالج الافتراضي
    logger.remove()
    
    # تنسيق الرسائل
    log_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )
    
    # معالج وحدة التحكم
    logger.add(
        sys.stdout,
        format=log_format,
        level=settings.log_level,
        colorize=True,
        backtrace=True,
        diagnose=True
    )
    
    # معالج الملف (إذا كان محدد)
    if settings.log_file:
        log_path = Path(settings.log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        
        logger.add(
            settings.log_file,
            format=log_format,
            level=settings.log_level,
            rotation=f"{settings.log_max_size} bytes",
            retention=settings.log_backup_count,
            compression="zip",
            backtrace=True,
            diagnose=True,
            encoding="utf-8"
        )
    
    # إضافة مرشحات للمكتبات الخارجية
    logger.add(
        sys.stdout,
        filter=lambda record: record["name"].startswith("sperm_analyzer"),
        level="DEBUG" if settings.debug else "INFO"
    )
    
    return logger

def get_logger(name: str = None):
    """الحصول على مسجل"""
    if name:
        return logger.bind(name=name)
    return logger

# إعداد المسجل العام
setup_logger()
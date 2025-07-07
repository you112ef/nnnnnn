import os
from typing import Optional
from pydantic import BaseSettings, Field
from pathlib import Path

class Settings(BaseSettings):
    """إعدادات التطبيق"""
    
    # إعدادات عامة
    app_name: str = Field(default="Sperm Analyzer AI", env="APP_NAME")
    app_version: str = Field(default="1.0.0", env="APP_VERSION")
    debug: bool = Field(default=False, env="DEBUG")
    
    # إعدادات الخادم
    host: str = Field(default="0.0.0.0", env="HOST")
    port: int = Field(default=8000, env="PORT")
    
    # إعدادات قاعدة البيانات
    database_url: str = Field(default="sqlite:///sperm_analyzer.db", env="DATABASE_URL")
    
    # إعدادات الملفات
    upload_directory: str = Field(default="uploads", env="UPLOAD_DIR")
    results_directory: str = Field(default="results", env="RESULTS_DIR")
    models_directory: str = Field(default="models", env="MODELS_DIR")
    static_directory: str = Field(default="static", env="STATIC_DIR")
    
    # حدود الملفات
    max_upload_size: int = Field(default=100*1024*1024, env="MAX_UPLOAD_SIZE")  # 100MB
    max_image_size: int = Field(default=10*1024*1024, env="MAX_IMAGE_SIZE")    # 10MB
    max_video_size: int = Field(default=100*1024*1024, env="MAX_VIDEO_SIZE")   # 100MB
    
    # إعدادات نموذج الذكاء الاصطناعي
    model_path: str = Field(default="models/sperm_yolov8.pt", env="MODEL_PATH")
    confidence_threshold: float = Field(default=0.5, env="CONFIDENCE_THRESHOLD")
    nms_threshold: float = Field(default=0.4, env="NMS_THRESHOLD")
    use_gpu: bool = Field(default=True, env="USE_GPU")
    
    # إعدادات التتبع
    max_track_age: int = Field(default=30, env="MAX_TRACK_AGE")
    min_track_length: int = Field(default=5, env="MIN_TRACK_LENGTH")
    track_initialization: int = Field(default=3, env="TRACK_INIT")
    
    # إعدادات التحليل
    pixel_to_micron_ratio: float = Field(default=0.5, env="PIXEL_TO_MICRON_RATIO")
    analysis_timeout: int = Field(default=300, env="ANALYSIS_TIMEOUT")  # 5 minutes
    
    # إعدادات الأمان
    secret_key: str = Field(default="your-secret-key-change-in-production", env="SECRET_KEY")
    access_token_expire_minutes: int = Field(default=30, env="ACCESS_TOKEN_EXPIRE_MINUTES")
    
    # إعدادات CORS
    cors_origins: list = Field(default=["*"], env="CORS_ORIGINS")
    cors_allow_credentials: bool = Field(default=True, env="CORS_ALLOW_CREDENTIALS")
    cors_allow_methods: list = Field(default=["*"], env="CORS_ALLOW_METHODS")
    cors_allow_headers: list = Field(default=["*"], env="CORS_ALLOW_HEADERS")
    
    # إعدادات التسجيل
    log_level: str = Field(default="INFO", env="LOG_LEVEL")
    log_file: Optional[str] = Field(default="logs/sperm_analyzer.log", env="LOG_FILE")
    log_max_size: int = Field(default=10*1024*1024, env="LOG_MAX_SIZE")  # 10MB
    log_backup_count: int = Field(default=5, env="LOG_BACKUP_COUNT")
    
    # إعدادات التخزين المؤقت
    cache_ttl: int = Field(default=3600, env="CACHE_TTL")  # 1 hour
    cache_max_size: int = Field(default=1000, env="CACHE_MAX_SIZE")
    
    # إعدادات التنظيف التلقائي
    auto_cleanup_enabled: bool = Field(default=True, env="AUTO_CLEANUP_ENABLED")
    cleanup_interval_hours: int = Field(default=24, env="CLEANUP_INTERVAL_HOURS")
    keep_uploads_days: int = Field(default=7, env="KEEP_UPLOADS_DAYS")
    keep_results_days: int = Field(default=30, env="KEEP_RESULTS_DAYS")
    
    # إعدادات المراقبة
    metrics_enabled: bool = Field(default=True, env="METRICS_ENABLED")
    health_check_interval: int = Field(default=60, env="HEALTH_CHECK_INTERVAL")  # seconds
    
    # إعدادات الإشعارات
    notifications_enabled: bool = Field(default=False, env="NOTIFICATIONS_ENABLED")
    webhook_url: Optional[str] = Field(default=None, env="WEBHOOK_URL")
    email_notifications: bool = Field(default=False, env="EMAIL_NOTIFICATIONS")
    
    # إعدادات SMTP (للإشعارات عبر البريد الإلكتروني)
    smtp_server: Optional[str] = Field(default=None, env="SMTP_SERVER")
    smtp_port: int = Field(default=587, env="SMTP_PORT")
    smtp_username: Optional[str] = Field(default=None, env="SMTP_USERNAME")
    smtp_password: Optional[str] = Field(default=None, env="SMTP_PASSWORD")
    smtp_use_tls: bool = Field(default=True, env="SMTP_USE_TLS")
    
    # إعدادات API
    api_rate_limit: int = Field(default=100, env="API_RATE_LIMIT")  # requests per minute
    api_key_required: bool = Field(default=False, env="API_KEY_REQUIRED")
    
    # إعدادات التطوير
    reload: bool = Field(default=False, env="RELOAD")
    docs_url: str = Field(default="/docs", env="DOCS_URL")
    redoc_url: str = Field(default="/redoc", env="REDOC_URL")
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._ensure_directories()
    
    def _ensure_directories(self):
        """إنشاء المجلدات المطلوبة"""
        directories = [
            self.upload_directory,
            self.results_directory,
            self.models_directory,
            self.static_directory,
        ]
        
        # إضافة مجلد السجلات إذا كان محدداً
        if self.log_file:
            log_dir = Path(self.log_file).parent
            directories.append(str(log_dir))
        
        for directory in directories:
            Path(directory).mkdir(parents=True, exist_ok=True)
    
    @property
    def database_url_sync(self) -> str:
        """رابط قاعدة البيانات المتزامن"""
        return self.database_url.replace("sqlite+aiosqlite://", "sqlite:///")
    
    @property
    def DATABASE_PATH(self) -> str:
        """مسار ملف قاعدة البيانات"""
        if self.database_url.startswith("sqlite:///"):
            return self.database_url.replace("sqlite:///", "")
        return "sperm_analyzer.db"
    
    @property
    def UPLOAD_PATH(self) -> str:
        """مسار مجلد الرفع"""
        return self.upload_directory
    
    @property
    def RESULTS_PATH(self) -> str:
        """مسار مجلد النتائج"""
        return self.results_directory
    
    @property
    def DEBUG(self) -> bool:
        """وضع التطوير"""
        return self.debug
    
    @property
    def is_production(self) -> bool:
        """هل البيئة إنتاجية"""
        return not self.debug and os.getenv("ENVIRONMENT", "development") == "production"
    
    @property
    def cors_origins_list(self) -> list:
        """قائمة المصادر المسموحة لـ CORS"""
        if isinstance(self.cors_origins, str):
            return [origin.strip() for origin in self.cors_origins.split(",")]
        return self.cors_origins
    
    def get_model_config(self) -> dict:
        """إعدادات النموذج"""
        return {
            "model_path": self.model_path,
            "confidence_threshold": self.confidence_threshold,
            "nms_threshold": self.nms_threshold,
            "use_gpu": self.use_gpu,
            "pixel_to_micron_ratio": self.pixel_to_micron_ratio
        }
    
    def get_tracking_config(self) -> dict:
        """إعدادات التتبع"""
        return {
            "max_age": self.max_track_age,
            "n_init": self.track_initialization,
            "min_track_length": self.min_track_length
        }
    
    def get_analysis_config(self) -> dict:
        """إعدادات التحليل"""
        return {
            "timeout": self.analysis_timeout,
            "pixel_to_micron_ratio": self.pixel_to_micron_ratio,
            "confidence_threshold": self.confidence_threshold,
            "nms_threshold": self.nms_threshold
        }
    
    def get_file_limits(self) -> dict:
        """حدود الملفات"""
        return {
            "max_upload_size": self.max_upload_size,
            "max_image_size": self.max_image_size,
            "max_video_size": self.max_video_size
        }
    
    def validate_settings(self) -> list:
        """التحقق من صحة الإعدادات"""
        errors = []
        
        # التحقق من وجود ملف النموذج
        if not os.path.exists(self.model_path):
            errors.append(f"ملف النموذج غير موجود: {self.model_path}")
        
        # التحقق من المجلدات
        required_dirs = [
            self.upload_directory,
            self.results_directory,
            self.models_directory
        ]
        
        for directory in required_dirs:
            if not os.path.exists(directory):
                try:
                    Path(directory).mkdir(parents=True, exist_ok=True)
                except Exception as e:
                    errors.append(f"فشل في إنشاء المجلد {directory}: {e}")
        
        # التحقق من إعدادات SMTP
        if self.email_notifications:
            if not self.smtp_server:
                errors.append("خادم SMTP مطلوب للإشعارات عبر البريد الإلكتروني")
            if not self.smtp_username:
                errors.append("اسم مستخدم SMTP مطلوب للإشعارات عبر البريد الإلكتروني")
        
        # التحقق من حدود الملفات
        if self.max_image_size > self.max_upload_size:
            errors.append("حد الصور أكبر من حد الرفع العام")
        
        if self.max_video_size > self.max_upload_size:
            errors.append("حد الفيديو أكبر من حد الرفع العام")
        
        # التحقق من المفتاح السري في الإنتاج
        if self.is_production and self.secret_key == "your-secret-key-change-in-production":
            errors.append("يجب تغيير المفتاح السري في بيئة الإنتاج")
        
        return errors

# إنشاء مثيل الإعدادات
settings = Settings()

# دالة للحصول على الإعدادات
def get_settings() -> Settings:
    """الحصول على مثيل الإعدادات"""
    return settings

# دالة لإعادة تحميل الإعدادات
def reload_settings():
    """إعادة تحميل الإعدادات"""
    global settings
    settings = Settings()
    return settings

# إعدادات النموذج
MODEL_CONFIG = {
    "supported_formats": {
        "images": [".jpg", ".jpeg", ".png", ".bmp", ".tiff"],
        "videos": [".mp4", ".avi", ".mov", ".mkv"]
    },
    "casa_parameters": {
        "VCL": {"min": 25.0, "max": 150.0, "unit": "μm/s"},
        "VSL": {"min": 15.0, "max": 75.0, "unit": "μm/s"},
        "VAP": {"min": 20.0, "max": 100.0, "unit": "μm/s"},
        "LIN": {"min": 40.0, "max": 85.0, "unit": "%"},
        "STR": {"min": 60.0, "max": 90.0, "unit": "%"},
        "WOB": {"min": 50.0, "max": 80.0, "unit": "%"},
        "ALH": {"min": 2.0, "max": 7.0, "unit": "μm"},
        "BCF": {"min": 5.0, "max": 45.0, "unit": "Hz"},
        "MOT": {"min": 40.0, "max": 100.0, "unit": "%"},
    },
    "quality_thresholds": {
        "excellent": 80,
        "good": 60,
        "fair": 40,
        "poor": 0
    }
}
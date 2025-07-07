from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from enum import Enum

class AnalysisStatus(str, Enum):
    """حالات التحليل"""
    PENDING = "pending"
    UPLOADING = "uploading" 
    PROCESSING = "processing"
    ANALYZING = "analyzing"
    COMPLETED = "completed"
    FAILED = "failed"

class AnalysisQuality(str, Enum):
    """جودة التحليل"""
    EXCELLENT = "excellent"
    GOOD = "good"
    FAIR = "fair"
    POOR = "poor"

class CasaParameters(BaseModel):
    """مؤشرات CASA"""
    vcl: float = Field(..., description="Curvilinear Velocity (μm/s)")
    vsl: float = Field(..., description="Straight-line Velocity (μm/s)")
    vap: float = Field(..., description="Average Path Velocity (μm/s)")
    lin: float = Field(..., description="Linearity (%)")
    str: float = Field(..., description="Straightness (%)")
    wob: float = Field(..., description="Wobble (%)")
    alh: float = Field(..., description="Amplitude of Lateral Head displacement (μm)")
    bcf: float = Field(..., description="Beat Cross Frequency (Hz)")
    mot: float = Field(..., description="Motility percentage (%)")

    def is_parameter_normal(self, parameter: str) -> bool:
        """تحديد ما إذا كان المؤشر ضمن النطاق الطبيعي"""
        normal_ranges = {
            'vcl': (25.0, 150.0),
            'vsl': (15.0, 75.0),
            'vap': (20.0, 100.0),
            'lin': (40.0, 85.0),
            'str': (60.0, 90.0),
            'wob': (50.0, 80.0),
            'alh': (2.0, 7.0),
            'bcf': (5.0, 45.0),
            'mot': (40.0, 100.0),
        }
        
        value = getattr(self, parameter.lower(), 0)
        if parameter.lower() in normal_ranges:
            min_val, max_val = normal_ranges[parameter.lower()]
            return min_val <= value <= max_val
        return True

class SpermMorphology(BaseModel):
    """تحليل شكل الحيوانات المنوية"""
    normal: float = Field(..., description="النسبة الطبيعية (%)")
    abnormal: float = Field(..., description="النسبة غير الطبيعية (%)")
    head_defects: float = Field(..., description="عيوب الرأس (%)")
    tail_defects: float = Field(..., description="عيوب الذيل (%)")
    neck_defects: float = Field(..., description="عيوب الرقبة (%)")

class VelocityDataPoint(BaseModel):
    """نقطة بيانات السرعة"""
    time_point: int = Field(..., description="النقطة الزمنية (ثانية)")
    velocity: float = Field(..., description="السرعة (μm/s)")

class SpermTrackingData(BaseModel):
    """بيانات تتبع الحيوان المنوي"""
    sperm_id: int = Field(..., description="معرف الحيوان المنوي")
    track_points: List[Dict[str, float]] = Field(..., description="نقاط المسار")
    total_distance: float = Field(..., description="المسافة الإجمالية")
    displacement: float = Field(..., description="الإزاحة")
    duration: float = Field(..., description="المدة الزمنية")

class AnalysisMetadata(BaseModel):
    """معلومات إضافية عن التحليل"""
    model_version: str = Field(..., description="إصدار النموذج")
    confidence: float = Field(..., description="مستوى الثقة")
    processing_time: int = Field(..., description="وقت المعالجة (ميلي ثانية)")
    frame_count: Optional[int] = Field(None, description="عدد الإطارات (للفيديو)")
    fps: Optional[float] = Field(None, description="معدل الإطارات")
    resolution: Optional[str] = Field(None, description="دقة الصورة/الفيديو")
    additional_data: Dict[str, Any] = Field(default_factory=dict, description="بيانات إضافية")

class AnalysisResult(BaseModel):
    """نتيجة التحليل الكاملة"""
    id: str = Field(..., description="معرف التحليل")
    file_name: str = Field(..., description="اسم الملف")
    file_size: int = Field(..., description="حجم الملف بالبايت")
    analysis_date: datetime = Field(..., description="تاريخ التحليل")
    status: AnalysisStatus = Field(default=AnalysisStatus.COMPLETED, description="حالة التحليل")
    
    # النتائج الأساسية
    sperm_count: int = Field(..., description="عدد الحيوانات المنوية")
    motility: float = Field(..., description="نسبة الحركة (%)")
    concentration: float = Field(..., description="التركيز (مليون/مل)")
    
    # التحليلات المتقدمة
    casa_parameters: CasaParameters = Field(..., description="مؤشرات CASA")
    morphology: SpermMorphology = Field(..., description="تحليل الشكل")
    velocity_distribution: List[VelocityDataPoint] = Field(..., description="توزيع السرعة")
    
    # بيانات التتبع (اختيارية)
    tracking_data: Optional[List[SpermTrackingData]] = Field(None, description="بيانات التتبع")
    
    # معلومات إضافية
    metadata: Optional[AnalysisMetadata] = Field(None, description="معلومات التحليل")
    
    def get_quality(self) -> AnalysisQuality:
        """تقييم جودة العينة"""
        scores = []
        
        # تقييم الحركة
        if self.motility >= 60:
            scores.append(100)
        elif self.motility >= 40:
            scores.append(75)
        elif self.motility >= 20:
            scores.append(50)
        else:
            scores.append(25)
        
        # تقييم التركيز
        if self.concentration >= 20:
            scores.append(100)
        elif self.concentration >= 15:
            scores.append(75)
        elif self.concentration >= 10:
            scores.append(50)
        else:
            scores.append(25)
        
        # تقييم الشكل
        if self.morphology.normal >= 70:
            scores.append(100)
        elif self.morphology.normal >= 50:
            scores.append(75)
        elif self.morphology.normal >= 30:
            scores.append(50)
        else:
            scores.append(25)
        
        # تقييم مؤشرات CASA
        lin_score = 100 if self.casa_parameters.lin >= 50 else (self.casa_parameters.lin / 50) * 100
        str_score = 100 if self.casa_parameters.str >= 70 else (self.casa_parameters.str / 70) * 100
        casa_score = (lin_score + str_score) / 2
        scores.append(casa_score)
        
        # حساب المتوسط
        average_score = sum(scores) / len(scores)
        
        if average_score >= 80:
            return AnalysisQuality.EXCELLENT
        elif average_score >= 60:
            return AnalysisQuality.GOOD
        elif average_score >= 40:
            return AnalysisQuality.FAIR
        else:
            return AnalysisQuality.POOR

    def to_dict(self) -> dict:
        """تحويل إلى قاموس"""
        return self.dict()

    def to_csv_string(self) -> str:
        """تحويل إلى نص CSV"""
        lines = ["Parameter,Value,Unit"]
        
        # البيانات الأساسية
        lines.append(f"Sperm Count,{self.sperm_count},count")
        lines.append(f"Motility,{self.motility:.1f},%")
        lines.append(f"Concentration,{self.concentration:.1f},M/ml")
        
        # مؤشرات CASA
        lines.append(f"VCL,{self.casa_parameters.vcl:.1f},μm/s")
        lines.append(f"VSL,{self.casa_parameters.vsl:.1f},μm/s")
        lines.append(f"VAP,{self.casa_parameters.vap:.1f},μm/s")
        lines.append(f"LIN,{self.casa_parameters.lin:.1f},%")
        lines.append(f"STR,{self.casa_parameters.str:.1f},%")
        lines.append(f"WOB,{self.casa_parameters.wob:.1f},%")
        lines.append(f"ALH,{self.casa_parameters.alh:.1f},μm")
        lines.append(f"BCF,{self.casa_parameters.bcf:.1f},Hz")
        lines.append(f"MOT,{self.casa_parameters.mot:.1f},%")
        
        # الشكل
        lines.append(f"Normal Morphology,{self.morphology.normal:.1f},%")
        lines.append(f"Abnormal Morphology,{self.morphology.abnormal:.1f},%")
        lines.append(f"Head Defects,{self.morphology.head_defects:.1f},%")
        lines.append(f"Tail Defects,{self.morphology.tail_defects:.1f},%")
        lines.append(f"Neck Defects,{self.morphology.neck_defects:.1f},%")
        
        return "\n".join(lines)

class AnalysisRequest(BaseModel):
    """طلب التحليل"""
    analysis_id: str = Field(..., description="معرف التحليل")
    file_path: Optional[str] = Field(None, description="مسار الملف")
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict, description="معاملات إضافية")

class AnalysisProgress(BaseModel):
    """تقدم التحليل"""
    analysis_id: str = Field(..., description="معرف التحليل")
    status: AnalysisStatus = Field(..., description="الحالة الحالية")
    progress: float = Field(..., description="نسبة التقدم (0-1)")
    message: str = Field(..., description="رسالة الحالة")
    estimated_time_remaining: Optional[int] = Field(None, description="الوقت المتبقي المقدر (ثواني)")

class ErrorResponse(BaseModel):
    """استجابة الخطأ"""
    error: str = Field(..., description="نوع الخطأ")
    message: str = Field(..., description="رسالة الخطأ")
    details: Optional[Dict[str, Any]] = Field(None, description="تفاصيل إضافية")

class SuccessResponse(BaseModel):
    """استجابة النجاح"""
    success: bool = Field(True, description="إشارة النجاح")
    message: str = Field(..., description="رسالة النجاح")
    data: Optional[Dict[str, Any]] = Field(None, description="البيانات")
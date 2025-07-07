# SpermAnalyzerAI - Training Scripts Package
"""
حزمة سكريبت التدريب لنموذج Sperm Analyzer AI

تحتوي هذه الحزمة على جميع الأدوات المطلوبة لتدريب وتقييم ونشر نموذج YOLOv8
لتحليل الحيوانات المنوية باستخدام الذكاء الاصطناعي.

المكونات:
- train_yolo.py: تدريب نموذج YOLOv8
- data_preprocessing.py: معالجة البيانات وتحسينها
- model_evaluation.py: تقييم النموذج وقياس الأداء
- model_deployment.py: نشر النموذج وتحسينه
- run_training.py: خط التدريب الشامل

الاستخدام:
python run_training.py --model-size nano --epochs 50

المطور: يوسف الشتيوي
"""

from .train_yolo import SpermYOLOTrainer
from .data_preprocessing import SpermDataPreprocessor
from .model_evaluation import SpermModelEvaluator
from .model_deployment import SpermModelDeployer

__version__ = "1.0.0"
__author__ = "يوسف الشتيوي"

__all__ = [
    "SpermYOLOTrainer",
    "SpermDataPreprocessor", 
    "SpermModelEvaluator",
    "SpermModelDeployer"
]
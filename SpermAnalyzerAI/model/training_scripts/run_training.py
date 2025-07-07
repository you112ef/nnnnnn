#!/usr/bin/env python3
# SpermAnalyzerAI - Complete Training Pipeline Runner
import sys
import argparse
from pathlib import Path
from loguru import logger
import time

# إضافة مجلد المشروع للمسار
sys.path.append(str(Path(__file__).parent.parent))

from train_yolo import SpermYOLOTrainer
from data_preprocessing import SpermDataPreprocessor
from model_evaluation import SpermModelEvaluator
from model_deployment import SpermModelDeployer

class SpermTrainingPipeline:
    """خط تدريب شامل لنموذج تحليل الحيوانات المنوية"""
    
    def __init__(self, config: dict):
        """
        تهيئة خط التدريب
        
        Args:
            config: إعدادات التدريب
        """
        self.config = config
        self.project_root = Path(__file__).parent.parent.parent
        
        # مسارات المشروع
        self.data_path = self.project_root / "data"
        self.models_path = self.project_root / "models"
        self.results_path = self.project_root / "results"
        
        # إنشاء المجلدات
        self.data_path.mkdir(exist_ok=True)
        self.models_path.mkdir(exist_ok=True)
        self.results_path.mkdir(exist_ok=True)
        
        logger.info(f"مجلد المشروع: {self.project_root}")
    
    def run_data_preprocessing(self) -> bool:
        """تشغيل معالجة البيانات"""
        logger.info("🔄 بدء معالجة البيانات...")
        
        try:
            # إنشاء معالج البيانات
            preprocessor = SpermDataPreprocessor(
                input_path=str(self.data_path / "raw"),
                output_path=str(self.data_path / "processed")
            )
            
            # معالجة البيانات
            preprocessor.process_dataset(
                quality_threshold=self.config.get('quality_threshold', 0.3),
                augmentation_factor=self.config.get('augmentation_factor', 2),
                extract_video_frames=self.config.get('extract_video_frames', True)
            )
            
            logger.info("✅ تم إكمال معالجة البيانات بنجاح")
            return True
            
        except Exception as e:
            logger.error(f"❌ فشل في معالجة البيانات: {e}")
            return False
    
    def run_model_training(self) -> str:
        """تشغيل تدريب النموذج"""
        logger.info("🤖 بدء تدريب النموذج...")
        
        try:
            # إنشاء مدرب النموذج
            trainer = SpermYOLOTrainer(
                data_path=str(self.data_path),
                model_size=self.config.get('model_size', 'nano')
            )
            
            # تحديث إعدادات التدريب
            if 'training_config' in self.config:
                trainer.training_config.update(self.config['training_config'])
            
            # إنشاء تكوين البيانات
            data_config = trainer.create_dataset_config()
            
            # إنتاج بيانات اصطناعية إذا لم توجد بيانات حقيقية
            processed_images = list((self.data_path / "processed" / "images" / "train").glob("*.jpg"))
            if len(processed_images) == 0:
                logger.info("لا توجد بيانات حقيقية - إنتاج بيانات اصطناعية...")
                trainer.generate_synthetic_data(
                    count=self.config.get('synthetic_data_count', 1000)
                )
            
            # تدريب النموذج
            model_path, training_results = trainer.train_model(data_config)
            
            logger.info(f"✅ تم إكمال التدريب بنجاح: {model_path}")
            return model_path
            
        except Exception as e:
            logger.error(f"❌ فشل في تدريب النموذج: {e}")
            return ""
    
    def run_model_evaluation(self, model_path: str) -> dict:
        """تشغيل تقييم النموذج"""
        logger.info("📊 بدء تقييم النموذج...")
        
        try:
            # إنشاء مقيم النموذج
            evaluator = SpermModelEvaluator(
                model_path=model_path,
                test_data_path=str(self.data_path / "processed")
            )
            
            # تشغيل التقييم
            metrics = evaluator.run_evaluation()
            
            logger.info("✅ تم إكمال التقييم بنجاح")
            return metrics
            
        except Exception as e:
            logger.error(f"❌ فشل في تقييم النموذج: {e}")
            return {}
    
    def run_model_deployment(self, model_path: str) -> bool:
        """تشغيل نشر النموذج"""
        logger.info("🚀 بدء نشر النموذج...")
        
        try:
            # إنشاء منشر النموذج
            deployer = SpermModelDeployer(
                model_path=model_path,
                output_dir=str(self.models_path / "deployed")
            )
            
            # نشر النموذج
            success = deployer.deploy_all_formats()
            
            if success:
                logger.info("✅ تم إكمال النشر بنجاح")
            else:
                logger.warning("⚠️ تم النشر مع بعض المشاكل")
            
            return success
            
        except Exception as e:
            logger.error(f"❌ فشل في نشر النموذج: {e}")
            return False
    
    def run_full_pipeline(self) -> dict:
        """تشغيل خط التدريب الكامل"""
        logger.info("🎯 بدء خط التدريب الشامل لـ Sperm Analyzer AI")
        
        start_time = time.time()
        results = {
            'start_time': start_time,
            'stages': {},
            'final_model_path': "",
            'evaluation_metrics': {},
            'deployment_success': False,
            'total_time': 0
        }
        
        # 1. معالجة البيانات
        stage_start = time.time()
        if self.config.get('run_preprocessing', True):
            preprocessing_success = self.run_data_preprocessing()
            results['stages']['preprocessing'] = {
                'success': preprocessing_success,
                'time': time.time() - stage_start
            }
            
            if not preprocessing_success and self.config.get('require_preprocessing', False):
                logger.error("فشل في معالجة البيانات - توقف التدريب")
                return results
        
        # 2. تدريب النموذج
        stage_start = time.time()
        model_path = self.run_model_training()
        results['stages']['training'] = {
            'success': bool(model_path),
            'time': time.time() - stage_start,
            'model_path': model_path
        }
        results['final_model_path'] = model_path
        
        if not model_path:
            logger.error("فشل في تدريب النموذج - توقف التدريب")
            return results
        
        # 3. تقييم النموذج
        if self.config.get('run_evaluation', True):
            stage_start = time.time()
            evaluation_metrics = self.run_model_evaluation(model_path)
            results['stages']['evaluation'] = {
                'success': bool(evaluation_metrics),
                'time': time.time() - stage_start
            }
            results['evaluation_metrics'] = evaluation_metrics
        
        # 4. نشر النموذج
        if self.config.get('run_deployment', True):
            stage_start = time.time()
            deployment_success = self.run_model_deployment(model_path)
            results['stages']['deployment'] = {
                'success': deployment_success,
                'time': time.time() - stage_start
            }
            results['deployment_success'] = deployment_success
        
        # حساب الوقت الإجمالي
        results['total_time'] = time.time() - start_time
        
        # طباعة ملخص النتائج
        self.print_pipeline_summary(results)
        
        return results
    
    def print_pipeline_summary(self, results: dict):
        """طباعة ملخص نتائج التدريب"""
        print("\n" + "="*60)
        print("🎯 ملخص نتائج تدريب Sperm Analyzer AI")
        print("="*60)
        
        # ملخص المراحل
        for stage_name, stage_info in results['stages'].items():
            status = "✅ نجح" if stage_info['success'] else "❌ فشل"
            time_str = f"{stage_info['time']:.2f}s"
            print(f"{stage_name.capitalize()}: {status} ({time_str})")
        
        print(f"\nالوقت الإجمالي: {results['total_time']:.2f} ثانية")
        
        # النموذج النهائي
        if results['final_model_path']:
            print(f"النموذج النهائي: {results['final_model_path']}")
        
        # مقاييس التقييم
        if results['evaluation_metrics']:
            metrics = results['evaluation_metrics']
            print(f"\nمقاييس الأداء:")
            print(f"  Precision: {metrics.get('precision', 0):.4f}")
            print(f"  Recall: {metrics.get('recall', 0):.4f}")
            print(f"  F1-Score: {metrics.get('f1_score', 0):.4f}")
            print(f"  FPS: {metrics.get('fps', 0):.2f}")
        
        # حالة النشر
        if results['deployment_success']:
            print(f"\n🚀 تم نشر النموذج بنجاح في: models/deployed/")
        
        print("="*60)

def create_default_config() -> dict:
    """إنشاء إعدادات افتراضية"""
    return {
        # إعدادات عامة
        'run_preprocessing': True,
        'run_evaluation': True,
        'run_deployment': True,
        'require_preprocessing': False,
        
        # إعدادات معالجة البيانات
        'quality_threshold': 0.3,
        'augmentation_factor': 2,
        'extract_video_frames': True,
        'synthetic_data_count': 500,
        
        # إعدادات النموذج
        'model_size': 'nano',  # nano, small, medium, large, xlarge
        
        # إعدادات التدريب
        'training_config': {
            'epochs': 50,
            'batch_size': 16,
            'imgsz': 640,
            'lr0': 0.01,
            'patience': 10,
            'save_period': 5,
            'workers': 4,
            'device': 'auto'
        }
    }

def parse_arguments():
    """تحليل مدخلات سطر الأوامر"""
    parser = argparse.ArgumentParser(
        description="SpermAnalyzerAI - خط تدريب شامل لنموذج تحليل الحيوانات المنوية"
    )
    
    parser.add_argument(
        '--config', '-c',
        type=str,
        help="مسار ملف إعدادات JSON (اختياري)"
    )
    
    parser.add_argument(
        '--model-size', '-m',
        choices=['nano', 'small', 'medium', 'large', 'xlarge'],
        default='nano',
        help="حجم نموذج YOLOv8 (افتراضي: nano)"
    )
    
    parser.add_argument(
        '--epochs', '-e',
        type=int,
        default=50,
        help="عدد دورات التدريب (افتراضي: 50)"
    )
    
    parser.add_argument(
        '--batch-size', '-b',
        type=int,
        default=16,
        help="حجم الدفعة (افتراضي: 16)"
    )
    
    parser.add_argument(
        '--skip-preprocessing',
        action='store_true',
        help="تخطي معالجة البيانات"
    )
    
    parser.add_argument(
        '--skip-evaluation',
        action='store_true',
        help="تخطي تقييم النموذج"
    )
    
    parser.add_argument(
        '--skip-deployment',
        action='store_true',
        help="تخطي نشر النموذج"
    )
    
    parser.add_argument(
        '--synthetic-only',
        action='store_true',
        help="استخدام البيانات الاصطناعية فقط"
    )
    
    return parser.parse_args()

def main():
    """الدالة الرئيسية"""
    # تحليل المدخلات
    args = parse_arguments()
    
    # إنشاء الإعدادات
    config = create_default_config()
    
    # تحديث الإعدادات من المدخلات
    config['model_size'] = args.model_size
    config['training_config']['epochs'] = args.epochs
    config['training_config']['batch_size'] = args.batch_size
    config['run_preprocessing'] = not args.skip_preprocessing
    config['run_evaluation'] = not args.skip_evaluation
    config['run_deployment'] = not args.skip_deployment
    
    if args.synthetic_only:
        config['synthetic_data_count'] = 1000
        config['run_preprocessing'] = False
    
    # تحميل ملف الإعدادات إذا تم تحديده
    if args.config:
        import json
        with open(args.config, 'r', encoding='utf-8') as f:
            custom_config = json.load(f)
            config.update(custom_config)
    
    # إنشاء وتشغيل خط التدريب
    pipeline = SpermTrainingPipeline(config)
    
    try:
        results = pipeline.run_full_pipeline()
        
        # حفظ النتائج
        results_file = pipeline.results_path / "training_results.json"
        with open(results_file, 'w', encoding='utf-8') as f:
            import json
            json.dump(results, f, indent=2, ensure_ascii=False, default=str)
        
        logger.info(f"تم حفظ تقرير التدريب: {results_file}")
        
        # تحديد حالة الخروج
        success = (
            results['final_model_path'] and
            results['stages'].get('training', {}).get('success', False)
        )
        
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        logger.info("تم إيقاف التدريب بواسطة المستخدم")
        sys.exit(1)
    except Exception as e:
        logger.error(f"خطأ غير متوقع: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
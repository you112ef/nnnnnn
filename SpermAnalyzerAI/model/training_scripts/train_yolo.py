# SpermAnalyzerAI - YOLOv8 Model Training Script
import os
import yaml
from pathlib import Path
from ultralytics import YOLO
import torch
import cv2
import numpy as np
from loguru import logger

class SpermYOLOTrainer:
    """فئة تدريب نموذج YOLOv8 لتحليل الحيوانات المنوية"""
    
    def __init__(self, data_path: str = "data", model_size: str = "nano"):
        """
        تهيئة المدرب
        
        Args:
            data_path: مسار بيانات التدريب
            model_size: حجم النموذج (nano, small, medium, large, xlarge)
        """
        self.data_path = Path(data_path)
        self.model_size = model_size
        self.model_name = f"yolov8{model_size[0]}.pt"  # yolov8n.pt, yolov8s.pt, etc.
        self.output_path = Path("models")
        self.output_path.mkdir(exist_ok=True)
        
        # إعداد الجهاز
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"استخدام الجهاز: {self.device}")
        
        # معلمات التدريب
        self.training_config = {
            "epochs": 100,
            "batch_size": 16 if self.device == "cuda" else 8,
            "imgsz": 640,
            "lr0": 0.01,
            "lrf": 0.01,
            "momentum": 0.937,
            "weight_decay": 0.0005,
            "warmup_epochs": 3,
            "warmup_momentum": 0.8,
            "warmup_bias_lr": 0.1,
            "box": 7.5,
            "cls": 0.5,
            "dfl": 1.5,
            "pose": 12.0,
            "kobj": 1.0,
            "label_smoothing": 0.0,
            "nbs": 64,
            "overlap_mask": True,
            "mask_ratio": 4,
            "dropout": 0.0,
            "val": True,
            "save": True,
            "save_period": 10,
            "cache": False,
            "device": self.device,
            "workers": 8 if self.device == "cuda" else 4,
            "project": "sperm_analysis",
            "name": "yolov8_sperm",
            "exist_ok": True,
            "pretrained": True,
            "optimizer": "SGD",
            "verbose": True,
            "seed": 42,
            "deterministic": True,
            "single_cls": False,
            "rect": False,
            "cos_lr": False,
            "close_mosaic": 10,
            "resume": False,
            "amp": True,
            "fraction": 1.0,
            "profile": False,
            "freeze": None,
        }
    
    def create_dataset_config(self):
        """إنشاء ملف تكوين البيانات"""
        
        # إنشاء مجلدات البيانات
        dataset_path = self.data_path / "sperm_dataset"
        dataset_path.mkdir(exist_ok=True)
        
        (dataset_path / "images" / "train").mkdir(parents=True, exist_ok=True)
        (dataset_path / "images" / "val").mkdir(parents=True, exist_ok=True)
        (dataset_path / "labels" / "train").mkdir(parents=True, exist_ok=True)
        (dataset_path / "labels" / "val").mkdir(parents=True, exist_ok=True)
        
        # تكوين البيانات
        dataset_config = {
            "path": str(dataset_path.absolute()),
            "train": "images/train",
            "val": "images/val",
            "nc": 1,  # عدد الفئات (حيوان منوي واحد فقط)
            "names": ["sperm"]
        }
        
        config_path = dataset_path / "dataset.yaml"
        with open(config_path, 'w', encoding='utf-8') as f:
            yaml.dump(dataset_config, f, default_flow_style=False, allow_unicode=True)
        
        logger.info(f"تم إنشاء ملف تكوين البيانات: {config_path}")
        return str(config_path)
    
    def generate_synthetic_data(self, count: int = 1000):
        """
        إنتاج بيانات تدريب اصطناعية للاختبار
        
        Args:
            count: عدد الصور المراد إنتاجها
        """
        logger.info("إنتاج بيانات تدريب اصطناعية...")
        
        dataset_path = self.data_path / "sperm_dataset"
        
        for split in ["train", "val"]:
            split_count = int(count * 0.8) if split == "train" else int(count * 0.2)
            images_dir = dataset_path / "images" / split
            labels_dir = dataset_path / "labels" / split
            
            for i in range(split_count):
                # إنشاء صورة اصطناعية
                image = self._generate_synthetic_image()
                
                # حفظ الصورة
                image_path = images_dir / f"sperm_{split}_{i:04d}.jpg"
                cv2.imwrite(str(image_path), image)
                
                # إنشاء تسميات عشوائية
                labels = self._generate_synthetic_labels()
                
                # حفظ التسميات
                label_path = labels_dir / f"sperm_{split}_{i:04d}.txt"
                with open(label_path, 'w') as f:
                    for label in labels:
                        f.write(f"0 {label[0]:.6f} {label[1]:.6f} {label[2]:.6f} {label[3]:.6f}\n")
        
        logger.info(f"تم إنتاج {count} صورة تدريب اصطناعية")
    
    def _generate_synthetic_image(self, width: int = 640, height: int = 640):
        """إنشاء صورة اصطناعية للحيوانات المنوية"""
        # خلفية رمادية مع ضوضاء
        image = np.random.randint(50, 100, (height, width, 3), dtype=np.uint8)
        
        # إضافة حبيبات وتشويش
        noise = np.random.randint(-20, 20, (height, width, 3), dtype=np.int16)
        image = np.clip(image.astype(np.int16) + noise, 0, 255).astype(np.uint8)
        
        # إضافة أشكال تشبه الحيوانات المنوية
        num_sperm = np.random.randint(5, 25)
        for _ in range(num_sperm):
            self._add_synthetic_sperm(image)
        
        return image
    
    def _add_synthetic_sperm(self, image):
        """إضافة شكل حيوان منوي اصطناعي"""
        h, w = image.shape[:2]
        
        # موقع عشوائي
        center_x = np.random.randint(30, w-30)
        center_y = np.random.randint(30, h-30)
        
        # لون أفتح قليلاً من الخلفية
        color = np.random.randint(120, 180)
        
        # رسم الرأس (دائرة صغيرة)
        head_radius = np.random.randint(3, 8)
        cv2.circle(image, (center_x, center_y), head_radius, (color, color, color), -1)
        
        # رسم الذيل (خط منحني)
        tail_length = np.random.randint(20, 50)
        tail_thickness = np.random.randint(1, 3)
        
        # نقاط الذيل
        points = []
        for i in range(tail_length):
            offset_x = center_x + i
            offset_y = center_y + int(5 * np.sin(i * 0.2)) + np.random.randint(-2, 2)
            
            if 0 <= offset_x < w and 0 <= offset_y < h:
                points.append((offset_x, offset_y))
        
        # رسم الذيل
        if len(points) > 1:
            points = np.array(points, np.int32)
            cv2.polylines(image, [points], False, (color, color, color), tail_thickness)
    
    def _generate_synthetic_labels(self):
        """إنتاج تسميات عشوائية بتنسيق YOLO"""
        num_objects = np.random.randint(5, 25)
        labels = []
        
        for _ in range(num_objects):
            # إحداثيات مركز المربع المحيط (نسبية)
            center_x = np.random.uniform(0.1, 0.9)
            center_y = np.random.uniform(0.1, 0.9)
            
            # العرض والارتفاع (نسبي)
            width = np.random.uniform(0.02, 0.1)
            height = np.random.uniform(0.02, 0.1)
            
            labels.append([center_x, center_y, width, height])
        
        return labels
    
    def train_model(self, data_config_path: str):
        """تدريب النموذج"""
        logger.info("بدء تدريب نموذج YOLOv8...")
        
        try:
            # تحميل النموذج المسبق التدريب
            model = YOLO(self.model_name)
            
            # بدء التدريب
            results = model.train(
                data=data_config_path,
                **self.training_config
            )
            
            # حفظ النموذج المدرب
            model_path = self.output_path / "sperm_yolov8.pt"
            model.save(str(model_path))
            
            logger.info(f"تم حفظ النموذج المدرب: {model_path}")
            
            return str(model_path), results
            
        except Exception as e:
            logger.error(f"خطأ في التدريب: {e}")
            raise
    
    def validate_model(self, model_path: str, data_config_path: str):
        """التحقق من النموذج"""
        logger.info("التحقق من النموذج...")
        
        try:
            model = YOLO(model_path)
            results = model.val(data=data_config_path)
            
            logger.info("نتائج التحقق:")
            logger.info(f"mAP50: {results.box.map50:.4f}")
            logger.info(f"mAP50-95: {results.box.map:.4f}")
            logger.info(f"Precision: {results.box.mp:.4f}")
            logger.info(f"Recall: {results.box.mr:.4f}")
            
            return results
            
        except Exception as e:
            logger.error(f"خطأ في التحقق: {e}")
            raise
    
    def test_inference(self, model_path: str, test_image_path: str = None):
        """اختبار الاستنتاج"""
        logger.info("اختبار الاستنتاج...")
        
        try:
            model = YOLO(model_path)
            
            if test_image_path and os.path.exists(test_image_path):
                # اختبار على صورة حقيقية
                results = model(test_image_path)
            else:
                # إنشاء صورة اختبار اصطناعية
                test_image = self._generate_synthetic_image()
                results = model(test_image)
            
            logger.info(f"تم اكتشاف {len(results[0].boxes)} حيوان منوي")
            
            return results
            
        except Exception as e:
            logger.error(f"خطأ في الاستنتاج: {e}")
            raise

def main():
    """تشغيل التدريب"""
    try:
        # إنشاء مدرب
        trainer = SpermYOLOTrainer(model_size="nano")  # نموذج صغير للاختبار السريع
        
        # إنشاء تكوين البيانات
        data_config = trainer.create_dataset_config()
        
        # إنتاج بيانات تدريب اصطناعية
        trainer.generate_synthetic_data(count=500)  # عدد صغير للاختبار
        
        # تدريب النموذج
        model_path, training_results = trainer.train_model(data_config)
        
        # التحقق من النموذج
        validation_results = trainer.validate_model(model_path, data_config)
        
        # اختبار الاستنتاج
        inference_results = trainer.test_inference(model_path)
        
        logger.info("✅ تم إكمال التدريب بنجاح!")
        
    except Exception as e:
        logger.error(f"❌ فشل التدريب: {e}")
        raise

if __name__ == "__main__":
    main()
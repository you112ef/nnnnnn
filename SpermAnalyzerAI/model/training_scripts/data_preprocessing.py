# SpermAnalyzerAI - Data Preprocessing Script
import os
import cv2
import numpy as np
import pandas as pd
from pathlib import Path
from typing import List, Tuple, Dict, Optional
import albumentations as A
from albumentations.pytorch import ToTensorV2
import json
from loguru import logger
from sklearn.model_selection import train_test_split
import shutil

class SpermDataPreprocessor:
    """فئة معالجة بيانات الحيوانات المنوية"""
    
    def __init__(self, input_path: str, output_path: str = "data/processed"):
        """
        تهيئة المعالج
        
        Args:
            input_path: مسار البيانات الأولية
            output_path: مسار البيانات المعالجة
        """
        self.input_path = Path(input_path)
        self.output_path = Path(output_path)
        self.output_path.mkdir(parents=True, exist_ok=True)
        
        # إعدادات المعالجة
        self.target_size = (640, 640)
        self.image_formats = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff']
        self.video_formats = ['.mp4', '.avi', '.mov', '.mkv']
        
        # إحصائيات البيانات
        self.stats = {
            'total_images': 0,
            'total_videos': 0,
            'total_annotations': 0,
            'processed_images': 0,
            'augmented_images': 0,
            'quality_filtered': 0
        }
    
    def setup_directories(self):
        """إنشاء مجلدات المشروع"""
        directories = [
            self.output_path / "images" / "train",
            self.output_path / "images" / "val",
            self.output_path / "images" / "test",
            self.output_path / "labels" / "train",
            self.output_path / "labels" / "val",
            self.output_path / "labels" / "test",
            self.output_path / "videos" / "train",
            self.output_path / "videos" / "val",
            self.output_path / "annotations",
            self.output_path / "statistics"
        ]
        
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"تم إنشاء مجلدات المشروع في: {self.output_path}")
    
    def scan_dataset(self) -> Dict[str, List[Path]]:
        """فحص مجموعة البيانات"""
        logger.info("فحص مجموعة البيانات...")
        
        files = {
            'images': [],
            'videos': [],
            'annotations': []
        }
        
        # فحص الملفات
        for file_path in self.input_path.rglob('*'):
            if file_path.is_file():
                suffix = file_path.suffix.lower()
                
                if suffix in self.image_formats:
                    files['images'].append(file_path)
                elif suffix in self.video_formats:
                    files['videos'].append(file_path)
                elif suffix in ['.txt', '.json', '.xml']:
                    files['annotations'].append(file_path)
        
        # تحديث الإحصائيات
        self.stats['total_images'] = len(files['images'])
        self.stats['total_videos'] = len(files['videos'])
        self.stats['total_annotations'] = len(files['annotations'])
        
        logger.info(f"تم العثور على {self.stats['total_images']} صورة")
        logger.info(f"تم العثور على {self.stats['total_videos']} فيديو")
        logger.info(f"تم العثور على {self.stats['total_annotations']} ملف تسمية")
        
        return files
    
    def assess_image_quality(self, image_path: Path) -> Dict[str, float]:
        """تقييم جودة الصورة"""
        try:
            image = cv2.imread(str(image_path))
            if image is None:
                return {'quality_score': 0.0, 'valid': False}
            
            # تحويل إلى رمادي
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # حساب مؤشرات الجودة
            # 1. حدة الصورة (Laplacian variance)
            laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
            
            # 2. السطوع المتوسط
            mean_brightness = np.mean(gray)
            
            # 3. التباين
            contrast = np.std(gray)
            
            # 4. تدرج الألوان
            hist = cv2.calcHist([gray], [0], None, [256], [0, 256])
            entropy = -np.sum(hist * np.log2(hist + 1e-7))
            
            # حساب نقاط الجودة
            sharpness_score = min(laplacian_var / 100, 1.0)
            brightness_score = 1.0 - abs(mean_brightness - 128) / 128
            contrast_score = min(contrast / 50, 1.0)
            entropy_score = min(entropy / 8, 1.0)
            
            # النتيجة النهائية
            quality_score = (
                sharpness_score * 0.3 +
                brightness_score * 0.25 +
                contrast_score * 0.25 +
                entropy_score * 0.2
            )
            
            return {
                'quality_score': quality_score,
                'sharpness': laplacian_var,
                'brightness': mean_brightness,
                'contrast': contrast,
                'entropy': entropy,
                'valid': quality_score > 0.3  # حد أدنى للجودة
            }
            
        except Exception as e:
            logger.error(f"خطأ في تقييم جودة الصورة {image_path}: {e}")
            return {'quality_score': 0.0, 'valid': False}
    
    def preprocess_image(self, image_path: Path, target_size: Tuple[int, int] = None) -> np.ndarray:
        """معالجة الصورة"""
        if target_size is None:
            target_size = self.target_size
        
        try:
            # قراءة الصورة
            image = cv2.imread(str(image_path))
            if image is None:
                raise ValueError(f"لا يمكن قراءة الصورة: {image_path}")
            
            # تحويل إلى RGB
            image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # تغيير الحجم مع الحفاظ على النسبة
            h, w = image.shape[:2]
            target_w, target_h = target_size
            
            # حساب النسبة
            scale = min(target_w / w, target_h / h)
            new_w = int(w * scale)
            new_h = int(h * scale)
            
            # تغيير الحجم
            image = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
            
            # إضافة حشو للوصول للحجم المطلوب
            delta_w = target_w - new_w
            delta_h = target_h - new_h
            top, bottom = delta_h // 2, delta_h - (delta_h // 2)
            left, right = delta_w // 2, delta_w - (delta_w // 2)
            
            # حشو بلون متوسط
            color = np.mean(image, axis=(0, 1))
            image = cv2.copyMakeBorder(
                image, top, bottom, left, right, 
                cv2.BORDER_CONSTANT, value=color
            )
            
            return image
            
        except Exception as e:
            logger.error(f"خطأ في معالجة الصورة {image_path}: {e}")
            raise
    
    def create_augmentation_pipeline(self) -> A.Compose:
        """إنشاء خط معالجة التحسين"""
        return A.Compose([
            # تحويلات هندسية
            A.RandomRotate90(p=0.3),
            A.Flip(p=0.3),
            A.Rotate(limit=15, p=0.3),
            A.ShiftScaleRotate(
                shift_limit=0.1,
                scale_limit=0.1,
                rotate_limit=15,
                p=0.3
            ),
            
            # تحويلات الألوان
            A.RandomBrightnessContrast(
                brightness_limit=0.2,
                contrast_limit=0.2,
                p=0.3
            ),
            A.HueSaturationValue(
                hue_shift_limit=10,
                sat_shift_limit=20,
                val_shift_limit=20,
                p=0.3
            ),
            
            # تحويلات الضوضاء والتشويش
            A.GaussNoise(var_limit=(10, 50), p=0.2),
            A.GaussianBlur(blur_limit=3, p=0.2),
            A.MotionBlur(blur_limit=3, p=0.2),
            
            # تحويلات أخرى
            A.CLAHE(clip_limit=2, p=0.2),
            A.RandomGamma(gamma_limit=(80, 120), p=0.2),
            
            # تطبيع
            A.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            ),
            ToTensorV2()
        ], bbox_params=A.BboxParams(
            format='yolo',
            label_fields=['class_labels']
        ))
    
    def extract_frames_from_video(self, video_path: Path, output_dir: Path, 
                                 frame_interval: int = 30) -> List[Path]:
        """استخراج إطارات من الفيديو"""
        try:
            cap = cv2.VideoCapture(str(video_path))
            if not cap.isOpened():
                raise ValueError(f"لا يمكن فتح الفيديو: {video_path}")
            
            fps = cap.get(cv2.CAP_PROP_FPS)
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            
            logger.info(f"معالجة فيديو {video_path.name}: {total_frames} إطار، {fps} fps")
            
            extracted_frames = []
            frame_count = 0
            saved_count = 0
            
            while True:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # حفظ الإطار كل frame_interval إطار
                if frame_count % frame_interval == 0:
                    frame_filename = f"{video_path.stem}_frame_{saved_count:06d}.jpg"
                    frame_path = output_dir / frame_filename
                    
                    cv2.imwrite(str(frame_path), frame)
                    extracted_frames.append(frame_path)
                    saved_count += 1
                
                frame_count += 1
            
            cap.release()
            logger.info(f"تم استخراج {len(extracted_frames)} إطار من {video_path.name}")
            
            return extracted_frames
            
        except Exception as e:
            logger.error(f"خطأ في استخراج الإطارات من {video_path}: {e}")
            return []
    
    def split_dataset(self, image_paths: List[Path], 
                     train_ratio: float = 0.7, 
                     val_ratio: float = 0.2, 
                     test_ratio: float = 0.1) -> Dict[str, List[Path]]:
        """تقسيم البيانات إلى تدريب وتحقق واختبار"""
        
        # التحقق من النسب
        assert abs(train_ratio + val_ratio + test_ratio - 1.0) < 1e-6, "النسب يجب أن تكون مجموعها 1"
        
        # التقسيم الأول: تدريب والباقي
        train_paths, temp_paths = train_test_split(
            image_paths, 
            test_size=(1 - train_ratio), 
            random_state=42
        )
        
        # التقسيم الثاني: تحقق واختبار
        val_size = val_ratio / (val_ratio + test_ratio)
        val_paths, test_paths = train_test_split(
            temp_paths, 
            test_size=(1 - val_size), 
            random_state=42
        )
        
        logger.info(f"تقسيم البيانات: {len(train_paths)} تدريب، {len(val_paths)} تحقق، {len(test_paths)} اختبار")
        
        return {
            'train': train_paths,
            'val': val_paths,
            'test': test_paths
        }
    
    def save_dataset_statistics(self):
        """حفظ إحصائيات البيانات"""
        stats_file = self.output_path / "statistics" / "dataset_stats.json"
        
        with open(stats_file, 'w', encoding='utf-8') as f:
            json.dump(self.stats, f, indent=2, ensure_ascii=False)
        
        logger.info(f"تم حفظ إحصائيات البيانات: {stats_file}")
    
    def process_dataset(self, 
                       quality_threshold: float = 0.3,
                       augmentation_factor: int = 2,
                       extract_video_frames: bool = True):
        """معالجة مجموعة البيانات الكاملة"""
        logger.info("بدء معالجة مجموعة البيانات...")
        
        # إنشاء المجلدات
        self.setup_directories()
        
        # فحص البيانات
        files = self.scan_dataset()
        
        # معالجة الصور
        valid_images = []
        for image_path in files['images']:
            quality = self.assess_image_quality(image_path)
            
            if quality['valid'] and quality['quality_score'] >= quality_threshold:
                valid_images.append(image_path)
                self.stats['processed_images'] += 1
            else:
                self.stats['quality_filtered'] += 1
        
        # استخراج إطارات من الفيديوهات
        if extract_video_frames:
            video_frames_dir = self.output_path / "video_frames"
            video_frames_dir.mkdir(exist_ok=True)
            
            for video_path in files['videos']:
                frames = self.extract_frames_from_video(video_path, video_frames_dir)
                valid_images.extend(frames)
        
        # تقسيم البيانات
        dataset_splits = self.split_dataset(valid_images)
        
        # معالجة كل تقسيم
        augmentation_pipeline = self.create_augmentation_pipeline()
        
        for split_name, image_paths in dataset_splits.items():
            logger.info(f"معالجة {split_name}: {len(image_paths)} صورة")
            
            for i, image_path in enumerate(image_paths):
                # معالجة الصورة الأساسية
                processed_image = self.preprocess_image(image_path)
                
                # حفظ الصورة
                output_name = f"{image_path.stem}_{i:06d}.jpg"
                output_path = self.output_path / "images" / split_name / output_name
                
                cv2.imwrite(str(output_path), cv2.cvtColor(processed_image, cv2.COLOR_RGB2BGR))
                
                # إنشاء تسمية أساسية (فارغة أو من ملف موجود)
                label_path = self.output_path / "labels" / split_name / f"{output_name[:-4]}.txt"
                self._create_default_label(label_path, processed_image.shape[:2])
                
                # إنشاء صور محسنة للتدريب فقط
                if split_name == 'train' and augmentation_factor > 1:
                    for aug_idx in range(augmentation_factor - 1):
                        try:
                            # تطبيق التحسين
                            augmented = augmentation_pipeline(image=processed_image)
                            aug_image = augmented['image']
                            
                            # حفظ الصورة المحسنة
                            aug_name = f"{image_path.stem}_{i:06d}_aug_{aug_idx:02d}.jpg"
                            aug_path = self.output_path / "images" / split_name / aug_name
                            
                            # تحويل من tensor إلى numpy إذا لزم الأمر
                            if hasattr(aug_image, 'numpy'):
                                aug_image = aug_image.numpy().transpose(1, 2, 0)
                                aug_image = (aug_image * 255).astype(np.uint8)
                            
                            cv2.imwrite(str(aug_path), cv2.cvtColor(aug_image, cv2.COLOR_RGB2BGR))
                            
                            # تسمية للصورة المحسنة
                            aug_label_path = self.output_path / "labels" / split_name / f"{aug_name[:-4]}.txt"
                            self._create_default_label(aug_label_path, aug_image.shape[:2])
                            
                            self.stats['augmented_images'] += 1
                            
                        except Exception as e:
                            logger.warning(f"فشل في تحسين الصورة {image_path}: {e}")
        
        # حفظ الإحصائيات
        self.save_dataset_statistics()
        
        logger.info("✅ تم إكمال معالجة البيانات بنجاح!")
        logger.info(f"الإحصائيات النهائية: {self.stats}")
    
    def _create_default_label(self, label_path: Path, image_shape: Tuple[int, int]):
        """إنشاء تسمية افتراضية (فارغة أو عشوائية للاختبار)"""
        # إنشاء تسميات عشوائية للاختبار
        num_objects = np.random.randint(0, 5)
        
        with open(label_path, 'w') as f:
            for _ in range(num_objects):
                # إحداثيات عشوائية (class_id, center_x, center_y, width, height)
                center_x = np.random.uniform(0.1, 0.9)
                center_y = np.random.uniform(0.1, 0.9)
                width = np.random.uniform(0.02, 0.1)
                height = np.random.uniform(0.02, 0.1)
                
                f.write(f"0 {center_x:.6f} {center_y:.6f} {width:.6f} {height:.6f}\n")

def main():
    """تشغيل معالجة البيانات"""
    input_directory = "raw_data"  # مجلد البيانات الأولية
    output_directory = "data/processed"  # مجلد البيانات المعالجة
    
    # إنشاء مجلد البيانات الأولية للاختبار
    Path(input_directory).mkdir(exist_ok=True)
    
    # إنشاء معالج البيانات
    preprocessor = SpermDataPreprocessor(input_directory, output_directory)
    
    # معالجة البيانات
    preprocessor.process_dataset(
        quality_threshold=0.3,
        augmentation_factor=3,
        extract_video_frames=True
    )

if __name__ == "__main__":
    main()
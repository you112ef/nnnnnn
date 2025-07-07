# SpermAnalyzerAI - Model Evaluation and Testing
import os
import cv2
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import json
import torch
from ultralytics import YOLO
from sklearn.metrics import precision_recall_curve, average_precision_score, confusion_matrix
from loguru import logger
import time
from datetime import datetime

class SpermModelEvaluator:
    """فئة تقييم نموذج تحليل الحيوانات المنوية"""
    
    def __init__(self, model_path: str, test_data_path: str = "data/processed"):
        """
        تهيئة المقيم
        
        Args:
            model_path: مسار النموذج المدرب
            test_data_path: مسار بيانات الاختبار
        """
        self.model_path = Path(model_path)
        self.test_data_path = Path(test_data_path)
        self.results_path = Path("evaluation_results")
        self.results_path.mkdir(exist_ok=True)
        
        # تحميل النموذج
        self.model = None
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        
        # إعدادات التقييم
        self.confidence_threshold = 0.5
        self.iou_threshold = 0.5
        self.image_size = 640
        
        # نتائج التقييم
        self.evaluation_results = {
            'timestamp': datetime.now().isoformat(),
            'model_path': str(model_path),
            'device': self.device,
            'metrics': {},
            'predictions': [],
            'performance': {}
        }
    
    def load_model(self) -> bool:
        """تحميل النموذج"""
        try:
            if not self.model_path.exists():
                logger.error(f"ملف النموذج غير موجود: {self.model_path}")
                return False
            
            logger.info(f"تحميل النموذج من: {self.model_path}")
            self.model = YOLO(str(self.model_path))
            
            logger.info(f"تم تحميل النموذج بنجاح على {self.device}")
            return True
            
        except Exception as e:
            logger.error(f"خطأ في تحميل النموذج: {e}")
            return False
    
    def load_test_data(self) -> Tuple[List[Path], List[Path]]:
        """تحميل بيانات الاختبار"""
        test_images_dir = self.test_data_path / "images" / "test"
        test_labels_dir = self.test_data_path / "labels" / "test"
        
        image_paths = []
        label_paths = []
        
        if not test_images_dir.exists():
            logger.warning(f"مجلد صور الاختبار غير موجود: {test_images_dir}")
            return [], []
        
        # جمع مسارات الصور والتسميات
        for image_path in test_images_dir.glob("*.jpg"):
            label_path = test_labels_dir / f"{image_path.stem}.txt"
            
            if label_path.exists():
                image_paths.append(image_path)
                label_paths.append(label_path)
        
        logger.info(f"تم العثور على {len(image_paths)} صورة اختبار مع تسميات")
        return image_paths, label_paths
    
    def parse_yolo_label(self, label_path: Path, image_shape: Tuple[int, int]) -> List[Dict]:
        """تحليل ملف تسمية YOLO"""
        annotations = []
        img_h, img_w = image_shape
        
        try:
            with open(label_path, 'r') as f:
                for line in f:
                    parts = line.strip().split()
                    if len(parts) >= 5:
                        class_id = int(parts[0])
                        center_x = float(parts[1]) * img_w
                        center_y = float(parts[2]) * img_h
                        width = float(parts[3]) * img_w
                        height = float(parts[4]) * img_h
                        
                        # تحويل إلى إحداثيات المربع المحيط
                        x1 = center_x - width / 2
                        y1 = center_y - height / 2
                        x2 = center_x + width / 2
                        y2 = center_y + height / 2
                        
                        annotations.append({
                            'class_id': class_id,
                            'bbox': [x1, y1, x2, y2],
                            'center': [center_x, center_y],
                            'size': [width, height]
                        })
        except Exception as e:
            logger.error(f"خطأ في تحليل التسمية {label_path}: {e}")
        
        return annotations
    
    def calculate_iou(self, box1: List[float], box2: List[float]) -> float:
        """حساب Intersection over Union (IoU)"""
        x1_1, y1_1, x2_1, y2_1 = box1
        x1_2, y1_2, x2_2, y2_2 = box2
        
        # حساب التقاطع
        x1_i = max(x1_1, x1_2)
        y1_i = max(y1_1, y1_2)
        x2_i = min(x2_1, x2_2)
        y2_i = min(y2_1, y2_2)
        
        if x2_i <= x1_i or y2_i <= y1_i:
            return 0.0
        
        intersection = (x2_i - x1_i) * (y2_i - y1_i)
        
        # حساب الاتحاد
        area1 = (x2_1 - x1_1) * (y2_1 - y1_1)
        area2 = (x2_2 - x1_2) * (y2_2 - y1_2)
        union = area1 + area2 - intersection
        
        return intersection / union if union > 0 else 0.0
    
    def evaluate_single_image(self, image_path: Path, label_path: Path) -> Dict:
        \"\"\"تقييم صورة واحدة\"\"\"\n        try:\n            # قراءة الصورة\n            image = cv2.imread(str(image_path))\n            if image is None:\n                return {'error': f'لا يمكن قراءة الصورة: {image_path}'}\n            \n            img_h, img_w = image.shape[:2]\n            \n            # تحميل التسميات الحقيقية\n            gt_annotations = self.parse_yolo_label(label_path, (img_h, img_w))\n            \n            # تشغيل النموذج\n            start_time = time.time()\n            results = self.model(\n                image, \n                conf=self.confidence_threshold,\n                iou=self.iou_threshold,\n                imgsz=self.image_size,\n                verbose=False\n            )\n            inference_time = time.time() - start_time\n            \n            # استخراج التنبؤات\n            predictions = []\n            if len(results) > 0 and len(results[0].boxes) > 0:\n                boxes = results[0].boxes\n                for i in range(len(boxes)):\n                    bbox = boxes.xyxy[i].cpu().numpy()  # [x1, y1, x2, y2]\n                    conf = float(boxes.conf[i].cpu().numpy())\n                    class_id = int(boxes.cls[i].cpu().numpy())\n                    \n                    predictions.append({\n                        'class_id': class_id,\n                        'confidence': conf,\n                        'bbox': bbox.tolist()\n                    })\n            \n            # حساب المطابقات\n            matches = self._match_predictions_to_gt(predictions, gt_annotations)\n            \n            return {\n                'image_path': str(image_path),\n                'gt_count': len(gt_annotations),\n                'pred_count': len(predictions),\n                'matches': matches,\n                'inference_time': inference_time,\n                'predictions': predictions,\n                'ground_truth': gt_annotations\n            }\n            \n        except Exception as e:\n            logger.error(f\"خطأ في تقييم الصورة {image_path}: {e}\")\n            return {'error': str(e)}\n    \n    def _match_predictions_to_gt(self, predictions: List[Dict], \n                                ground_truth: List[Dict]) -> Dict:\n        \"\"\"مطابقة التنبؤات مع الحقيقة الأرضية\"\"\"\n        true_positives = 0\n        false_positives = 0\n        false_negatives = len(ground_truth)\n        \n        matched_gt = set()\n        matched_predictions = []\n        \n        # فرز التنبؤات حسب الثقة\n        sorted_predictions = sorted(predictions, key=lambda x: x['confidence'], reverse=True)\n        \n        for pred in sorted_predictions:\n            best_iou = 0\n            best_gt_idx = -1\n            \n            # البحث عن أفضل مطابقة\n            for gt_idx, gt in enumerate(ground_truth):\n                if gt_idx in matched_gt:\n                    continue\n                \n                iou = self.calculate_iou(pred['bbox'], gt['bbox'])\n                if iou > best_iou:\n                    best_iou = iou\n                    best_gt_idx = gt_idx\n            \n            # تحديد المطابقة\n            if best_iou >= self.iou_threshold and best_gt_idx != -1:\n                true_positives += 1\n                matched_gt.add(best_gt_idx)\n                matched_predictions.append({\n                    'prediction': pred,\n                    'ground_truth': ground_truth[best_gt_idx],\n                    'iou': best_iou\n                })\n            else:\n                false_positives += 1\n        \n        false_negatives = len(ground_truth) - len(matched_gt)\n        \n        return {\n            'true_positives': true_positives,\n            'false_positives': false_positives,\n            'false_negatives': false_negatives,\n            'matched_predictions': matched_predictions\n        }\n    \n    def calculate_metrics(self, all_results: List[Dict]) -> Dict:\n        \"\"\"حساب مقاييس التقييم\"\"\"\n        total_tp = sum(r['matches']['true_positives'] for r in all_results if 'matches' in r)\n        total_fp = sum(r['matches']['false_positives'] for r in all_results if 'matches' in r)\n        total_fn = sum(r['matches']['false_negatives'] for r in all_results if 'matches' in r)\n        \n        # حساب المقاييس الأساسية\n        precision = total_tp / (total_tp + total_fp) if (total_tp + total_fp) > 0 else 0\n        recall = total_tp / (total_tp + total_fn) if (total_tp + total_fn) > 0 else 0\n        f1_score = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0\n        \n        # حساب متوسط وقت الاستنتاج\n        inference_times = [r['inference_time'] for r in all_results if 'inference_time' in r]\n        avg_inference_time = np.mean(inference_times) if inference_times else 0\n        \n        # حساب إحصائيات إضافية\n        total_images = len([r for r in all_results if 'matches' in r])\n        total_gt_objects = sum(r['gt_count'] for r in all_results if 'gt_count' in r)\n        total_pred_objects = sum(r['pred_count'] for r in all_results if 'pred_count' in r)\n        \n        return {\n            'precision': precision,\n            'recall': recall,\n            'f1_score': f1_score,\n            'true_positives': total_tp,\n            'false_positives': total_fp,\n            'false_negatives': total_fn,\n            'total_images': total_images,\n            'total_gt_objects': total_gt_objects,\n            'total_pred_objects': total_pred_objects,\n            'avg_inference_time': avg_inference_time,\n            'fps': 1 / avg_inference_time if avg_inference_time > 0 else 0\n        }\n    \n    def create_visualizations(self, all_results: List[Dict]):\n        \"\"\"إنشاء الرسوم البيانية\"\"\"\n        logger.info(\"إنشاء الرسوم البيانية...\")\n        \n        # إعداد matplotlib للعربية\n        plt.rcParams['font.family'] = ['Arial Unicode MS', 'Tahoma']\n        \n        # 1. رسم بياني لتوزيع الثقة\n        confidences = []\n        for result in all_results:\n            if 'predictions' in result:\n                confidences.extend([p['confidence'] for p in result['predictions']])\n        \n        if confidences:\n            plt.figure(figsize=(10, 6))\n            plt.hist(confidences, bins=30, alpha=0.7, edgecolor='black')\n            plt.title('توزيع درجات الثقة للتنبؤات')\n            plt.xlabel('درجة الثقة')\n            plt.ylabel('التكرار')\n            plt.grid(True, alpha=0.3)\n            plt.savefig(self.results_path / 'confidence_distribution.png', dpi=300, bbox_inches='tight')\n            plt.close()\n        \n        # 2. رسم بياني لتوزيع IoU\n        ious = []\n        for result in all_results:\n            if 'matches' in result:\n                ious.extend([m['iou'] for m in result['matches']['matched_predictions']])\n        \n        if ious:\n            plt.figure(figsize=(10, 6))\n            plt.hist(ious, bins=20, alpha=0.7, edgecolor='black')\n            plt.title('توزيع قيم IoU للمطابقات الصحيحة')\n            plt.xlabel('IoU')\n            plt.ylabel('التكرار')\n            plt.grid(True, alpha=0.3)\n            plt.savefig(self.results_path / 'iou_distribution.png', dpi=300, bbox_inches='tight')\n            plt.close()\n        \n        # 3. رسم بياني لأوقات الاستنتاج\n        inference_times = [r['inference_time'] for r in all_results if 'inference_time' in r]\n        \n        if inference_times:\n            plt.figure(figsize=(12, 8))\n            \n            plt.subplot(2, 2, 1)\n            plt.hist(inference_times, bins=20, alpha=0.7, edgecolor='black')\n            plt.title('توزيع أوقات الاستنتاج')\n            plt.xlabel('الوقت (ثانية)')\n            plt.ylabel('التكرار')\n            \n            plt.subplot(2, 2, 2)\n            plt.plot(inference_times)\n            plt.title('أوقات الاستنتاج عبر الصور')\n            plt.xlabel('رقم الصورة')\n            plt.ylabel('الوقت (ثانية)')\n            \n            plt.subplot(2, 2, 3)\n            fps_values = [1/t if t > 0 else 0 for t in inference_times]\n            plt.hist(fps_values, bins=20, alpha=0.7, edgecolor='black')\n            plt.title('توزيع FPS')\n            plt.xlabel('FPS')\n            plt.ylabel('التكرار')\n            \n            plt.subplot(2, 2, 4)\n            plt.boxplot([inference_times, fps_values], labels=['الوقت (ثانية)', 'FPS'])\n            plt.title('ملخص الأداء')\n            \n            plt.tight_layout()\n            plt.savefig(self.results_path / 'performance_analysis.png', dpi=300, bbox_inches='tight')\n            plt.close()\n    \n    def generate_report(self, metrics: Dict, all_results: List[Dict]):\n        \"\"\"إنتاج تقرير التقييم\"\"\"\n        report_path = self.results_path / 'evaluation_report.md'\n        \n        with open(report_path, 'w', encoding='utf-8') as f:\n            f.write(\"# تقرير تقييم نموذج Sperm Analyzer AI\\n\\n\")\n            \n            f.write(f\"**التاريخ**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\\n\")\n            f.write(f\"**النموذج**: {self.model_path}\\n\")\n            f.write(f\"**الجهاز**: {self.device}\\n\\n\")\n            \n            f.write(\"## المقاييس الأساسية\\n\\n\")\n            f.write(f\"- **Precision**: {metrics['precision']:.4f}\\n\")\n            f.write(f\"- **Recall**: {metrics['recall']:.4f}\\n\")\n            f.write(f\"- **F1-Score**: {metrics['f1_score']:.4f}\\n\\n\")\n            \n            f.write(\"## إحصائيات التقييم\\n\\n\")\n            f.write(f\"- **عدد الصور**: {metrics['total_images']}\\n\")\n            f.write(f\"- **إجمالي الكائنات الحقيقية**: {metrics['total_gt_objects']}\\n\")\n            f.write(f\"- **إجمالي التنبؤات**: {metrics['total_pred_objects']}\\n\")\n            f.write(f\"- **True Positives**: {metrics['true_positives']}\\n\")\n            f.write(f\"- **False Positives**: {metrics['false_positives']}\\n\")\n            f.write(f\"- **False Negatives**: {metrics['false_negatives']}\\n\\n\")\n            \n            f.write(\"## أداء النموذج\\n\\n\")\n            f.write(f\"- **متوسط وقت الاستنتاج**: {metrics['avg_inference_time']:.4f} ثانية\\n\")\n            f.write(f\"- **FPS**: {metrics['fps']:.2f}\\n\\n\")\n            \n            f.write(\"## تحليل النتائج\\n\\n\")\n            \n            if metrics['precision'] >= 0.8:\n                f.write(\"✅ **الدقة ممتازة**: النموذج يحقق دقة عالية في اكتشاف الحيوانات المنوية.\\n\")\n            elif metrics['precision'] >= 0.6:\n                f.write(\"⚠️ **الدقة جيدة**: النموذج يحقق دقة معقولة لكن يمكن تحسينها.\\n\")\n            else:\n                f.write(\"❌ **الدقة منخفضة**: النموذج يحتاج إلى تحسين كبير.\\n\")\n            \n            if metrics['recall'] >= 0.8:\n                f.write(\"✅ **الاستدعاء ممتاز**: النموذج يكتشف معظم الحيوانات المنوية.\\n\")\n            elif metrics['recall'] >= 0.6:\n                f.write(\"⚠️ **الاستدعاء جيد**: النموذج يفوت بعض الحيوانات المنوية.\\n\")\n            else:\n                f.write(\"❌ **الاستدعاء منخفض**: النموذج يفوت الكثير من الحيوانات المنوية.\\n\")\n            \n            if metrics['fps'] >= 10:\n                f.write(\"✅ **الأداء ممتاز**: النموذج سريع بما يكفي للاستخدام في الوقت الفعلي.\\n\")\n            elif metrics['fps'] >= 5:\n                f.write(\"⚠️ **الأداء جيد**: النموذج مناسب للاستخدام العادي.\\n\")\n            else:\n                f.write(\"❌ **الأداء بطيء**: النموذج قد يحتاج لتحسين في السرعة.\\n\")\n        \n        logger.info(f\"تم إنشاء تقرير التقييم: {report_path}\")\n    \n    def run_evaluation(self) -> Dict:\n        \"\"\"تشغيل التقييم الكامل\"\"\"\n        logger.info(\"بدء تقييم النموذج...\")\n        \n        # تحميل النموذج\n        if not self.load_model():\n            raise RuntimeError(\"فشل في تحميل النموذج\")\n        \n        # تحميل بيانات الاختبار\n        image_paths, label_paths = self.load_test_data()\n        \n        if not image_paths:\n            raise RuntimeError(\"لا توجد بيانات اختبار\")\n        \n        # تقييم كل صورة\n        all_results = []\n        for i, (img_path, lbl_path) in enumerate(zip(image_paths, label_paths)):\n            if i % 10 == 0:\n                logger.info(f\"معالجة الصورة {i+1}/{len(image_paths)}\")\n            \n            result = self.evaluate_single_image(img_path, lbl_path)\n            all_results.append(result)\n        \n        # حساب المقاييس\n        metrics = self.calculate_metrics(all_results)\n        \n        # إنشاء الرسوم البيانية\n        self.create_visualizations(all_results)\n        \n        # إنتاج التقرير\n        self.generate_report(metrics, all_results)\n        \n        # حفظ النتائج\n        self.evaluation_results['metrics'] = metrics\n        self.evaluation_results['predictions'] = all_results\n        \n        results_file = self.results_path / 'evaluation_results.json'\n        with open(results_file, 'w', encoding='utf-8') as f:\n            json.dump(self.evaluation_results, f, indent=2, ensure_ascii=False, default=str)\n        \n        logger.info(\"✅ تم إكمال التقييم بنجاح!\")\n        logger.info(f\"النتائج: Precision={metrics['precision']:.4f}, Recall={metrics['recall']:.4f}, F1={metrics['f1_score']:.4f}\")\n        \n        return metrics\n\ndef main():\n    \"\"\"تشغيل التقييم\"\"\"\n    model_path = \"models/sperm_yolov8.pt\"\n    test_data_path = \"data/processed\"\n    \n    # التحقق من وجود النموذج\n    if not Path(model_path).exists():\n        logger.error(f\"ملف النموذج غير موجود: {model_path}\")\n        logger.info(\"يرجى تدريب النموذج أولاً باستخدام train_yolo.py\")\n        return\n    \n    # إنشاء مقيم النموذج\n    evaluator = SpermModelEvaluator(model_path, test_data_path)\n    \n    # تشغيل التقييم\n    try:\n        metrics = evaluator.run_evaluation()\n        print(\"\\n\" + \"=\"*50)\n        print(\"نتائج التقييم النهائية:\")\n        print(f\"Precision: {metrics['precision']:.4f}\")\n        print(f\"Recall: {metrics['recall']:.4f}\")\n        print(f\"F1-Score: {metrics['f1_score']:.4f}\")\n        print(f\"FPS: {metrics['fps']:.2f}\")\n        print(\"=\"*50)\n        \n    except Exception as e:\n        logger.error(f\"فشل التقييم: {e}\")\n        raise\n\nif __name__ == \"__main__\":\n    main()
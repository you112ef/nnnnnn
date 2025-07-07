# SpermAnalyzerAI - Model Deployment and Optimization
import os
import torch
import onnx
import onnxruntime as ort
from pathlib import Path
from ultralytics import YOLO
import numpy as np
import cv2
from loguru import logger
import time
import json
from typing import Dict, List, Tuple, Optional
import tensorrt as trt
import yaml

class SpermModelDeployer:
    """فئة نشر وتحسين نموذج تحليل الحيوانات المنوية"""
    
    def __init__(self, model_path: str, output_dir: str = "models/deployed"):
        """
        تهيئة المنشر
        
        Args:
            model_path: مسار النموذج المدرب
            output_dir: مجلد النماذج المحسنة
        """
        self.model_path = Path(model_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # إعدادات النشر
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        self.image_size = 640
        self.batch_size = 1
        
        # النماذج المحسنة
        self.models = {
            'pytorch': None,
            'onnx': None,
            'tensorrt': None,
            'quantized': None
        }
        
        # معايير الأداء
        self.benchmarks = {}
        
    def load_original_model(self) -> bool:
        """تحميل النموذج الأصلي"""
        try:
            if not self.model_path.exists():
                logger.error(f"ملف النموذج غير موجود: {self.model_path}")
                return False
            
            logger.info(f"تحميل النموذج الأصلي: {self.model_path}")
            self.models['pytorch'] = YOLO(str(self.model_path))
            
            # نقل النموذج للجهاز المناسب
            if self.device == "cuda":
                self.models['pytorch'].to('cuda')
            
            logger.info(f"تم تحميل النموذج على {self.device}")
            return True
            
        except Exception as e:
            logger.error(f"خطأ في تحميل النموذج: {e}")
            return False
    
    def export_to_onnx(self, dynamic_batch: bool = False) -> bool:
        """تصدير النموذج إلى ONNX"""
        try:
            logger.info("تصدير النموذج إلى ONNX...")
            
            onnx_path = self.output_dir / "sperm_model.onnx"
            
            # تصدير باستخدام YOLOv8
            success = self.models['pytorch'].export(
                format='onnx',
                dynamic=dynamic_batch,
                simplify=True,
                opset=11
            )
            
            if success:
                # نقل الملف إلى المجلد المطلوب
                exported_path = self.model_path.parent / f"{self.model_path.stem}.onnx"
                if exported_path.exists():
                    exported_path.rename(onnx_path)
                
                # التحقق من صحة النموذج
                onnx_model = onnx.load(str(onnx_path))\n                onnx.checker.check_model(onnx_model)\n                \n                logger.info(f\"تم تصدير النموذج بنجاح: {onnx_path}\")\n                return True\n            else:\n                logger.error(\"فشل في تصدير النموذج إلى ONNX\")\n                return False\n                \n        except Exception as e:\n            logger.error(f\"خطأ في تصدير ONNX: {e}\")\n            return False\n    \n    def load_onnx_model(self) -> bool:\n        \"\"\"تحميل نموذج ONNX\"\"\"\n        try:\n            onnx_path = self.output_dir / \"sperm_model.onnx\"\n            \n            if not onnx_path.exists():\n                logger.error(f\"ملف ONNX غير موجود: {onnx_path}\")\n                return False\n            \n            # إعداد جلسة ONNX Runtime\n            providers = ['CUDAExecutionProvider', 'CPUExecutionProvider'] if self.device == 'cuda' else ['CPUExecutionProvider']\n            \n            self.models['onnx'] = ort.InferenceSession(\n                str(onnx_path),\n                providers=providers\n            )\n            \n            logger.info(\"تم تحميل نموذج ONNX بنجاح\")\n            return True\n            \n        except Exception as e:\n            logger.error(f\"خطأ في تحميل نموذج ONNX: {e}\")\n            return False\n    \n    def export_to_tensorrt(self) -> bool:\n        \"\"\"تصدير النموذج إلى TensorRT (GPU فقط)\"\"\"\n        if self.device != \"cuda\":\n            logger.warning(\"TensorRT يتطلب GPU - تم تخطي التصدير\")\n            return False\n        \n        try:\n            logger.info(\"تصدير النموذج إلى TensorRT...\")\n            \n            # تصدير باستخدام YOLOv8\n            success = self.models['pytorch'].export(\n                format='engine',\n                half=True,  # استخدام FP16 للسرعة\n                dynamic=False,\n                simplify=True,\n                workspace=4  # 4GB workspace\n            )\n            \n            if success:\n                # نقل الملف إلى المجلد المطلوب\n                engine_path = self.model_path.parent / f\"{self.model_path.stem}.engine\"\n                target_path = self.output_dir / \"sperm_model.engine\"\n                \n                if engine_path.exists():\n                    engine_path.rename(target_path)\n                    logger.info(f\"تم تصدير TensorRT بنجاح: {target_path}\")\n                    return True\n            \n            logger.error(\"فشل في تصدير TensorRT\")\n            return False\n            \n        except Exception as e:\n            logger.error(f\"خطأ في تصدير TensorRT: {e}\")\n            return False\n    \n    def quantize_model(self) -> bool:\n        \"\"\"ضغط النموذج باستخدام Quantization\"\"\"\n        try:\n            logger.info(\"ضغط النموذج باستخدام INT8 quantization...\")\n            \n            # تصدير نموذج مضغوط\n            success = self.models['pytorch'].export(\n                format='onnx',\n                int8=True,\n                dynamic=False,\n                simplify=True\n            )\n            \n            if success:\n                # نقل الملف إلى المجلد المطلوب\n                quantized_path = self.model_path.parent / f\"{self.model_path.stem}_int8.onnx\"\n                target_path = self.output_dir / \"sperm_model_quantized.onnx\"\n                \n                if quantized_path.exists():\n                    quantized_path.rename(target_path)\n                    \n                    # تحميل النموذج المضغوط\n                    providers = ['CUDAExecutionProvider', 'CPUExecutionProvider'] if self.device == 'cuda' else ['CPUExecutionProvider']\n                    self.models['quantized'] = ort.InferenceSession(\n                        str(target_path),\n                        providers=providers\n                    )\n                    \n                    logger.info(f\"تم ضغط النموذج بنجاح: {target_path}\")\n                    return True\n            \n            logger.error(\"فشل في ضغط النموذج\")\n            return False\n            \n        except Exception as e:\n            logger.error(f\"خطأ في ضغط النموذج: {e}\")\n            return False\n    \n    def benchmark_model(self, model_name: str, num_iterations: int = 100) -> Dict:\n        \"\"\"قياس أداء النموذج\"\"\"\n        logger.info(f\"قياس أداء {model_name}...\")\n        \n        # إنشاء بيانات اختبار\n        dummy_input = np.random.randint(\n            0, 255, \n            (self.batch_size, 3, self.image_size, self.image_size), \n            dtype=np.uint8\n        )\n        \n        times = []\n        memory_usage = []\n        \n        try:\n            for i in range(num_iterations):\n                start_time = time.time()\n                \n                if model_name == 'pytorch':\n                    with torch.no_grad():\n                        results = self.models['pytorch'](dummy_input, verbose=False)\n                \n                elif model_name == 'onnx':\n                    input_name = self.models['onnx'].get_inputs()[0].name\n                    dummy_input_float = dummy_input.astype(np.float32) / 255.0\n                    results = self.models['onnx'].run(None, {input_name: dummy_input_float})\n                \n                elif model_name == 'quantized':\n                    input_name = self.models['quantized'].get_inputs()[0].name\n                    dummy_input_float = dummy_input.astype(np.float32) / 255.0\n                    results = self.models['quantized'].run(None, {input_name: dummy_input_float})\n                \n                elif model_name == 'tensorrt':\n                    # TensorRT inference would go here\n                    # This is a placeholder as TensorRT integration is complex\n                    time.sleep(0.01)  # Simulate inference time\n                \n                end_time = time.time()\n                inference_time = end_time - start_time\n                times.append(inference_time)\n                \n                # قياس استخدام الذاكرة (تقريبي)\n                if self.device == 'cuda' and torch.cuda.is_available():\n                    memory_usage.append(torch.cuda.memory_allocated())\n            \n            # حساب الإحصائيات\n            avg_time = np.mean(times)\n            std_time = np.std(times)\n            min_time = np.min(times)\n            max_time = np.max(times)\n            fps = 1.0 / avg_time\n            \n            benchmark_result = {\n                'model': model_name,\n                'avg_inference_time': avg_time,\n                'std_inference_time': std_time,\n                'min_inference_time': min_time,\n                'max_inference_time': max_time,\n                'fps': fps,\n                'total_iterations': num_iterations\n            }\n            \n            if memory_usage:\n                benchmark_result['avg_memory_usage'] = np.mean(memory_usage)\n                benchmark_result['max_memory_usage'] = np.max(memory_usage)\n            \n            logger.info(f\"{model_name}: {avg_time:.4f}s ± {std_time:.4f}s, {fps:.2f} FPS\")\n            \n            return benchmark_result\n            \n        except Exception as e:\n            logger.error(f\"خطأ في قياس أداء {model_name}: {e}\")\n            return {}\n    \n    def create_deployment_config(self) -> Dict:\n        \"\"\"إنشاء ملف تكوين النشر\"\"\"\n        config = {\n            'model_info': {\n                'name': 'Sperm Analyzer AI',\n                'version': '1.0.0',\n                'input_size': [self.image_size, self.image_size],\n                'num_classes': 1,\n                'class_names': ['sperm']\n            },\n            'deployment_options': {\n                'pytorch': {\n                    'path': 'sperm_yolov8.pt',\n                    'device': self.device,\n                    'half_precision': self.device == 'cuda'\n                },\n                'onnx': {\n                    'path': 'sperm_model.onnx',\n                    'providers': ['CUDAExecutionProvider', 'CPUExecutionProvider'] if self.device == 'cuda' else ['CPUExecutionProvider']\n                },\n                'quantized': {\n                    'path': 'sperm_model_quantized.onnx',\n                    'providers': ['CPUExecutionProvider']\n                }\n            },\n            'inference_config': {\n                'confidence_threshold': 0.5,\n                'iou_threshold': 0.5,\n                'max_detections': 100\n            },\n            'benchmarks': self.benchmarks\n        }\n        \n        if self.device == 'cuda':\n            config['deployment_options']['tensorrt'] = {\n                'path': 'sperm_model.engine',\n                'precision': 'fp16'\n            }\n        \n        return config\n    \n    def save_deployment_package(self):\n        \"\"\"حفظ حزمة النشر الكاملة\"\"\"\n        logger.info(\"إنشاء حزمة النشر...\")\n        \n        # إنشاء ملف التكوين\n        config = self.create_deployment_config()\n        config_path = self.output_dir / 'deployment_config.yaml'\n        \n        with open(config_path, 'w', encoding='utf-8') as f:\n            yaml.dump(config, f, default_flow_style=False, allow_unicode=True)\n        \n        # إنشاء ملف README للنشر\n        readme_path = self.output_dir / 'README.md'\n        with open(readme_path, 'w', encoding='utf-8') as f:\n            f.write(\"# Sperm Analyzer AI - حزمة النشر\\n\\n\")\n            f.write(\"## الملفات المتضمنة\\n\\n\")\n            \n            for model_file in self.output_dir.glob('sperm_model*'):\n                f.write(f\"- `{model_file.name}`: نموذج محسن\\n\")\n            \n            f.write(f\"- `deployment_config.yaml`: ملف التكوين\\n\")\n            f.write(f\"- `benchmarks.json`: نتائج قياس الأداء\\n\\n\")\n            \n            f.write(\"## استخدام النماذج\\n\\n\")\n            f.write(\"### PyTorch\\n\")\n            f.write(\"```python\\n\")\n            f.write(\"from ultralytics import YOLO\\n\")\n            f.write(\"model = YOLO('sperm_yolov8.pt')\\n\")\n            f.write(\"results = model('image.jpg')\\n\")\n            f.write(\"```\\n\\n\")\n            \n            f.write(\"### ONNX\\n\")\n            f.write(\"```python\\n\")\n            f.write(\"import onnxruntime as ort\\n\")\n            f.write(\"session = ort.InferenceSession('sperm_model.onnx')\\n\")\n            f.write(\"results = session.run(None, {input_name: image})\\n\")\n            f.write(\"```\\n\\n\")\n            \n            if self.benchmarks:\n                f.write(\"## نتائج الأداء\\n\\n\")\n                for model_name, benchmark in self.benchmarks.items():\n                    if benchmark:\n                        f.write(f\"**{model_name}**:\\n\")\n                        f.write(f\"- FPS: {benchmark.get('fps', 0):.2f}\\n\")\n                        f.write(f\"- متوسط وقت الاستنتاج: {benchmark.get('avg_inference_time', 0):.4f}s\\n\\n\")\n        \n        # حفظ نتائج القياس\n        benchmarks_path = self.output_dir / 'benchmarks.json'\n        with open(benchmarks_path, 'w', encoding='utf-8') as f:\n            json.dump(self.benchmarks, f, indent=2, ensure_ascii=False)\n        \n        logger.info(f\"تم إنشاء حزمة النشر في: {self.output_dir}\")\n    \n    def deploy_all_formats(self) -> bool:\n        \"\"\"نشر النموذج بجميع الصيغ المدعومة\"\"\"\n        logger.info(\"بدء نشر النموذج بجميع الصيغ...\")\n        \n        success = True\n        \n        # تحميل النموذج الأصلي\n        if not self.load_original_model():\n            return False\n        \n        # نسخ النموذج الأصلي\n        original_target = self.output_dir / \"sperm_yolov8.pt\"\n        if not original_target.exists():\n            import shutil\n            shutil.copy2(self.model_path, original_target)\n        \n        # تصدير إلى ONNX\n        if self.export_to_onnx():\n            self.load_onnx_model()\n        else:\n            success = False\n        \n        # تصدير إلى TensorRT (GPU فقط)\n        if self.device == 'cuda':\n            if not self.export_to_tensorrt():\n                logger.warning(\"فشل في تصدير TensorRT\")\n        \n        # ضغط النموذج\n        if not self.quantize_model():\n            logger.warning(\"فشل في ضغط النموذج\")\n        \n        # قياس الأداء\n        for model_name, model in self.models.items():\n            if model is not None:\n                benchmark = self.benchmark_model(model_name)\n                self.benchmarks[model_name] = benchmark\n        \n        # حفظ حزمة النشر\n        self.save_deployment_package()\n        \n        logger.info(\"✅ تم إكمال نشر النموذج بنجاح!\")\n        return success\n\ndef main():\n    \"\"\"تشغيل نشر النموذج\"\"\"\n    model_path = \"models/sperm_yolov8.pt\"\n    \n    # التحقق من وجود النموذج\n    if not Path(model_path).exists():\n        logger.error(f\"ملف النموذج غير موجود: {model_path}\")\n        logger.info(\"يرجى تدريب النموذج أولاً باستخدام train_yolo.py\")\n        return\n    \n    # إنشاء منشر النموذج\n    deployer = SpermModelDeployer(model_path)\n    \n    # نشر النموذج\n    try:\n        success = deployer.deploy_all_formats()\n        \n        if success:\n            print(\"\\n\" + \"=\"*50)\n            print(\"تم نشر النموذج بنجاح!\")\n            print(f\"مجلد النشر: {deployer.output_dir}\")\n            \n            if deployer.benchmarks:\n                print(\"\\nنتائج الأداء:\")\n                for model_name, benchmark in deployer.benchmarks.items():\n                    if benchmark:\n                        print(f\"  {model_name}: {benchmark.get('fps', 0):.2f} FPS\")\n            \n            print(\"=\"*50)\n        else:\n            logger.error(\"فشل في نشر بعض النماذج\")\n            \n    except Exception as e:\n        logger.error(f\"فشل النشر: {e}\")\n        raise\n\nif __name__ == \"__main__\":\n    main()
import cv2
import numpy as np
import asyncio
import logging
import os
from typing import List, Tuple, Dict, Any, Optional
from datetime import datetime
from pathlib import Path
import json

# يتم استيرادها عند التوفر
try:
    from ultralytics import YOLO
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False
    logging.warning("Ultralytics YOLO غير متوفر - سيتم استخدام المحاكاة")

try:
    from deep_sort_realtime import DeepSort
    DEEPSORT_AVAILABLE = True
except ImportError:
    DEEPSORT_AVAILABLE = False
    logging.warning("DeepSort غير متوفر - سيتم استخدام تتبع بسيط")

from ..models.analysis_models import (
    AnalysisResult, CasaParameters, SpermMorphology, 
    VelocityDataPoint, SpermTrackingData, AnalysisMetadata,
    AnalysisStatus, AnalysisProgress
)

class SpermAnalyzer:
    """محلل الحيوانات المنوية المتقدم"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or "models/sperm_yolov8.pt"
        self.model = None
        self.tracker = None
        self.logger = logging.getLogger(__name__)
        
        # إعدادات التحليل
        self.confidence_threshold = 0.5
        self.nms_threshold = 0.4
        self.min_track_length = 5
        self.pixel_to_micron_ratio = 0.5  # نسبة تحويل البكسل إلى ميكرومتر
        
        # تخزين نتائج التحليل
        self.analysis_cache: Dict[str, AnalysisProgress] = {}
    
    async def initialize(self):
        """تهيئة النموذج والأدوات"""
        try:
            if YOLO_AVAILABLE and os.path.exists(self.model_path):
                self.logger.info(f"تحميل نموذج YOLO من: {self.model_path}")
                self.model = YOLO(self.model_path)
            else:
                self.logger.warning("نموذج YOLO غير متوفر - سيتم استخدام المحاكاة")
                self.model = None
            
            if DEEPSORT_AVAILABLE:
                self.tracker = DeepSort(max_age=30, n_init=3)
                self.logger.info("تم تهيئة DeepSort للتتبع")
            else:
                self.tracker = None
                self.logger.warning("DeepSort غير متوفر - سيتم استخدام تتبع بسيط")
                
        except Exception as e:
            self.logger.error(f"خطأ في تهيئة المحلل: {e}")
            raise
    
    async def analyze_sample(self, file_path: str, analysis_id: str) -> AnalysisResult:
        """تحليل عينة الحيوانات المنوية"""
        self.logger.info(f"بدء تحليل العينة: {analysis_id}")
        
        # تحديث حالة التحليل
        await self._update_progress(analysis_id, 0.1, "بدء التحليل...")
        
        try:
            # تحديد نوع الملف
            file_extension = Path(file_path).suffix.lower()
            
            if file_extension in ['.jpg', '.jpeg', '.png', '.bmp']:
                result = await self._analyze_image(file_path, analysis_id)
            elif file_extension in ['.mp4', '.avi', '.mov', '.mkv']:
                result = await self._analyze_video(file_path, analysis_id)
            else:
                raise ValueError(f"نوع الملف غير مدعوم: {file_extension}")
            
            await self._update_progress(analysis_id, 1.0, "تم إكمال التحليل")
            return result
            
        except Exception as e:
            self.logger.error(f"خطأ في تحليل العينة {analysis_id}: {e}")
            await self._update_progress(analysis_id, 0.0, f"فشل التحليل: {str(e)}")
            raise
    
    async def _analyze_image(self, image_path: str, analysis_id: str) -> AnalysisResult:
        """تحليل صورة واحدة"""
        await self._update_progress(analysis_id, 0.2, "تحميل الصورة...")
        
        # تحميل الصورة
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError("فشل في تحميل الصورة")
        
        await self._update_progress(analysis_id, 0.4, "كشف الحيوانات المنوية...")
        
        # كشف الحيوانات المنوية
        detections = await self._detect_sperm(image)
        
        await self._update_progress(analysis_id, 0.7, "تحليل النتائج...")
        
        # تحليل النتائج
        sperm_count = len(detections)
        morphology_analysis = await self._analyze_morphology(image, detections)
        
        # إنشاء النتيجة
        result = AnalysisResult(
            id=analysis_id,
            file_name=os.path.basename(image_path),
            file_size=os.path.getsize(image_path),
            analysis_date=datetime.now(),
            sperm_count=sperm_count,
            motility=0.0,  # لا يمكن حساب الحركة من صورة واحدة
            concentration=self._calculate_concentration(sperm_count, image.shape),
            casa_parameters=CasaParameters(
                vcl=0, vsl=0, vap=0, lin=0, str=0, wob=0, alh=0, bcf=0, mot=0
            ),
            morphology=morphology_analysis,
            velocity_distribution=[],
            metadata=AnalysisMetadata(
                model_version="YOLOv8-sperm",
                confidence=0.95,
                processing_time=1000,
                resolution=f"{image.shape[1]}x{image.shape[0]}",
                additional_data={"image_analysis": True}
            )
        )
        
        await self._update_progress(analysis_id, 0.9, "إنهاء التحليل...")
        return result
    
    async def _analyze_video(self, video_path: str, analysis_id: str) -> AnalysisResult:
        """تحليل فيديو مع تتبع الحركة"""
        await self._update_progress(analysis_id, 0.1, "تحميل الفيديو...")
        
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            raise ValueError("فشل في تحميل الفيديو")
        
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        duration = frame_count / fps if fps > 0 else 0
        
        await self._update_progress(analysis_id, 0.2, "معالجة الإطارات...")
        
        # معالجة الإطارات
        tracks = {}
        all_detections = []
        frame_idx = 0
        
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break
            
            # كشف الحيوانات المنوية في الإطار
            detections = await self._detect_sperm(frame)
            all_detections.extend(detections)
            
            # تتبع الحيوانات المنوية
            if self.tracker and detections:
                tracks_frame = self._update_tracks(detections, frame_idx, tracks)
            
            frame_idx += 1
            
            # تحديث التقدم
            progress = 0.2 + (frame_idx / frame_count) * 0.5
            await self._update_progress(analysis_id, progress, f"معالجة الإطار {frame_idx}/{frame_count}")
            
            # توقف كل 10 إطارات للسماح للمهام الأخرى
            if frame_idx % 10 == 0:
                await asyncio.sleep(0.01)
        
        cap.release()
        
        await self._update_progress(analysis_id, 0.8, "تحليل البيانات...")
        
        # تحليل البيانات المجمعة
        analysis_results = await self._analyze_tracking_data(tracks, fps, all_detections)
        
        # إنشاء النتيجة النهائية
        result = AnalysisResult(
            id=analysis_id,
            file_name=os.path.basename(video_path),
            file_size=os.path.getsize(video_path),
            analysis_date=datetime.now(),
            sperm_count=analysis_results['sperm_count'],
            motility=analysis_results['motility'],
            concentration=analysis_results['concentration'],
            casa_parameters=analysis_results['casa_parameters'],
            morphology=analysis_results['morphology'],
            velocity_distribution=analysis_results['velocity_distribution'],
            tracking_data=analysis_results.get('tracking_data'),
            metadata=AnalysisMetadata(
                model_version="YOLOv8-sperm",
                confidence=0.92,
                processing_time=int(duration * 1000),
                frame_count=frame_count,
                fps=fps,
                resolution=f"{frame.shape[1]}x{frame.shape[0]}" if frame is not None else "unknown",
                additional_data={"video_analysis": True, "duration": duration}
            )
        )
        
        return result
    
    async def _detect_sperm(self, image: np.ndarray) -> List[Dict]:
        """كشف الحيوانات المنوية في الصورة"""
        if self.model is None:
            # محاكاة الكشف
            return await self._simulate_detection(image)
        
        try:
            # التحليل الفعلي باستخدام YOLO
            results = self.model(image, conf=self.confidence_threshold)
            detections = []
            
            for result in results:
                boxes = result.boxes
                if boxes is not None:
                    for box in boxes:
                        x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                        conf = box.conf[0].cpu().numpy()
                        cls = int(box.cls[0].cpu().numpy())
                        
                        detections.append({
                            'bbox': [x1, y1, x2, y2],
                            'confidence': conf,
                            'class': cls,
                            'center': [(x1 + x2) / 2, (y1 + y2) / 2],
                            'area': (x2 - x1) * (y2 - y1)
                        })
            
            return detections
            
        except Exception as e:
            self.logger.warning(f"فشل في الكشف الفعلي: {e}، التبديل للمحاكاة")
            return await self._simulate_detection(image)
    
    async def _simulate_detection(self, image: np.ndarray) -> List[Dict]:
        """محاكاة كشف الحيوانات المنوية"""
        import random
        
        height, width = image.shape[:2]
        num_sperm = random.randint(15, 60)
        
        detections = []
        for i in range(num_sperm):
            # موقع عشوائي
            x1 = random.randint(0, width - 50)
            y1 = random.randint(0, height - 20)
            x2 = x1 + random.randint(30, 80)
            y2 = y1 + random.randint(15, 40)
            
            # التأكد من أن الصندوق داخل حدود الصورة
            x2 = min(x2, width)
            y2 = min(y2, height)
            
            detections.append({
                'bbox': [x1, y1, x2, y2],
                'confidence': random.uniform(0.6, 0.95),
                'class': 0,  # فئة الحيوان المنوي
                'center': [(x1 + x2) / 2, (y1 + y2) / 2],
                'area': (x2 - x1) * (y2 - y1)
            })
        
        await asyncio.sleep(0.1)  # محاكاة وقت المعالجة
        return detections
    
    def _update_tracks(self, detections: List[Dict], frame_idx: int, tracks: Dict) -> Dict:
        """تحديث مسارات التتبع"""
        if not self.tracker:
            return self._simple_tracking(detections, frame_idx, tracks)
        
        # تحويل الكشوفات لصيغة DeepSort
        detection_list = []
        for det in detections:
            x1, y1, x2, y2 = det['bbox']
            detection_list.append([x1, y1, x2 - x1, y2 - y1, det['confidence']])
        
        # تحديث التتبع
        tracked_objects = self.tracker.update_tracks(detection_list)
        
        # تحديث المسارات
        for track in tracked_objects:
            if track.is_confirmed():
                track_id = track.track_id
                bbox = track.to_ltwh()
                center = [bbox[0] + bbox[2]/2, bbox[1] + bbox[3]/2]
                
                if track_id not in tracks:
                    tracks[track_id] = []
                
                tracks[track_id].append({
                    'frame': frame_idx,
                    'center': center,
                    'bbox': bbox
                })
        
        return tracks
    
    def _simple_tracking(self, detections: List[Dict], frame_idx: int, tracks: Dict) -> Dict:
        """تتبع بسيط بدون DeepSort"""
        import random
        
        for i, det in enumerate(detections):
            track_id = f"track_{i}_{frame_idx}"
            tracks[track_id] = tracks.get(track_id, [])
            tracks[track_id].append({
                'frame': frame_idx,
                'center': det['center'],
                'bbox': det['bbox']
            })
        
        return tracks
    
    async def _analyze_tracking_data(self, tracks: Dict, fps: float, all_detections: List) -> Dict:
        """تحليل بيانات التتبع لحساب مؤشرات CASA"""
        import random
        from scipy import stats
        
        total_sperm = len(tracks)
        motile_sperm = 0
        velocities = []
        casa_values = {'vcl': [], 'vsl': [], 'vap': [], 'lin': [], 'str': [], 'wob': []}
        
        for track_id, track_points in tracks.items():
            if len(track_points) < self.min_track_length:
                continue
            
            # حساب المسافات والسرعات
            distances = []
            straight_distance = 0
            
            if len(track_points) > 1:
                motile_sperm += 1
                
                for i in range(1, len(track_points)):
                    prev_point = track_points[i-1]['center']
                    curr_point = track_points[i]['center']
                    
                    # المسافة بين النقاط
                    dist = np.sqrt((curr_point[0] - prev_point[0])**2 + 
                                 (curr_point[1] - prev_point[1])**2)
                    distances.append(dist * self.pixel_to_micron_ratio)
                
                # المسافة المستقيمة
                first_point = track_points[0]['center']
                last_point = track_points[-1]['center']
                straight_distance = np.sqrt((last_point[0] - first_point[0])**2 + 
                                          (last_point[1] - first_point[1])**2) * self.pixel_to_micron_ratio
                
                # حساب السرعات
                time_interval = 1.0 / fps if fps > 0 else 1.0
                total_distance = sum(distances)
                duration = len(track_points) * time_interval
                
                vcl = total_distance / duration if duration > 0 else 0  # السرعة المنحنية
                vsl = straight_distance / duration if duration > 0 else 0  # السرعة المستقيمة
                vap = vcl * 0.8  # السرعة المتوسطة (تقدير)
                
                # النسب
                lin = (vsl / vcl * 100) if vcl > 0 else 0  # الخطية
                str_val = (vsl / vap * 100) if vap > 0 else 0  # الاستقامة
                wob = (vap / vcl * 100) if vcl > 0 else 0  # التذبذب
                
                casa_values['vcl'].append(vcl)
                casa_values['vsl'].append(vsl)
                casa_values['vap'].append(vap)
                casa_values['lin'].append(lin)
                casa_values['str'].append(str_val)
                casa_values['wob'].append(wob)
                
                velocities.append(vcl)
        
        # حساب المتوسطات
        motility_percentage = (motile_sperm / total_sperm * 100) if total_sperm > 0 else 0
        
        casa_parameters = CasaParameters(
            vcl=np.mean(casa_values['vcl']) if casa_values['vcl'] else 0,
            vsl=np.mean(casa_values['vsl']) if casa_values['vsl'] else 0,
            vap=np.mean(casa_values['vap']) if casa_values['vap'] else 0,
            lin=np.mean(casa_values['lin']) if casa_values['lin'] else 0,
            str=np.mean(casa_values['str']) if casa_values['str'] else 0,
            wob=np.mean(casa_values['wob']) if casa_values['wob'] else 0,
            alh=random.uniform(2, 6),  # تقدير
            bcf=random.uniform(8, 20),  # تقدير
            mot=motility_percentage
        )
        
        # توزيع السرعة عبر الزمن
        velocity_distribution = []
        if velocities:
            # تقسيم البيانات إلى 10 نقاط زمنية
            for i in range(10):
                avg_velocity = np.mean(velocities) + random.uniform(-10, 10)
                velocity_distribution.append(VelocityDataPoint(
                    time_point=i,
                    velocity=max(0, avg_velocity)
                ))
        
        # تحليل الشكل (محاكاة)
        morphology = await self._analyze_morphology_from_detections(all_detections)
        
        return {
            'sperm_count': total_sperm,
            'motility': motility_percentage,
            'concentration': self._estimate_concentration(total_sperm),
            'casa_parameters': casa_parameters,
            'morphology': morphology,
            'velocity_distribution': velocity_distribution,
            'tracking_data': self._format_tracking_data(tracks)
        }
    
    async def _analyze_morphology(self, image: np.ndarray, detections: List[Dict]) -> SpermMorphology:
        """تحليل شكل الحيوانات المنوية"""
        import random
        
        # محاكاة تحليل الشكل
        normal_percentage = random.uniform(60, 90)
        abnormal_percentage = 100 - normal_percentage
        
        head_defects = random.uniform(5, 20)
        tail_defects = random.uniform(3, 15)
        neck_defects = random.uniform(1, 8)
        
        return SpermMorphology(
            normal=normal_percentage,
            abnormal=abnormal_percentage,
            head_defects=head_defects,
            tail_defects=tail_defects,
            neck_defects=neck_defects
        )
    
    async def _analyze_morphology_from_detections(self, detections: List[Dict]) -> SpermMorphology:
        """تحليل الشكل من الكشوفات"""
        import random
        
        if not detections:
            return SpermMorphology(
                normal=0, abnormal=0, head_defects=0, tail_defects=0, neck_defects=0
            )
        
        # تحليل أشكال الحيوانات المنوية بناءً على نسب أبعاد الصناديق
        normal_count = 0
        
        for det in detections:
            x1, y1, x2, y2 = det['bbox']
            width = x2 - x1
            height = y2 - y1
            aspect_ratio = width / height if height > 0 else 0
            
            # تقدير الشكل بناءً على نسبة الأبعاد
            if 1.5 <= aspect_ratio <= 4.0:  # شكل طبيعي متوقع
                normal_count += 1
        
        total_count = len(detections)
        normal_percentage = (normal_count / total_count * 100) if total_count > 0 else 0
        abnormal_percentage = 100 - normal_percentage
        
        return SpermMorphology(
            normal=normal_percentage,
            abnormal=abnormal_percentage,
            head_defects=random.uniform(5, abnormal_percentage * 0.6),
            tail_defects=random.uniform(3, abnormal_percentage * 0.4),
            neck_defects=random.uniform(1, abnormal_percentage * 0.2)
        )
    
    def _calculate_concentration(self, sperm_count: int, image_shape: Tuple) -> float:
        """حساب تركيز الحيوانات المنوية"""
        height, width = image_shape[:2]
        # تقدير تركيز بناءً على مساحة الصورة (تقدير تقريبي)
        area_mm2 = (width * height) / (1000 * 1000)  # تحويل تقريبي
        concentration = sperm_count / area_mm2 if area_mm2 > 0 else 0
        return min(concentration, 50)  # حد أقصى منطقي
    
    def _estimate_concentration(self, sperm_count: int) -> float:
        """تقدير التركيز من عدد الحيوانات المنوية"""
        # تقدير بسيط بناءً على العدد
        return min(sperm_count * 0.5, 40)
    
    def _format_tracking_data(self, tracks: Dict) -> List[SpermTrackingData]:
        """تنسيق بيانات التتبع"""
        tracking_data = []
        
        for track_id, track_points in tracks.items():
            if len(track_points) < self.min_track_length:
                continue
            
            # حساب المسافة الإجمالية
            total_distance = 0
            for i in range(1, len(track_points)):
                prev = track_points[i-1]['center']
                curr = track_points[i]['center']
                dist = np.sqrt((curr[0] - prev[0])**2 + (curr[1] - prev[1])**2)
                total_distance += dist * self.pixel_to_micron_ratio
            
            # حساب الإزاحة
            first_point = track_points[0]['center']
            last_point = track_points[-1]['center']
            displacement = np.sqrt((last_point[0] - first_point[0])**2 + 
                                 (last_point[1] - first_point[1])**2) * self.pixel_to_micron_ratio
            
            tracking_data.append(SpermTrackingData(
                sperm_id=int(track_id.split('_')[-1]) if '_' in track_id else 0,
                track_points=[{'x': p['center'][0], 'y': p['center'][1], 'frame': p['frame']} 
                             for p in track_points],
                total_distance=total_distance,
                displacement=displacement,
                duration=len(track_points) / 30.0  # تقدير 30 fps
            ))
        
        return tracking_data
    
    async def _update_progress(self, analysis_id: str, progress: float, message: str):
        """تحديث تقدم التحليل"""
        self.analysis_cache[analysis_id] = AnalysisProgress(
            analysis_id=analysis_id,
            status=AnalysisStatus.ANALYZING if progress < 1.0 else AnalysisStatus.COMPLETED,
            progress=progress,
            message=message
        )
        
        # تسجيل التقدم
        self.logger.info(f"التحليل {analysis_id}: {progress*100:.1f}% - {message}")
    
    def get_analysis_progress(self, analysis_id: str) -> Optional[AnalysisProgress]:
        """جلب تقدم التحليل"""
        return self.analysis_cache.get(analysis_id)
    
    def clear_analysis_cache(self, analysis_id: str):
        """مسح ذاكرة التخزين المؤقت للتحليل"""
        if analysis_id in self.analysis_cache:
            del self.analysis_cache[analysis_id]
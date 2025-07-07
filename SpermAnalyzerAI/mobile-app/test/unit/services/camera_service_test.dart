import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:camera/camera.dart';

import 'package:sperm_analyzer_ai/services/camera_service.dart';

// Mock classes
class MockCameraController extends Mock implements CameraController {}
class MockCameraDescription extends Mock implements CameraDescription {}

void main() {
  group('CameraService Tests', () {
    late ProviderContainer container;
    late MockCameraController mockController;
    late MockCameraDescription mockCamera;

    setUp(() {
      container = ProviderContainer();
      mockController = MockCameraController();
      mockCamera = MockCameraDescription();
      
      // Setup mock camera description
      when(() => mockCamera.name).thenReturn('Test Camera');
      when(() => mockCamera.lensDirection).thenReturn(CameraLensDirection.back);
      when(() => mockCamera.sensorOrientation).thenReturn(90);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default camera state', () {
      final notifier = container.read(cameraStateProvider.notifier);
      final state = container.read(cameraStateProvider);

      expect(state.isInitialized, false);
      expect(state.controller, null);
      expect(state.availableCameras, isEmpty);
      expect(state.selectedCameraIndex, 0);
      expect(state.flashMode, FlashMode.off);
      expect(state.zoomLevel, 1.0);
      expect(state.isRecording, false);
      expect(state.isCapturing, false);
      expect(state.liveAnalysisEnabled, false);
    });

    test('should handle camera initialization', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      notifier.initializeCameras([mockCamera]);
      final state = container.read(cameraStateProvider);

      expect(state.availableCameras, contains(mockCamera));
      expect(state.availableCameras.length, 1);
    });

    test('should handle camera controller setup', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Mock controller initialization
      when(() => mockController.value).thenReturn(
        const CameraValue(
          isInitialized: true,
          isStreamingImages: false,
          isRecordingVideo: false,
          isRecordingPaused: false,
          isTakingPicture: false,
          isStreamingVideoRtmp: false,
          flashMode: FlashMode.off,
          exposureMode: ExposureMode.auto,
          focusMode: FocusMode.auto,
          exposurePointSupported: true,
          focusPointSupported: true,
        ),
      );
      when(() => mockController.description).thenReturn(mockCamera);
      
      notifier.setController(mockController);
      final state = container.read(cameraStateProvider);

      expect(state.controller, mockController);
      expect(state.isInitialized, true);
    });

    test('should handle flash mode changes', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Test all flash modes
      notifier.toggleFlash();
      expect(container.read(cameraStateProvider).flashMode, FlashMode.auto);
      
      notifier.toggleFlash();
      expect(container.read(cameraStateProvider).flashMode, FlashMode.always);
      
      notifier.toggleFlash();
      expect(container.read(cameraStateProvider).flashMode, FlashMode.torch);
      
      notifier.toggleFlash();
      expect(container.read(cameraStateProvider).flashMode, FlashMode.off);
    });

    test('should handle zoom level changes', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Test zoom constraints
      notifier.setZoomLevel(0.5); // Below minimum
      expect(container.read(cameraStateProvider).zoomLevel, 1.0);
      
      notifier.setZoomLevel(2.5); // Valid zoom
      expect(container.read(cameraStateProvider).zoomLevel, 2.5);
      
      notifier.setZoomLevel(15.0); // Above maximum
      expect(container.read(cameraStateProvider).zoomLevel, 10.0);
    });

    test('should handle camera switching', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Setup multiple cameras
      final frontCamera = MockCameraDescription();
      when(() => frontCamera.name).thenReturn('Front Camera');
      when(() => frontCamera.lensDirection).thenReturn(CameraLensDirection.front);
      
      notifier.initializeCameras([mockCamera, frontCamera]);
      
      // Switch camera
      notifier.switchCamera();
      expect(container.read(cameraStateProvider).selectedCameraIndex, 1);
      
      // Switch back
      notifier.switchCamera();
      expect(container.read(cameraStateProvider).selectedCameraIndex, 0);
    });

    test('should handle recording state', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      notifier.setRecording(true);
      expect(container.read(cameraStateProvider).isRecording, true);
      
      notifier.setRecording(false);
      expect(container.read(cameraStateProvider).isRecording, false);
    });

    test('should handle capturing state', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      notifier.setCapturing(true);
      expect(container.read(cameraStateProvider).isCapturing, true);
      
      notifier.setCapturing(false);
      expect(container.read(cameraStateProvider).isCapturing, false);
    });

    test('should handle live analysis toggle', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      notifier.toggleLiveAnalysis();
      expect(container.read(cameraStateProvider).liveAnalysisEnabled, true);
      
      notifier.toggleLiveAnalysis();
      expect(container.read(cameraStateProvider).liveAnalysisEnabled, false);
    });

    test('should handle focus point setting', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      const focusPoint = Offset(0.5, 0.5);
      notifier.setFocusPoint(focusPoint);
      
      final state = container.read(cameraStateProvider);
      expect(state.focusPoint, focusPoint);
    });

    test('should handle exposure point setting', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      const exposurePoint = Offset(0.3, 0.7);
      notifier.setExposurePoint(exposurePoint);
      
      final state = container.read(cameraStateProvider);
      expect(state.exposurePoint, exposurePoint);
    });

    test('should validate camera capabilities', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Test flash availability
      expect(notifier.isFlashAvailable(), false); // No controller set
      
      // Set mock controller
      when(() => mockController.value).thenReturn(
        const CameraValue(
          isInitialized: true,
          flashMode: FlashMode.off,
          isStreamingImages: false,
          isRecordingVideo: false,
          isRecordingPaused: false,
          isTakingPicture: false,
          isStreamingVideoRtmp: false,
          exposureMode: ExposureMode.auto,
          focusMode: FocusMode.auto,
          exposurePointSupported: true,
          focusPointSupported: true,
        ),
      );
      notifier.setController(mockController);
      
      expect(notifier.isFlashAvailable(), true);
      expect(notifier.canTakePictures(), true);
      expect(notifier.canRecordVideo(), true);
    });

    test('should handle camera disposal', () {
      final notifier = container.read(cameraStateProvider.notifier);
      
      // Set controller
      notifier.setController(mockController);
      expect(container.read(cameraStateProvider).controller, mockController);
      
      // Dispose camera
      notifier.disposeCamera();
      final state = container.read(cameraStateProvider);
      
      expect(state.controller, null);
      expect(state.isInitialized, false);
      expect(state.isRecording, false);
      expect(state.isCapturing, false);
    });

    group('Error Handling', () {
      test('should handle camera initialization errors', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        // Test with empty camera list
        notifier.initializeCameras([]);
        final state = container.read(cameraStateProvider);
        
        expect(state.availableCameras, isEmpty);
        expect(state.error, isNull); // Should handle gracefully
      });

      test('should handle invalid zoom levels', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        // Test negative zoom
        notifier.setZoomLevel(-1.0);
        expect(container.read(cameraStateProvider).zoomLevel, 1.0);
        
        // Test very high zoom
        notifier.setZoomLevel(100.0);
        expect(container.read(cameraStateProvider).zoomLevel, 10.0);
      });

      test('should handle camera switching with single camera', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        notifier.initializeCameras([mockCamera]);
        
        // Should stay on same camera
        notifier.switchCamera();
        expect(container.read(cameraStateProvider).selectedCameraIndex, 0);
      });
    });

    group('Camera Permissions', () {
      test('should track permission status', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        notifier.setPermissionStatus(true);
        expect(container.read(cameraStateProvider).hasPermission, true);
        
        notifier.setPermissionStatus(false);
        expect(container.read(cameraStateProvider).hasPermission, false);
      });
    });

    group('Image Quality Settings', () {
      test('should handle image quality settings', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        notifier.setImageQuality(ImageQuality.high);
        expect(container.read(cameraStateProvider).imageQuality, ImageQuality.high);
        
        notifier.setImageQuality(ImageQuality.medium);
        expect(container.read(cameraStateProvider).imageQuality, ImageQuality.medium);
        
        notifier.setImageQuality(ImageQuality.low);
        expect(container.read(cameraStateProvider).imageQuality, ImageQuality.low);
      });

      test('should handle video quality settings', () {
        final notifier = container.read(cameraStateProvider.notifier);
        
        notifier.setVideoQuality(VideoQuality.high);
        expect(container.read(cameraStateProvider).videoQuality, VideoQuality.high);
        
        notifier.setVideoQuality(VideoQuality.medium);
        expect(container.read(cameraStateProvider).videoQuality, VideoQuality.medium);
        
        notifier.setVideoQuality(VideoQuality.low);
        expect(container.read(cameraStateProvider).videoQuality, VideoQuality.low);
      });
    });
  });
}

// Enums for testing
enum ImageQuality { low, medium, high }
enum VideoQuality { low, medium, high }
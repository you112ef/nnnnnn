import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

import 'package:sperm_analyzer_ai/services/analysis_service.dart';
import 'package:sperm_analyzer_ai/models/analysis_result.dart';

// Mock classes
class MockFile extends Mock implements File {}

void main() {
  group('AnalysisService Tests', () {
    late ProviderContainer container;
    late MockFile mockFile;

    setUp(() {
      container = ProviderContainer();
      mockFile = MockFile();
      
      // Setup mock file behavior
      when(() => mockFile.path).thenReturn('/test/path/sample.jpg');
      when(() => mockFile.lengthSync()).thenReturn(1024 * 1024); // 1MB
      when(() => mockFile.existsSync()).thenReturn(true);
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default state', () {
      final notifier = container.read(analysisStateProvider.notifier);
      final state = container.read(analysisStateProvider);

      expect(state.isAnalyzing, false);
      expect(state.selectedFile, null);
      expect(state.result, null);
      expect(state.progress, 0.0);
      expect(state.status, 'ready');
    });

    test('should set selected file correctly', () {
      final notifier = container.read(analysisStateProvider.notifier);
      
      notifier.setSelectedFile(mockFile);
      final state = container.read(analysisStateProvider);

      expect(state.selectedFile, mockFile);
      expect(state.selectedFile?.path, '/test/path/sample.jpg');
    });

    test('should clear selected file', () {
      final notifier = container.read(analysisStateProvider.notifier);
      
      // Set file first
      notifier.setSelectedFile(mockFile);
      expect(container.read(analysisStateProvider).selectedFile, mockFile);
      
      // Clear file
      notifier.clearSelectedFile();
      final state = container.read(analysisStateProvider);
      
      expect(state.selectedFile, null);
    });

    test('should validate file format correctly', () {
      final notifier = container.read(analysisStateProvider.notifier);

      // Test valid image formats
      final validImageFormats = ['jpg', 'jpeg', 'png', 'bmp'];
      for (final format in validImageFormats) {
        when(() => mockFile.path).thenReturn('/test/sample.$format');
        expect(notifier.isValidFormat(mockFile), true);
      }

      // Test valid video formats
      final validVideoFormats = ['mp4', 'avi', 'mov', 'mkv'];
      for (final format in validVideoFormats) {
        when(() => mockFile.path).thenReturn('/test/sample.$format');
        expect(notifier.isValidFormat(mockFile), true);
      }

      // Test invalid formats
      when(() => mockFile.path).thenReturn('/test/sample.txt');
      expect(notifier.isValidFormat(mockFile), false);
      
      when(() => mockFile.path).thenReturn('/test/sample.doc');
      expect(notifier.isValidFormat(mockFile), false);
    });

    test('should validate file size correctly', () {
      final notifier = container.read(analysisStateProvider.notifier);

      // Test valid file size (under 100MB)
      when(() => mockFile.lengthSync()).thenReturn(50 * 1024 * 1024); // 50MB
      expect(notifier.isValidFileSize(mockFile), true);

      // Test file size at limit (100MB)
      when(() => mockFile.lengthSync()).thenReturn(100 * 1024 * 1024); // 100MB
      expect(notifier.isValidFileSize(mockFile), true);

      // Test oversized file (over 100MB)
      when(() => mockFile.lengthSync()).thenReturn(150 * 1024 * 1024); // 150MB
      expect(notifier.isValidFileSize(mockFile), false);
    });

    test('should update progress during analysis', () async {
      final notifier = container.read(analysisStateProvider.notifier);
      
      // Start analysis simulation
      notifier.setSelectedFile(mockFile);
      
      // Simulate progress updates
      notifier.updateProgress(0.0, 'Initializing...');
      expect(container.read(analysisStateProvider).progress, 0.0);
      expect(container.read(analysisStateProvider).status, 'Initializing...');
      
      notifier.updateProgress(0.3, 'Processing image...');
      expect(container.read(analysisStateProvider).progress, 0.3);
      expect(container.read(analysisStateProvider).status, 'Processing image...');
      
      notifier.updateProgress(0.7, 'Analyzing results...');
      expect(container.read(analysisStateProvider).progress, 0.7);
      expect(container.read(analysisStateProvider).status, 'Analyzing results...');
      
      notifier.updateProgress(1.0, 'Analysis complete');
      expect(container.read(analysisStateProvider).progress, 1.0);
      expect(container.read(analysisStateProvider).status, 'Analysis complete');
    });

    test('should handle analysis errors gracefully', () async {
      final notifier = container.read(analysisStateProvider.notifier);
      
      // Simulate error condition
      notifier.setError('Network connection failed');
      final state = container.read(analysisStateProvider);
      
      expect(state.error, 'Network connection failed');
      expect(state.isAnalyzing, false);
    });

    test('should reset analysis state', () async {
      final notifier = container.read(analysisStateProvider.notifier);
      
      // Set some state
      notifier.setSelectedFile(mockFile);
      notifier.updateProgress(0.5, 'Processing...');
      notifier.setError('Some error');
      
      // Reset state
      notifier.resetAnalysis();
      final state = container.read(analysisStateProvider);
      
      expect(state.selectedFile, null);
      expect(state.progress, 0.0);
      expect(state.status, 'ready');
      expect(state.error, null);
      expect(state.isAnalyzing, false);
    });

    test('should generate analysis metadata correctly', () {
      final notifier = container.read(analysisStateProvider.notifier);
      
      final metadata = notifier.generateMetadata(mockFile);
      
      expect(metadata.fileName, 'sample.jpg');
      expect(metadata.fileSize, isA<int>());
      expect(metadata.analysisDate, isA<DateTime>());
      expect(metadata.appVersion, isNotEmpty);
      expect(metadata.deviceInfo, isNotEmpty);
    });

    test('should format file size correctly', () {
      final notifier = container.read(analysisStateProvider.notifier);
      
      expect(notifier.formatFileSize(512), '512 B');
      expect(notifier.formatFileSize(1024), '1.0 KB');
      expect(notifier.formatFileSize(1536), '1.5 KB');
      expect(notifier.formatFileSize(1024 * 1024), '1.0 MB');
      expect(notifier.formatFileSize(1536 * 1024), '1.5 MB');
      expect(notifier.formatFileSize(1024 * 1024 * 1024), '1.0 GB');
    });

    group('Analysis Result Validation', () {
      test('should validate CASA parameters', () {
        final result = AnalysisResult(
          id: 'test-id',
          spermCount: 25,
          motility: 65.5,
          concentration: 45.2,
          overallQuality: 78.3,
          casaParameters: CasaParameters(
            vcl: 32.5,
            vsl: 28.1,
            vap: 30.2,
            lin: 86.4,
            str: 93.1,
            wob: 92.8,
            mot: 65.5,
            alh: 4.2,
            bcf: 18.7,
          ),
          morphology: MorphologyData(
            normal: 8.5,
            abnormal: 91.5,
            headDefects: 45.2,
            tailDefects: 32.1,
            neckDefects: 14.2,
          ),
          velocityDistribution: [],
          metadata: AnalysisMetadata(
            fileName: 'test.jpg',
            fileSize: 1024,
            analysisDate: DateTime.now(),
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
          ),
        );

        expect(result.casaParameters.vcl, greaterThan(0));
        expect(result.casaParameters.vsl, greaterThan(0));
        expect(result.casaParameters.lin, greaterThanOrEqualTo(0));
        expect(result.casaParameters.lin, lessThanOrEqualTo(100));
        expect(result.morphology.normal + result.morphology.abnormal, closeTo(100, 0.1));
      });

      test('should calculate quality assessment correctly', () {
        final result = AnalysisResult(
          id: 'test-id',
          spermCount: 25,
          motility: 65.5,
          concentration: 45.2,
          overallQuality: 78.3,
          casaParameters: CasaParameters(
            vcl: 32.5,
            vsl: 28.1,
            vap: 30.2,
            lin: 86.4,
            str: 93.1,
            wob: 92.8,
            mot: 65.5,
            alh: 4.2,
            bcf: 18.7,
          ),
          morphology: MorphologyData(
            normal: 8.5,
            abnormal: 91.5,
            headDefects: 45.2,
            tailDefects: 32.1,
            neckDefects: 14.2,
          ),
          velocityDistribution: [],
          metadata: AnalysisMetadata(
            fileName: 'test.jpg',
            fileSize: 1024,
            analysisDate: DateTime.now(),
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
          ),
        );

        // Test quality thresholds
        expect(result.spermCount >= 15, true); // WHO 2010 criteria
        expect(result.motility >= 40, true); // WHO 2010 criteria
        expect(result.morphology.normal >= 4, true); // WHO 2010 criteria
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:io';

import 'package:sperm_analyzer_ai/services/chart_export_service.dart';
import 'package:sperm_analyzer_ai/models/analysis_result.dart';
import '../../test_config.dart';

// Mock classes
class MockFile extends Mock implements File {}

void main() {
  group('ChartExportService Tests', () {
    late ProviderContainer container;
    late ChartExportService exportService;
    late List<AnalysisResult> testResults;

    setUp(() {
      container = ProviderContainer();
      exportService = ChartExportService();
      testResults = TestConfig.generateMockResults(5);
    });

    tearDown(() {
      container.dispose();
    });

    test('should export data to CSV format', () async {
      final csvData = await exportService.exportToCsv(testResults);
      
      expect(csvData, isNotEmpty);
      expect(csvData, contains('Analysis ID'));
      expect(csvData, contains('Date'));
      expect(csvData, contains('Sperm Count'));
      expect(csvData, contains('Motility'));
      expect(csvData, contains('Concentration'));
      expect(csvData, contains('Overall Quality'));
      
      // Check that each result is included
      for (final result in testResults) {
        expect(csvData, contains(result.id));
        expect(csvData, contains(result.spermCount.toString()));
        expect(csvData, contains(result.motility.toString()));
        expect(csvData, contains(result.concentration.toString()));
        expect(csvData, contains(result.overallQuality.toString()));
      }
    });

    test('should export data to JSON format', () async {
      final jsonData = await exportService.exportToJson(testResults);
      
      expect(jsonData, isNotEmpty);
      expect(jsonData, contains('"analysis_results"'));
      expect(jsonData, contains('"export_metadata"'));
      expect(jsonData, contains('"total_results"'));
      expect(jsonData, contains('"export_date"'));
      expect(jsonData, contains('"app_version"'));
      
      // Check that each result is included
      for (final result in testResults) {
        expect(jsonData, contains('"${result.id}"'));
      }
    });

    test('should generate detailed analysis report', () async {
      final report = await exportService.generateDetailedReport(testResults);
      
      expect(report, isNotEmpty);
      expect(report, contains('# تقرير تحليل شامل'));
      expect(report, contains('## الملخص التنفيذي'));
      expect(report, contains('## التحاليل الفردية'));
      expect(report, contains('## الإحصائيات الإجمالية'));
      expect(report, contains('## المعايير المرجعية'));
      expect(report, contains('## التوصيات'));
      
      // Check statistical content
      expect(report, contains('متوسط عدد الحيوانات المنوية'));
      expect(report, contains('متوسط الحركة'));
      expect(report, contains('متوسط التركيز'));
      expect(report, contains('متوسط الجودة'));
    });

    test('should calculate statistics correctly', () {
      final stats = exportService.calculateStatistics(testResults);
      
      expect(stats, isNotEmpty);
      expect(stats, contains('totalAnalyses'));
      expect(stats, contains('averageSpermCount'));
      expect(stats, contains('averageMotility'));
      expect(stats, contains('averageConcentration'));
      expect(stats, contains('averageQuality'));
      expect(stats, contains('minSpermCount'));
      expect(stats, contains('maxSpermCount'));
      expect(stats, contains('minMotility'));
      expect(stats, contains('maxMotility'));
      expect(stats, contains('standardDeviationSpermCount'));
      expect(stats, contains('standardDeviationMotility'));
      
      // Verify calculations
      final totalAnalyses = stats['totalAnalyses'] as int;
      expect(totalAnalyses, equals(testResults.length));
      
      final avgSpermCount = stats['averageSpermCount'] as double;
      final expectedAvgSpermCount = testResults.map((r) => r.spermCount).reduce((a, b) => a + b) / testResults.length;
      expect(avgSpermCount, closeTo(expectedAvgSpermCount, 0.01));
    });

    test('should format numbers correctly', () {
      expect(exportService.formatNumber(123.456), '123.46');
      expect(exportService.formatNumber(0.123), '0.12');
      expect(exportService.formatNumber(1000.0), '1000.00');
      expect(exportService.formatNumber(0.0), '0.00');
    });

    test('should format dates correctly', () {
      final testDate = DateTime(2024, 1, 15, 10, 30, 45);
      final formattedDate = exportService.formatDate(testDate);
      
      expect(formattedDate, contains('2024'));
      expect(formattedDate, contains('01'));
      expect(formattedDate, contains('15'));
    });

    test('should generate export filename correctly', () {
      final filename = exportService.generateExportFilename('csv');
      
      expect(filename, contains('sperm_analysis_export_'));
      expect(filename, contains('.csv'));
      expect(filename, isNot(contains(' '))); // No spaces
      expect(filename, matches(RegExp(r'^sperm_analysis_export_\d{8}_\d{6}\.csv$')));
    });

    test('should validate export format', () {
      expect(exportService.isValidExportFormat('csv'), true);
      expect(exportService.isValidExportFormat('json'), true);
      expect(exportService.isValidExportFormat('pdf'), true);
      expect(exportService.isValidExportFormat('txt'), false);
      expect(exportService.isValidExportFormat(''), false);
      expect(exportService.isValidExportFormat('XML'), false);
    });

    test('should handle empty results list', () async {
      final emptyResults = <AnalysisResult>[];
      
      final csvData = await exportService.exportToCsv(emptyResults);
      expect(csvData, contains('Analysis ID')); // Header should still be present
      expect(csvData.split('\n').length, lessThanOrEqualTo(2)); // Only header row
      
      final jsonData = await exportService.exportToJson(emptyResults);
      expect(jsonData, contains('"total_results": 0'));
      
      final report = await exportService.generateDetailedReport(emptyResults);
      expect(report, contains('لا توجد نتائج متاحة'));
    });

    test('should handle single result correctly', () async {
      final singleResult = [testResults.first];
      
      final csvData = await exportService.exportToCsv(singleResult);
      expect(csvData.split('\n').length, equals(3)); // Header + 1 data row + empty line
      
      final stats = exportService.calculateStatistics(singleResult);
      expect(stats['totalAnalyses'], equals(1));
      expect(stats['standardDeviationSpermCount'], equals(0.0));
      expect(stats['standardDeviationMotility'], equals(0.0));
    });

    group('CASA Parameters Export', () {
      test('should include CASA parameters in CSV export', () async {
        final csvData = await exportService.exportToCsv(testResults);
        
        expect(csvData, contains('VCL'));
        expect(csvData, contains('VSL'));
        expect(csvData, contains('VAP'));
        expect(csvData, contains('LIN'));
        expect(csvData, contains('STR'));
        expect(csvData, contains('WOB'));
        expect(csvData, contains('MOT'));
        expect(csvData, contains('ALH'));
        expect(csvData, contains('BCF'));
      });

      test('should include CASA parameters in JSON export', () async {
        final jsonData = await exportService.exportToJson(testResults);
        
        expect(jsonData, contains('casa_parameters'));
        expect(jsonData, contains('vcl'));
        expect(jsonData, contains('vsl'));
        expect(jsonData, contains('lin'));
        expect(jsonData, contains('mot'));
      });
    });

    group('Morphology Data Export', () {
      test('should include morphology data in exports', () async {
        final csvData = await exportService.exportToCsv(testResults);
        
        expect(csvData, contains('Normal Morphology'));
        expect(csvData, contains('Abnormal Morphology'));
        expect(csvData, contains('Head Defects'));
        expect(csvData, contains('Tail Defects'));
        expect(csvData, contains('Neck Defects'));
        
        final jsonData = await exportService.exportToJson(testResults);
        expect(jsonData, contains('morphology'));
        expect(jsonData, contains('normal'));
        expect(jsonData, contains('abnormal'));
        expect(jsonData, contains('head_defects'));
        expect(jsonData, contains('tail_defects'));
        expect(jsonData, contains('neck_defects'));
      });
    });

    group('Chart Data Export', () {
      test('should export chart data for plotting', () async {
        final chartData = await exportService.exportChartData(testResults);
        
        expect(chartData, isNotEmpty);
        expect(chartData, contains('timeSeriesData'));
        expect(chartData, contains('motilityData'));
        expect(chartData, contains('concentrationData'));
        expect(chartData, contains('qualityData'));
        expect(chartData, contains('casaData'));
        expect(chartData, contains('morphologyData'));
      });

      test('should generate chart configuration', () {
        final chartConfig = exportService.generateChartConfig();
        
        expect(chartConfig, isNotEmpty);
        expect(chartConfig, contains('colors'));
        expect(chartConfig, contains('themes'));
        expect(chartConfig, contains('formats'));
        expect(chartConfig, contains('defaultSettings'));
      });
    });

    group('Performance Tests', () {
      test('should handle large datasets efficiently', () async {
        final largeResults = TestConfig.generateMockResults(1000);
        
        final stopwatch = Stopwatch()..start();
        final csvData = await exportService.exportToCsv(largeResults);
        stopwatch.stop();
        
        expect(csvData, isNotEmpty);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle memory efficiently for large exports', () async {
        final largeResults = TestConfig.generateMockResults(500);
        
        final jsonData = await exportService.exportToJson(largeResults);
        final report = await exportService.generateDetailedReport(largeResults);
        
        expect(jsonData, isNotEmpty);
        expect(report, isNotEmpty);
        // Should complete without memory issues
      });
    });

    group('Error Handling', () {
      test('should handle corrupt data gracefully', () async {
        final corruptResult = AnalysisResult(
          id: 'corrupt-id',
          spermCount: -1, // Invalid value
          motility: 150.0, // Invalid percentage
          concentration: -10.0, // Invalid value
          overallQuality: 200.0, // Invalid percentage
          casaParameters: CasaParameters(
            vcl: double.nan,
            vsl: double.infinity,
            vap: -1.0,
            lin: 150.0,
            str: -50.0,
            wob: 1000.0,
            mot: -25.0,
            alh: double.nan,
            bcf: double.infinity,
          ),
          morphology: MorphologyData(
            normal: 150.0,
            abnormal: -50.0,
            headDefects: double.nan,
            tailDefects: double.infinity,
            neckDefects: -10.0,
          ),
          velocityDistribution: [],
          metadata: AnalysisMetadata(
            fileName: 'corrupt.jpg',
            fileSize: -1,
            analysisDate: DateTime.now(),
            appVersion: '',
            deviceInfo: '',
          ),
        );
        
        final corruptResults = [corruptResult];
        
        // Should not throw exceptions
        final csvData = await exportService.exportToCsv(corruptResults);
        expect(csvData, isNotEmpty);
        
        final jsonData = await exportService.exportToJson(corruptResults);
        expect(jsonData, isNotEmpty);
        
        final report = await exportService.generateDetailedReport(corruptResults);
        expect(report, isNotEmpty);
      });
    });
  });
}
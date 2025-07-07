import 'package:flutter_test/flutter_test.dart';
import 'package:sperm_analyzer_ai/models/analysis_result.dart';

void main() {
  group('AnalysisResult Model Tests', () {
    late AnalysisResult testResult;
    late CasaParameters testCasa;
    late MorphologyData testMorphology;
    late AnalysisMetadata testMetadata;

    setUp(() {
      testCasa = CasaParameters(
        vcl: 32.5,
        vsl: 28.1,
        vap: 30.2,
        lin: 86.4,
        str: 93.1,
        wob: 92.8,
        mot: 65.5,
        alh: 4.2,
        bcf: 18.7,
      );

      testMorphology = MorphologyData(
        normal: 8.5,
        abnormal: 91.5,
        headDefects: 45.2,
        tailDefects: 32.1,
        neckDefects: 14.2,
      );

      testMetadata = AnalysisMetadata(
        fileName: 'test_sample.mp4',
        fileSize: 1024 * 1024, // 1MB
        analysisDate: DateTime(2024, 1, 15, 10, 30, 45),
        appVersion: '1.0.0',
        deviceInfo: 'Test Device Model',
      );

      testResult = AnalysisResult(
        id: 'test-analysis-123',
        spermCount: 25,
        motility: 65.5,
        concentration: 45.2,
        overallQuality: 78.3,
        casaParameters: testCasa,
        morphology: testMorphology,
        velocityDistribution: [
          VelocityDistribution(velocity: 10.0, count: 5),
          VelocityDistribution(velocity: 20.0, count: 8),
          VelocityDistribution(velocity: 30.0, count: 12),
        ],
        metadata: testMetadata,
      );
    });

    group('AnalysisResult Tests', () {
      test('should create valid AnalysisResult', () {
        expect(testResult.id, 'test-analysis-123');
        expect(testResult.spermCount, 25);
        expect(testResult.motility, 65.5);
        expect(testResult.concentration, 45.2);
        expect(testResult.overallQuality, 78.3);
        expect(testResult.casaParameters, testCasa);
        expect(testResult.morphology, testMorphology);
        expect(testResult.velocityDistribution.length, 3);
        expect(testResult.metadata, testMetadata);
      });

      test('should validate sperm count ranges', () {
        expect(testResult.spermCount >= 0, true);
        expect(testResult.spermCount <= 1000, true); // Reasonable upper limit
      });

      test('should validate percentage ranges', () {
        expect(testResult.motility >= 0, true);
        expect(testResult.motility <= 100, true);
        expect(testResult.overallQuality >= 0, true);
        expect(testResult.overallQuality <= 100, true);
      });

      test('should validate concentration values', () {
        expect(testResult.concentration >= 0, true);
        expect(testResult.concentration <= 1000, true); // million/ml
      });

      test('should calculate quality assessment', () {
        // Test quality calculation based on WHO 2010 criteria
        final result = AnalysisResult(
          id: 'quality-test',
          spermCount: 15, // WHO minimum
          motility: 40, // WHO minimum
          concentration: 15, // WHO minimum
          overallQuality: 70.0,
          casaParameters: testCasa,
          morphology: MorphologyData(
            normal: 4, // WHO minimum
            abnormal: 96,
            headDefects: 50,
            tailDefects: 30,
            neckDefects: 16,
          ),
          velocityDistribution: [],
          metadata: testMetadata,
        );

        expect(result.isWHONormal(), true);
      });

      test('should handle edge cases for quality assessment', () {
        final belowWHO = AnalysisResult(
          id: 'below-who',
          spermCount: 10, // Below WHO
          motility: 30, // Below WHO
          concentration: 10, // Below WHO
          overallQuality: 50.0,
          casaParameters: testCasa,
          morphology: MorphologyData(
            normal: 2, // Below WHO
            abnormal: 98,
            headDefects: 60,
            tailDefects: 25,
            neckDefects: 13,
          ),
          velocityDistribution: [],
          metadata: testMetadata,
        );

        expect(belowWHO.isWHONormal(), false);
      });

      test('should calculate time since analysis', () {
        final recentAnalysis = AnalysisResult(
          id: 'recent',
          spermCount: 25,
          motility: 65.5,
          concentration: 45.2,
          overallQuality: 78.3,
          casaParameters: testCasa,
          morphology: testMorphology,
          velocityDistribution: [],
          metadata: AnalysisMetadata(
            fileName: 'recent.mp4',
            fileSize: 1024,
            analysisDate: DateTime.now().subtract(const Duration(hours: 2)),
            appVersion: '1.0.0',
            deviceInfo: 'Test Device',
          ),
        );

        final timeSince = recentAnalysis.timeSinceAnalysis();
        expect(timeSince.inHours, 2);
      });
    });

    group('CasaParameters Tests', () {
      test('should create valid CASA parameters', () {
        expect(testCasa.vcl, 32.5);
        expect(testCasa.vsl, 28.1);
        expect(testCasa.vap, 30.2);
        expect(testCasa.lin, 86.4);
        expect(testCasa.str, 93.1);
        expect(testCasa.wob, 92.8);
        expect(testCasa.mot, 65.5);
        expect(testCasa.alh, 4.2);
        expect(testCasa.bcf, 18.7);
      });

      test('should validate velocity parameters', () {
        expect(testCasa.vcl > 0, true);
        expect(testCasa.vsl > 0, true);
        expect(testCasa.vap > 0, true);
        expect(testCasa.vsl <= testCasa.vcl, true); // VSL should be <= VCL
        expect(testCasa.vap <= testCasa.vcl, true); // VAP should be <= VCL
      });

      test('should validate percentage parameters', () {
        expect(testCasa.lin >= 0 && testCasa.lin <= 100, true);
        expect(testCasa.str >= 0 && testCasa.str <= 100, true);
        expect(testCasa.wob >= 0 && testCasa.wob <= 100, true);
        expect(testCasa.mot >= 0 && testCasa.mot <= 100, true);
      });

      test('should validate amplitude and frequency parameters', () {
        expect(testCasa.alh >= 0, true);
        expect(testCasa.bcf >= 0, true);
        expect(testCasa.alh <= 20, true); // Reasonable upper limit
        expect(testCasa.bcf <= 50, true); // Reasonable upper limit
      });

      test('should calculate derived parameters correctly', () {
        // LIN = (VSL / VCL) * 100
        final expectedLin = (testCasa.vsl / testCasa.vcl) * 100;
        expect(testCasa.lin, closeTo(expectedLin, 1.0));

        // STR = (VSL / VAP) * 100
        final expectedStr = (testCasa.vsl / testCasa.vap) * 100;
        expect(testCasa.str, closeTo(expectedStr, 1.0));

        // WOB = (VAP / VCL) * 100
        final expectedWob = (testCasa.vap / testCasa.vcl) * 100;
        expect(testCasa.wob, closeTo(expectedWob, 1.0));
      });
    });

    group('MorphologyData Tests', () {
      test('should create valid morphology data', () {
        expect(testMorphology.normal, 8.5);
        expect(testMorphology.abnormal, 91.5);
        expect(testMorphology.headDefects, 45.2);
        expect(testMorphology.tailDefects, 32.1);
        expect(testMorphology.neckDefects, 14.2);
      });

      test('should validate percentage ranges', () {
        expect(testMorphology.normal >= 0 && testMorphology.normal <= 100, true);
        expect(testMorphology.abnormal >= 0 && testMorphology.abnormal <= 100, true);
      });

      test('should validate normal + abnormal = 100%', () {
        final sum = testMorphology.normal + testMorphology.abnormal;
        expect(sum, closeTo(100.0, 0.1));
      });

      test('should validate defect percentages', () {
        expect(testMorphology.headDefects >= 0, true);
        expect(testMorphology.tailDefects >= 0, true);
        expect(testMorphology.neckDefects >= 0, true);
        
        // Defects should not exceed abnormal percentage
        final totalDefects = testMorphology.headDefects + 
                           testMorphology.tailDefects + 
                           testMorphology.neckDefects;
        expect(totalDefects >= testMorphology.abnormal, true);
      });

      test('should calculate morphology assessment', () {
        expect(testMorphology.isWHONormal(), true); // 8.5% > 4% WHO criteria
        
        final belowWHO = MorphologyData(
          normal: 2.0, // Below WHO 4%
          abnormal: 98.0,
          headDefects: 60.0,
          tailDefects: 25.0,
          neckDefects: 13.0,
        );
        expect(belowWHO.isWHONormal(), false);
      });
    });

    group('VelocityDistribution Tests', () {
      test('should create valid velocity distribution', () {
        final velocity = testResult.velocityDistribution.first;
        expect(velocity.velocity, 10.0);
        expect(velocity.count, 5);
      });

      test('should validate velocity values', () {
        for (final velocity in testResult.velocityDistribution) {
          expect(velocity.velocity >= 0, true);
          expect(velocity.count >= 0, true);
        }
      });

      test('should sort velocity distribution by velocity', () {
        final velocities = testResult.velocityDistribution.map((v) => v.velocity).toList();
        final sortedVelocities = List<double>.from(velocities)..sort();
        expect(velocities, orderedEquals(sortedVelocities));
      });

      test('should calculate total sperm count from distribution', () {
        final totalFromDistribution = testResult.velocityDistribution
            .map((v) => v.count)
            .reduce((a, b) => a + b);
        expect(totalFromDistribution, equals(25)); // Should match spermCount
      });
    });

    group('AnalysisMetadata Tests', () {
      test('should create valid metadata', () {
        expect(testMetadata.fileName, 'test_sample.mp4');
        expect(testMetadata.fileSize, 1024 * 1024);
        expect(testMetadata.analysisDate, DateTime(2024, 1, 15, 10, 30, 45));
        expect(testMetadata.appVersion, '1.0.0');
        expect(testMetadata.deviceInfo, 'Test Device Model');
      });

      test('should validate file information', () {
        expect(testMetadata.fileName.isNotEmpty, true);
        expect(testMetadata.fileSize > 0, true);
        expect(testMetadata.appVersion.isNotEmpty, true);
        expect(testMetadata.deviceInfo.isNotEmpty, true);
      });

      test('should validate file extension', () {
        expect(testMetadata.isVideoFile(), true);
        expect(testMetadata.isImageFile(), false);
        
        final imageMetadata = AnalysisMetadata(
          fileName: 'test.jpg',
          fileSize: 1024,
          analysisDate: DateTime.now(),
          appVersion: '1.0.0',
          deviceInfo: 'Test Device',
        );
        
        expect(imageMetadata.isVideoFile(), false);
        expect(imageMetadata.isImageFile(), true);
      });

      test('should format file size correctly', () {
        expect(testMetadata.formatFileSize(), '1.0 MB');
        
        final smallFile = AnalysisMetadata(
          fileName: 'small.jpg',
          fileSize: 512,
          analysisDate: DateTime.now(),
          appVersion: '1.0.0',
          deviceInfo: 'Test Device',
        );
        
        expect(smallFile.formatFileSize(), '512 B');
      });

      test('should format analysis date correctly', () {
        final formattedDate = testMetadata.formatAnalysisDate();
        expect(formattedDate, contains('2024'));
        expect(formattedDate, contains('01'));
        expect(formattedDate, contains('15'));
      });
    });

    group('Data Serialization Tests', () {
      test('should convert to JSON correctly', () {
        final json = testResult.toJson();
        
        expect(json['id'], 'test-analysis-123');
        expect(json['spermCount'], 25);
        expect(json['motility'], 65.5);
        expect(json['concentration'], 45.2);
        expect(json['overallQuality'], 78.3);
        expect(json['casaParameters'], isNotNull);
        expect(json['morphology'], isNotNull);
        expect(json['velocityDistribution'], isNotNull);
        expect(json['metadata'], isNotNull);
      });

      test('should create from JSON correctly', () {
        final json = testResult.toJson();
        final recreatedResult = AnalysisResult.fromJson(json);
        
        expect(recreatedResult.id, testResult.id);
        expect(recreatedResult.spermCount, testResult.spermCount);
        expect(recreatedResult.motility, testResult.motility);
        expect(recreatedResult.concentration, testResult.concentration);
        expect(recreatedResult.overallQuality, testResult.overallQuality);
        expect(recreatedResult.casaParameters.vcl, testResult.casaParameters.vcl);
        expect(recreatedResult.morphology.normal, testResult.morphology.normal);
      });

      test('should handle null values in JSON', () {
        final jsonWithNulls = {
          'id': 'test-id',
          'spermCount': null,
          'motility': null,
          'concentration': null,
          'overallQuality': null,
          'casaParameters': null,
          'morphology': null,
          'velocityDistribution': null,
          'metadata': null,
        };
        
        // Should handle gracefully without throwing
        expect(() => AnalysisResult.fromJson(jsonWithNulls), returnsNormally);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle extreme values', () {
        final extremeResult = AnalysisResult(
          id: 'extreme-test',
          spermCount: 0,
          motility: 0.0,
          concentration: 0.0,
          overallQuality: 0.0,
          casaParameters: CasaParameters(
            vcl: 0.1,
            vsl: 0.1,
            vap: 0.1,
            lin: 0.0,
            str: 0.0,
            wob: 0.0,
            mot: 0.0,
            alh: 0.0,
            bcf: 0.0,
          ),
          morphology: MorphologyData(
            normal: 0.0,
            abnormal: 100.0,
            headDefects: 100.0,
            tailDefects: 0.0,
            neckDefects: 0.0,
          ),
          velocityDistribution: [],
          metadata: testMetadata,
        );
        
        expect(extremeResult.isValid(), true);
        expect(extremeResult.isWHONormal(), false);
      });

      test('should handle very large values', () {
        final largeResult = AnalysisResult(
          id: 'large-test',
          spermCount: 999,
          motility: 100.0,
          concentration: 999.9,
          overallQuality: 100.0,
          casaParameters: CasaParameters(
            vcl: 999.9,
            vsl: 999.9,
            vap: 999.9,
            lin: 100.0,
            str: 100.0,
            wob: 100.0,
            mot: 100.0,
            alh: 50.0,
            bcf: 100.0,
          ),
          morphology: MorphologyData(
            normal: 100.0,
            abnormal: 0.0,
            headDefects: 0.0,
            tailDefects: 0.0,
            neckDefects: 0.0,
          ),
          velocityDistribution: [],
          metadata: testMetadata,
        );
        
        expect(largeResult.isValid(), true);
        expect(largeResult.isWHONormal(), true);
      });

      test('should validate data consistency', () {
        expect(testResult.isDataConsistent(), true);
        
        // Test inconsistent morphology data
        final inconsistentResult = AnalysisResult(
          id: 'inconsistent-test',
          spermCount: 25,
          motility: 65.5,
          concentration: 45.2,
          overallQuality: 78.3,
          casaParameters: testCasa,
          morphology: MorphologyData(
            normal: 50.0,
            abnormal: 60.0, // Should be 50.0 to sum to 100%
            headDefects: 30.0,
            tailDefects: 20.0,
            neckDefects: 10.0,
          ),
          velocityDistribution: [],
          metadata: testMetadata,
        );
        
        expect(inconsistentResult.isDataConsistent(), false);
      });
    });
  });
}
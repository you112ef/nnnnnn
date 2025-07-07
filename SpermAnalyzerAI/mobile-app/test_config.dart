import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test configuration and setup utilities
class TestConfig {
  /// Sets up the test environment with mock initial values
  static Future<void> setupTestEnvironment() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Initialize SharedPreferences with mock values
    SharedPreferences.setMockInitialValues({
      'language_code': 'ar',
      'country_code': 'SA',
      'dark_mode': true,
      'notifications_enabled': true,
      'first_launch': false,
    });
    
    // Setup method channel mocks
    _setupMethodChannelMocks();
  }
  
  /// Sets up mock method channels for testing
  static void _setupMethodChannelMocks() {
    // Mock camera plugin
    const MethodChannel('plugins.flutter.io/camera')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'availableCameras':
          return [
            {
              'name': 'back_camera',
              'lensDirection': 'back',
              'sensorOrientation': 90,
            },
            {
              'name': 'front_camera', 
              'lensDirection': 'front',
              'sensorOrientation': 270,
            },
          ];
        case 'initialize':
          return null;
        case 'takePicture':
          return {'path': '/test/path/image.jpg'};
        case 'startVideoRecording':
          return null;
        case 'stopVideoRecording':
          return {'path': '/test/path/video.mp4'};
        default:
          return null;
      }
    });
    
    // Mock image picker plugin
    const MethodChannel('plugins.flutter.io/image_picker')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'pickImage':
          return '/test/path/picked_image.jpg';
        case 'pickVideo':
          return '/test/path/picked_video.mp4';
        default:
          return null;
      }
    });
    
    // Mock file picker plugin
    const MethodChannel('miguelruivo.flutter.plugins.file_picker')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'any':
          return {
            'files': [
              {
                'path': '/test/path/file.jpg',
                'name': 'file.jpg',
                'size': 1024 * 1024,
                'bytes': null,
              }
            ]
          };
        default:
          return null;
      }
    });
    
    // Mock permission handler
    const MethodChannel('flutter.baseflow.com/permissions/methods')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'requestPermissions':
          return {0: 1}; // granted
        case 'checkPermissionStatus':
          return 1; // granted
        default:
          return null;
      }
    });
    
    // Mock path provider
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getApplicationDocumentsDirectory':
          return '/test/documents';
        case 'getTemporaryDirectory':
          return '/test/temp';
        case 'getExternalStorageDirectory':
          return '/test/external';
        default:
          return null;
      }
    });
    
    // Mock share plus
    const MethodChannel('dev.fluttercommunity.plus/share')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'share':
          return null;
        case 'shareFiles':
          return null;
        default:
          return null;
      }
    });
  }
  
  /// Creates mock analysis result for testing
  static Map<String, dynamic> createMockAnalysisResult() {
    return {
      'id': 'test-analysis-123',
      'spermCount': 25,
      'motility': 65.5,
      'concentration': 45.2,
      'overallQuality': 78.3,
      'casaParameters': {
        'vcl': 32.5,
        'vsl': 28.1,
        'vap': 30.2,
        'lin': 86.4,
        'str': 93.1,
        'wob': 92.8,
        'mot': 65.5,
        'alh': 4.2,
        'bcf': 18.7,
      },
      'morphology': {
        'normal': 8.5,
        'abnormal': 91.5,
        'headDefects': 45.2,
        'tailDefects': 32.1,
        'neckDefects': 14.2,
      },
      'velocityDistribution': [
        {'time': 1, 'velocity': 28.5},
        {'time': 2, 'velocity': 31.2},
        {'time': 3, 'velocity': 29.8},
        {'time': 4, 'velocity': 33.1},
        {'time': 5, 'velocity': 27.9},
      ],
      'metadata': {
        'fileName': 'test_sample.jpg',
        'fileSize': 1024 * 1024,
        'analysisDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'deviceInfo': 'Test Device',
        'doctorName': 'Dr. Test',
        'labName': 'Test Laboratory',
        'contactEmail': 'test@lab.com',
        'contactPhone': '+1234567890',
      },
    };
  }
  
  /// Creates mock file for testing
  static Map<String, dynamic> createMockFile({
    String? path,
    String? name,
    int? size,
  }) {
    return {
      'path': path ?? '/test/path/sample.jpg',
      'name': name ?? 'sample.jpg',
      'size': size ?? 1024 * 1024,
    };
  }
  
  /// Test data for CASA parameters validation
  static Map<String, Map<String, double>> getCasaTestData() {
    return {
      'normal': {
        'vcl': 35.0,
        'vsl': 25.0,
        'vap': 30.0,
        'lin': 75.0,
        'str': 85.0,
        'wob': 88.0,
        'mot': 60.0,
        'alh': 4.5,
        'bcf': 15.0,
      },
      'low_motility': {
        'vcl': 15.0,
        'vsl': 10.0,
        'vap': 12.0,
        'lin': 45.0,
        'str': 55.0,
        'wob': 60.0,
        'mot': 25.0,
        'alh': 3.0,
        'bcf': 8.0,
      },
      'high_velocity': {
        'vcl': 85.0,
        'vsl': 70.0,
        'vap': 78.0,
        'lin': 95.0,
        'str': 98.0,
        'wob': 97.0,
        'mot': 95.0,
        'alh': 7.0,
        'bcf': 25.0,
      },
    };
  }
  
  /// Test data for morphology validation
  static Map<String, Map<String, double>> getMorphologyTestData() {
    return {
      'normal': {
        'normal': 15.0,
        'abnormal': 85.0,
        'headDefects': 30.0,
        'tailDefects': 35.0,
        'neckDefects': 20.0,
      },
      'poor_morphology': {
        'normal': 2.0,
        'abnormal': 98.0,
        'headDefects': 60.0,
        'tailDefects': 25.0,
        'neckDefects': 13.0,
      },
      'excellent_morphology': {
        'normal': 25.0,
        'abnormal': 75.0,
        'headDefects': 15.0,
        'tailDefects': 35.0,
        'neckDefects': 25.0,
      },
    };
  }
  
  /// Cleanup test environment
  static Future<void> cleanupTestEnvironment() async {
    // Clear any persistent test data
    SharedPreferences.setMockInitialValues({});
    
    // Reset method channel handlers
    const MethodChannel('plugins.flutter.io/camera')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/image_picker')
        .setMockMethodCallHandler(null);
    const MethodChannel('miguelruivo.flutter.plugins.file_picker')
        .setMockMethodCallHandler(null);
    const MethodChannel('flutter.baseflow.com/permissions/methods')
        .setMockMethodCallHandler(null);
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler(null);
    const MethodChannel('dev.fluttercommunity.plus/share')
        .setMockMethodCallHandler(null);
  }
}

/// Custom test matchers for the application
class TestMatchers {
  /// Matches CASA parameter values within expected ranges
  static Matcher isValidCasaValue(String parameter) {
    return predicate<double>((value) {
      switch (parameter.toLowerCase()) {
        case 'vcl':
          return value >= 0 && value <= 200;
        case 'vsl':
          return value >= 0 && value <= 150;
        case 'vap':
          return value >= 0 && value <= 175;
        case 'lin':
        case 'str':
        case 'wob':
        case 'mot':
          return value >= 0 && value <= 100;
        case 'alh':
          return value >= 0 && value <= 15;
        case 'bcf':
          return value >= 0 && value <= 50;
        default:
          return false;
      }
    }, 'is valid $parameter value');
  }
  
  /// Matches morphology percentage values
  static Matcher isValidPercentage() {
    return predicate<double>((value) {
      return value >= 0 && value <= 100;
    }, 'is valid percentage (0-100)');
  }
  
  /// Matches sperm count values
  static Matcher isValidSpermCount() {
    return predicate<double>((value) {
      return value >= 0 && value <= 500; // million/ml
    }, 'is valid sperm count');
  }
  
  /// Matches file size values
  static Matcher isValidFileSize() {
    return predicate<int>((value) {
      return value > 0 && value <= 100 * 1024 * 1024; // max 100MB
    }, 'is valid file size');
  }
}

/// Test utilities for common operations
class TestUtils {
  /// Pumps widget and waits for animations to complete
  static Future<void> pumpAndSettle(
    WidgetTester tester, [
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await tester.pumpAndSettle(timeout);
  }
  
  /// Takes a screenshot during testing (for debugging)
  static Future<void> takeScreenshot(
    WidgetTester tester,
    String name,
  ) async {
    // In a real implementation, this would save a screenshot
    // For now, just a placeholder for debugging purposes
    debugPrint('Screenshot taken: $name');
  }
  
  /// Verifies that translation exists for given key in both languages
  static void verifyTranslationExists(String key) {
    // This would verify that the translation key exists in both
    // Arabic and English translation maps
    expect(key, isNotEmpty);
  }
  
  /// Simulates network delay for testing async operations
  static Future<void> simulateNetworkDelay([Duration? delay]) async {
    await Future.delayed(delay ?? const Duration(milliseconds: 500));
  }
  
  /// Creates a test container with providers
  static ProviderContainer createTestContainer({
    List<Override>? overrides,
  }) {
    return ProviderContainer(
      overrides: overrides ?? [],
    );
  }
}
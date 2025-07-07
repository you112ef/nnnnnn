import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sperm_analyzer_ai/main.dart';
import 'package:sperm_analyzer_ai/screens/main_screen.dart';
import 'package:sperm_analyzer_ai/screens/analysis_screen.dart';
import 'package:sperm_analyzer_ai/screens/results_screen.dart';
import 'package:sperm_analyzer_ai/screens/charts_screen.dart';
import 'package:sperm_analyzer_ai/screens/settings_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete app workflow test', (tester) async {
      // Launch the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Should start with splash screen
      expect(find.text('محلل الحيوانات المنوية'), findsOneWidget);
      
      // Wait for splash to complete and navigate to main screen
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Should now be on main screen
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('التحليل'), findsOneWidget);

      // Test navigation through all tabs
      await _testNavigationFlow(tester);
      
      // Test analysis workflow
      await _testAnalysisWorkflow(tester);
      
      // Test settings functionality
      await _testSettingsWorkflow(tester);
      
      // Test language switching
      await _testLanguageSwitching(tester);
    });

    testWidgets('app launch and initialization', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Verify splash screen appears
      expect(find.byType(SplashScreen), findsOneWidget);
      
      // Wait for app initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Should navigate to main screen
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('camera permission and access flow', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on camera FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should show camera options
      expect(find.text('خيارات التصوير'), findsOneWidget);
      expect(find.text('صورة'), findsOneWidget);
      expect(find.text('فيديو'), findsOneWidget);

      // Tap on photo option
      await tester.tap(find.text('صورة'));
      await tester.pumpAndSettle();

      // Should navigate to camera screen or show permission dialog
      // (Actual camera functionality would require device testing)
    });

    testWidgets('analysis workflow simulation', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to analysis screen
      expect(find.byType(AnalysisScreen), findsOneWidget);

      // Look for file picker options
      expect(find.text('اختر طريقة التحليل'), findsOneWidget);
      expect(find.text('التقاط صورة'), findsOneWidget);
      expect(find.text('اختر صورة'), findsOneWidget);
      expect(find.text('تسجيل فيديو'), findsOneWidget);
      expect(find.text('اختر ملف'), findsOneWidget);

      // Test file picker option
      await tester.tap(find.text('اختر صورة'));
      await tester.pumpAndSettle();
      
      // Should trigger file picker (would open system dialog in real device)
    });

    testWidgets('results and charts display', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to results tab
      await tester.tap(find.text('النتائج'));
      await tester.pumpAndSettle();

      expect(find.byType(ResultsScreen), findsOneWidget);

      // Should show no results initially
      expect(find.text('لا توجد نتائج متاحة'), findsOneWidget);

      // Navigate to charts tab
      await tester.tap(find.text('الرسوم البيانية'));
      await tester.pumpAndSettle();

      expect(find.byType(ChartsScreen), findsOneWidget);

      // Should show no data state
      expect(find.text('لا توجد بيانات للرسوم البيانية'), findsOneWidget);
    });

    testWidgets('settings and preferences', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to settings
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      // Should have language option
      expect(find.text('اللغة'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);

      // Should have other settings options
      expect(find.text('الوضع الداكن'), findsOneWidget);
      expect(find.text('الإشعارات'), findsOneWidget);
    });

    group('Performance Tests', () {
      testWidgets('app startup performance', (tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // App should start within reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      });

      testWidgets('navigation performance', (tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final stopwatch = Stopwatch();

        // Test navigation performance between tabs
        for (int i = 0; i < 5; i++) {
          stopwatch.start();
          await tester.tap(find.text('النتائج'));
          await tester.pumpAndSettle();
          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
          stopwatch.reset();

          stopwatch.start();
          await tester.tap(find.text('الرسوم البيانية'));
          await tester.pumpAndSettle();
          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
          stopwatch.reset();

          stopwatch.start();
          await tester.tap(find.text('التحليل'));
          await tester.pumpAndSettle();
          stopwatch.stop();

          expect(stopwatch.elapsedMilliseconds, lessThan(1000));
          stopwatch.reset();
        }
      });
    });

    group('Error Handling Tests', () {
      testWidgets('network error handling', (tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // These tests would require mocking network failures
        // For now, just ensure app doesn't crash with network issues
        expect(find.byType(MainScreen), findsOneWidget);
      });

      testWidgets('invalid file handling', (tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test would involve trying to select invalid file types
        // and ensuring proper error messages are shown
        expect(find.byType(AnalysisScreen), findsOneWidget);
      });
    });
  });
}

// Helper functions for testing workflows
Future<void> _testNavigationFlow(WidgetTester tester) async {
  // Test navigation to each tab
  final tabs = ['النتائج', 'الرسوم البيانية', 'الإعدادات', 'التحليل'];
  
  for (final tab in tabs) {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
    
    // Verify the tab is selected
    expect(find.text(tab), findsOneWidget);
  }
}

Future<void> _testAnalysisWorkflow(WidgetTester tester) async {
  // Ensure we're on analysis tab
  await tester.tap(find.text('التحليل'));
  await tester.pumpAndSettle();

  // Check all analysis options are available
  expect(find.text('التقاط صورة'), findsOneWidget);
  expect(find.text('اختر صورة'), findsOneWidget);
  expect(find.text('تسجيل فيديو'), findsOneWidget);
  expect(find.text('اختر ملف'), findsOneWidget);
  
  // Test camera access
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  expect(find.text('خيارات التصوير'), findsOneWidget);
  
  // Dismiss camera options
  await tester.tapAt(const Offset(200, 100));
  await tester.pumpAndSettle();
}

Future<void> _testSettingsWorkflow(WidgetTester tester) async {
  // Navigate to settings
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();

  // Test language setting visibility
  expect(find.text('اللغة'), findsOneWidget);
  expect(find.text('العربية'), findsOneWidget);
  
  // Test other settings
  expect(find.text('الوضع الداكن'), findsOneWidget);
  expect(find.text('الإشعارات'), findsOneWidget);
}

Future<void> _testLanguageSwitching(WidgetTester tester) async {
  // Navigate to settings
  await tester.tap(find.text('الإعدادات'));
  await tester.pumpAndSettle();

  // Look for language switch option
  final languageSwitch = find.byType(Switch);
  if (languageSwitch.evaluate().isNotEmpty) {
    await tester.tap(languageSwitch.first);
    await tester.pumpAndSettle();
    
    // Should switch to English
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    
    // Switch back to Arabic
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    
    expect(find.text('الإعدادات'), findsOneWidget);
    expect(find.text('اللغة'), findsOneWidget);
  }
}
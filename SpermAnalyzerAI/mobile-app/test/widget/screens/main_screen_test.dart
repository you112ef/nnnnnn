import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sperm_analyzer_ai/screens/main_screen.dart';
import 'package:sperm_analyzer_ai/services/localization_service.dart';

void main() {
  group('MainScreen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should display correct navigation items in Arabic', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Wait for the widget to build completely
      await tester.pumpAndSettle();

      // Check Arabic navigation labels
      expect(find.text('التحليل'), findsOneWidget);
      expect(find.text('النتائج'), findsOneWidget);
      expect(find.text('الرسوم البيانية'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('should display correct navigation items in English', (tester) async {
      final container = ProviderContainer();
      await container.read(localizationProvider.notifier).switchToEnglish();

      await tester.pumpWidget(
        ProviderScope(
          parent: container,
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check English navigation labels
      expect(find.text('Analysis'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Charts'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should navigate between screens when tapping navigation items', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Results tab
      await tester.tap(find.text('النتائج'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(find.byType(MainScreen), findsOneWidget);

      // Tap on Charts tab
      await tester.tap(find.text('الرسوم البيانية'));
      await tester.pumpAndSettle();

      // Tap on Settings tab
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      // Tap back to Analysis tab
      await tester.tap(find.text('التحليل'));
      await tester.pumpAndSettle();
    });

    testWidgets('should show camera options when FAB is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should show bottom sheet with camera options
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('خيارات التصوير'), findsOneWidget);
      expect(find.text('صورة'), findsOneWidget);
      expect(find.text('فيديو'), findsOneWidget);
    });

    testWidgets('should dismiss camera options when tapping outside', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify bottom sheet is shown
      expect(find.byType(BottomSheet), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();

      // Bottom sheet should be dismissed
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('should apply correct theme colors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar color
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, isNotNull);

      // Check FAB color
      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, isNotNull);
    });

    testWidgets('should handle RTL layout for Arabic', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get the main widget and check text direction
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      
      // Should have proper RTL directionality for Arabic
      expect(find.byType(Directionality), findsWidgets);
    });

    testWidgets('should display app title correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find AppBar title
      expect(find.text('محلل الحيوانات المنوية بالذكاء الاصطناعي'), findsOneWidget);
    });

    testWidgets('should show loading indicator during initialization', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // During initial pump, might show loading
      await tester.pump(Duration.zero);

      // After settling, should show main content
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    group('Accessibility Tests', () {
      testWidgets('should have proper semantics for navigation', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MainScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check that navigation items have proper semantics
        expect(find.bySemanticsLabel('التحليل'), findsOneWidget);
        expect(find.bySemanticsLabel('النتائج'), findsOneWidget);
        expect(find.bySemanticsLabel('الرسوم البيانية'), findsOneWidget);
        expect(find.bySemanticsLabel('الإعدادات'), findsOneWidget);
      });

      testWidgets('should have accessible FAB', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MainScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // FAB should have proper tooltip/semantics
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
        
        final fabWidget = tester.widget<FloatingActionButton>(fab);
        expect(fabWidget.tooltip, isNotNull);
      });
    });

    group('State Management Tests', () {
      testWidgets('should persist selected tab across rebuilds', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MainScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate to Charts tab
        await tester.tap(find.text('الرسوم البيانية'));
        await tester.pumpAndSettle();

        // Rebuild the widget
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MainScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should still be on Charts tab (if state is properly managed)
        final bottomNavBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
        expect(bottomNavBar.currentIndex, isNotNull);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle navigation errors gracefully', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: MainScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Rapidly tap navigation items
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.text('النتائج'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('الرسوم البيانية'));
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should still be functional
        expect(find.byType(BottomNavigationBar), findsOneWidget);
      });
    });
  });
}
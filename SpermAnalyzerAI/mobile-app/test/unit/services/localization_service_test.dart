import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sperm_analyzer_ai/services/localization_service.dart';

void main() {
  group('LocalizationService Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default locale (Arabic)', () {
      final locale = container.read(localizationProvider);
      expect(locale.languageCode, 'ar');
      expect(locale.countryCode, 'SA');
    });

    test('should switch to English locale', () async {
      final notifier = container.read(localizationProvider.notifier);
      
      await notifier.switchToEnglish();
      final locale = container.read(localizationProvider);
      
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, 'US');
    });

    test('should switch to Arabic locale', () async {
      final notifier = container.read(localizationProvider.notifier);
      
      // First switch to English
      await notifier.switchToEnglish();
      expect(container.read(localizationProvider).languageCode, 'en');
      
      // Then switch back to Arabic
      await notifier.switchToArabic();
      final locale = container.read(localizationProvider);
      
      expect(locale.languageCode, 'ar');
      expect(locale.countryCode, 'SA');
    });

    test('should persist locale preference', () async {
      final notifier = container.read(localizationProvider.notifier);
      
      // Switch to English and verify persistence
      await notifier.switchToEnglish();
      
      // Create new container to simulate app restart
      final newContainer = ProviderContainer();
      await newContainer.read(localizationProvider.notifier).loadSavedLocale();
      
      expect(newContainer.read(localizationProvider).languageCode, 'en');
      
      newContainer.dispose();
    });

    group('Translation Tests', () {
      test('should provide Arabic translations', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('app_name', 'ar'), 'محلل الحيوانات المنوية بالذكاء الاصطناعي');
        expect(service.getTranslation('analysis', 'ar'), 'التحليل');
        expect(service.getTranslation('results', 'ar'), 'النتائج');
        expect(service.getTranslation('charts', 'ar'), 'الرسوم البيانية');
        expect(service.getTranslation('settings', 'ar'), 'الإعدادات');
      });

      test('should provide English translations', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('app_name', 'en'), 'Sperm Analyzer AI');
        expect(service.getTranslation('analysis', 'en'), 'Analysis');
        expect(service.getTranslation('results', 'en'), 'Results');
        expect(service.getTranslation('charts', 'en'), 'Charts');
        expect(service.getTranslation('settings', 'en'), 'Settings');
      });

      test('should provide medical terms in Arabic', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('sperm_count', 'ar'), 'عدد الحيوانات المنوية');
        expect(service.getTranslation('motility', 'ar'), 'الحركة');
        expect(service.getTranslation('concentration', 'ar'), 'التركيز');
        expect(service.getTranslation('morphology', 'ar'), 'الشكل والبنية');
        expect(service.getTranslation('casa_parameters', 'ar'), 'معاملات CASA');
      });

      test('should provide medical terms in English', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('sperm_count', 'en'), 'Sperm Count');
        expect(service.getTranslation('motility', 'en'), 'Motility');
        expect(service.getTranslation('concentration', 'en'), 'Concentration');
        expect(service.getTranslation('morphology', 'en'), 'Morphology');
        expect(service.getTranslation('casa_parameters', 'en'), 'CASA Parameters');
      });

      test('should provide CASA parameter translations', () {
        final service = LocalizationService();
        
        // Arabic CASA parameters
        expect(service.getTranslation('vcl', 'ar'), 'السرعة المنحنية');
        expect(service.getTranslation('vsl', 'ar'), 'السرعة المستقيمة');
        expect(service.getTranslation('vap', 'ar'), 'متوسط السرعة');
        expect(service.getTranslation('lin', 'ar'), 'الخطية');
        expect(service.getTranslation('str', 'ar'), 'الاستقامة');
        
        // English CASA parameters
        expect(service.getTranslation('vcl', 'en'), 'Curvilinear Velocity');
        expect(service.getTranslation('vsl', 'en'), 'Straight Line Velocity');
        expect(service.getTranslation('vap', 'en'), 'Average Path Velocity');
        expect(service.getTranslation('lin', 'en'), 'Linearity');
        expect(service.getTranslation('str', 'en'), 'Straightness');
      });

      test('should provide unit translations', () {
        final service = LocalizationService();
        
        // Arabic units
        expect(service.getTranslation('unit_million_per_ml', 'ar'), 'مليون/مل');
        expect(service.getTranslation('unit_percent', 'ar'), '%');
        expect(service.getTranslation('unit_micrometers_per_second', 'ar'), 'ميكرومتر/ثانية');
        expect(service.getTranslation('unit_hertz', 'ar'), 'هرتز');
        
        // English units
        expect(service.getTranslation('unit_million_per_ml', 'en'), 'million/ml');
        expect(service.getTranslation('unit_percent', 'en'), '%');
        expect(service.getTranslation('unit_micrometers_per_second', 'en'), 'μm/s');
        expect(service.getTranslation('unit_hertz', 'en'), 'Hz');
      });

      test('should return fallback for missing translations', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('non_existent_key', 'ar'), 'non_existent_key');
        expect(service.getTranslation('non_existent_key', 'en'), 'non_existent_key');
      });

      test('should handle empty or null keys gracefully', () {
        final service = LocalizationService();
        
        expect(service.getTranslation('', 'ar'), '');
        expect(service.getTranslation('', 'en'), '');
      });
    });

    group('RTL Support Tests', () {
      test('should detect Arabic as RTL language', () {
        expect(LocalizationService.isRTLLanguage('ar'), true);
      });

      test('should detect English as LTR language', () {
        expect(LocalizationService.isRTLLanguage('en'), false);
      });

      test('should provide correct text direction', () {
        expect(LocalizationService.getTextDirection('ar').name, 'rtl');
        expect(LocalizationService.getTextDirection('en').name, 'ltr');
      });
    });

    group('LocalizedText Widget Tests', () {
      testWidgets('should display Arabic text correctly', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LocalizedText('app_name'),
            ),
          ),
        );

        expect(find.text('محلل الحيوانات المنوية بالذكاء الاصطناعي'), findsOneWidget);
      });

      testWidgets('should display English text when locale is English', (tester) async {
        final container = ProviderContainer();
        await container.read(localizationProvider.notifier).switchToEnglish();

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: LocalizedText('app_name'),
            ),
          ),
        );

        expect(find.text('Sperm Analyzer AI'), findsOneWidget);
        
        container.dispose();
      });

      testWidgets('should apply custom style to LocalizedText', (tester) async {
        const testStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: LocalizedText(
                'app_name',
                style: testStyle,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style?.fontSize, 24);
        expect(textWidget.style?.fontWeight, FontWeight.bold);
      });
    });

    group('Language Switching Integration', () {
      testWidgets('should update UI when language changes', (tester) async {
        final container = ProviderContainer();

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  final locale = ref.watch(localizationProvider);
                  return Text('Current language: ${locale.languageCode}');
                },
              ),
            ),
          ),
        );

        // Initially should be Arabic
        expect(find.text('Current language: ar'), findsOneWidget);

        // Switch to English
        await container.read(localizationProvider.notifier).switchToEnglish();
        await tester.pump();

        expect(find.text('Current language: en'), findsOneWidget);

        container.dispose();
      });
    });
  });
}
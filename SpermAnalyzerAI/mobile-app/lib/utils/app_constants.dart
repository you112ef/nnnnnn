import 'package:flutter/material.dart';

class AppConstants {
  // الألوان الأساسية - التصميم الداكن الأزرق
  static const Color primaryColor = Color(0xFF0D1B2A);
  static const Color surfaceColor = Color(0xFF1B263B);
  static const Color backgroundColor = Color(0xFF0D1B2A);
  static const Color accentColor = Color(0xFF415A77);
  static const Color textColor = Color(0xFFE0E1DD);
  static const Color secondaryTextColor = Color(0xFF778DA9);
  
  // ألوان إضافية
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFF44336);
  static const Color infoColor = Color(0xFF2196F3);
  
  // أحجام
  static const double padding = 16.0;
  static const double margin = 16.0;
  static const double borderRadius = 12.0;
  static const double elevation = 8.0;
  
  // أحجام النصوص
  static const double titleSize = 24.0;
  static const double subtitleSize = 18.0;
  static const double bodySize = 16.0;
  static const double captionSize = 14.0;
  
  // API URLs
  static const String baseUrl = 'http://localhost:8000';
  static const String analyzeEndpoint = '/analyze';
  static const String resultsEndpoint = '/results';
  static const String statusEndpoint = '/status';
  static const String exportEndpoint = '/export';
  
  // أنواع الملفات المدعومة
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'mkv'];
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'bmp'];
  
  // مؤشرات CASA
  static const List<String> casaParameters = [
    'VCL', // Curvilinear Velocity
    'VSL', // Straight-line Velocity  
    'VAP', // Average Path Velocity
    'LIN', // Linearity
    'STR', // Straightness
    'WOB', // Wobble
    'ALH', // Amplitude of Lateral Head displacement
    'BCF', // Beat Cross Frequency
    'MOT', // Motility percentage
  ];
  
  // حدود القيم الطبيعية
  static const Map<String, Map<String, double>> normalRanges = {
    'VCL': {'min': 25.0, 'max': 150.0},
    'VSL': {'min': 15.0, 'max': 75.0},
    'VAP': {'min': 20.0, 'max': 100.0},
    'LIN': {'min': 40.0, 'max': 85.0},
    'STR': {'min': 60.0, 'max': 90.0},
    'WOB': {'min': 50.0, 'max': 80.0},
    'ALH': {'min': 2.0, 'max': 7.0},
    'BCF': {'min': 5.0, 'max': 45.0},
    'MOT': {'min': 40.0, 'max': 100.0},
  };
  
  // إعدادات الكاميرا
  static const int cameraQuality = 1; // High quality
  static const int maxVideoDuration = 30; // seconds
  static const double cameraAspectRatio = 16 / 9;
  
  // إعدادات التصدير
  static const List<String> exportFormats = ['JSON', 'CSV', 'PDF'];
  
  // رسائل التطبيق
  static const String appNameAr = 'محلل الحيوانات المنوية AI';
  static const String appNameEn = 'Sperm Analyzer AI';
  static const String appName = 'Sperm Analyzer AI';
  static const String appVersion = '1.0.0';
  static const String developerNameAr = 'يوسف الشتيوي';
  static const String developerNameEn = 'Youssef Al-Shatiwy';
  static const String developerName = 'يوسف الشتيوي';
  
  // أسماء الخطوط
  static const String arabicFontFamily = 'Cairo';
  static const String arabicFontFamilyBold = 'Tajawal';
  static const String englishFontFamily = 'Roboto';
  
  // إعدادات اللغة الافتراضية
  static const String defaultLanguage = 'ar';
  static const bool defaultDarkMode = true;
  
  // مفاتيح التخزين المحلي
  static const String languageKey = 'selected_language';
  static const String themeKey = 'selected_theme';
  static const String firstLaunchKey = 'first_launch';
  static const String lastAnalysisKey = 'last_analysis';
  
  // إعدادات الشبكة
  static const int connectionTimeout = 30; // seconds
  static const int receiveTimeout = 60; // seconds
  static const int maxRetries = 3;
  
  // حدود الملفات
  static const int maxFileSize = 100 * 1024 * 1024; // 100 MB
  static const int maxImageSize = 10 * 1024 * 1024; // 10 MB
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, surfaceColor],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFF778DA9)],
  );
  
  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}
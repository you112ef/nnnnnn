import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../utils/app_constants.dart';

// Provider للغة الحالية
final localizationProvider = StateNotifierProvider<LocalizationNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalizationNotifier(prefs);
});

class LocalizationNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  
  LocalizationNotifier(this._prefs) : super(const Locale('ar', 'SA')) {
    _loadLocale();
  }
  
  void _loadLocale() {
    final languageCode = _prefs.getString(AppConstants.languageKey) ?? 'ar';
    state = Locale(languageCode, languageCode == 'ar' ? 'SA' : 'US');
  }
  
  Future<void> setLocale(String languageCode) async {
    await _prefs.setString(AppConstants.languageKey, languageCode);
    state = Locale(languageCode, languageCode == 'ar' ? 'SA' : 'US');
  }
  
  bool get isArabic => state.languageCode == 'ar';
  bool get isEnglish => state.languageCode == 'en';
}

// خدمة الترجمة
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  bool get isArabic => locale.languageCode == 'ar';
  
  // النصوص الأساسية
  String get appTitle => isArabic ? 'محلل الحيوانات المنوية AI' : 'Sperm Analyzer AI';
  String get welcome => isArabic ? 'مرحباً بك' : 'Welcome';
  String get analyze => isArabic ? 'تحليل' : 'Analyze';
  String get results => isArabic ? 'النتائج' : 'Results';
  String get charts => isArabic ? 'الرسوم البيانية' : 'Charts';
  String get settings => isArabic ? 'الإعدادات' : 'Settings';
  String get camera => isArabic ? 'الكاميرا' : 'Camera';
  String get gallery => isArabic ? 'المعرض' : 'Gallery';
  String get upload => isArabic ? 'رفع' : 'Upload';
  String get download => isArabic ? 'تحميل' : 'Download';
  String get share => isArabic ? 'مشاركة' : 'Share';
  String get export => isArabic ? 'تصدير' : 'Export';
  String get delete => isArabic ? 'حذف' : 'Delete';
  String get cancel => isArabic ? 'إلغاء' : 'Cancel';
  String get ok => isArabic ? 'موافق' : 'OK';
  String get yes => isArabic ? 'نعم' : 'Yes';
  String get no => isArabic ? 'لا' : 'No';
  String get save => isArabic ? 'حفظ' : 'Save';
  String get loading => isArabic ? 'جاري التحميل...' : 'Loading...';
  String get processing => isArabic ? 'جاري المعالجة...' : 'Processing...';
  String get analyzing => isArabic ? 'جاري التحليل...' : 'Analyzing...';
  String get complete => isArabic ? 'مكتمل' : 'Complete';
  String get error => isArabic ? 'خطأ' : 'Error';
  String get success => isArabic ? 'نجح' : 'Success';
  String get warning => isArabic ? 'تحذير' : 'Warning';
  String get info => isArabic ? 'معلومات' : 'Info';
  
  // شاشة التحليل
  String get analysisTitle => isArabic ? 'تحليل العينة' : 'Sample Analysis';
  String get selectFile => isArabic ? 'اختر ملف' : 'Select File';
  String get takePhoto => isArabic ? 'التقط صورة' : 'Take Photo';
  String get recordVideo => isArabic ? 'سجل فيديو' : 'Record Video';
  String get startAnalysis => isArabic ? 'ابدأ التحليل' : 'Start Analysis';
  String get analysisProgress => isArabic ? 'تقدم التحليل' : 'Analysis Progress';
  String get analysisComplete => isArabic ? 'التحليل مكتمل' : 'Analysis Complete';
  String get viewResults => isArabic ? 'عرض النتائج' : 'View Results';
  
  // شاشة النتائج
  String get resultsTitle => isArabic ? 'نتائج التحليل' : 'Analysis Results';
  String get spermCount => isArabic ? 'عدد الحيوانات المنوية' : 'Sperm Count';
  String get motility => isArabic ? 'الحركة' : 'Motility';
  String get morphology => isArabic ? 'الشكل' : 'Morphology';
  String get concentration => isArabic ? 'التركيز' : 'Concentration';
  String get velocity => isArabic ? 'السرعة' : 'Velocity';
  String get linearity => isArabic ? 'الخطية' : 'Linearity';
  String get straightness => isArabic ? 'الاستقامة' : 'Straightness';
  String get wobble => isArabic ? 'التذبذب' : 'Wobble';
  String get amplitude => isArabic ? 'السعة' : 'Amplitude';
  String get frequency => isArabic ? 'التردد' : 'Frequency';
  
  // مؤشرات CASA
  String get casaParameters => isArabic ? 'مؤشرات CASA' : 'CASA Parameters';
  String get vcl => isArabic ? 'السرعة المنحنية (VCL)' : 'Curvilinear Velocity (VCL)';
  String get vsl => isArabic ? 'السرعة المستقيمة (VSL)' : 'Straight-line Velocity (VSL)';
  String get vap => isArabic ? 'متوسط سرعة المسار (VAP)' : 'Average Path Velocity (VAP)';
  String get lin => isArabic ? 'الخطية (LIN)' : 'Linearity (LIN)';
  String get str => isArabic ? 'الاستقامة (STR)' : 'Straightness (STR)';
  String get wob => isArabic ? 'التذبذب (WOB)' : 'Wobble (WOB)';
  String get alh => isArabic ? 'سعة النزوح الجانبي (ALH)' : 'Amplitude of Lateral Head (ALH)';
  String get bcf => isArabic ? 'تردد تقاطع النبضة (BCF)' : 'Beat Cross Frequency (BCF)';
  String get mot => isArabic ? 'نسبة الحركة (MOT)' : 'Motility Percentage (MOT)';
  
  // شاشة الرسوم البيانية
  String get chartsTitle => isArabic ? 'الرسوم البيانية' : 'Charts';
  String get motilityChart => isArabic ? 'رسم الحركة' : 'Motility Chart';
  String get velocityChart => isArabic ? 'رسم السرعة' : 'Velocity Chart';
  String get concentrationChart => isArabic ? 'رسم التركيز' : 'Concentration Chart';
  String get timeSeriesChart => isArabic ? 'رسم زمني' : 'Time Series Chart';
  String get distributionChart => isArabic ? 'رسم التوزيع' : 'Distribution Chart';
  String get comparisonChart => isArabic ? 'رسم المقارنة' : 'Comparison Chart';
  
  // شاشة الإعدادات
  String get settingsTitle => isArabic ? 'الإعدادات' : 'Settings';
  String get language => isArabic ? 'اللغة' : 'Language';
  String get arabic => isArabic ? 'العربية' : 'Arabic';
  String get english => isArabic ? 'الإنجليزية' : 'English';
  String get theme => isArabic ? 'المظهر' : 'Theme';
  String get darkTheme => isArabic ? 'المظهر الداكن' : 'Dark Theme';
  String get lightTheme => isArabic ? 'المظهر الفاتح' : 'Light Theme';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get about => isArabic ? 'حول التطبيق' : 'About';
  String get version => isArabic ? 'الإصدار' : 'Version';
  String get developer => isArabic ? 'المطور' : 'Developer';
  String get contact => isArabic ? 'تواصل معنا' : 'Contact Us';
  String get privacy => isArabic ? 'سياسة الخصوصية' : 'Privacy Policy';
  String get terms => isArabic ? 'شروط الاستخدام' : 'Terms of Use';
  
  // رسائل الخطأ
  String get networkError => isArabic ? 'خطأ في الشبكة' : 'Network Error';
  String get serverError => isArabic ? 'خطأ في الخادم' : 'Server Error';
  String get fileNotFound => isArabic ? 'الملف غير موجود' : 'File Not Found';
  String get invalidFile => isArabic ? 'ملف غير صالح' : 'Invalid File';
  String get fileTooLarge => isArabic ? 'الملف كبير جداً' : 'File Too Large';
  String get permissionDenied => isArabic ? 'تم رفض الإذن' : 'Permission Denied';
  String get cameraNotAvailable => isArabic ? 'الكاميرا غير متاحة' : 'Camera Not Available';
  String get analysisError => isArabic ? 'خطأ في التحليل' : 'Analysis Error';
  String get noDataAvailable => isArabic ? 'لا توجد بيانات' : 'No Data Available';
  String get tryAgain => isArabic ? 'حاول مرة أخرى' : 'Try Again';
  
  // رسائل النجاح
  String get uploadSuccess => isArabic ? 'تم الرفع بنجاح' : 'Upload Successful';
  String get analysisSuccess => isArabic ? 'تم التحليل بنجاح' : 'Analysis Successful';
  String get exportSuccess => isArabic ? 'تم التصدير بنجاح' : 'Export Successful';
  String get saveSuccess => isArabic ? 'تم الحفظ بنجاح' : 'Save Successful';
  String get shareSuccess => isArabic ? 'تمت المشاركة بنجاح' : 'Share Successful';
  
  // وحدات القياس
  String get micrometersPerSecond => isArabic ? 'ميكرومتر/ثانية' : 'μm/s';
  String get percentage => isArabic ? '%' : '%';
  String get micrometers => isArabic ? 'ميكرومتر' : 'μm';
  String get hertz => isArabic ? 'هرتز' : 'Hz';
  String get millionPerMl => isArabic ? 'مليون/مل' : 'million/ml';
  String get count => isArabic ? 'عدد' : 'count';
  
  // تصنيفات الجودة
  String get excellent => isArabic ? 'ممتاز' : 'Excellent';
  String get good => isArabic ? 'جيد' : 'Good';
  String get fair => isArabic ? 'مقبول' : 'Fair';
  String get poor => isArabic ? 'ضعيف' : 'Poor';
  
  // تفاصيل الشكل
  String get normalMorphology => isArabic ? 'الشكل الطبيعي' : 'Normal Morphology';
  String get abnormalMorphology => isArabic ? 'الشكل غير الطبيعي' : 'Abnormal Morphology';
  String get headDefects => isArabic ? 'تشوهات الرأس' : 'Head Defects';
  String get neckDefects => isArabic ? 'تشوهات العنق' : 'Neck Defects';
  String get tailDefects => isArabic ? 'تشوهات الذيل' : 'Tail Defects';
  
  // تبويبات النتائج
  String get overview => isArabic ? 'نظرة عامة' : 'Overview';
  String get detailedResults => isArabic ? 'النتائج التفصيلية' : 'Detailed Results';
  String get recommendations => isArabic ? 'التوصيات' : 'Recommendations';
  
  // أنواع الرسوم البيانية
  String get lineChart => isArabic ? 'رسم خطي' : 'Line Chart';
  String get barChart => isArabic ? 'رسم عمودي' : 'Bar Chart';
  String get pieChart => isArabic ? 'رسم دائري' : 'Pie Chart';
  String get radarChart => isArabic ? 'رسم رادار' : 'Radar Chart';
  
  // مراحل التحليل
  String get uploadingFile => isArabic ? 'رفع الملف...' : 'Uploading file...';
  String get processingImage => isArabic ? 'معالجة الصورة...' : 'Processing image...';
  String get detectingSperm => isArabic ? 'اكتشاف الحيوانات المنوية...' : 'Detecting sperm...';
  String get calculatingParameters => isArabic ? 'حساب المعايير...' : 'Calculating parameters...';
  String get generatingReport => isArabic ? 'إنتاج التقرير...' : 'Generating report...';
  
  // التصدير
  String get exportToJson => isArabic ? 'تصدير كـ JSON' : 'Export as JSON';
  String get exportToCsv => isArabic ? 'تصدير كـ CSV' : 'Export as CSV';
  String get exportToPdf => isArabic ? 'تصدير كـ PDF' : 'Export as PDF';
  String get exportChart => isArabic ? 'تصدير الرسم البياني' : 'Export Chart';
  
  // المساعدة والدعم
  String get help => isArabic ? 'المساعدة' : 'Help';
  String get faq => isArabic ? 'الأسئلة الشائعة' : 'FAQ';
  String get documentation => isArabic ? 'الوثائق' : 'Documentation';
  String get support => isArabic ? 'الدعم الفني' : 'Support';
  
  // إعدادات إضافية
  String get advancedSettings => isArabic ? 'إعدادات متقدمة' : 'Advanced Settings';
  String get cameraSettings => isArabic ? 'إعدادات الكاميرا' : 'Camera Settings';
  String get analysisSettings => isArabic ? 'إعدادات التحليل' : 'Analysis Settings';
  String get dataPrivacy => isArabic ? 'خصوصية البيانات' : 'Data Privacy';
  String get autoSave => isArabic ? 'الحفظ التلقائي' : 'Auto Save';
  String get cloudSync => isArabic ? 'المزامنة السحابية' : 'Cloud Sync';
  
  // أيام الأسبوع
  String get monday => isArabic ? 'الاثنين' : 'Monday';
  String get tuesday => isArabic ? 'الثلاثاء' : 'Tuesday';
  String get wednesday => isArabic ? 'الأربعاء' : 'Wednesday';
  String get thursday => isArabic ? 'الخميس' : 'Thursday';
  String get friday => isArabic ? 'الجمعة' : 'Friday';
  String get saturday => isArabic ? 'السبت' : 'Saturday';
  String get sunday => isArabic ? 'الأحد' : 'Sunday';
  
  // الشهور
  String get january => isArabic ? 'يناير' : 'January';
  String get february => isArabic ? 'فبراير' : 'February';
  String get march => isArabic ? 'مارس' : 'March';
  String get april => isArabic ? 'أبريل' : 'April';
  String get may => isArabic ? 'مايو' : 'May';
  String get june => isArabic ? 'يونيو' : 'June';
  String get july => isArabic ? 'يوليو' : 'July';
  String get august => isArabic ? 'أغسطس' : 'August';
  String get september => isArabic ? 'سبتمبر' : 'September';
  String get october => isArabic ? 'أكتوبر' : 'October';
  String get november => isArabic ? 'نوفمبر' : 'November';
  String get december => isArabic ? 'ديسمبر' : 'December';
  
  // معلومات إحصائية
  String get total => isArabic ? 'المجموع' : 'Total';
  String get average => isArabic ? 'المتوسط' : 'Average';
  String get minimum => isArabic ? 'الحد الأدنى' : 'Minimum';
  String get maximum => isArabic ? 'الحد الأقصى' : 'Maximum';
  String get standardDeviation => isArabic ? 'الانحراف المعياري' : 'Standard Deviation';
  String get median => isArabic ? 'الوسيط' : 'Median';
  String get range => isArabic ? 'المدى' : 'Range';
  
  // حالات التحليل
  String get pending => isArabic ? 'في الانتظار' : 'Pending';
  String get inProgress => isArabic ? 'قيد التنفيذ' : 'In Progress';
  String get completed => isArabic ? 'مكتمل' : 'Completed';
  String get failed => isArabic ? 'فشل' : 'Failed';
  String get cancelled => isArabic ? 'ملغي' : 'Cancelled';
  
  // التقييم الطبي
  String get normalRange => isArabic ? 'المعدل الطبيعي' : 'Normal Range';
  String get belowNormal => isArabic ? 'أقل من الطبيعي' : 'Below Normal';
  String get aboveNormal => isArabic ? 'أعلى من الطبيعي' : 'Above Normal';
  String get withinNormal => isArabic ? 'ضمن المعدل الطبيعي' : 'Within Normal';
  String get consultDoctor => isArabic ? 'استشر الطبيب' : 'Consult Doctor';
  String get repeatTest => isArabic ? 'أعد الفحص' : 'Repeat Test';
  String get lifestyleChanges => isArabic ? 'تغييرات نمط الحياة' : 'Lifestyle Changes';
  
  // رسائل تأكيد
  String get confirmDelete => isArabic ? 'هل تريد حذف هذا العنصر؟' : 'Do you want to delete this item?';
  String get confirmExport => isArabic ? 'هل تريد تصدير النتائج؟' : 'Do you want to export the results?';
  String get confirmShare => isArabic ? 'هل تريد مشاركة النتائج؟' : 'Do you want to share the results?';
  String get confirmClear => isArabic ? 'هل تريد مسح جميع البيانات؟' : 'Do you want to clear all data?';
  
  // ملاحظات تعليمية
  String get tipBetterImages => isArabic 
    ? 'للحصول على صور أفضل، استخدم إضاءة جيدة وثبت الجهاز'
    : 'For better images, use good lighting and stabilize the device';
  String get tipVideoLength => isArabic
    ? 'الفيديوهات الطويلة تعطي نتائج أكثر دقة'
    : 'Longer videos provide more accurate results';
  String get tipRegularTesting => isArabic
    ? 'الفحص المنتظم يساعد في متابعة التحسن'
    : 'Regular testing helps track improvement';
    
  
  // إرشادات
  String get cameraInstructions => isArabic 
    ? 'ضع العينة تحت المجهر واضبط التركيز قبل التصوير'
    : 'Place sample under microscope and adjust focus before capturing';
  String get videoInstructions => isArabic
    ? 'سجل فيديو لمدة 10-30 ثانية للحصول على أفضل النتائج'
    : 'Record video for 10-30 seconds for best results';
  String get fileInstructions => isArabic
    ? 'يدعم التطبيق صور JPG/PNG وفيديوهات MP4/AVI'
    : 'App supports JPG/PNG images and MP4/AVI videos';
    
  // Developer info
  String get developerInfo => isArabic 
    ? 'يوسف الشتيوي - خبير تطوير التطبيقات الطبية'
    : 'Youssef Al-Shatiwy - Medical App Development Expert';
}
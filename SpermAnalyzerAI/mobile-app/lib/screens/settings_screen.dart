import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_constants.dart';
import '../services/localization_service.dart';
import '../widgets/analysis_card.dart';
import '../widgets/custom_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPackageInfo();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _packageInfo = packageInfo;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'الإعدادات' : 'Settings',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor,
              AppConstants.backgroundColor,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // معلومات التطبيق
                    _buildAppInfoSection(isArabic),
                    
                    const SizedBox(height: 16),
                    
                    // إعدادات اللغة
                    _buildLanguageSection(isArabic),
                    
                    const SizedBox(height: 16),
                    
                    // إعدادات التطبيق
                    _buildAppSettingsSection(isArabic),
                    
                    const SizedBox(height: 16),
                    
                    // دعم ومساعدة
                    _buildSupportSection(isArabic),
                    
                    const SizedBox(height: 16),
                    
                    // معلومات المطور
                    _buildDeveloperSection(isArabic),
                    
                    const SizedBox(height: 24),
                    
                    // إصدار التطبيق
                    _buildVersionInfo(isArabic),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(bool isArabic) {
    return AnalysisCard(
      gradient: AppConstants.accentGradient,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.biotech,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppConstants.appName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic 
                ? 'تحليل ذكي ودقيق للحيوانات المنوية'
                : 'Smart and accurate sperm analysis',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSection(bool isArabic) {
    return AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.language,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'اللغة' : 'Language',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLanguageOption(
                  label: 'العربية',
                  isSelected: isArabic,
                  onTap: () => _changeLanguage('ar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLanguageOption(
                  label: 'English',
                  isSelected: !isArabic,
                  onTap: () => _changeLanguage('en'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppConstants.accentColor 
              : AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? AppConstants.accentColor 
                : AppConstants.accentColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection(bool isArabic) {
    return AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'إعدادات التطبيق' : 'App Settings',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.camera_alt,
            title: isArabic ? 'إعدادات الكاميرا' : 'Camera Settings',
            subtitle: isArabic ? 'جودة الكاميرا والتسجيل' : 'Camera quality and recording',
            onTap: () => _showCameraSettings(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.cloud_upload,
            title: isArabic ? 'إعدادات الرفع' : 'Upload Settings',
            subtitle: isArabic ? 'خادم API والتحليل' : 'API server and analysis',
            onTap: () => _showUploadSettings(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.download,
            title: isArabic ? 'إعدادات التصدير' : 'Export Settings',
            subtitle: isArabic ? 'صيغ التصدير والمشاركة' : 'Export formats and sharing',
            onTap: () => _showExportSettings(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: isArabic ? 'الإشعارات' : 'Notifications',
            subtitle: isArabic ? 'تنبيهات التحليل والنتائج' : 'Analysis and results alerts',
            onTap: () => _showNotificationSettings(isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(bool isArabic) {
    return AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'الدعم والمساعدة' : 'Support & Help',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: isArabic ? 'الأسئلة الشائعة' : 'FAQ',
            subtitle: isArabic ? 'الأسئلة والأجوبة الشائعة' : 'Frequently asked questions',
            onTap: () => _showFAQ(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.book,
            title: isArabic ? 'دليل الاستخدام' : 'User Guide',
            subtitle: isArabic ? 'كيفية استخدام التطبيق' : 'How to use the app',
            onTap: () => _showUserGuide(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.bug_report,
            title: isArabic ? 'الإبلاغ عن مشكلة' : 'Report Issue',
            subtitle: isArabic ? 'أبلغ عن خطأ أو مشكلة' : 'Report a bug or issue',
            onTap: () => _reportIssue(isArabic),
          ),
          _buildSettingsTile(
            icon: Icons.star_rate,
            title: isArabic ? 'تقييم التطبيق' : 'Rate App',
            subtitle: isArabic ? 'قيم التطبيق في المتجر' : 'Rate the app in store',
            onTap: () => _rateApp(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperSection(bool isArabic) {
    return AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                isArabic ? 'المطور' : 'Developer',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: AppConstants.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.developerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic 
                          ? 'خبير تطوير التطبيقات الطبية'
                          : 'Medical App Development Expert',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.secondaryTextColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: isArabic ? 'تواصل' : 'Contact',
                  onPressed: () => _contactDeveloper(),
                  icon: Icons.email,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: isArabic ? 'مشاركة' : 'Share',
                  onPressed: () => _shareApp(isArabic),
                  icon: Icons.share,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            isArabic ? 'معلومات الإصدار' : 'Version Info',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _packageInfo != null 
                ? '${isArabic ? 'الإصدار' : 'Version'} ${_packageInfo!.version}'
                : '${isArabic ? 'الإصدار' : 'Version'} ${AppConstants.appVersion}',
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
            ),
          ),
          if (_packageInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              '${isArabic ? 'رقم البناء' : 'Build'} ${_packageInfo!.buildNumber}',
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.secondaryTextColor,
                fontFamily: 'Cairo',
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '© 2024 ${AppConstants.developerName}',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppConstants.accentColor,
          size: 20,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.secondaryTextColor,
            fontFamily: 'Cairo',
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppConstants.secondaryTextColor,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  void _changeLanguage(String languageCode) {
    ref.read(localizationProvider.notifier).setLocale(languageCode);
  }

  void _showCameraSettings(bool isArabic) {
    _showSettingsDialog(
      title: isArabic ? 'إعدادات الكاميرا' : 'Camera Settings',
      content: isArabic 
          ? 'ستكون متاحة في الإصدار القادم'
          : 'Will be available in next version',
    );
  }

  void _showUploadSettings(bool isArabic) {
    _showSettingsDialog(
      title: isArabic ? 'إعدادات الرفع' : 'Upload Settings',
      content: isArabic 
          ? 'ستكون متاحة في الإصدار القادم'
          : 'Will be available in next version',
    );
  }

  void _showExportSettings(bool isArabic) {
    _showSettingsDialog(
      title: isArabic ? 'إعدادات التصدير' : 'Export Settings',
      content: isArabic 
          ? 'ستكون متاحة في الإصدار القادم'
          : 'Will be available in next version',
    );
  }

  void _showNotificationSettings(bool isArabic) {
    _showSettingsDialog(
      title: isArabic ? 'الإشعارات' : 'Notifications',
      content: isArabic 
          ? 'ستكون متاحة في الإصدار القادم'
          : 'Will be available in next version',
    );
  }

  void _showFAQ(bool isArabic) {
    _showInfoDialog(
      title: isArabic ? 'الأسئلة الشائعة' : 'FAQ',
      content: isArabic 
          ? 'س: كيف يعمل التطبيق؟\nج: يستخدم التطبيق تقنيات الذكاء الاصطناعي لتحليل صور وفيديوهات الحيوانات المنوية.\n\nس: هل النتائج دقيقة؟\nج: نعم، يستخدم نموذج YOLOv8 المتقدم لضمان دقة عالية.\n\nس: كيف أحفظ النتائج؟\nج: يمكنك تصدير النتائج بصيغة JSON أو CSV.'
          : 'Q: How does the app work?\nA: The app uses AI to analyze sperm images and videos.\n\nQ: Are results accurate?\nA: Yes, it uses advanced YOLOv8 model for high accuracy.\n\nQ: How to save results?\nA: You can export results as JSON or CSV.',
    );
  }

  void _showUserGuide(bool isArabic) {
    _showInfoDialog(
      title: isArabic ? 'دليل الاستخدام' : 'User Guide',
      content: isArabic 
          ? '1. انتقل إلى تبويب التحليل\n2. اختر صورة أو فيديو أو التقط جديد\n3. انقر على "بدء التحليل"\n4. انتظر حتى اكتمال التحليل\n5. اعرض النتائج والرسوم البيانية\n6. صدر أو شارك النتائج'
          : '1. Go to Analysis tab\n2. Choose image/video or capture new\n3. Tap "Start Analysis"\n4. Wait for analysis completion\n5. View results and charts\n6. Export or share results',
    );
  }

  void _reportIssue(bool isArabic) {
    _contactDeveloper();
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'سيتم فتح متجر التطبيقات قريباً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
      ),
    );
  }

  void _contactDeveloper() {
    Share.share(
      'تواصل مع المطور: ${AppConstants.developerName}\nEmail: developer@example.com',
    );
  }

  void _shareApp(bool isArabic) {
    Share.share(
      isArabic 
          ? 'تحقق من تطبيق Sperm Analyzer AI - تحليل ذكي ودقيق للحيوانات المنوية\nالمطور: ${AppConstants.developerName}'
          : 'Check out Sperm Analyzer AI - Smart and accurate sperm analysis\nDeveloper: ${AppConstants.developerName}',
    );
  }

  void _showSettingsDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          title,
          style: const TextStyle(
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: AppConstants.secondaryTextColor,
            fontFamily: 'Cairo',
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              ref.read(localizationProvider).languageCode == 'ar' 
                  ? 'موافق' 
                  : 'OK',
              style: const TextStyle(
                color: AppConstants.accentColor,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          title,
          style: const TextStyle(
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              ref.read(localizationProvider).languageCode == 'ar' 
                  ? 'إغلاق' 
                  : 'Close',
              style: const TextStyle(
                color: AppConstants.accentColor,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
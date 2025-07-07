import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../utils/app_constants.dart';
import '../services/localization_service.dart';
import '../services/analysis_service.dart';
import 'analysis_screen.dart';
import 'results_screen.dart';
import 'charts_screen.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';

// Provider لتتبع الصفحة الحالية
final currentPageProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    
    final List<Widget> pages = [
      const AnalysisScreen(),
      const ResultsScreen(),
      const ChartsScreen(),
      const SettingsScreen(),
    ];
    
    final List<BottomNavigationBarItem> bottomNavItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.biotech),
        activeIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.biotech),
        ),
        label: isArabic ? 'تحليل' : 'Analysis',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.assignment),
        activeIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.assignment),
        ),
        label: isArabic ? 'النتائج' : 'Results',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.bar_chart),
        activeIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bar_chart),
        ),
        label: isArabic ? 'الرسوم البيانية' : 'Charts',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.settings),
        activeIcon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.accentColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.settings),
        ),
        label: isArabic ? 'الإعدادات' : 'Settings',
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppConstants.mediumAnimation,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: pages[currentPage],
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: currentPage,
            onTap: (index) {
              ref.read(currentPageProvider.notifier).state = index;
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppConstants.surfaceColor,
            selectedItemColor: AppConstants.accentColor,
            unselectedItemColor: AppConstants.textColor.withOpacity(0.6),
            selectedFontSize: 12,
            unselectedFontSize: 10,
            elevation: 0,
            items: bottomNavItems,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
      
      // Floating Action Button للوصول السريع للكاميرا
      floatingActionButton: currentPage == 0 ? _buildFloatingActionButton(context, ref) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  Widget _buildFloatingActionButton(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: FloatingActionButton.extended(
        onPressed: () {
          // انتقال سريع للكاميرا
          _showCameraOptions(context, ref);
        },
        backgroundColor: AppConstants.accentColor,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.camera_alt, size: 24),
        label: Text(
          isArabic ? 'كاميرا سريعة' : 'Quick Camera',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }
  
  void _showCameraOptions(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // مؤشر السحب
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppConstants.textColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              isArabic ? 'خيارات الكاميرا' : 'Camera Options',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
                fontFamily: 'Cairo',
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCameraOption(
                  context,
                  icon: Icons.photo_camera,
                  title: isArabic ? 'صورة' : 'Photo',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(isVideo: false),
                      ),
                    );
                    
                    if (result != null && result['file'] != null) {
                      final file = result['file'] as File;
                      ref.read(analysisStateProvider.notifier).setSelectedFile(file);
                      // الانتقال لشاشة التحليل
                      _currentIndex = 0;
                      setState(() {});
                    }
                  },
                ),
                _buildCameraOption(
                  context,
                  icon: Icons.videocam,
                  title: isArabic ? 'فيديو' : 'Video',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(isVideo: true),
                      ),
                    );
                    
                    if (result != null && result['file'] != null) {
                      final file = result['file'] as File;
                      ref.read(analysisStateProvider.notifier).setSelectedFile(file);
                      // الانتقال لشاشة التحليل
                      _currentIndex = 0;
                      setState(() {});
                    }
                  },
                ),
                _buildCameraOption(
                  context,
                  icon: Icons.folder,
                  title: isArabic ? 'ملف' : 'File',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: فتح منتقي الملفات
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCameraOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppConstants.accentColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: AppConstants.accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppConstants.textColor,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
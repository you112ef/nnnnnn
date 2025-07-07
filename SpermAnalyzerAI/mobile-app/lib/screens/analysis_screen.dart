import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../utils/app_constants.dart';
import '../services/localization_service.dart';
import '../services/analysis_service.dart';
import '../services/camera_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/analysis_card.dart';
import 'camera_screen.dart';

// Provider لحالة التحليل
final analysisStateProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    final analysisState = ref.watch(analysisStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'تحليل العينة' : 'Sample Analysis',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAnalysisInfo(context),
          ),
        ],
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
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // معلومات التحليل
                        _buildAnalysisInfo(isArabic),
                        
                        const SizedBox(height: 20),
                        
                        // خيارات رفع الملفات
                        Expanded(
                          child: analysisState.isAnalyzing
                              ? _buildAnalysisProgress(analysisState)
                              : _buildUploadOptions(isArabic),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // معلومات الملف المحدد
                        if (analysisState.selectedFile != null)
                          _buildSelectedFileInfo(analysisState.selectedFile!, isArabic),
                        
                        const SizedBox(height: 20),
                        
                        // زر بدء التحليل
                        if (analysisState.selectedFile != null && !analysisState.isAnalyzing)
                          CustomButton(
                            text: isArabic ? 'بدء التحليل' : 'Start Analysis',
                            onPressed: () => _startAnalysis(),
                            isLoading: analysisState.isAnalyzing,
                            icon: Icons.play_arrow,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisInfo(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: AppConstants.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isArabic ? 'معلومات التحليل' : 'Analysis Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isArabic
                ? 'يستخدم هذا التطبيق نموذج YOLOv8 المتقدم لتحليل الحيوانات المنوية وحساب مؤشرات CASA بدقة عالية.'
                : 'This app uses advanced YOLOv8 model to analyze sperm and calculate CASA parameters with high accuracy.',
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOptions(bool isArabic) {
    return Column(
      children: [
        // عنوان الخيارات
        Text(
          isArabic ? 'اختر طريقة التحليل' : 'Choose Analysis Method',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        
        const SizedBox(height: 20),
        
        // بطاقات الخيارات
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildOptionCard(
                icon: Icons.camera_alt,
                title: isArabic ? 'التقاط صورة' : 'Take Photo',
                subtitle: isArabic ? 'استخدم الكاميرا' : 'Use Camera',
                onTap: () => _pickImage(ImageSource.camera),
              ),
              _buildOptionCard(
                icon: Icons.photo_library,
                title: isArabic ? 'اختر صورة' : 'Pick Image',
                subtitle: isArabic ? 'من المعرض' : 'From Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              _buildOptionCard(
                icon: Icons.videocam,
                title: isArabic ? 'تسجيل فيديو' : 'Record Video',
                subtitle: isArabic ? 'استخدم الكاميرا' : 'Use Camera',
                onTap: () => _pickVideo(ImageSource.camera),
              ),
              _buildOptionCard(
                icon: Icons.folder,
                title: isArabic ? 'اختر ملف' : 'Pick File',
                subtitle: isArabic ? 'صور أو فيديو' : 'Image or Video',
                onTap: () => _pickFile(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // معلومات الملفات المدعومة
        _buildSupportedFormats(isArabic),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return AnalysisCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppConstants.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedFormats(bool isArabic) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'الصيغ المدعومة:' : 'Supported Formats:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'الصور: JPG, PNG, BMP\nالفيديو: MP4, AVI, MOV, MKV'
                : 'Images: JPG, PNG, BMP\nVideos: MP4, AVI, MOV, MKV',
            style: const TextStyle(
              fontSize: 12,
              color: AppConstants.secondaryTextColor,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisProgress(AnalysisState state) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    
    return CustomProgressIndicator(
      progress: state.progress,
      status: state.status,
      isArabic: isArabic,
    );
  }

  Widget _buildSelectedFileInfo(File file, bool isArabic) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final fileSizeText = _formatFileSize(fileSize);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.accentColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(fileName),
            color: AppConstants.accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileSizeText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.secondaryTextColor,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ref.read(analysisStateProvider.notifier).clearSelectedFile();
            },
            icon: const Icon(
              Icons.close,
              color: AppConstants.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (AppConstants.supportedImageFormats.contains(extension)) {
      return Icons.image;
    } else if (AppConstants.supportedVideoFormats.contains(extension)) {
      return Icons.video_file;
    }
    return Icons.file_present;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // التنقل لشاشة الكاميرا لالتقاط صورة
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraScreen(isVideo: false),
          ),
        );
        
        if (result != null && result['file'] != null) {
          final file = result['file'] as File;
          ref.read(analysisStateProvider.notifier).setSelectedFile(file);
        }
        return;
      }

      final permission = Permission.photos;
      final status = await permission.request();
      if (!status.isGranted) {
        _showPermissionDenied();
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        final file = File(image.path);
        ref.read(analysisStateProvider.notifier).setSelectedFile(file);
      }
    } catch (e) {
      _showError('خطأ في اختيار الصورة: $e');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // التنقل لشاشة الكاميرا لتسجيل فيديو
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => const CameraScreen(isVideo: true),
          ),
        );
        
        if (result != null && result['file'] != null) {
          final file = result['file'] as File;
          ref.read(analysisStateProvider.notifier).setSelectedFile(file);
        }
        return;
      }

      final permission = Permission.photos;
      final status = await permission.request();
      if (!status.isGranted) {
        _showPermissionDenied();
        return;
      }

      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        final file = File(video.path);
        ref.read(analysisStateProvider.notifier).setSelectedFile(file);
      }
    } catch (e) {
      _showError('خطأ في اختيار الفيديو: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          ...AppConstants.supportedImageFormats,
          ...AppConstants.supportedVideoFormats,
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        ref.read(analysisStateProvider.notifier).setSelectedFile(file);
      }
    } catch (e) {
      _showError('خطأ في اختيار الملف: $e');
    }
  }

  Future<void> _startAnalysis() async {
    final analysisState = ref.read(analysisStateProvider);
    if (analysisState.selectedFile == null) return;

    try {
      await ref.read(analysisStateProvider.notifier).startAnalysis(
        analysisState.selectedFile!,
      );
      
      // انتقال إلى شاشة النتائج عند اكتمال التحليل
      if (mounted) {
        _showAnalysisComplete();
      }
    } catch (e) {
      _showError('خطأ في التحليل: $e');
    }
  }

  void _showAnalysisInfo(BuildContext context) {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          isArabic ? 'معلومات التحليل' : 'Analysis Information',
          style: const TextStyle(
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        content: Text(
          isArabic
              ? 'يستخدم هذا التطبيق تقنيات الذكاء الاصطناعي المتقدمة لتحليل الحيوانات المنوية:\n\n• نموذج YOLOv8 للكشف والتتبع\n• خوارزمية DeepSORT للتتبع المتقدم\n• حساب مؤشرات CASA بدقة عالية\n• تحليل الحركة والسرعة والشكل'
              : 'This app uses advanced AI technologies for sperm analysis:\n\n• YOLOv8 model for detection and tracking\n• DeepSORT algorithm for advanced tracking\n• High-accuracy CASA parameter calculation\n• Motion, velocity, and morphology analysis',
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
              isArabic ? 'موافق' : 'OK',
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

  void _showAnalysisComplete() {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: Text(
          isArabic ? 'التحليل مكتمل' : 'Analysis Complete',
          style: const TextStyle(
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
        content: Text(
          isArabic
              ? 'تم تحليل العينة بنجاح. يمكنك الآن عرض النتائج والرسوم البيانية.'
              : 'Sample analysis completed successfully. You can now view results and charts.',
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
              isArabic ? 'موافق' : 'OK',
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

  void _showPermissionDenied() {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic ? 'تم رفض الإذن' : 'Permission Denied',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }
}
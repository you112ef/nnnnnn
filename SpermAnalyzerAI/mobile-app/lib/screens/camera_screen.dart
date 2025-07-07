import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import '../services/camera_service.dart';
import '../services/localization_service.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final bool isVideo;
  
  const CameraScreen({
    super.key,
    required this.isVideo,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeCamera() async {
    await ref.read(cameraServiceProvider.notifier).initializeCamera();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    final cameraState = ref.watch(cameraServiceProvider);
    final cameraPermission = ref.watch(cameraPermissionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.isVideo
              ? (isArabic ? 'تسجيل فيديو' : 'Record Video')
              : (isArabic ? 'التقاط صورة' : 'Take Photo'),
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // زر تبديل الكاميرا
          if (cameraState.availableCameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: () {
                ref.read(cameraServiceProvider.notifier).switchCamera();
              },
            ),
          // زر الفلاش
          IconButton(
            icon: Icon(
              cameraState.isFlashOn ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () {
              ref.read(cameraServiceProvider.notifier).toggleFlash();
            },
          ),
        ],
      ),
      body: cameraPermission.when(
        data: (hasPermission) {
          if (!hasPermission) {
            return _buildPermissionDenied(isArabic);
          }

          if (cameraState.cameraController == null || 
              !cameraState.cameraController!.value.isInitialized) {
            return _buildLoadingView(isArabic);
          }

          return _buildCameraView(cameraState, isArabic);
        },
        loading: () => _buildLoadingView(isArabic),
        error: (error, _) => _buildErrorView(error.toString(), isArabic),
      ),
    );
  }

  Widget _buildPermissionDenied(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'إذن الكاميرا مطلوب' : 'Camera Permission Required',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              isArabic
                  ? 'يرجى السماح للتطبيق بالوصول إلى الكاميرا لالتقاط الصور والفيديوهات'
                  : 'Please allow the app to access the camera for taking photos and videos',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: isArabic ? 'طلب الإذن' : 'Request Permission',
              onPressed: () async {
                await ref.read(cameraServiceProvider.notifier).requestPermissions();
              },
              icon: Icons.camera_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView(bool isArabic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentColor),
          ),
          const SizedBox(height: 20),
          Text(
            isArabic ? 'تحضير الكاميرا...' : 'Preparing Camera...',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'خطأ في الكاميرا' : 'Camera Error',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: isArabic ? 'إعادة المحاولة' : 'Retry',
              onPressed: () {
                _initializeCamera();
              },
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(CameraServiceState cameraState, bool isArabic) {
    return Stack(
      children: [
        // عرض الكاميرا
        Positioned.fill(
          child: CameraPreview(cameraState.cameraController!),
        ),
        
        // طبقة تحكم شفافة
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // شريط التحكم السفلي
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(cameraState, isArabic),
        ),

        // مؤشر الحالة العلوي
        if (cameraState.isRecording || _isCapturing)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildStatusIndicator(cameraState, isArabic),
          ),

        // شبكة المساعدة (اختيارية)
        if (cameraState.showGrid)
          Positioned.fill(
            child: _buildGridOverlay(),
          ),
      ],
    );
  }

  Widget _buildBottomControls(CameraServiceState cameraState, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padding,
        vertical: 30,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // زر المعرض
          _buildControlButton(
            icon: Icons.photo_library,
            onPressed: () {
              Navigator.pop(context);
            },
          ),

          // زر الالتقاط/التسجيل الرئيسي
          _buildCaptureButton(cameraState, isArabic),

          // زر الإعدادات
          _buildControlButton(
            icon: Icons.settings,
            onPressed: () {
              _showCameraSettings(context, isArabic);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCaptureButton(CameraServiceState cameraState, bool isArabic) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            onTap: _isCapturing ? null : () => _handleCapture(cameraState),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.isVideo && cameraState.isRecording
                    ? AppConstants.errorColor
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.accentColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.isVideo
                    ? (cameraState.isRecording ? Icons.stop : Icons.videocam)
                    : Icons.camera_alt,
                color: widget.isVideo && cameraState.isRecording
                    ? Colors.white
                    : AppConstants.primaryColor,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(CameraServiceState cameraState, bool isArabic) {
    if (!widget.isVideo || !cameraState.isRecording) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isArabic ? 'جاري التقاط الصورة...' : 'Capturing...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.errorColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isArabic ? 'تسجيل...' : 'Recording...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(cameraState.recordingDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(
      painter: GridPainter(),
      child: Container(),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _handleCapture(CameraServiceState cameraState) async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      if (widget.isVideo) {
        if (cameraState.isRecording) {
          // إيقاف التسجيل
          final file = await ref.read(cameraServiceProvider.notifier).stopVideoRecording();
          if (file != null && mounted) {
            Navigator.pop(context, {'file': file});
          }
        } else {
          // بدء التسجيل
          await ref.read(cameraServiceProvider.notifier).startVideoRecording();
        }
      } else {
        // التقاط صورة
        final file = await ref.read(cameraServiceProvider.notifier).takePicture();
        if (file != null && mounted) {
          Navigator.pop(context, {'file': file});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ: $e',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _showCameraSettings(BuildContext context, bool isArabic) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final cameraState = ref.watch(cameraServiceProvider);
            final cameraSettings = ref.watch(cameraSettingsProvider);
            
            return Container(
              padding: const EdgeInsets.all(AppConstants.padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'إعدادات الكاميرا' : 'Camera Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // إعداد الشبكة
                  SwitchListTile(
                    title: Text(
                      isArabic ? 'إظهار الشبكة' : 'Show Grid',
                      style: const TextStyle(
                        color: AppConstants.textColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    subtitle: Text(
                      isArabic ? 'لمساعدة في التأطير' : 'Help with framing',
                      style: const TextStyle(
                        color: AppConstants.secondaryTextColor,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    value: cameraState.showGrid,
                    onChanged: (value) {
                      ref.read(cameraServiceProvider.notifier).toggleGrid();
                    },
                    activeColor: AppConstants.accentColor,
                  ),
                  
                  // إعداد جودة الصورة (للصور فقط)
                  if (!widget.isVideo) ...[
                    const Divider(color: AppConstants.secondaryTextColor),
                    ListTile(
                      title: Text(
                        isArabic ? 'جودة الصورة' : 'Image Quality',
                        style: const TextStyle(
                          color: AppConstants.textColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      subtitle: Text(
                        '${(cameraSettings.imageQuality * 100).round()}%',
                        style: const TextStyle(
                          color: AppConstants.secondaryTextColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: cameraSettings.imageQuality,
                          min: 0.5,
                          max: 1.0,
                          divisions: 5,
                          onChanged: (value) {
                            ref.read(cameraSettingsProvider.notifier).updateImageQuality(value);
                          },
                          activeColor: AppConstants.accentColor,
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// رسام الشبكة
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1.0;

    // خطوط عمودية
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // خطوط أفقية
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
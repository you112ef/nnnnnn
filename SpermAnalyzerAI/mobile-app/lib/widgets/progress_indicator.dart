import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_constants.dart';

class CustomProgressIndicator extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String status;
  final bool isArabic;
  final Color? primaryColor;
  final Color? backgroundColor;
  final double? size;
  final double? strokeWidth;
  final bool showPercentage;

  const CustomProgressIndicator({
    super.key,
    required this.progress,
    required this.status,
    required this.isArabic,
    this.primaryColor,
    this.backgroundColor,
    this.size,
    this.strokeWidth,
    this.showPercentage = true,
  });

  @override
  State<CustomProgressIndicator> createState() => _CustomProgressIndicatorState();
}

class _CustomProgressIndicatorState extends State<CustomProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _rotationController.repeat();
    _progressController.forward();
  }

  @override
  void didUpdateWidget(CustomProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = widget.primaryColor ?? AppConstants.accentColor;
    final Color bgColor = widget.backgroundColor ?? AppConstants.surfaceColor;
    final double size = widget.size ?? 200;
    final double strokeWidth = widget.strokeWidth ?? 8;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // العنوان
          Text(
            widget.isArabic ? 'جاري التحليل' : 'Analysis in Progress',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          
          const SizedBox(height: 24),
          
          // مؤشر التقدم الدائري
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // الخلفية الدائرية
                CustomPaint(
                  size: Size(size, size),
                  painter: CircularProgressBackgroundPainter(
                    backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                    strokeWidth: strokeWidth,
                  ),
                ),
                
                // مؤشر التقدم
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: CircularProgressPainter(
                        progress: _progressAnimation.value,
                        primaryColor: primaryColor,
                        strokeWidth: strokeWidth,
                      ),
                    );
                  },
                ),
                
                // النسبة المئوية والنص
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.showPercentage)
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: size * 0.12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              fontFamily: 'Cairo',
                            ),
                          );
                        },
                      ),
                    
                    // أيقونة متحركة
                    AnimatedBuilder(
                      animation: _rotationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationController.value * 2 * math.pi,
                          child: Icon(
                            Icons.biotech,
                            size: size * 0.2,
                            color: primaryColor.withOpacity(0.7),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // حالة التقدم
          AnimatedSwitcher(
            duration: AppConstants.mediumAnimation,
            child: Container(
              key: ValueKey(widget.status),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.status,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // شريط التقدم الخطي
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 6,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressBackgroundPainter extends CustomPainter {
  final Color backgroundColor;
  final double strokeWidth;

  CircularProgressBackgroundPainter({
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // تدرج لوني للتقدم
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: [
        primaryColor,
        primaryColor.withOpacity(0.7),
        primaryColor,
      ],
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      paint,
    );

    // نقطة في نهاية التقدم
    if (progress > 0) {
      final endAngle = -math.pi / 2 + sweepAngle;
      final endPoint = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );

      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(endPoint, strokeWidth / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// مؤشر تقدم مبسط
class SimpleProgressIndicator extends StatelessWidget {
  final double progress;
  final Color? color;
  final double? height;

  const SimpleProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height ?? 4,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular((height ?? 4) / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? AppConstants.accentColor,
            borderRadius: BorderRadius.circular((height ?? 4) / 2),
          ),
        ),
      ),
    );
  }
}

// مؤشر تقدم مع خطوات
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool isArabic;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;
            
            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted || isCurrent
                          ? AppConstants.accentColor
                          : AppConstants.surfaceColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.accentColor,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : isCurrent
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                  ),
                  if (index < totalSteps - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: isCompleted
                            ? AppConstants.accentColor
                            : AppConstants.surfaceColor,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        if (stepLabels.length > currentStep)
          Text(
            stepLabels[currentStep],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
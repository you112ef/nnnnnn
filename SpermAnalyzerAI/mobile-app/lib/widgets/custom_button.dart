import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isOutlined;
  final bool isGradient;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.padding,
    this.fontSize,
    this.fontWeight,
    this.isOutlined = false,
    this.isGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPress = isEnabled && !isLoading;
    final Color bgColor = backgroundColor ?? AppConstants.accentColor;
    final Color txColor = textColor ?? Colors.white;
    
    if (isOutlined) {
      return _buildOutlinedButton(canPress, bgColor, txColor);
    } else if (isGradient) {
      return _buildGradientButton(canPress, txColor);
    } else {
      return _buildElevatedButton(canPress, bgColor, txColor);
    }
  }

  Widget _buildElevatedButton(bool canPress, Color bgColor, Color txColor) {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      width: width,
      height: height ?? 50,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canPress ? bgColor : bgColor.withOpacity(0.5),
          foregroundColor: txColor,
          disabledBackgroundColor: bgColor.withOpacity(0.3),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
          elevation: canPress ? 4 : 2,
        ),
        child: _buildButtonContent(txColor),
      ),
    );
  }

  Widget _buildOutlinedButton(bool canPress, Color bgColor, Color txColor) {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      width: width,
      height: height ?? 50,
      child: OutlinedButton(
        onPressed: canPress ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: canPress ? bgColor : bgColor.withOpacity(0.5),
          side: BorderSide(
            color: canPress ? bgColor : bgColor.withOpacity(0.5),
            width: 2,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
          ),
        ),
        child: _buildButtonContent(canPress ? bgColor : bgColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildGradientButton(bool canPress, Color txColor) {
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      width: width,
      height: height ?? 50,
      decoration: BoxDecoration(
        gradient: canPress
            ? AppConstants.accentGradient
            : LinearGradient(
                colors: [
                  AppConstants.accentColor.withOpacity(0.3),
                  AppConstants.surfaceColor.withOpacity(0.3),
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: canPress ? AppConstants.buttonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canPress ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: _buildButtonContent(txColor),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: color),
        
        if ((isLoading || icon != null) && text.isNotEmpty)
          const SizedBox(width: 8),
        
        if (text.isNotEmpty)
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w600,
                color: color,
                fontFamily: 'Cairo',
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

// زر أيقونة مخصص
class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final bool isEnabled;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = backgroundColor ?? AppConstants.accentColor;
    final Color icColor = iconColor ?? Colors.white;
    final double btnSize = size ?? 48;
    final double icSize = iconSize ?? 24;

    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      width: btnSize,
      height: btnSize,
      decoration: BoxDecoration(
        color: isEnabled ? bgColor : bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(btnSize / 2),
        boxShadow: isEnabled ? AppConstants.buttonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(btnSize / 2),
          child: Container(
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: icSize,
              color: isEnabled ? icColor : icColor.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// زر نص مخصص
class CustomTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isEnabled;

  const CustomTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color txColor = textColor ?? AppConstants.accentColor;

    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: isEnabled ? txColor : txColor.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 14,
          fontWeight: fontWeight ?? FontWeight.w500,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

// زر تبديل مخصص
class CustomToggleButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;
  final Color? selectedColor;
  final Color? unselectedColor;

  const CustomToggleButton({
    super.key,
    required this.isSelected,
    required this.onPressed,
    required this.text,
    this.icon,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color selColor = selectedColor ?? AppConstants.accentColor;
    final Color unselColor = unselectedColor ?? AppConstants.surfaceColor;

    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? selColor : unselColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? selColor : AppConstants.textColor.withOpacity(0.3),
        ),
        boxShadow: isSelected ? AppConstants.buttonShadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppConstants.textColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:ui';

/// 毛玻璃效果卡片组件
/// 实现Apple风格的frosted glass效果
class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double blurRadius;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final bool animated;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12.0,
    this.blurRadius = 20.0,
    this.opacity = 0.15,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.onTap,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? _defaultBoxShadow(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurRadius,
            sigmaY: blurRadius,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    if (animated) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: card,
      );
    }

    return card;
  }

  List<BoxShadow> _defaultBoxShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

/// 毛玻璃效果容器
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final double blurRadius;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 12.0,
    this.blurRadius = 20.0,
    this.opacity = 0.15,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurRadius,
            sigmaY: blurRadius,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.3),
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃效果按钮
class GlassmorphismButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsets padding;
  final double borderRadius;
  final double blurRadius;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool enabled;

  const GlassmorphismButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.borderRadius = 8.0,
    this.blurRadius = 15.0,
    this.opacity = 0.2,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: GlassmorphismContainer(
          padding: padding,
          borderRadius: borderRadius,
          blurRadius: blurRadius,
          opacity: opacity,
          backgroundColor: backgroundColor,
          borderColor: borderColor,
          borderWidth: borderWidth,
          child: child,
        ),
      ),
    );
  }
}

/// 毛玻璃效果输入框
class GlassmorphismTextField extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double borderRadius;
  final double blurRadius;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const GlassmorphismTextField({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.borderRadius = 12.0,
    this.blurRadius = 20.0,
    this.opacity = 0.15,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: borderRadius,
      blurRadius: blurRadius,
      opacity: opacity,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
          prefixIcon: prefixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  child: prefixIcon!,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? IconTheme(
                  data: IconThemeData(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  child: suffixIcon!,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// 毛玻璃效果预设样式
class GlassmorphismStyles {
  static const double defaultBorderRadius = 12.0;
  static const double defaultBlurRadius = 20.0;
  static const double defaultOpacity = 0.15;
  static const double defaultBorderWidth = 1.0;

  // 标准样式
  static GlassmorphismCard standard({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    EdgeInsets margin = EdgeInsets.zero,
    VoidCallback? onTap,
  }) {
    return GlassmorphismCard(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }

  // 高模糊样式（用于模态框）
  static GlassmorphismCard highBlur({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    EdgeInsets margin = EdgeInsets.zero,
    VoidCallback? onTap,
  }) {
    return GlassmorphismCard(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      onTap: onTap,
      blurRadius: 30.0,
      opacity: 0.2,
      child: child,
    );
  }

  // 低模糊样式（用于背景）
  static GlassmorphismCard lowBlur({
    required Widget child,
    double? width,
    double? height,
    EdgeInsets padding = const EdgeInsets.all(16.0),
    EdgeInsets margin = EdgeInsets.zero,
    VoidCallback? onTap,
  }) {
    return GlassmorphismCard(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      onTap: onTap,
      blurRadius: 10.0,
      opacity: 0.1,
      child: child,
    );
  }
}

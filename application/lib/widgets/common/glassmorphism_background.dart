import 'package:flutter/material.dart';
import 'dart:ui';

/// Apple风格的毛玻璃背景组件
/// 提供动态渐变背景和毛玻璃效果
class GlassmorphismBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;

  const GlassmorphismBackground({
    super.key,
    required this.child,
    this.enableAnimation = true,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
  });

  @override
  State<GlassmorphismBackground> createState() => _GlassmorphismBackgroundState();
}

class _GlassmorphismBackgroundState extends State<GlassmorphismBackground>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enableAnimation) {
      _backgroundAnimationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildBackgroundDecoration(),
      child: widget.child,
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    final defaultColors = [
      const Color(0xFF1C1C1E),
      const Color(0xFF2C2C2E),
      const Color(0xFF3A3A3C),
      const Color(0xFF4A4A4C),
    ];

    final colors = widget.gradientColors ?? defaultColors;
    final begin = widget.gradientBegin ?? Alignment.topLeft;
    final end = widget.gradientEnd ?? Alignment.bottomRight;

    if (widget.enableAnimation) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
          stops: [
            0.0,
            0.3 + 0.2 * _backgroundAnimation.value,
            0.7 + 0.2 * (1 - _backgroundAnimation.value),
            1.0,
          ],
        ),
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      );
    }
  }
}

/// 毛玻璃卡片背景
class GlassmorphismCardBackground extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurRadius;
  final double opacity;

  const GlassmorphismCardBackground({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.blurRadius = 10.0,
    this.opacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

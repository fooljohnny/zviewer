import 'package:flutter/material.dart';
import 'dart:ui';

/// ZViewer Logo组件
/// 支持多种尺寸和样式变体
class ZViewerLogo extends StatelessWidget {
  final double size;
  final ZViewerLogoVariant variant;
  final bool animated;
  final Color? backgroundColor;

  const ZViewerLogo({
    super.key,
    this.size = 64.0,
    this.variant = ZViewerLogoVariant.standard,
    this.animated = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: animated ? const Duration(seconds: 2) : Duration.zero,
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _getGradient(),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.125),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: size * 0.3,
            sigmaY: size * 0.3,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _getGlassColor(),
              border: Border.all(
                color: _getBorderColor(),
                width: size * 0.015,
              ),
            ),
            child: Center(
              child: Text(
                'Z',
                style: TextStyle(
                  fontSize: size * 0.56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (variant) {
      case ZViewerLogoVariant.standard:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF007AFF), // iOS Blue
            Color(0xFF5856D6), // iOS Purple
            Color(0xFFFF9500), // iOS Orange
          ],
        );
      case ZViewerLogoVariant.dark:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1C1E), // Dark Gray
            Color(0xFF2C2C2E), // Medium Gray
            Color(0xFF3A3A3C), // Light Gray
          ],
        );
      case ZViewerLogoVariant.monochrome:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor ?? Colors.black,
            backgroundColor ?? Colors.black,
            backgroundColor ?? Colors.black,
          ],
        );
    }
  }

  Color _getGlassColor() {
    switch (variant) {
      case ZViewerLogoVariant.standard:
        return Colors.white.withOpacity(0.15);
      case ZViewerLogoVariant.dark:
        return Colors.black.withOpacity(0.15);
      case ZViewerLogoVariant.monochrome:
        return Colors.white.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (variant) {
      case ZViewerLogoVariant.standard:
        return Colors.white.withOpacity(0.3);
      case ZViewerLogoVariant.dark:
        return Colors.white.withOpacity(0.2);
      case ZViewerLogoVariant.monochrome:
        return Colors.white.withOpacity(0.3);
    }
  }
}

/// Logo变体枚举
enum ZViewerLogoVariant {
  standard,  // 标准毛玻璃效果
  dark,      // 深色背景版本
  monochrome, // 单色版本
}

/// 预设尺寸的Logo组件
class ZViewerLogoSmall extends StatelessWidget {
  const ZViewerLogoSmall({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZViewerLogo(size: 32.0);
  }
}

class ZViewerLogoMedium extends StatelessWidget {
  const ZViewerLogoMedium({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZViewerLogo(size: 64.0);
  }
}

class ZViewerLogoLarge extends StatelessWidget {
  const ZViewerLogoLarge({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZViewerLogo(size: 128.0);
  }
}

/// 动画Logo组件
class ZViewerLogoAnimated extends StatefulWidget {
  final double size;
  final ZViewerLogoVariant variant;

  const ZViewerLogoAnimated({
    super.key,
    this.size = 64.0,
    this.variant = ZViewerLogoVariant.standard,
  });

  @override
  State<ZViewerLogoAnimated> createState() => _ZViewerLogoAnimatedState();
}

class _ZViewerLogoAnimatedState extends State<ZViewerLogoAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(
      begin: 0.15,
      end: 0.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return ZViewerLogo(
          size: widget.size,
          variant: widget.variant,
          animated: true,
        );
      },
    );
  }
}



import 'package:flutter/material.dart';

/// 现代化背景组件
/// 提供与登录页面一致的动态渐变背景
class ModernBackground extends StatefulWidget {
  final Widget child;
  final bool enableAnimation;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;

  const ModernBackground({
    super.key,
    required this.child,
    this.enableAnimation = true,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
  });

  @override
  State<ModernBackground> createState() => _ModernBackgroundState();
}

class _ModernBackgroundState extends State<ModernBackground>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enableAnimation) {
      _backgroundController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: _buildBackgroundDecoration(),
          child: Stack(
            children: [
              // 装饰性圆形
              _buildDecorativeCircles(),
              
              // 主要内容
              widget.child,
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    final defaultColors = [
      const Color(0xFF667eea),
      const Color(0xFF764ba2),
      const Color(0xFFf093fb),
      const Color(0xFFf5576c),
      const Color(0xFF4facfe),
      const Color(0xFF00f2fe),
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
            0.2 + 0.1 * _backgroundAnimation.value,
            0.4 + 0.1 * (1 - _backgroundAnimation.value),
            0.6 + 0.1 * _backgroundAnimation.value,
            0.8 + 0.1 * (1 - _backgroundAnimation.value),
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

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // 大圆形
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        // 中圆形
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
          ),
        ),
        // 小圆形
        Positioned(
          top: 200,
          left: 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        // 额外的小圆形
        Positioned(
          top: 400,
          right: 80,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

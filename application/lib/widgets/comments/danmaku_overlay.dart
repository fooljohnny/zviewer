import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';

/// 弹幕评论覆盖层组件
/// 在媒体文件上显示半透明飘过的评论
class DanmakuOverlay extends StatefulWidget {
  final List<DanmakuComment> comments;
  final bool isVisible;
  final Duration animationDuration;
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final double backgroundOpacity;
  final double borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onCommentTap;
  final VoidCallback? onToggleVisibility;

  const DanmakuOverlay({
    super.key,
    required this.comments,
    this.isVisible = true,
    this.animationDuration = const Duration(seconds: 8),
    this.fontSize = 14.0,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.backgroundOpacity = 0.7,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.onCommentTap,
    this.onToggleVisibility,
  });

  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends State<DanmakuOverlay>
    with TickerProviderStateMixin {
  final List<DanmakuAnimationController> _activeAnimations = [];
  final math.Random _random = math.Random();
  Timer? _spawnTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _startSpawning();
    }
  }

  @override
  void didUpdateWidget(DanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startSpawning();
      } else {
        _stopSpawning();
      }
    }
  }

  @override
  void dispose() {
    _stopSpawning();
    for (final controller in _activeAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (widget.comments.isNotEmpty && mounted) {
        _spawnComment();
      }
    });
  }

  void _stopSpawning() {
    _spawnTimer?.cancel();
    for (final controller in _activeAnimations) {
      controller.stop();
    }
  }

  void _spawnComment() {
    if (widget.comments.isEmpty) return;

    final comment = widget.comments[_random.nextInt(widget.comments.length)];
    final initialTop = _random.nextDouble() * (MediaQuery.of(context).size.height - 100);
    
    final controller = DanmakuAnimationController(
      vsync: this,
      duration: widget.animationDuration,
      comment: comment,
      initialTop: initialTop,
    );

    _activeAnimations.add(controller);

    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _activeAnimations.remove(controller);
        controller.dispose();
      }
    });

    controller.startAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 切换按钮
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: widget.onToggleVisibility,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.comment_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        // 弹幕动画
        ..._activeAnimations.map((controller) {
          final comment = controller.comment;
          final animation = controller.animation;
          
          return Positioned(
            top: controller.initialTop,
            left: animation.value * MediaQuery.of(context).size.width,
            child: GestureDetector(
              onTap: () => widget.onCommentTap?.call(),
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _calculateOpacity(animation.value),
                    child: Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        color: widget.backgroundColor.withOpacity(widget.backgroundOpacity.clamp(0.0, 1.0)),
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        comment.content,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  double _calculateOpacity(double progress) {
    if (progress < 0.1) {
      return (progress / 0.1).clamp(0.0, 1.0);
    } else if (progress > 0.9) {
      return ((1.0 - progress) / 0.1).clamp(0.0, 1.0);
    }
    return 1.0;
  }
}

/// 弹幕评论数据模型
class DanmakuComment {
  final String id;
  final String content;
  final String author;
  final DateTime timestamp;
  final Color? color;
  final double? speed;

  const DanmakuComment({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    this.color,
    this.speed,
  });
}

/// 弹幕动画控制器
class DanmakuAnimationController extends AnimationController {
  final DanmakuComment comment;
  final double initialTop;

  DanmakuAnimationController({
    required super.vsync,
    required Duration super.duration,
    required this.comment,
    required this.initialTop,
  });

  late Animation<double> animation;

  void startAnimation() {
    animation = Tween<double>(
      begin: 1.0,
      end: -0.2,
    ).animate(CurvedAnimation(
      parent: this,
      curve: Curves.linear,
    ));
    forward();
  }
}

/// 弹幕评论输入组件
class DanmakuInput extends StatefulWidget {
  final Function(String content) onSubmit;
  final bool isLoading;
  final String? hintText;

  const DanmakuInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.hintText = '发送弹幕...',
  });

  @override
  State<DanmakuInput> createState() => _DanmakuInputState();
}

class _DanmakuInputState extends State<DanmakuInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _controller.text.trim();
    if (content.isNotEmpty) {
      widget.onSubmit(content);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.isLoading ? null : _submitComment,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isLoading 
                      ? Colors.grey 
                      : Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 弹幕设置面板
class DanmakuSettings extends StatelessWidget {
  final bool isVisible;
  final double fontSize;
  final double opacity;
  final Duration animationDuration;
  final ValueChanged<bool>? onVisibilityChanged;
  final ValueChanged<double>? onFontSizeChanged;
  final ValueChanged<double>? onOpacityChanged;
  final ValueChanged<Duration>? onDurationChanged;

  const DanmakuSettings({
    super.key,
    required this.isVisible,
    this.fontSize = 14.0,
    this.opacity = 0.7,
    this.animationDuration = const Duration(seconds: 8),
    this.onVisibilityChanged,
    this.onFontSizeChanged,
    this.onOpacityChanged,
    this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 显示开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '显示弹幕',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Switch(
                value: isVisible,
                onChanged: onVisibilityChanged,
                activeThumbColor: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 字体大小
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '字体大小',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${fontSize.toInt()}px',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: fontSize,
            min: 10.0,
            max: 20.0,
            divisions: 10,
            activeColor: Colors.blue,
            onChanged: onFontSizeChanged,
          ),
          
          // 透明度
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '透明度',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${(opacity * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: opacity,
            min: 0.3,
            max: 1.0,
            divisions: 7,
            activeColor: Colors.blue,
            onChanged: onOpacityChanged,
          ),
          
          // 动画速度
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '动画速度',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${(8 - animationDuration.inSeconds).toInt()}x',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          Slider(
            value: 8 - animationDuration.inSeconds.toDouble(),
            min: 1.0,
            max: 7.0,
            divisions: 6,
            activeColor: Colors.blue,
            onChanged: (value) {
              onDurationChanged?.call(Duration(seconds: (8 - value).toInt()));
            },
          ),
        ],
        ),
      ),
    );
  }
}

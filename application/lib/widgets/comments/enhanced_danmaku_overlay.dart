import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../services/danmaku_service.dart';

/// 增强版弹幕覆盖层组件
/// 支持更丰富的动画效果和交互
class EnhancedDanmakuOverlay extends StatefulWidget {
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
  final Function(String content)? onCommentSubmit;
  final bool showInput;
  final String? currentUser;

  const EnhancedDanmakuOverlay({
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
    this.onCommentSubmit,
    this.showInput = false,
    this.currentUser = '匿名用户',
  });

  @override
  State<EnhancedDanmakuOverlay> createState() => _EnhancedDanmakuOverlayState();
}

class _EnhancedDanmakuOverlayState extends State<EnhancedDanmakuOverlay>
    with TickerProviderStateMixin {
  final List<DanmakuAnimationController> _activeAnimations = [];
  final math.Random _random = math.Random();
  Timer? _spawnTimer;
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _startSpawning();
    }
  }

  @override
  void didUpdateWidget(EnhancedDanmakuOverlay oldWidget) {
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
    _inputController.dispose();
    _inputFocusNode.dispose();
    for (final controller in _activeAnimations) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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

  void _submitComment() {
    final content = _inputController.text.trim();
    if (content.isNotEmpty && widget.onCommentSubmit != null) {
      widget.onCommentSubmit!(content);
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
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
                        color: comment.color.withOpacity(widget.backgroundOpacity.clamp(0.0, 1.0)),
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
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
        
        // 控制按钮
        _buildControlButtons(),
        
        // 评论输入
        if (widget.showInput) _buildCommentInput(),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Positioned(
      top: 16,
      right: 16,
      child: Row(
        children: [
          // 弹幕开关
          _buildControlButton(
            icon: widget.isVisible ? Icons.comment : Icons.comment_outlined,
            onTap: widget.onToggleVisibility,
            tooltip: widget.isVisible ? '隐藏弹幕' : '显示弹幕',
          ),
          const SizedBox(width: 8),
          // 评论输入开关
          _buildControlButton(
            icon: Icons.edit,
            onTap: () {
              setState(() {
                // 切换输入框显示
              });
            },
            tooltip: '发送弹幕',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
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
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '发送弹幕评论...',
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
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// 弹幕动画控制器
class DanmakuAnimationController extends AnimationController {
  final DanmakuComment comment;
  final double initialTop;

  DanmakuAnimationController({
    required TickerProvider vsync,
    required Duration duration,
    required this.comment,
    required this.initialTop,
  }) : super(vsync: vsync, duration: duration);

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

import 'package:flutter/material.dart';

/// 图集详情页手势处理器
/// 处理右滑返回手势
class AlbumGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;
  final double swipeThreshold;
  final double swipeVelocityThreshold;

  const AlbumGestureHandler({
    super.key,
    required this.child,
    this.onSwipeBack,
    this.swipeThreshold = 100.0,
    this.swipeVelocityThreshold = 300.0,
  });

  @override
  State<AlbumGestureHandler> createState() => _AlbumGestureHandlerState();
}

class _AlbumGestureHandlerState extends State<AlbumGestureHandler>
    with TickerProviderStateMixin {
  late AnimationController _swipeAnimationController;
  late Animation<Offset> _swipeAnimation;
  late Animation<double> _opacityAnimation;
  
  double _dragDistance = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _swipeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _swipeAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              _isDragging ? _dragDistance : _swipeAnimation.value.dx * MediaQuery.of(context).size.width,
              0,
            ),
            child: Opacity(
              opacity: _isDragging 
                  ? (1.0 - (_dragDistance / MediaQuery.of(context).size.width).clamp(0.0, 1.0))
                  : _opacityAnimation.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _dragDistance = 0.0;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // 只处理向右的滑动
    if (details.delta.dx > 0) {
      setState(() {
        _dragDistance += details.delta.dx;
        _dragDistance = _dragDistance.clamp(0.0, MediaQuery.of(context).size.width);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    _isDragging = false;

    // 检查是否满足返回条件
    final screenWidth = MediaQuery.of(context).size.width;
    final dragPercentage = _dragDistance / screenWidth;
    final velocity = details.velocity.pixelsPerSecond.dx;

    bool shouldReturn = false;

    // 条件1：拖拽距离超过阈值
    if (dragPercentage > (widget.swipeThreshold / screenWidth)) {
      shouldReturn = true;
    }

    // 条件2：拖拽速度超过阈值
    if (velocity > widget.swipeVelocityThreshold) {
      shouldReturn = true;
    }

    if (shouldReturn) {
      _performSwipeBack();
    } else {
      _resetPosition();
    }
  }

  void _performSwipeBack() {
    _swipeAnimationController.forward().then((_) {
      widget.onSwipeBack?.call();
    });
  }

  void _resetPosition() {
    setState(() {
      _dragDistance = 0.0;
    });
  }
}

/// 图集详情页手势包装器
/// 为图集详情页添加手势导航功能
class AlbumDetailGestureWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;

  const AlbumDetailGestureWrapper({
    super.key,
    required this.child,
    this.onSwipeBack,
  });

  @override
  Widget build(BuildContext context) {
    return AlbumGestureHandler(
      onSwipeBack: onSwipeBack ?? () => Navigator.of(context).pop(),
      child: child,
    );
  }
}

/// 图集卡片手势处理器
/// 为图集卡片添加点击和手势反馈
class AlbumCardGestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration animationDuration;

  const AlbumCardGestureHandler({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  @override
  State<AlbumCardGestureHandler> createState() => _AlbumCardGestureHandlerState();
}

class _AlbumCardGestureHandlerState extends State<AlbumCardGestureHandler>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rippleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              children: [
                widget.child,
                if (_rippleAnimation.value > 0)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(
                          0.1 * (1.0 - _rippleAnimation.value),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
    _rippleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    _rippleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
    _rippleController.reverse();
  }
}


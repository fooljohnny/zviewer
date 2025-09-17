import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GestureHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const GestureHandler({
    super.key,
    required this.child,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<GestureHandler> createState() => _GestureHandlerState();
}

class _GestureHandlerState extends State<GestureHandler> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowLeft:
              widget.onPrevious?.call();
              break;
            case LogicalKeyboardKey.arrowRight:
              widget.onNext?.call();
              break;
            case LogicalKeyboardKey.escape:
              // Could be used to exit fullscreen or close viewer
              break;
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          // Single tap - could be used to toggle controls
        },
        onDoubleTap: () {
          // Double tap - could be used to zoom in/out
        },
        onPanUpdate: (details) {
          // Pan gesture for navigation
          final delta = details.delta.dx;
          if (delta.abs() > 50) { // Threshold for swipe
            if (delta > 0) {
              // Swipe right - go to previous
              widget.onPrevious?.call();
            } else {
              // Swipe left - go to next
              widget.onNext?.call();
            }
          }
        },
        child: widget.child,
      ),
    );
  }
}

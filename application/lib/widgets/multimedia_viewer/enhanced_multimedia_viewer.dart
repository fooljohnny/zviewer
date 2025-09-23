import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../comments/danmaku_overlay.dart';
import '../common/glassmorphism_card.dart';

/// 增强版多媒体查看器
/// 集成弹幕评论系统和毛玻璃效果
class EnhancedMultimediaViewer extends StatefulWidget {
  final String mediaPath;
  final String mediaId;
  final List<DanmakuComment> comments;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(String content)? onCommentSubmit;
  final bool showComments;
  final VoidCallback? onToggleComments;

  const EnhancedMultimediaViewer({
    super.key,
    required this.mediaPath,
    required this.mediaId,
    this.comments = const [],
    this.onPrevious,
    this.onNext,
    this.onCommentSubmit,
    this.showComments = true,
    this.onToggleComments,
  });

  @override
  State<EnhancedMultimediaViewer> createState() => _EnhancedMultimediaViewerState();
}

class _EnhancedMultimediaViewerState extends State<EnhancedMultimediaViewer>
    with TickerProviderStateMixin {
  late VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _showCommentInput = false;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
    _setupControlsAnimation();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _controlsAnimationController.dispose();
    super.dispose();
  }

  void _initializeMedia() {
    final extension = widget.mediaPath.toLowerCase().split('.').last;
    _isVideo = ['mp4', 'webm', 'mov'].contains(extension);
    
    if (_isVideo) {
      _videoController = VideoPlayerController.network(widget.mediaPath);
      _videoController!.initialize().then((_) {
        setState(() {});
      });
    }
  }

  void _setupControlsAnimation() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _togglePlayPause() {
    if (_isVideo && _videoController != null) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    
    if (_showControls) {
      _controlsAnimationController.forward();
    } else {
      _controlsAnimationController.reverse();
    }
  }

  void _toggleCommentInput() {
    setState(() {
      _showCommentInput = !_showCommentInput;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 媒体内容
          _buildMediaContent(),
          
          // 弹幕覆盖层
          if (widget.showComments)
            DanmakuOverlay(
              comments: widget.comments,
              isVisible: widget.showComments,
              onCommentTap: () {
                // 处理弹幕点击
              },
              onToggleVisibility: widget.onToggleComments,
            ),
          
          // 控制栏
          if (_showControls)
            _buildControls(),
          
          // 评论输入
          if (_showCommentInput)
            _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_isVideo && _videoController != null) {
      return Center(
        child: _videoController!.value.isInitialized
            ? AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            : const CircularProgressIndicator(),
      );
    } else {
      return PhotoView(
        imageProvider: NetworkImage(widget.mediaPath),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        onTapUp: (context, details, controllerValue) {
          _toggleControls();
        },
      );
    }
  }

  Widget _buildControls() {
    return AnimatedBuilder(
      animation: _controlsAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _controlsAnimation.value.clamp(0.0, 1.0),
          child: Stack(
            children: [
              // 顶部控制栏
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 返回按钮
                      GlassmorphismButton(
                        onPressed: () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      
                      // 标题
                      const Text(
                        'ZViewer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // 更多选项
                      Row(
                        children: [
                          // 弹幕开关
                          GlassmorphismButton(
                            onPressed: widget.onToggleComments,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              widget.showComments 
                                  ? Icons.comment 
                                  : Icons.comment_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 评论输入
                          GlassmorphismButton(
                            onPressed: _toggleCommentInput,
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部控制栏
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 上一个
                      if (widget.onPrevious != null)
                        GlassmorphismButton(
                          onPressed: widget.onPrevious,
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.skip_previous,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      
                      // 播放/暂停
                      if (_isVideo)
                        GlassmorphismButton(
                          onPressed: _togglePlayPause,
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      
                      // 下一个
                      if (widget.onNext != null)
                        GlassmorphismButton(
                          onPressed: widget.onNext,
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: DanmakuInput(
        onSubmit: (content) {
          widget.onCommentSubmit?.call(content);
          _toggleCommentInput();
        },
        hintText: '发送弹幕评论...',
      ),
    );
  }
}

/// 多媒体详情页面
class MultimediaDetailPage extends StatefulWidget {
  final List<String> mediaPaths;
  final int initialIndex;
  final List<DanmakuComment> comments;

  const MultimediaDetailPage({
    super.key,
    required this.mediaPaths,
    this.initialIndex = 0,
    this.comments = const [],
  });

  @override
  State<MultimediaDetailPage> createState() => _MultimediaDetailPageState();
}

class _MultimediaDetailPageState extends State<MultimediaDetailPage> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showComments = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNext() {
    if (_currentIndex < widget.mediaPaths.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onCommentSubmit(String content) {
    // 处理评论提交
    print('New comment: $content');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.mediaPaths.length,
        itemBuilder: (context, index) {
          return EnhancedMultimediaViewer(
            mediaPath: widget.mediaPaths[index],
            mediaId: widget.mediaPaths[index].hashCode.toString(),
            comments: widget.comments,
            onPrevious: index > 0 ? _onPrevious : null,
            onNext: index < widget.mediaPaths.length - 1 ? _onNext : null,
            onCommentSubmit: _onCommentSubmit,
            showComments: _showComments,
            onToggleComments: () {
              setState(() {
                _showComments = !_showComments;
              });
            },
          );
        },
      ),
    );
  }
}



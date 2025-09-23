import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../comments/enhanced_danmaku_overlay.dart';
import '../common/glassmorphism_card.dart';
import '../../services/danmaku_service.dart';
import '../../providers/danmaku_provider.dart';
import 'package:provider/provider.dart';

/// 增强版多媒体详情页面
/// 集成弹幕评论系统和毛玻璃效果
class EnhancedDetailPage extends StatefulWidget {
  final String mediaPath;
  final String mediaId;
  final String? title;
  final String? description;
  final List<String>? relatedMedia;
  final int initialIndex;

  const EnhancedDetailPage({
    super.key,
    required this.mediaPath,
    required this.mediaId,
    this.title,
    this.description,
    this.relatedMedia,
    this.initialIndex = 0,
  });

  @override
  State<EnhancedDetailPage> createState() => _EnhancedDetailPageState();
}

class _EnhancedDetailPageState extends State<EnhancedDetailPage>
    with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _showComments = true;
  bool _showCommentInput = false;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
    _setupAnimations();
    _loadComments();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _controlsAnimationController.dispose();
    _backgroundAnimationController.dispose();
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

  void _setupAnimations() {
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

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));
    
    _backgroundAnimationController.repeat();
  }

  void _loadComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DanmakuProvider>().loadComments(widget.mediaId);
    });
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

  void _toggleComments() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  void _toggleCommentInput() {
    setState(() {
      _showCommentInput = !_showCommentInput;
    });
  }

  void _onCommentSubmit(String content) {
    context.read<DanmakuProvider>().addComment(
      widget.mediaId,
      content,
      '当前用户', // 这里应该从用户状态获取
    );
    _toggleCommentInput();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Stack(
          children: [
            // 媒体内容
            _buildMediaContent(),
            
            // 弹幕覆盖层
            if (_showComments)
              Consumer<DanmakuProvider>(
                builder: (context, danmakuProvider, child) {
                  return EnhancedDanmakuOverlay(
                    comments: danmakuProvider.getComments(widget.mediaId),
                    isVisible: _showComments,
                    onCommentTap: () {
                      // 处理弹幕点击
                    },
                    onToggleVisibility: _toggleComments,
                    onCommentSubmit: _onCommentSubmit,
                    showInput: _showCommentInput,
                  );
                },
              ),
            
            // 控制栏
            if (_showControls)
              _buildControls(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF3A3A3C),
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
                      Expanded(
                        child: Center(
                          child: Text(
                            widget.title ?? 'ZViewer',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      
                      // 更多选项
                      Row(
                        children: [
                          // 弹幕开关
                          GlassmorphismButton(
                            onPressed: _toggleComments,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _showComments 
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
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 媒体信息
                        if (widget.description != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.description!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        
                        // 控制按钮
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
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
                          
                          // 分享按钮
                          GlassmorphismButton(
                            onPressed: _shareMedia,
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          
                          // 收藏按钮
                          GlassmorphismButton(
                            onPressed: _favoriteMedia,
                            padding: const EdgeInsets.all(12),
                            child: const Icon(
                              Icons.favorite_border,
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareMedia() {
    // 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能待实现'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _favoriteMedia() {
    // 实现收藏功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('收藏功能待实现'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}


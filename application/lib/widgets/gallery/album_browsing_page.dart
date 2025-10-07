import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/modern_background.dart';
import '../common/image_thumbnail.dart';
import '../../providers/album_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/comment_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../models/album.dart';
import '../../models/comment.dart';
import '../../utils/album_permissions.dart';
import '../../config/api_config.dart';
import 'album_gesture_handler.dart';

/// 图集浏览页面
/// 采用瀑布式布局展示图集图片，信息在底部，支持评论功能
class AlbumBrowsingPage extends StatefulWidget {
  final Album album;

  const AlbumBrowsingPage({super.key, required this.album});

  @override
  State<AlbumBrowsingPage> createState() => _AlbumBrowsingPageState();
}

class _AlbumBrowsingPageState extends State<AlbumBrowsingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollController();
    _loadAlbumDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    _fadeController.forward();
  }

  void _setupScrollController() {
    _scrollController = ScrollController();
  }

  void _loadAlbumDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().getAlbum(widget.album.id);
      // 增加浏览次数
      context.read<AlbumProvider>().incrementViewCount(widget.album.id);
      // 加载评论
      context.read<CommentProvider>().loadAlbumComments(widget.album.id);
      // 加载收藏状态
      context.read<FavoriteProvider>().loadFavoriteStatus(widget.album.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 检查查看权限
        if (!AlbumPermissions.canViewAlbum(widget.album, authProvider)) {
          return Scaffold(
            body: ModernBackground(
              child: SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '无权限访问',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AlbumPermissions.getVisibilityDescription(widget.album),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('返回'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black, // 设置黑色背景
          body: AlbumDetailGestureWrapper(
            onSwipeBack: () => Navigator.of(context).pop(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  // 主要内容
                  Column(
                    children: [
                      _buildAppBar(authProvider),
                      Expanded(
                        child: _buildAlbumContent(),
                      ),
                    ],
                  ),
                  // 悬浮返回按钮
                  _buildFloatingBackButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AuthProvider authProvider) {
    return const SizedBox.shrink(); // 完全移除，不产生任何间隙
  }

  Widget _buildFloatingBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // 淡淡的半透明背景
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumContent() {
    return Consumer<AlbumProvider>(
      builder: (context, albumProvider, child) {
        final album = albumProvider.currentAlbum ?? widget.album;
        
        if (albumProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 瀑布式图片布局
            _buildWaterfallImages(album),
            // 图集信息
            _buildAlbumInfo(album),
            // 评论区（占位符，将在后续story中实现）
            _buildCommentsSection(album),
          ],
        );
      },
    );
  }

  Widget _buildWaterfallImages(Album album) {
    if (album.images?.isEmpty ?? true) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: Colors.white54,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无图片',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 使用瀑布式布局展示图片
    return _buildWaterfallGrid(album.images!);
  }

  Widget _buildWaterfallGrid(List<AlbumImage> images) {
    return SliverToBoxAdapter(
      child: _WaterfallLayout(
        crossAxisCount: 1, // 单列布局，宽度与屏幕一致
        crossAxisSpacing: 0, // 无间隙
        mainAxisSpacing: 0, // 无间隙
        children: images.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;
          return _buildWaterfallImageItem(image, index);
        }).toList(),
      ),
    );
  }

  Widget _buildWaterfallImageItem(AlbumImage image, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedHeight = _calculateImageHeight(image);
    
    return Container(
      width: screenWidth, // 明确设置宽度为屏幕宽度
      height: calculatedHeight, // 明确设置高度
      color: Colors.black, // 黑色背景填充
      child: ImageThumbnail(
        id: image.imageId ?? '',
        filePath: image.imagePath ?? '',
        mimeType: image.mimeType ?? 'image/jpeg',
        skipThumbnail: true, // 强制跳过缩略图，直接使用原图
        width: screenWidth, // 明确设置宽度为屏幕宽度
        height: calculatedHeight, // 明确设置高度
        fit: BoxFit.contain, // 完整显示图片，保持宽高比，不裁剪
        borderRadius: BorderRadius.zero,
      ),
    );
  }

  double _calculateImageHeight(AlbumImage image) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = image.width?.toDouble() ?? 0.0;
    final height = image.height?.toDouble() ?? 0.0;
    
    // 详细的调试信息
    if (ApiConfig.isDevelopment) {
      print('🖼️ ===== Image Height Calculation Debug =====');
      print('🖼️ Image ID: ${image.imageId}');
      print('🖼️ Image Path: ${image.imagePath}');
      print('🖼️ MIME Type: ${image.mimeType}');
      print('🖼️ Raw Width: ${image.width} (${width})');
      print('🖼️ Raw Height: ${image.height} (${height})');
      print('🖼️ Screen Width: $screenWidth');
      print('🖼️ Width is finite: ${width.isFinite}');
      print('🖼️ Height is finite: ${height.isFinite}');
      print('🖼️ Width > 0: ${width > 0}');
      print('🖼️ Height > 0: ${height > 0}');
    }
    
    // 如果宽高信息不可用或异常，使用合理的默认高度
    if (width <= 0 || height <= 0 || !width.isFinite || !height.isFinite) {
      final defaultHeight = screenWidth * 1.2;
      if (ApiConfig.isDevelopment) {
        print('🖼️ ❌ Invalid dimensions detected:');
        print('🖼️   - Width: $width (valid: ${width > 0 && width.isFinite})');
        print('🖼️   - Height: $height (valid: ${height > 0 && height.isFinite})');
        print('🖼️ ✅ Using default height: $defaultHeight (1.2 aspect ratio)');
        print('🖼️ ===========================================');
      }
      return defaultHeight;
    }
    
    // 根据图片原始宽高比精确计算高度，保持原始比例
    final aspectRatio = width / height;
    
    if (ApiConfig.isDevelopment) {
      print('🖼️ Calculated aspect ratio: $aspectRatio');
    }
    
    // 检查宽高比是否合理，避免极端值
    if (aspectRatio <= 0 || !aspectRatio.isFinite || aspectRatio > 10 || aspectRatio < 0.1) {
      final defaultHeight = screenWidth * 1.2;
      if (ApiConfig.isDevelopment) {
        print('🖼️ ❌ Invalid aspect ratio detected:');
        print('🖼️   - Aspect Ratio: $aspectRatio');
        print('🖼️   - Is finite: ${aspectRatio.isFinite}');
        print('🖼️   - Is > 0: ${aspectRatio > 0}');
        print('🖼️   - Is <= 10: ${aspectRatio <= 10}');
        print('🖼️   - Is >= 0.1: ${aspectRatio >= 0.1}');
        print('🖼️ ✅ Using default height: $defaultHeight');
        print('🖼️ ===========================================');
      }
      return defaultHeight;
    }
    
    double calculatedHeight = screenWidth / aspectRatio;
    
    // 设置合理的高度范围，避免图片过高或过低
    final minHeight = screenWidth * 0.5; // 最小高度为屏幕宽度的50%
    final maxHeight = screenWidth * 3.0; // 最大高度为屏幕宽度的300%
    
    final originalHeight = calculatedHeight;
    final wasClamped = false;
    
    if (calculatedHeight < minHeight) {
      calculatedHeight = minHeight;
    } else if (calculatedHeight > maxHeight) {
      calculatedHeight = maxHeight;
    }
    
    if (ApiConfig.isDevelopment) {
      print('🖼️ ✅ Valid dimensions and aspect ratio:');
      print('🖼️   - Original Width: $width');
      print('🖼️   - Original Height: $height');
      print('🖼️   - Aspect Ratio: $aspectRatio');
      print('🖼️   - Calculated Height: $originalHeight');
      print('🖼️   - Min Height: $minHeight');
      print('🖼️   - Max Height: $maxHeight');
      print('🖼️   - Final Height: $calculatedHeight');
      print('🖼️   - Was Clamped: ${calculatedHeight != originalHeight}');
      print('🖼️ ===========================================');
    }
    
    return calculatedHeight;
  }


  Widget _buildAlbumInfo(Album album) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述
            if (album.description.isNotEmpty)
              Text(
                album.displayDescription,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            const SizedBox(height: 16),
            // 统计信息
            _buildStatsRow(album),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsRow(Album album) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        return Row(
          children: [
            _buildStatItem(
              icon: Icons.visibility,
              label: '浏览',
              value: '${album.viewCount}次',
            ),
            const SizedBox(width: 24),
            _buildStatItem(
              icon: Icons.favorite,
              label: '点赞',
              value: '${album.likeCount}个',
            ),
            const SizedBox(width: 24),
            _buildFavoriteButton(album, favoriteProvider),
          ],
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton(Album album, FavoriteProvider favoriteProvider) {
    final isFavorited = favoriteProvider.isFavorited(album.id);
    final isToggling = favoriteProvider.isToggling(album.id);
    
    return GestureDetector(
      onTap: isToggling ? null : () => _toggleFavorite(album, favoriteProvider),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isToggling)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  isFavorited ? Icons.star : Icons.star_border,
                  size: 16,
                  color: isFavorited ? Colors.amber : Colors.white.withValues(alpha: 0.7),
                ),
              const SizedBox(width: 4),
              Text(
                '收藏',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${album.favoriteCount ?? 0}个',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(Album album, FavoriteProvider favoriteProvider) {
    favoriteProvider.toggleFavorite(album.id).then((_) {
      if (!mounted) return;
      if (favoriteProvider.getError(album.id) != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(favoriteProvider.getError(album.id)!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Widget _buildCommentsSection(Album album) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '评论区',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Consumer<CommentProvider>(
              builder: (context, commentProvider, child) {
                if (commentProvider.isLoading(album.id)) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                }

                final comments = commentProvider.getComments(album.id);
                
                if (comments.isEmpty) {
                  return _buildEmptyComments();
                }

                return Column(
                  children: [
                    _buildCommentList(comments, commentProvider),
                    const SizedBox(height: 16),
                    _buildCommentInput(album.id, commentProvider),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无评论',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '成为第一个评论的人吧！',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList(List<Comment> comments, CommentProvider commentProvider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return _buildCommentItem(comment, commentProvider);
      },
    );
  }

  Widget _buildCommentItem(Comment comment, CommentProvider commentProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      comment.formattedCreatedAt,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final canDelete = authProvider.isAdmin || 
                      (authProvider.user?.id == comment.authorId);
                  
                  if (canDelete) {
                    return PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteCommentDialog(comment, commentProvider);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.displayContent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _toggleCommentLike(comment, commentProvider),
                child: Row(
                  children: [
                    Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: comment.isLiked ? Colors.red : Colors.white.withValues(alpha: 0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comment.likeCount}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(String albumId, CommentProvider commentProvider) {
    final TextEditingController controller = TextEditingController();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '写下你的评论...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              maxLines: null,
              onSubmitted: (value) => _submitComment(albumId, value, commentProvider, controller),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: commentProvider.isSubmitting(albumId) 
                ? null 
                : () => _submitComment(albumId, controller.text, commentProvider, controller),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: commentProvider.isSubmitting(albumId)
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment(String albumId, String content, CommentProvider commentProvider, TextEditingController controller) {
    if (content.trim().isEmpty) return;
    
    commentProvider.addComment(albumId, content.trim()).then((success) {
      if (!mounted) return;
      
      if (success) {
        controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论发布成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(commentProvider.getError(albumId) ?? '评论发布失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _toggleCommentLike(Comment comment, CommentProvider commentProvider) {
    if (comment.isLiked) {
      commentProvider.unlikeComment(widget.album.id, comment.id);
    } else {
      commentProvider.likeComment(widget.album.id, comment.id);
    }
  }

  void _showDeleteCommentDialog(Comment comment, CommentProvider commentProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              commentProvider.deleteComment(widget.album.id, comment.id).then((success) {
                if (!mounted) return;
                
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('评论已删除')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(commentProvider.getError(widget.album.id) ?? '删除失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

}

/// 瀑布式布局组件
class _WaterfallLayout extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const _WaterfallLayout({
    required this.children,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  });

  @override
  State<_WaterfallLayout> createState() => _WaterfallLayoutState();
}

class _WaterfallLayoutState extends State<_WaterfallLayout> {
  List<double> _columnHeights = [];
  List<List<Widget>> _columnChildren = [];

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _distributeChildren();
  }

  @override
  void didUpdateWidget(_WaterfallLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children != widget.children ||
        oldWidget.crossAxisCount != widget.crossAxisCount) {
      _initializeColumns();
      _distributeChildren();
    }
  }

  void _initializeColumns() {
    _columnHeights = List.filled(widget.crossAxisCount, 0.0);
    _columnChildren = List.generate(widget.crossAxisCount, (_) => []);
  }

  void _distributeChildren() {
    _initializeColumns();
    
    for (int i = 0; i < widget.children.length; i++) {
      final child = widget.children[i];
      final childHeight = _estimateChildHeight(child);
      
      // 找到最短的列
      int shortestColumnIndex = 0;
      for (int j = 1; j < widget.crossAxisCount; j++) {
        if (_columnHeights[j] < _columnHeights[shortestColumnIndex]) {
          shortestColumnIndex = j;
        }
      }
      
      // 将子组件添加到最短的列
      _columnChildren[shortestColumnIndex].add(child);
      _columnHeights[shortestColumnIndex] += childHeight + widget.mainAxisSpacing;
    }
  }

  double _estimateChildHeight(Widget child) {
    // 简单的估算高度，实际项目中可能需要更复杂的计算
    if (child is AspectRatio) {
      return 200.0; // 默认高度
    }
    return 200.0; // 默认高度
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.crossAxisCount, (columnIndex) {
        Widget columnChild = Column(
          children: _columnChildren[columnIndex].map((child) {
            if (widget.mainAxisSpacing == 0) {
              return child; // 无间距时直接返回子组件
            }
            return Padding(
              padding: EdgeInsets.only(
                bottom: _columnChildren[columnIndex].last == child 
                    ? 0 
                    : widget.mainAxisSpacing,
              ),
              child: child,
            );
          }).toList(),
        );
        
        if (widget.crossAxisSpacing == 0) {
          return Expanded(child: columnChild); // 无间距时直接返回
        }
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: columnIndex < widget.crossAxisCount - 1 
                  ? widget.crossAxisSpacing / 2 
                  : 0,
              left: columnIndex > 0 
                  ? widget.crossAxisSpacing / 2 
                  : 0,
            ),
            child: columnChild,
          ),
        );
      }),
    );
  }
}

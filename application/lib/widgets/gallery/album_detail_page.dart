import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/modern_background.dart';
import '../common/image_thumbnail.dart';
import '../../providers/album_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/album.dart';
import '../../models/content_item.dart';
import '../../utils/album_permissions.dart';
import '../multimedia_viewer/multimedia_viewer.dart';
import '../admin/album_analytics.dart';
import 'album_gesture_handler.dart';

/// 图集详情页
/// 用户查看图集详细信息和图片的页面
class AlbumDetailPage extends StatefulWidget {
  final Album album;

  const AlbumDetailPage({super.key, required this.album});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAlbumDetails();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  void _loadAlbumDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().getAlbum(widget.album.id);
      // 增加浏览次数
      context.read<AlbumProvider>().incrementViewCount(widget.album.id);
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
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '无权限访问',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AlbumPermissions.getVisibilityDescription(widget.album),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
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
          body: AlbumDetailGestureWrapper(
            onSwipeBack: () => Navigator.of(context).pop(),
            child: ModernBackground(
              child: SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(authProvider),
                      Expanded(
                        child: _buildAlbumContent(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Expanded(
            child: Text(
              widget.album.displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 更多操作按钮
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareAlbum();
                  break;
                case 'analytics':
                  _viewAnalytics(authProvider);
                  break;
                case 'report':
                  _reportAlbum();
                  break;
                case 'edit':
                  _editAlbum(authProvider);
                  break;
                case 'delete':
                  _deleteAlbum(authProvider);
                  break;
              }
            },
            itemBuilder: (context) {
              final canEdit = AlbumPermissions.canEditAlbum(widget.album, authProvider);
              final canDelete = AlbumPermissions.canDeleteAlbum(widget.album, authProvider);
              final canViewStats = AlbumPermissions.canViewAlbumStats(widget.album, authProvider);
              
              return [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('分享'),
                    ],
                  ),
                ),
                if (canViewStats)
                  const PopupMenuItem(
                    value: 'analytics',
                    child: Row(
                      children: [
                        Icon(Icons.analytics),
                        SizedBox(width: 8),
                        Text('分析'),
                      ],
                    ),
                  ),
                if (canEdit)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('编辑'),
                      ],
                    ),
                  ),
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.red),
                      SizedBox(width: 8),
                      Text('举报', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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

        return SingleChildScrollView(
          child: Column(
            children: [
              // 图集头部信息
              _buildAlbumHeader(album),
              const SizedBox(height: 24),
              // 图片网格
              _buildImageGrid(album),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumHeader(Album album) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 封面图片
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: album.hasCover
                  ? ImageThumbnail(
                      id: album.coverImageId,
                      thumbnailPath: album.coverThumbnailPath,
                      filePath: album.coverImageUrl!,
                      mimeType: 'image/jpeg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.photo_album,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          // 图集信息
          _buildAlbumInfo(album),
        ],
      ),
    );
  }

  Widget _buildAlbumInfo(Album album) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和状态
        Row(
          children: [
            Expanded(
              child: Text(
                album.displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusChip(album.status),
          ],
        ),
        const SizedBox(height: 8),
        // 描述
        if (album.description.isNotEmpty)
          Text(
            album.displayDescription,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        const SizedBox(height: 16),
        // 统计信息
        _buildStatsRow(album),
        const SizedBox(height: 16),
        // 标签
        if (album.tags.isNotEmpty) _buildTagsSection(album),
      ],
    );
  }

  Widget _buildStatusChip(AlbumStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case AlbumStatus.draft:
        color = Colors.grey;
        text = '草稿';
        icon = Icons.edit;
        break;
      case AlbumStatus.published:
        color = Colors.green;
        text = '已发布';
        icon = Icons.public;
        break;
      case AlbumStatus.archived:
        color = Colors.orange;
        text = '已归档';
        icon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Album album) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.person,
          label: '作者',
          value: album.userName,
        ),
        const SizedBox(width: 24),
        _buildStatItem(
          icon: Icons.photo,
          label: '图片',
          value: album.imageCountDisplayText,
        ),
        const SizedBox(width: 24),
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
      ],
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
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
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

  Widget _buildTagsSection(Album album) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '标签',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: album.tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageGrid(Album album) {
    if (album.images.isEmpty) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
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
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: album.images.length,
        itemBuilder: (context, index) {
          final image = album.images[index];
          return _buildImageThumbnail(image, index);
        },
      ),
    );
  }

  Widget _buildImageThumbnail(ContentItem image, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(image, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ImageThumbnail(
            id: image.id,
            thumbnailPath: image.thumbnailPath,
            filePath: image.filePath,
            mimeType: image.mimeType,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),
    );
  }

  void _openImageViewer(ContentItem image, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultimediaViewer(
          mediaPath: image.filePath,
          onPrevious: index > 0 ? () {
            final album = context.read<AlbumProvider>().currentAlbum ?? widget.album;
            if (index > 0) {
              final prevImage = album.images[index - 1];
              _openImageViewer(prevImage, index - 1);
            }
          } : null,
          onNext: () {
            final album = context.read<AlbumProvider>().currentAlbum ?? widget.album;
            if (index < album.images.length - 1) {
              final nextImage = album.images[index + 1];
              _openImageViewer(nextImage, index + 1);
            }
          },
        ),
      ),
    );
  }

  void _shareAlbum() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中')),
    );
  }

  void _viewAnalytics(AuthProvider authProvider) {
    if (!AlbumPermissions.canViewAlbumStats(widget.album, authProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AlbumPermissions.getPermissionErrorMessage('view_stats', widget.album)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumAnalyticsView(album: widget.album),
      ),
    );
  }

  void _reportAlbum() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('举报图集'),
        content: const Text('您确定要举报这个图集吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('举报已提交')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('举报'),
          ),
        ],
      ),
    );
  }

  void _editAlbum(AuthProvider authProvider) {
    if (!AlbumPermissions.canEditAlbum(widget.album, authProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AlbumPermissions.getPermissionErrorMessage('edit', widget.album)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: 导航到编辑页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中')),
    );
  }

  void _deleteAlbum(AuthProvider authProvider) {
    if (!AlbumPermissions.canDeleteAlbum(widget.album, authProvider)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AlbumPermissions.getPermissionErrorMessage('delete', widget.album)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图集'),
        content: Text('您确定要删除"${widget.album.title}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AlbumProvider>().deleteAlbum(widget.album.id);
              Navigator.of(context).pop(); // 返回上一页
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/modern_background.dart';
import '../common/zviewer_logo.dart';
import 'album_waterfall_grid.dart';
import 'album_detail_page.dart';
import '../../providers/album_provider.dart';
import '../../models/album.dart';

/// 图集主页
/// 显示公开图集的瀑布式布局
class AlbumHomepage extends StatefulWidget {
  const AlbumHomepage({super.key});

  @override
  State<AlbumHomepage> createState() => _AlbumHomepageState();
}

class _AlbumHomepageState extends State<AlbumHomepage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _backgroundAnimationController.repeat();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().loadPublicAlbums(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: _buildAlbumContent(),
        ),
      ),
    );
  }


  Widget _buildAlbumContent() {
    return Consumer<AlbumProvider>(
      builder: (context, albumProvider, child) {
        if (albumProvider.isLoading && albumProvider.albums.isEmpty) {
          return _buildLoadingState();
        }

        if (albumProvider.albums.isEmpty && !albumProvider.isLoading) {
          return _buildEmptyState();
        }

        return AlbumWaterfallGrid(
          albums: albumProvider.albums,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onLoadMore: () {
            albumProvider.loadMoreAlbums();
          },
          isLoading: albumProvider.isLoadingMore,
          hasMore: albumProvider.currentPage < albumProvider.totalPages,
          mobileCardHeight: MediaQuery.of(context).size.height * 0.6,
          desktopCardMinWidth: 300,
          desktopCardMaxWidth: 400,
          onAlbumTap: (album) => _navigateToAlbumDetail(album),
        );
      },
    );
  }


  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ZViewerLogoAnimated(size: 64),
          const SizedBox(height: 24),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            '加载图集中...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无图集',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '管理员可以创建图集来展示内容',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAlbumDetail(Album album) {
    // 导航到图集详情页
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumDetailPage(album: album),
      ),
    );
  }
}

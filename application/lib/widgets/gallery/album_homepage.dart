import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/modern_background.dart';
import '../common/zviewer_logo.dart';
import 'album_waterfall_grid.dart';
import 'album_browsing_page.dart';
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
  late ScrollController _scrollController;
  double _savedScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupScrollController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    
    _backgroundAnimationController.repeat();
  }

  void _setupScrollController() {
    _scrollController = ScrollController();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 加载用户自己的图集，而不是公开图集
      context.read<AlbumProvider>().loadAlbums(refresh: true);
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
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          onLoadMore: () {
            albumProvider.loadMoreAlbums();
          },
          isLoading: albumProvider.isLoadingMore,
          hasMore: albumProvider.currentPage < albumProvider.totalPages,
          mobileCardHeight: MediaQuery.of(context).size.height * 0.6,
          desktopCardMinWidth: 300,
          desktopCardMaxWidth: 400,
          onAlbumTap: (album) => _navigateToAlbumDetail(album),
          scrollController: _scrollController,
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
    // 保存当前滚动位置
    _savedScrollPosition = _scrollController.offset;
    
    // 导航到图集浏览页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumBrowsingPage(album: album),
      ),
    ).then((_) {
      // 返回时恢复滚动位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _savedScrollPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }
}

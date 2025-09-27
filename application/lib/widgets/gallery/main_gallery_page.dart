import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/modern_background.dart';
import '../common/zviewer_logo.dart';
import 'responsive_waterfall_grid.dart';
import '../../providers/content_management_provider.dart';
import '../../models/content_item.dart';

/// 主画廊页面
/// 集成响应式瀑布式布局和毛玻璃效果
class MainGalleryPage extends StatefulWidget {
  const MainGalleryPage({super.key});

  @override
  State<MainGalleryPage> createState() => _MainGalleryPageState();
}

class _MainGalleryPageState extends State<MainGalleryPage>
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
      context.read<ContentManagementProvider>().loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _buildGalleryContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAppBar() {
    return const SizedBox.shrink(); // 移除搜索按钮，返回空组件
  }

  Widget _buildGalleryContent() {
    return Consumer<ContentManagementProvider>(
      builder: (context, contentProvider, child) {
        if (contentProvider.isLoading && contentProvider.content.isEmpty) {
          return _buildLoadingState();
        }

        final waterfallItems = _convertToWaterfallItems(contentProvider.content);

        return ResponsiveWaterfallGrid(
          items: waterfallItems,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onLoadMore: () {
            // 加载更多内容
            // contentProvider.loadMoreContent();
          },
          isLoading: contentProvider.isLoading,
          hasMore: true,
          mobileCardHeight: MediaQuery.of(context).size.height * 0.6,
          desktopCardMinWidth: 300,
          desktopCardMaxWidth: 400,
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
            '加载中...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }



  List<WaterfallItem> _convertToWaterfallItems(List<ContentItem> content) {
    return content.map((item) {
      return WaterfallItem(
        id: item.id,
        imageUrl: item.filePath,
        title: item.title,
        subtitle: item.description,
        aspectRatio: _calculateAspectRatio(item),
        onTap: () => _navigateToDetail(item),
        thumbnailPath: item.thumbnailPath,
        mimeType: item.mimeType,
        metadata: {
          'type': item.type.toString().split('.').last,
          'createdAt': item.uploadedAt,
          'author': item.userName,
        },
      );
    }).toList();
  }

  double _calculateAspectRatio(ContentItem item) {
    final width = item.metadata['width']?.toDouble() ?? 1.0;
    final height = item.metadata['height']?.toDouble() ?? 1.0;
    return width / height;
  }

  void _navigateToDetail(ContentItem item) {
    // 导航到详情页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Placeholder(), // 这里应该是详情页面
      ),
    );
  }

}

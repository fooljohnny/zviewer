import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';
import 'responsive_waterfall_grid.dart';
import '../../providers/content_management_provider.dart';

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
  late Animation<double> _backgroundAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
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

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentManagementProvider>().loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
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
      floatingActionButton: _buildFloatingActionButton(),
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo
          const ZViewerLogoSmall(),
          const SizedBox(width: 12),
          
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ZViewer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '多媒体画廊',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // 搜索按钮
          GlassmorphismButton(
            onPressed: _toggleSearch,
            padding: const EdgeInsets.all(8),
            child: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    return Consumer<ContentManagementProvider>(
      builder: (context, contentProvider, child) {
        if (contentProvider.isLoading && contentProvider.content.isEmpty) {
          return _buildLoadingState();
        }

        final filteredContent = _filterContent(contentProvider.content);
        final waterfallItems = _convertToWaterfallItems(filteredContent);

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

  Widget _buildFloatingActionButton() {
    return GlassmorphismButton(
      onPressed: _showAddContentDialog,
      padding: const EdgeInsets.all(16),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  List<dynamic> _filterContent(List<dynamic> content) {
    if (_searchQuery.isEmpty) return content;
    
    return content.where((item) {
      final title = item['title']?.toString().toLowerCase() ?? '';
      final description = item['description']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  List<WaterfallItem> _convertToWaterfallItems(List<dynamic> content) {
    return content.map((item) {
      return WaterfallItem(
        id: item['id']?.toString() ?? '',
        imageUrl: item['imageUrl']?.toString() ?? '',
        title: item['title']?.toString(),
        subtitle: item['description']?.toString(),
        aspectRatio: _calculateAspectRatio(item),
        onTap: () => _navigateToDetail(item),
        metadata: {
          'type': item['type']?.toString() ?? 'image',
          'createdAt': item['createdAt'],
          'author': item['author'],
        },
      );
    }).toList();
  }

  double _calculateAspectRatio(Map<String, dynamic> item) {
    final width = item['width']?.toDouble() ?? 1.0;
    final height = item['height']?.toDouble() ?? 1.0;
    return width / height;
  }

  void _navigateToDetail(Map<String, dynamic> item) {
    // 导航到详情页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Placeholder(), // 这里应该是详情页面
      ),
    );
  }

  void _showAddContentDialog() {
    showDialog(
      context: context,
      builder: (context) => GlassmorphismCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '添加内容',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '选择要添加的内容类型',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAddOption(
                  icon: Icons.photo_camera,
                  label: '拍照',
                  onTap: () {
                    Navigator.pop(context);
                    // 实现拍照功能
                  },
                ),
                _buildAddOption(
                  icon: Icons.photo_library,
                  label: '相册',
                  onTap: () {
                    Navigator.pop(context);
                    // 实现相册选择功能
                  },
                ),
                _buildAddOption(
                  icon: Icons.videocam,
                  label: '录像',
                  onTap: () {
                    Navigator.pop(context);
                    // 实现录像功能
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '取消',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

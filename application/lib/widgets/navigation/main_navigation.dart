import 'package:flutter/material.dart';
import '../gallery/main_gallery_page.dart';
import '../gallery/responsive_demo_page.dart';
import '../gallery/layout_test_tool.dart';
import '../multimedia_viewer/enhanced_detail_page.dart';
import '../comments/danmaku_demo_page.dart';
import '../demo/feature_showcase.dart';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';

/// 主导航页面
/// 提供不同功能的入口
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      title: '功能展示',
      icon: Icons.star,
      page: FeatureShowcase(),
    ),
    const NavigationItem(
      title: '主画廊',
      icon: Icons.photo_library,
      page: MainGalleryPage(),
    ),
    const NavigationItem(
      title: '响应式演示',
      icon: Icons.grid_view,
      page: ResponsiveDemoPage(),
    ),
    const NavigationItem(
      title: '布局测试',
      icon: Icons.tune,
      page: LayoutTestTool(),
    ),
    const NavigationItem(
      title: '详情页面',
      icon: Icons.visibility,
      page: EnhancedDetailPage(
        mediaPath: 'https://picsum.photos/800/600?random=1',
        mediaId: 'demo_1',
        title: '演示图片',
        description: '这是一个演示详情页面，展示了弹幕评论系统和毛玻璃效果。',
      ),
    ),
    const NavigationItem(
      title: '弹幕演示',
      icon: Icons.chat_bubble_outline,
      page: DanmakuDemoPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1C1C1E),
              Color(0xFF2C2C2E),
              Color(0xFF3A3A3C),
            ],
          ),
        ),
        child: Row(
          children: [
            // 侧边栏
            _buildSidebar(),
            
            // 主内容区域
            Expanded(
              child: _navigationItems[_selectedIndex].page,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo区域
          Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              children: [
                ZViewerLogoMedium(),
                SizedBox(height: 16),
                Text(
                  'ZViewer',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '多媒体查看器',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // 导航菜单
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GlassmorphismButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected ? Colors.blue : Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // 底部信息
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  '版本 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '响应式多媒体查看器',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 导航项数据模型
class NavigationItem {
  final String title;
  final IconData icon;
  final Widget page;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.page,
  });
}

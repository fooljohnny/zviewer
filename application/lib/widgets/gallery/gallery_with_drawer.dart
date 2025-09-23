import 'package:flutter/material.dart';
import 'dart:ui';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';
import '../profile/profile_page.dart';
import 'main_gallery_page.dart';

/// 带抽屉的主画廊页面
/// 包含左侧抽屉和个人中心功能
class GalleryWithDrawer extends StatefulWidget {
  const GalleryWithDrawer({super.key});

  @override
  State<GalleryWithDrawer> createState() => _GalleryWithDrawerState();
}

class _GalleryWithDrawerState extends State<GalleryWithDrawer>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _drawerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _drawerAnimationController.forward();
  }

  void _closeDrawer() {
    _drawerAnimationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // 主内容
          const MainGalleryPage(),
          
          // 抽屉遮罩
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, child) {
              if (_drawerAnimation.value == 0) {
                return const SizedBox.shrink();
              }
              
              return GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.5 * _drawerAnimation.value),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          
          // 左侧抽屉
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -MediaQuery.of(context).size.width * 0.8 * (1 - _drawerAnimation.value),
                  0,
                ),
                child: _buildDrawer(),
              );
            },
          ),
          
          // 悬浮菜单按钮
          _buildFloatingMenuButton(),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1C1E),
            Color(0xFF2C2C2E),
            Color(0xFF3A3A3C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 抽屉头部
            _buildDrawerHeader(),
            
            // 菜单项
            Expanded(
              child: _buildMenuItems(),
            ),
            
            // 抽屉底部
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const ZViewerLogoMedium(),
          const SizedBox(width: 16),
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
                  '多媒体查看器',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _closeDrawer,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildMenuItem(
          icon: Icons.person,
          title: '个人中心',
          subtitle: '管理账户信息',
          onTap: () {
            _closeDrawer();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          },
        ),
        
        _buildMenuItem(
          icon: Icons.photo_library,
          title: '我的收藏',
          subtitle: '查看收藏的内容',
          onTap: () {
            _closeDrawer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('收藏功能开发中')),
            );
          },
        ),
        
        _buildMenuItem(
          icon: Icons.history,
          title: '浏览历史',
          subtitle: '查看最近浏览的内容',
          onTap: () {
            _closeDrawer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('历史记录功能开发中')),
            );
          },
        ),
        
        _buildMenuItem(
          icon: Icons.settings,
          title: '设置',
          subtitle: '应用设置和偏好',
          onTap: () {
            _closeDrawer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('设置功能开发中')),
            );
          },
        ),
        
        _buildMenuItem(
          icon: Icons.help_outline,
          title: '帮助与支持',
          subtitle: '获取使用帮助',
          onTap: () {
            _closeDrawer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('帮助功能开发中')),
            );
          },
        ),
        
        _buildMenuItem(
          icon: Icons.info_outline,
          title: '关于',
          subtitle: '版本信息和应用详情',
          onTap: () {
            _closeDrawer();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('关于页面开发中')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphismCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Divider(
            color: Colors.white24,
            height: 1,
          ),
          const SizedBox(height: 16),
          Text(
            'ZViewer v1.0.0',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          Text(
            '© 2024 ZViewer Team',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMenuButton() {
    return Positioned(
      top: 50,
      left: 20,
      child: GestureDetector(
        onTap: _openDrawer,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF007AFF),
                Color(0xFF5856D6),
                Color(0xFFFF9500),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: ZViewerLogoSmall(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

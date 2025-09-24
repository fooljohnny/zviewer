import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';
import '../common/glassmorphism_card.dart';
import '../common/modern_background.dart';
import '../common/zviewer_logo.dart';
import '../profile/profile_page.dart';
import '../admin/admin_file_management.dart';
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
      body: ModernBackground(
        child: Stack(
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
              final screenWidth = MediaQuery.of(context).size.width;
              final isMobile = screenWidth < 600;
              final drawerWidth = isMobile ? screenWidth * 0.8 : screenWidth * 0.45;
              
              return Transform.translate(
                offset: Offset(
                  -drawerWidth * (1 - _drawerAnimation.value),
                  0,
                ),
                child: _buildDrawer(),
              );
            },
          ),
          
                    // 悬浮菜单按钮 - 只在抽屉关闭时显示
                    AnimatedBuilder(
                      animation: _drawerAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 16,  // 与搜索按钮同一水平位置
                          left: 16, // 左上角位置
                          child: Transform.scale(
                            scale: 1.0 - _drawerAnimation.value * 0.3, // 稍微缩小
                            child: Opacity(
                              opacity: (1.0 - _drawerAnimation.value) * 0.9,
                              child: _buildFloatingMenuButton(),
                            ),
                          ),
                        );
                      },
                    ),
        ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Container(
      width: isMobile ? screenWidth * 0.8 : screenWidth * 0.45,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D1B69),
            Color(0xFF11998E),
            Color(0xFF38EF7D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(8, 0),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const ZViewerLogo(size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ZViewer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '多媒体查看器',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: IconButton(
              onPressed: _closeDrawer,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAdmin = authProvider.isAdmin;
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 600;
        
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 16),
          children: [
            // 管理员专用菜单项
            if (isAdmin) ...[
              _buildMenuItem(
                icon: Icons.admin_panel_settings,
                title: '管理资源',
                subtitle: '查看和管理多媒体文件',
                isAdmin: true,
                onTap: () {
                  _closeDrawer();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminFileManagement(),
                    ),
                  );
                },
              ),
              _buildDivider(),
            ],
            
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
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isAdmin = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 4 : 6),
      child: GlassmorphismCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: isAdmin ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.purple.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ) : null,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 4 : 6),
                  decoration: BoxDecoration(
                    color: isAdmin 
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isAdmin ? Colors.blue.shade300 : Colors.white,
                    size: isMobile ? 16 : 20,
                  ),
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isAdmin ? Colors.blue.shade300 : Colors.white,
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 4 : 6, 
                                vertical: isMobile ? 1 : 2
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: Colors.blue.shade300,
                                  fontSize: isMobile ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isAdmin 
                              ? Colors.blue.shade200.withOpacity(0.8)
                              : Colors.white.withOpacity(0.6),
                          fontSize: isMobile ? 10 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isAdmin 
                      ? Colors.blue.shade300.withOpacity(0.7)
                      : Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
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
    return GestureDetector(
      onTap: _openDrawer,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.09),
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: ZViewerLogoSmall(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

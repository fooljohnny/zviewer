import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';
import '../admin/admin_file_management.dart';

/// 个人中心页面
/// 展示用户信息和提供修改密码等功能
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Listen to authentication state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    // Remove the listener to prevent memory leaks
    context.read<AuthProvider>().removeListener(_onAuthStateChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    // If user is no longer authenticated, close this page
    if (!context.read<AuthProvider>().isAuthenticated && mounted) {
      // 使用SchedulerBinding确保在下一个帧中安全执行导航操作
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _changePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('新密码和确认密码不匹配'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('新密码长度至少6位'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    // 模拟密码修改
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('密码修改成功'),
            backgroundColor: Colors.green,
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // 关闭确认对话框
              Navigator.of(context).pop();
              
              // 显示退出中的提示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('正在退出登录...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              
              // 执行退出登录 - 这会触发 _onAuthStateChanged 自动关闭页面
              await context.read<AuthProvider>().logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              // 头部区域（带关闭按钮）
              _buildHeader(),
              
              // 内容区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 用户信息卡片
                      _buildUserInfoCard(),
                      const SizedBox(height: 20),
                      
                      // 修改密码卡片
                      _buildChangePasswordCard(),
                      const SizedBox(height: 20),
                      
                      // 其他功能卡片
                      _buildOtherFeaturesCard(),
                      const SizedBox(height: 20),
                      
                      // 退出登录按钮
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          Color(0xFF2D1B69),
          Color(0xFF11998E),
          Color(0xFF38EF7D),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  '个人中心',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '管理您的账户信息',
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
              onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildUserInfoCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        return GlassmorphismCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '账户信息',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('用户名', user?.displayName ?? '未知用户'),
              _buildInfoRow('邮箱', user?.email ?? '未设置'),
              _buildInfoRow('用户ID', user?.id ?? '未知'),
              _buildInfoRow('注册时间', '2024年1月1日'),
              _buildInfoRow('最后登录', '刚刚'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangePasswordCard() {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '修改密码',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          // 当前密码
          _buildPasswordField(
            controller: _currentPasswordController,
            label: '当前密码',
            obscureText: _obscureCurrentPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureCurrentPassword = !_obscureCurrentPassword;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // 新密码
          _buildPasswordField(
            controller: _newPasswordController,
            label: '新密码',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureNewPassword = !_obscureNewPassword;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // 确认密码
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: '确认新密码',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // 修改密码按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '修改密码',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '请输入$label',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withOpacity(0.7),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherFeaturesCard() {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '其他功能',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.settings,
            title: '应用设置',
            subtitle: '个性化您的使用体验',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能开发中')),
              );
            },
          ),
          _buildFeatureItem(
            icon: Icons.help_outline,
            title: '帮助与支持',
            subtitle: '获取使用帮助和技术支持',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('帮助功能开发中')),
              );
            },
          ),
          _buildFeatureItem(
            icon: Icons.info_outline,
            title: '关于ZViewer',
            subtitle: '版本信息和应用详情',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('关于页面开发中')),
              );
            },
          ),
          
          // 管理员功能
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.user?.role == 'admin') {
                return _buildFeatureItem(
                  icon: Icons.admin_panel_settings,
                  title: '文件管理',
                  subtitle: '管理多媒体文件',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminFileManagement(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
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
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

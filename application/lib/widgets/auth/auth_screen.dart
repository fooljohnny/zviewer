import 'package:flutter/material.dart';
import '../common/glassmorphism_background.dart';
import '../common/zviewer_logo.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Tab state changed
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _switchToLogin() {
    _tabController.animateTo(0);
  }

  void _switchToRegister() {
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassmorphismBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _buildAuthContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const ZViewerLogoMedium(),
          const SizedBox(height: 16),
          Text(
            'ZViewer',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Text(
            '多媒体画廊',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassmorphismCardBackground(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTabBar(),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  LoginForm(
                    onSwitchToRegister: _switchToRegister,
                  ),
                  RegisterForm(
                    onSwitchToLogin: _switchToLogin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.login),
            text: '登录',
          ),
          Tab(
            icon: Icon(Icons.person_add),
            text: '注册',
          ),
        ],
      ),
    );
  }
}
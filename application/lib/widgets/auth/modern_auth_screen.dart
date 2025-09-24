import 'package:flutter/material.dart';
import 'dart:ui';
import '../common/zviewer_logo.dart';
import 'modern_login_form.dart';
import 'modern_register_form.dart';

class ModernAuthScreen extends StatefulWidget {
  const ModernAuthScreen({super.key});

  @override
  State<ModernAuthScreen> createState() => _ModernAuthScreenState();
}

class _ModernAuthScreenState extends State<ModernAuthScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _backgroundController;
  late AnimationController _logoController;
  late AnimationController _formController;
  
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _formAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundController.repeat(reverse: true);
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _backgroundController.dispose();
    _logoController.dispose();
    _formController.dispose();
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
      body: _buildModernBackground(),
    );
  }

  Widget _buildModernBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                  _backgroundController.value,
                )!,
                Color.lerp(
                  const Color(0xFFf093fb),
                  const Color(0xFFf5576c),
                  _backgroundController.value,
                )!,
                Color.lerp(
                  const Color(0xFF4facfe),
                  const Color(0xFF00f2fe),
                  _backgroundController.value,
                )!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // 装饰性圆形
                _buildDecorativeCircles(),
                
                // 主要内容
                _buildMainContent(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // 大圆形
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        // 中圆形
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        // 小圆形
        Positioned(
          top: 200,
          left: 50,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Scrollbar(
        thumbVisibility: false,
        trackVisibility: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 区域
              _buildLogoSection(),
              
              const SizedBox(height: 50),
              
              // 表单区域
              _buildFormSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Center(
                  child: ZViewerLogo(size: 80),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'ZViewer',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '发现精彩的多媒体世界',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _formAnimation,
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
            minHeight: 300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: _isLoginMode() 
                  ? ModernLoginForm(
                      onSwitchToRegister: _switchToRegister,
                    )
                  : ModernRegisterForm(
                      onSwitchToLogin: _switchToLogin,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLoginMode() {
    return _tabController.index == 0;
  }

}

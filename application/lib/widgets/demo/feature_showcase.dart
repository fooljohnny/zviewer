import 'package:flutter/material.dart';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';
import '../gallery/responsive_waterfall_grid.dart';
import '../comments/enhanced_danmaku_overlay.dart';
import '../../services/danmaku_service.dart';

/// 功能展示页面
/// 展示ZViewer的所有核心功能
class FeatureShowcase extends StatefulWidget {
  const FeatureShowcase({super.key});

  @override
  State<FeatureShowcase> createState() => _FeatureShowcaseState();
}

class _FeatureShowcaseState extends State<FeatureShowcase>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;
  bool _showDanmaku = true;
  final List<DanmakuComment> _demoComments = [];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateDemoComments();
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
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.linear,
    ));
    
    _backgroundAnimationController.repeat();
  }

  void _generateDemoComments() {
    final comments = [
      '这个设计太棒了！',
      '毛玻璃效果很现代',
      '响应式布局完美',
      '弹幕系统很有趣',
      '用户体验很好',
      '界面很美观',
      '功能很全面',
      '动画很流畅',
    ];

    _demoComments.clear();
    for (int i = 0; i < comments.length; i++) {
      _demoComments.add(DanmakuComment(
        id: 'demo_$i',
        content: comments[i],
        author: '用户${i + 1}',
        timestamp: DateTime.now().subtract(Duration(minutes: i)),
        color: _getRandomColor(),
        speed: 0.8 + (i % 3) * 0.2,
      ));
    }
  }

  Color _getRandomColor() {
    final colors = [
      Colors.white,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.yellow,
      Colors.cyan,
    ];
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Stack(
          children: [
            // 主内容
            _buildMainContent(),
            
            // 弹幕覆盖层
            if (_showDanmaku)
              EnhancedDanmakuOverlay(
                comments: _demoComments,
                isVisible: _showDanmaku,
                onCommentTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('弹幕被点击了！'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onToggleVisibility: () {
                  setState(() {
                    _showDanmaku = !_showDanmaku;
                  });
                },
              ),
            
            // 控制面板
            _buildControlPanel(),
          ],
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
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF3A3A3C),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 80), // 为控制面板留出空间
          
          // 标题区域
          _buildTitleSection(),
          
          const SizedBox(height: 40),
          
          // 功能展示
          _buildFeatureSection(
            '响应式瀑布式布局',
            '移动端单列，桌面端多列，完美适配各种屏幕尺寸',
            Icons.grid_view,
            _buildWaterfallDemo(),
          ),
          
          const SizedBox(height: 40),
          
          _buildFeatureSection(
            '毛玻璃效果设计',
            'Apple风格的frosted glass效果，现代优雅',
            Icons.blur_on,
            _buildGlassmorphismDemo(),
          ),
          
          const SizedBox(height: 40),
          
          _buildFeatureSection(
            '弹幕评论系统',
            '半透明弹幕在媒体上飘过，增强社交互动',
            Icons.chat_bubble_outline,
            _buildDanmakuDemo(),
          ),
          
          const SizedBox(height: 40),
          
          _buildFeatureSection(
            '多媒体查看器',
            '支持图片和视频，手势控制，全屏体验',
            Icons.photo_library,
            _buildMediaViewerDemo(),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Center(
      child: Column(
        children: [
          const ZViewerLogoLarge(),
          const SizedBox(height: 24),
          const Text(
            'ZViewer',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '现代化多媒体查看器',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '响应式设计 • 毛玻璃效果 • 弹幕评论 • 流畅动画',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(
    String title,
    String description,
    IconData icon,
    Widget demo,
  ) {
    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          demo,
        ],
      ),
    );
  }

  Widget _buildWaterfallDemo() {
    final demoItems = List.generate(6, (index) {
      return WaterfallItem(
        id: 'demo_$index',
        imageUrl: 'https://picsum.photos/400/300?random=$index',
        title: '演示项目 ${index + 1}',
        subtitle: '这是一个演示项目',
        aspectRatio: 0.8 + (index % 3) * 0.3,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('点击了演示项目 ${index + 1}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      );
    });

    return Container(
      height: 300,
      child: ResponsiveWaterfallGrid(
        items: demoItems,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mobileCardHeight: 150,
        desktopCardMinWidth: 120,
        desktopCardMaxWidth: 150,
      ),
    );
  }

  Widget _buildGlassmorphismDemo() {
    return Row(
      children: [
        Expanded(
          child: GlassmorphismCard(
            child: const Column(
              children: [
                Icon(Icons.star, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  '标准卡片',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassmorphismCard(
            blurRadius: 30,
            opacity: 0.2,
            child: const Column(
              children: [
                Icon(Icons.blur_on, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  '高模糊',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassmorphismCard(
            blurRadius: 10,
            opacity: 0.1,
            child: const Column(
              children: [
                Icon(Icons.visibility, color: Colors.white, size: 32),
                SizedBox(height: 8),
                Text(
                  '低模糊',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDanmakuDemo() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/600/400?random=1'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              '点击右上角按钮体验弹幕效果',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaViewerDemo() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: NetworkImage('https://picsum.photos/600/400?random=2'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '支持图片和视频查看',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      top: 20,
      right: 20,
      child: GlassmorphismCard(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showDanmaku = !_showDanmaku;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _showDanmaku ? Icons.comment : Icons.comment_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _generateDemoComments();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


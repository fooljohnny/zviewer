import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/danmaku_provider.dart';
import '../../services/danmaku_service.dart';
import 'enhanced_danmaku_overlay.dart';
import '../common/glassmorphism_card.dart';

/// 弹幕评论演示页面
/// 展示弹幕系统的各种功能
class DanmakuDemoPage extends StatefulWidget {
  const DanmakuDemoPage({super.key});

  @override
  State<DanmakuDemoPage> createState() => _DanmakuDemoPageState();
}

class _DanmakuDemoPageState extends State<DanmakuDemoPage>
    with TickerProviderStateMixin {
  final String _mediaId = 'demo_media';
  bool _showComments = true;
  bool _showInput = false;
  final TextEditingController _inputController = TextEditingController();
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  final List<String> _demoComments = [
    '这个图片真好看！',
    '太美了，收藏了',
    '请问这是在哪里拍的？',
    '色彩搭配很棒',
    '构图很专业',
    '学到了，谢谢分享',
    '这是什么设备拍的？',
    '后期处理了吗？',
    '光线处理得很好',
    '很有艺术感',
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDemoComments();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _inputController.dispose();
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

  void _loadDemoComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final danmakuProvider = context.read<DanmakuProvider>();
      danmakuProvider.loadComments(_mediaId);
      
      // 添加一些演示评论
      for (int i = 0; i < 5; i++) {
        danmakuProvider.addComment(
          _mediaId,
          _demoComments[i],
          '用户${i + 1}',
        );
      }
    });
  }

  void _addRandomComment() {
    final danmakuProvider = context.read<DanmakuProvider>();
    final randomComment = _demoComments[
      DateTime.now().millisecondsSinceEpoch % _demoComments.length
    ];
    danmakuProvider.addComment(
      _mediaId,
      randomComment,
      '随机用户',
    );
  }

  void _submitComment() {
    final content = _inputController.text.trim();
    if (content.isNotEmpty) {
      context.read<DanmakuProvider>().addComment(
        _mediaId,
        content,
        '当前用户',
      );
      _inputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: Stack(
          children: [
            // 背景图片
            _buildBackgroundImage(),
            
            // 弹幕覆盖层
            if (_showComments)
              Consumer<DanmakuProvider>(
                builder: (context, danmakuProvider, child) {
                  return EnhancedDanmakuOverlay(
                    comments: danmakuProvider.getComments(_mediaId),
                    isVisible: _showComments,
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
                        _showComments = !_showComments;
                      });
                    },
                    onCommentSubmit: (content) => _submitComment(),
                    showInput: _showInput,
                  );
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

  Widget _buildBackgroundImage() {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://picsum.photos/1200/800?random=1'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
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
      ),
    );
  }

  Widget _buildControlPanel() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: GlassmorphismCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '弹幕评论演示',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _showComments ? Icons.comment : Icons.comment_outlined,
                  label: _showComments ? '隐藏弹幕' : '显示弹幕',
                  onTap: () {
                    setState(() {
                      _showComments = !_showComments;
                    });
                  },
                ),
                _buildControlButton(
                  icon: Icons.add_comment,
                  label: '添加弹幕',
                  onTap: _addRandomComment,
                ),
                _buildControlButton(
                  icon: Icons.edit,
                  label: '发送弹幕',
                  onTap: () {
                    setState(() {
                      _showInput = !_showInput;
                    });
                  },
                ),
              ],
            ),
            
            // 评论输入
            if (_showInput) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入弹幕内容...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
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


import 'package:flutter/material.dart';
import 'responsive_waterfall_grid.dart';

/// 响应式布局演示页面
/// 展示移动端和桌面端的不同布局效果
class ResponsiveDemoPage extends StatefulWidget {
  const ResponsiveDemoPage({super.key});

  @override
  State<ResponsiveDemoPage> createState() => _ResponsiveDemoPageState();
}

class _ResponsiveDemoPageState extends State<ResponsiveDemoPage> {
  final List<WaterfallItem> _demoItems = [];

  @override
  void initState() {
    super.initState();
    _generateDemoItems();
  }

  void _generateDemoItems() {
    final List<Map<String, dynamic>> demoData = [
      {
        'id': '1',
        'title': '美丽的风景',
        'subtitle': '拍摄于2024年',
        'aspectRatio': 1.2,
        'type': 'image',
      },
      {
        'id': '2',
        'title': '城市夜景',
        'subtitle': '繁华的都市',
        'aspectRatio': 0.8,
        'type': 'image',
      },
      {
        'id': '3',
        'title': '自然风光',
        'subtitle': '大自然的馈赠',
        'aspectRatio': 1.5,
        'type': 'image',
      },
      {
        'id': '4',
        'title': '旅行视频',
        'subtitle': '精彩的旅程',
        'aspectRatio': 1.77,
        'type': 'video',
      },
      {
        'id': '5',
        'title': '艺术创作',
        'subtitle': '创意无限',
        'aspectRatio': 0.9,
        'type': 'image',
      },
      {
        'id': '6',
        'title': '生活记录',
        'subtitle': '美好时光',
        'aspectRatio': 1.3,
        'type': 'image',
      },
      {
        'id': '7',
        'title': '音乐视频',
        'subtitle': '动听的旋律',
        'aspectRatio': 1.77,
        'type': 'video',
      },
      {
        'id': '8',
        'title': '美食摄影',
        'subtitle': '诱人的美味',
        'aspectRatio': 1.0,
        'type': 'image',
      },
      {
        'id': '9',
        'title': '建筑艺术',
        'subtitle': '现代设计',
        'aspectRatio': 1.4,
        'type': 'image',
      },
      {
        'id': '10',
        'title': '运动瞬间',
        'subtitle': '活力四射',
        'aspectRatio': 0.7,
        'type': 'image',
      },
    ];

    _demoItems.clear();
    for (final data in demoData) {
      _demoItems.add(WaterfallItem(
        id: data['id'],
        imageUrl: 'https://picsum.photos/400/300?random=${data['id']}',
        title: data['title'],
        subtitle: data['subtitle'],
        aspectRatio: data['aspectRatio'],
        onTap: () => _onItemTap(data),
        metadata: {
          'type': data['type'],
        },
      ));
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('描述: ${item['subtitle']}'),
            const SizedBox(height: 8),
            Text('类型: ${item['type']}'),
            const SizedBox(height: 8),
            Text('宽高比: ${item['aspectRatio']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('响应式布局演示'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _generateDemoItems();
              });
            },
          ),
        ],
      ),
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
        child: ResponsiveWaterfallGrid(
          items: _demoItems,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          mobileCardHeight: MediaQuery.of(context).size.height * 0.6,
          desktopCardMinWidth: 300,
          desktopCardMaxWidth: 400,
          onLoadMore: () {
            // 模拟加载更多
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _generateDemoItems();
                });
              }
            });
          },
          isLoading: false,
          hasMore: true,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _generateDemoItems();
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}



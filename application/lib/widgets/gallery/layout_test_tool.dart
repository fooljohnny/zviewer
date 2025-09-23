import 'package:flutter/material.dart';
import 'responsive_waterfall_grid.dart';

/// 布局测试工具
/// 用于测试不同屏幕尺寸下的响应式布局效果
class LayoutTestTool extends StatefulWidget {
  const LayoutTestTool({super.key});

  @override
  State<LayoutTestTool> createState() => _LayoutTestToolState();
}

class _LayoutTestToolState extends State<LayoutTestTool> {
  double _simulatedWidth = 400;
  final List<WaterfallItem> _testItems = [];

  @override
  void initState() {
    super.initState();
    _generateTestItems();
  }

  void _generateTestItems() {
    _testItems.clear();
    for (int i = 1; i <= 20; i++) {
      _testItems.add(WaterfallItem(
        id: 'test_$i',
        imageUrl: 'https://picsum.photos/400/300?random=$i',
        title: '测试项目 $i',
        subtitle: '这是一个测试项目',
        aspectRatio: 0.5 + (i % 3) * 0.5, // 0.5, 1.0, 1.5
        onTap: () => _onItemTap(i),
        metadata: {
          'type': i % 4 == 0 ? 'video' : 'image',
        },
      ));
    }
  }

  void _onItemTap(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了测试项目 $index'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('布局测试工具'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControlPanel(),
          Expanded(
            child: _buildTestArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 宽度控制
          Row(
            children: [
              const Text(
                '模拟宽度: ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Expanded(
                child: Slider(
                  value: _simulatedWidth,
                  min: 300,
                  max: 1200,
                  divisions: 18,
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    setState(() {
                      _simulatedWidth = value;
                    });
                  },
                ),
              ),
              Text(
                '${_simulatedWidth.toInt()}px',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          
          // 预设按钮
          Wrap(
            spacing: 8,
            children: [
              _buildPresetButton('手机', 375),
              _buildPresetButton('平板', 768),
              _buildPresetButton('桌面', 1024),
              _buildPresetButton('大屏', 1440),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 布局信息
          _buildLayoutInfo(),
        ],
      ),
    );
  }

  Widget _buildPresetButton(String label, double width) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _simulatedWidth = width;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.2),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _buildLayoutInfo() {
    final crossAxisCount = ResponsiveBreakpoints.getCrossAxisCount(_simulatedWidth);
    final isMobile = ResponsiveBreakpoints.isMobile(_simulatedWidth);
    final isTablet = ResponsiveBreakpoints.isTablet(_simulatedWidth);
    final isDesktop = ResponsiveBreakpoints.isDesktop(_simulatedWidth);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildInfoItem('列数', crossAxisCount.toString()),
        _buildInfoItem('设备', isMobile ? '手机' : isTablet ? '平板' : '桌面'),
        _buildInfoItem('布局', isMobile ? '单列' : '瀑布'),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTestArea() {
    return Container(
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
      child: Center(
        child: Container(
          width: _simulatedWidth,
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.blue.withOpacity(0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ResponsiveWaterfallGrid(
              items: _testItems,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: const EdgeInsets.all(8),
              mobileCardHeight: 200,
              desktopCardMinWidth: 150,
              desktopCardMaxWidth: 200,
            ),
          ),
        ),
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('布局测试工具说明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这个工具帮助您测试不同屏幕尺寸下的布局效果：'),
            SizedBox(height: 16),
            Text('• 移动端 (< 600px): 单列布局，卡片占满屏幕宽度'),
            Text('• 平板端 (600-900px): 2列瀑布式布局'),
            Text('• 桌面端 (900-1200px): 3列瀑布式布局'),
            Text('• 大屏端 (> 1200px): 4列瀑布式布局'),
            SizedBox(height: 16),
            Text('使用滑块调整模拟宽度，观察布局变化。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}



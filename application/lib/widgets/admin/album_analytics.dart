import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/album.dart';
import '../../utils/album_permissions.dart';

/// 图集分析页面
/// 显示图集的统计信息和分析数据
class AlbumAnalyticsView extends StatefulWidget {
  final Album album;

  const AlbumAnalyticsView({super.key, required this.album});

  @override
  State<AlbumAnalyticsView> createState() => _AlbumAnalyticsViewState();
}

class _AlbumAnalyticsViewState extends State<AlbumAnalyticsView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 检查权限
        if (!AlbumPermissions.canViewAlbumStats(widget.album, authProvider)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('图集分析'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '无权限查看统计信息',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '只有图集创建者和管理员可以查看统计信息',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.album.title} - 分析'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '概览', icon: Icon(Icons.dashboard)),
                Tab(text: '趋势', icon: Icon(Icons.trending_up)),
                Tab(text: '详情', icon: Icon(Icons.analytics)),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedTimeRange = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: '1d',
                    child: Text('最近1天'),
                  ),
                  const PopupMenuItem(
                    value: '7d',
                    child: Text('最近7天'),
                  ),
                  const PopupMenuItem(
                    value: '30d',
                    child: Text('最近30天'),
                  ),
                  const PopupMenuItem(
                    value: '90d',
                    child: Text('最近90天'),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getTimeRangeText(_selectedTimeRange)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTrendsTab(),
              _buildDetailsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 关键指标卡片
          _buildKeyMetricsCards(),
          const SizedBox(height: 24),
          // 图集信息
          _buildAlbumInfoCard(),
          const SizedBox(height: 24),
          // 最近活动
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 浏览趋势图表
          _buildTrendChart('浏览趋势', Icons.visibility, Colors.blue),
          const SizedBox(height: 24),
          // 点赞趋势图表
          _buildTrendChart('点赞趋势', Icons.favorite, Colors.red),
          const SizedBox(height: 24),
          // 分享趋势图表
          _buildTrendChart('分享趋势', Icons.share, Colors.green),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 详细统计表格
          _buildDetailedStatsTable(),
          const SizedBox(height: 24),
          // 用户行为分析
          _buildUserBehaviorAnalysis(),
          const SizedBox(height: 24),
          // 图片分析
          _buildImageAnalysis(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关键指标',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: '总浏览量',
                value: widget.album.viewCount.toString(),
                icon: Icons.visibility,
                color: Colors.blue,
                trend: '+12%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: '总点赞数',
                value: widget.album.likeCount.toString(),
                icon: Icons.favorite,
                color: Colors.red,
                trend: '+8%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: '图片数量',
                value: widget.album.imageCount.toString(),
                icon: Icons.photo,
                color: Colors.green,
                trend: '0%',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: '分享次数',
                value: '0', // TODO: 从API获取
                icon: Icons.share,
                color: Colors.orange,
                trend: '+5%',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trend,
              style: TextStyle(
                color: trend.startsWith('+') ? Colors.green : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '图集信息',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('创建时间', widget.album.formattedCreatedAt),
            _buildInfoRow('更新时间', widget.album.formattedUpdatedAt),
            _buildInfoRow('状态', widget.album.statusDisplayText),
            _buildInfoRow('可见性', widget.album.isPublic ? '公开' : '私有'),
            _buildInfoRow('创建者', widget.album.userName),
            _buildInfoRow('标签', widget.album.tagsDisplayText),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '最近活动',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // TODO: 从API获取最近活动数据
            const Center(
              child: Text('暂无最近活动数据'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(String title, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // TODO: 实现实际的图表组件
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '图表功能开发中',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细统计',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Table(
              children: [
                _buildTableRow('平均每日浏览量', '0'),
                _buildTableRow('平均每日点赞数', '0'),
                _buildTableRow('平均每日分享数', '0'),
                _buildTableRow('用户停留时间', '0分钟'),
                _buildTableRow('跳出率', '0%'),
                _buildTableRow('转化率', '0%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildUserBehaviorAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '用户行为分析',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // TODO: 实现用户行为分析图表
            const Center(
              child: Text('用户行为分析功能开发中'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '图片分析',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // TODO: 实现图片分析功能
            const Center(
              child: Text('图片分析功能开发中'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRangeText(String range) {
    switch (range) {
      case '1d':
        return '最近1天';
      case '7d':
        return '最近7天';
      case '30d':
        return '最近30天';
      case '90d':
        return '最近90天';
      default:
        return '最近7天';
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 瀑布式网格布局组件
/// 类似Pinterest的Masonry布局，支持不同高度的多媒体内容
class WaterfallGrid extends StatefulWidget {
  final List<WaterfallItem> items;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;

  const WaterfallGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = EdgeInsets.zero,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.emptyWidget,
    this.loadingWidget,
  });

  @override
  State<WaterfallGrid> createState() => _WaterfallGridState();
}

class _WaterfallGridState extends State<WaterfallGrid> {
  late ScrollController _scrollController;
  final List<double> _columnHeights = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initializeColumnHeights();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeColumnHeights() {
    _columnHeights.clear();
    for (int i = 0; i < widget.crossAxisCount; i++) {
      _columnHeights.add(0.0);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: widget.padding,
          sliver: SliverWaterfallGrid(
            items: widget.items,
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
          ),
        ),
        if (widget.isLoading)
          SliverToBoxAdapter(
            child: widget.loadingWidget ?? _buildLoadingWidget(),
          ),
      ],
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无内容',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加一些多媒体文件开始浏览',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// 瀑布式网格的Sliver实现
class SliverWaterfallGrid extends StatelessWidget {
  final List<WaterfallItem> items;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const SliverWaterfallGrid({
    super.key,
    required this.items,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.crossAxisExtent;
        final itemWidth = (availableWidth - 
            (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
        
        final columns = List.generate(crossAxisCount, (index) => <Widget>[]);
        final columnHeights = List.filled(crossAxisCount, 0.0);

        for (final item in items) {
          final shortestColumnIndex = columnHeights.indexOf(
            columnHeights.reduce(math.min),
          );
          
          columns[shortestColumnIndex].add(
            Padding(
              padding: EdgeInsets.only(
                bottom: mainAxisSpacing,
              ),
              child: WaterfallItemWidget(
                item: item,
                width: itemWidth,
              ),
            ),
          );
          
          columnHeights[shortestColumnIndex] += item.height + mainAxisSpacing;
        }

        return SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((column) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: column,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// 瀑布式网格项
class WaterfallItem {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final double aspectRatio;
  final VoidCallback? onTap;
  final Map<String, dynamic>? metadata;

  const WaterfallItem({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.aspectRatio = 1.0,
    this.onTap,
    this.metadata,
  });

  double get height => 200 * aspectRatio; // 基础高度200px
}

/// 瀑布式网格项组件
class WaterfallItemWidget extends StatelessWidget {
  final WaterfallItem item;
  final double width;

  const WaterfallItemWidget({
    super.key,
    required this.item,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片部分
              AspectRatio(
                aspectRatio: item.aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[400]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 这里应该使用实际的图片加载组件
                      Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                      // 播放按钮（如果是视频）
                      if (item.metadata?['type'] == 'video')
                        const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      // 右上角操作按钮
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 标题和副标题
              if (item.title != null || item.subtitle != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.title != null)
                        Text(
                          item.title!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 响应式瀑布式网格布局
/// 移动端：单列，卡片占满屏幕宽度
/// 桌面端：多列瀑布式布局，自适应窗体大小
class ResponsiveWaterfallGrid extends StatefulWidget {
  final List<WaterfallItem> items;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final VoidCallback? onLoadMore;
  final bool isLoading;
  final bool hasMore;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final double mobileCardHeight;
  final double desktopCardMinWidth;
  final double desktopCardMaxWidth;

  const ResponsiveWaterfallGrid({
    super.key,
    required this.items,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = EdgeInsets.zero,
    this.onLoadMore,
    this.isLoading = false,
    this.hasMore = true,
    this.emptyWidget,
    this.loadingWidget,
    this.mobileCardHeight = 300.0,
    this.desktopCardMinWidth = 300.0,
    this.desktopCardMaxWidth = 400.0,
  });

  @override
  State<ResponsiveWaterfallGrid> createState() => _ResponsiveWaterfallGridState();
}

class _ResponsiveWaterfallGridState extends State<ResponsiveWaterfallGrid> {
  late ScrollController _scrollController;
  int _crossAxisCount = 1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (widget.hasMore && !widget.isLoading && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  int _calculateCrossAxisCount(double availableWidth) {
    if (availableWidth < 600) {
      // 移动端：单列
      return 1;
    } else {
      // 桌面端：计算能容纳的列数
      final availableWidthForCards = availableWidth - 
          widget.padding.horizontal - 
          (widget.crossAxisSpacing * 2);
      
      final maxColumns = (availableWidthForCards / widget.desktopCardMinWidth).floor();
      final minColumns = math.max(1, (availableWidthForCards / widget.desktopCardMaxWidth).ceil());
      
      return math.max(1, math.min(maxColumns, minColumns));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        _crossAxisCount = _calculateCrossAxisCount(availableWidth);
        
        if (widget.items.isEmpty) {
          return widget.emptyWidget ?? _buildEmptyWidget();
        }

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: widget.padding,
              sliver: _buildWaterfallGrid(availableWidth),
            ),
            if (widget.isLoading)
              SliverToBoxAdapter(
                child: widget.loadingWidget ?? _buildLoadingWidget(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWaterfallGrid(double availableWidth) {
    if (_crossAxisCount == 1) {
      // 移动端：单列布局
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = widget.items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: widget.mainAxisSpacing,
              ),
              child: ResponsiveWaterfallItem(
                item: item,
                isMobile: true,
                width: availableWidth - widget.padding.horizontal,
                height: widget.mobileCardHeight,
              ),
            );
          },
          childCount: widget.items.length,
        ),
      );
    } else {
      // 桌面端：瀑布式布局
      return SliverWaterfallGrid(
        items: widget.items,
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        availableWidth: availableWidth,
        desktopCardMinWidth: widget.desktopCardMinWidth,
        desktopCardMaxWidth: widget.desktopCardMaxWidth,
      );
    }
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

/// 响应式瀑布式网格的Sliver实现
class SliverWaterfallGrid extends StatelessWidget {
  final List<WaterfallItem> items;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double availableWidth;
  final double desktopCardMinWidth;
  final double desktopCardMaxWidth;

  const SliverWaterfallGrid({
    super.key,
    required this.items,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.availableWidth,
    required this.desktopCardMinWidth,
    required this.desktopCardMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidthForCards = availableWidth - (crossAxisCount - 1) * crossAxisSpacing;
    final itemWidth = availableWidthForCards / crossAxisCount;
    
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
          child: ResponsiveWaterfallItem(
            item: item,
            isMobile: false,
            width: itemWidth,
            height: null, // 桌面端使用原始宽高比
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
  }
}

/// 响应式瀑布式网格项组件
class ResponsiveWaterfallItem extends StatelessWidget {
  final WaterfallItem item;
  final bool isMobile;
  final double width;
  final double? height;

  const ResponsiveWaterfallItem({
    super.key,
    required this.item,
    required this.isMobile,
    required this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: isMobile ? 12 : 8,
              offset: Offset(0, isMobile ? 6 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片部分
              _buildImageSection(),
              
              // 标题和副标题
              if (item.title != null || item.subtitle != null)
                _buildTextSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final imageHeight = height ?? (width * item.aspectRatio);
    
    return Container(
      height: imageHeight,
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
            child: Icon(
              Icons.image,
              size: isMobile ? 64 : 48,
              color: Colors.grey,
            ),
          ),
          
          // 播放按钮（如果是视频）
          if (item.metadata?['type'] == 'video')
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          
          // 右上角操作按钮
          Positioned(
            top: isMobile ? 12 : 8,
            right: isMobile ? 12 : 8,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 4),
              ),
              child: Icon(
                Icons.more_vert,
                size: isMobile ? 20 : 16,
                color: Colors.white,
              ),
            ),
          ),
          
          // 移动端底部渐变遮罩
          if (isMobile)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextSection() {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.title != null)
            Text(
              item.title!,
              style: TextStyle(
                fontSize: isMobile ? 18 : 14,
                fontWeight: FontWeight.w600,
                color: isMobile ? Colors.white : Colors.black87,
              ),
              maxLines: isMobile ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (item.subtitle != null) ...[
            SizedBox(height: isMobile ? 8 : 4),
            Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: isMobile ? 14 : 12,
                color: isMobile ? Colors.white70 : Colors.grey[600],
              ),
              maxLines: isMobile ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// 瀑布式网格项数据模型
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

/// 响应式布局断点工具类
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;

  static bool isMobile(double width) => width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
  static bool isLargeDesktop(double width) => width >= largeDesktop;

  static int getCrossAxisCount(double width, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
    int largeDesktopColumns = 4,
  }) {
    if (isMobile(width)) return mobileColumns;
    if (isTablet(width)) return tabletColumns;
    if (isLargeDesktop(width)) return largeDesktopColumns;
    return desktopColumns;
  }
}



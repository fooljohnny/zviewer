import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../common/image_thumbnail.dart';
import '../../models/album.dart';
import 'album_gesture_handler.dart';

/// 图集瀑布式网格布局
/// 专门用于显示图集的瀑布式布局
class AlbumWaterfallGrid extends StatefulWidget {
  final List<Album> albums;
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
  final Function(Album)? onAlbumTap;

  const AlbumWaterfallGrid({
    super.key,
    required this.albums,
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
    this.onAlbumTap,
  });

  @override
  State<AlbumWaterfallGrid> createState() => _AlbumWaterfallGridState();
}

class _AlbumWaterfallGridState extends State<AlbumWaterfallGrid> {
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
        
        if (widget.albums.isEmpty) {
          return widget.emptyWidget ?? _buildEmptyWidget();
        }

        return Scrollbar(
          thumbVisibility: false,
          trackVisibility: false,
          child: CustomScrollView(
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
          ),
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
            final album = widget.albums[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: widget.mainAxisSpacing,
              ),
              child: AlbumWaterfallItem(
                album: album,
                isMobile: true,
                width: availableWidth - widget.padding.horizontal,
                height: widget.mobileCardHeight,
                onTap: () => widget.onAlbumTap?.call(album),
              ),
            );
          },
          childCount: widget.albums.length,
        ),
      );
    } else {
      // 桌面端：瀑布式布局
      return SliverAlbumWaterfallGrid(
        albums: widget.albums,
        crossAxisCount: _crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        availableWidth: availableWidth,
        desktopCardMinWidth: widget.desktopCardMinWidth,
        desktopCardMaxWidth: widget.desktopCardMaxWidth,
        onAlbumTap: widget.onAlbumTap,
      );
    }
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无图集',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建一些图集开始浏览',
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

/// 图集瀑布式网格的Sliver实现
class SliverAlbumWaterfallGrid extends StatelessWidget {
  final List<Album> albums;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double availableWidth;
  final double desktopCardMinWidth;
  final double desktopCardMaxWidth;
  final Function(Album)? onAlbumTap;

  const SliverAlbumWaterfallGrid({
    super.key,
    required this.albums,
    required this.crossAxisCount,
    required this.crossAxisSpacing,
    required this.mainAxisSpacing,
    required this.availableWidth,
    required this.desktopCardMinWidth,
    required this.desktopCardMaxWidth,
    this.onAlbumTap,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidthForCards = availableWidth - (crossAxisCount - 1) * crossAxisSpacing;
    final itemWidth = availableWidthForCards / crossAxisCount;
    
    final columns = List.generate(crossAxisCount, (index) => <Widget>[]);
    final columnHeights = List.filled(crossAxisCount, 0.0);

    for (final album in albums) {
      final shortestColumnIndex = columnHeights.indexOf(
        columnHeights.reduce(math.min),
      );
      
      columns[shortestColumnIndex].add(
        Padding(
          padding: EdgeInsets.only(
            bottom: mainAxisSpacing,
          ),
          child: AlbumWaterfallItem(
            album: album,
            isMobile: false,
            width: itemWidth,
            height: null, // 桌面端使用原始宽高比
            onTap: () => onAlbumTap?.call(album),
          ),
        ),
      );
      
      columnHeights[shortestColumnIndex] += album.aspectRatio * itemWidth + mainAxisSpacing;
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

/// 图集瀑布式网格项组件
class AlbumWaterfallItem extends StatelessWidget {
  final Album album;
  final bool isMobile;
  final double width;
  final double? height;
  final VoidCallback? onTap;

  const AlbumWaterfallItem({
    super.key,
    required this.album,
    required this.isMobile,
    required this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlbumCardGestureHandler(
      onTap: onTap,
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
              // 封面图片部分
              _buildCoverImageSection(),
              
              // 图集信息
              _buildAlbumInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection() {
    final imageHeight = height ?? (width * album.aspectRatio);
    
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
          // 封面图片
          if (album.hasCover)
            ImageThumbnail(
              id: album.coverImageId,
              thumbnailPath: album.coverThumbnailPath,
              filePath: album.coverImageUrl!,
              mimeType: 'image/jpeg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
            )
          else
            Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.photo_album,
                size: 48,
                color: Colors.grey,
              ),
            ),
          
          // 图片数量指示器
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    album.imageCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 状态指示器
          Positioned(
            top: 8,
            left: 8,
            child: _buildStatusIndicator(),
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

  Widget _buildStatusIndicator() {
    Color color;
    IconData icon;
    
    switch (album.status) {
      case AlbumStatus.draft:
        color = Colors.grey;
        icon = Icons.edit;
        break;
      case AlbumStatus.published:
        color = Colors.green;
        icon = Icons.public;
        break;
      case AlbumStatus.archived:
        color = Colors.orange;
        icon = Icons.archive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 12,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAlbumInfoSection() {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 图集标题
          Text(
            album.displayTitle,
            style: TextStyle(
              fontSize: isMobile ? 18 : 14,
              fontWeight: FontWeight.w600,
              color: isMobile ? Colors.white : Colors.black87,
            ),
            maxLines: isMobile ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // 图集描述
          if (album.description.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 4),
            Text(
              album.displayDescription,
              style: TextStyle(
                fontSize: isMobile ? 14 : 12,
                color: isMobile ? Colors.white70 : Colors.grey[600],
              ),
              maxLines: isMobile ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // 图集统计信息
          SizedBox(height: isMobile ? 12 : 8),
          Row(
            children: [
              // 作者
              Icon(
                Icons.person,
                size: isMobile ? 16 : 12,
                color: isMobile ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                album.userName,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 10,
                  color: isMobile ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              // 创建时间
              Icon(
                Icons.access_time,
                size: isMobile ? 16 : 12,
                color: isMobile ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                album.formattedCreatedAt,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 10,
                  color: isMobile ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
          
          // 标签
          if (album.tags.isNotEmpty) ...[
            SizedBox(height: isMobile ? 8 : 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: album.tags.take(3).map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isMobile ? Colors.white : Colors.blue).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isMobile ? Colors.white : Colors.blue).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 8,
                      color: isMobile ? Colors.white : Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// 扩展Album模型以支持瀑布式布局
extension AlbumWaterfallExtension on Album {
  double get aspectRatio {
    // 如果没有封面图片，使用默认宽高比
    if (!hasCover) return 1.0;
    
    // 这里可以根据实际需要计算宽高比
    // 暂时使用默认值
    return 1.2;
  }
}

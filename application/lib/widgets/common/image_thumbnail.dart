import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/api_config.dart';

/// 图片缩略图组件
/// 支持多种图片格式：SVG, WebP, PNG, JPG, JPEG, GIF
class ImageThumbnail extends StatelessWidget {
  final String? id;
  final String? thumbnailPath;
  final String? filePath;
  final String? mimeType;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool skipThumbnail; // 强制跳过缩略图，直接使用原图

  const ImageThumbnail({
    super.key,
    this.id,
    this.thumbnailPath,
    this.filePath,
    this.mimeType,
    this.width = 48,
    this.height = 48,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.skipThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    // 优先使用缩略图
    final imageUrl = _getImageUrl();
    
    if (imageUrl == null) {
      return _buildErrorWidget();
    }

    // 根据文件类型选择不同的显示方式
    if (_isSvgFile()) {
      return _buildSvgWidget(imageUrl);
    } else {
      return _buildCachedImageWidget(imageUrl);
    }
  }

  String? _getImageUrl() {
    String? url;
    
    // 如果设置了跳过缩略图，直接使用原图
    if (skipThumbnail) {
      if (id != null && id!.isNotEmpty) {
        // 使用ID获取原始图片
        url = '${ApiConfig.mediaUrl}/media/stream/$id';
      } else if (filePath != null && filePath!.isNotEmpty) {
        // 使用文件路径
        if (filePath!.startsWith('http')) {
          url = filePath;
        } else {
          // 修复文件路径处理 - 如果路径已经包含media/stream，直接使用
          if (filePath!.startsWith('/media/stream/')) {
            String cleanPath = filePath!.substring(1); // 移除开头的斜杠
            url = '${ApiConfig.mediaUrl}/$cleanPath';
          } else {
            // 否则按原来的逻辑处理
            String cleanPath = filePath!.startsWith('/') ? filePath!.substring(1) : filePath!;
            url = '${ApiConfig.mediaUrl}/media/stream/$cleanPath';
          }
        }
      }
    } else {
      // 优先使用缩略图路径
      if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
        // 如果thumbnailPath已经是完整URL，直接使用
        if (thumbnailPath!.startsWith('http')) {
          url = thumbnailPath;
        } else {
          // 否则构建完整URL
          url = '${ApiConfig.mediaUrl}/media/thumbnail/$thumbnailPath';
        }
      } else if (id != null && id!.isNotEmpty) {
        // 使用ID获取原始图片
        url = '${ApiConfig.mediaUrl}/media/stream/$id';
      } else if (filePath != null && filePath!.isNotEmpty) {
        // 最后尝试使用文件路径
        if (filePath!.startsWith('http')) {
          url = filePath;
        } else {
          // 修复文件路径处理 - 如果路径已经包含media/stream，直接使用
          if (filePath!.startsWith('/media/stream/')) {
            String cleanPath = filePath!.substring(1); // 移除开头的斜杠
            url = '${ApiConfig.mediaUrl}/$cleanPath';
          } else {
            // 否则按原来的逻辑处理
            String cleanPath = filePath!.startsWith('/') ? filePath!.substring(1) : filePath!;
            url = '${ApiConfig.mediaUrl}/media/stream/$cleanPath';
          }
        }
      }
    }
    
    // 调试信息
    if (ApiConfig.isDevelopment) {
      print('ImageThumbnail URL: $url');
      print('  - thumbnailPath: $thumbnailPath');
      print('  - id: $id');
      print('  - filePath: $filePath');
      print('  - mimeType: $mimeType');
      print('  - ApiConfig.mediaUrl: ${ApiConfig.mediaUrl}');
    }
    
    return url;
  }

  bool _isSvgFile() {
    if (mimeType != null) {
      return mimeType!.toLowerCase().contains('svg');
    }
    if (filePath != null) {
      return filePath!.toLowerCase().endsWith('.svg');
    }
    return false;
  }

  Widget _buildSvgWidget(String imageUrl) {
    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: SvgPicture.network(
          imageUrl,
          width: width.isFinite ? width : null,
          height: height.isFinite ? height : null,
          fit: fit,
          placeholderBuilder: (context) => _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildCachedImageWidget(String imageUrl) {
    // 为了获得最高清晰度，不限制内存缓存尺寸
    // 让图片以原始分辨率加载和显示
    int? memCacheWidth;
    int? memCacheHeight;
    
    // 只有在图片尺寸非常大时才限制内存缓存，避免内存溢出
    if (width.isFinite && width > 0 && width < 2000) {
      memCacheWidth = (width * 3).round(); // 增加缓存倍数
    }
    if (height.isFinite && height > 0 && height < 2000) {
      memCacheHeight = (height * 3).round(); // 增加缓存倍数
    }
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.black, // 改为黑色背景
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: fit,
          placeholder: (context, url) {
            if (ApiConfig.isDevelopment) {
              print('Loading image: $url');
            }
            return _buildPlaceholder();
          },
          errorWidget: (context, url, error) {
            if (ApiConfig.isDevelopment) {
              print('Image load error: $url, error: $error');
            }
            // 尝试使用备用URL
            return _buildFallbackImage();
          },
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          // 添加重试机制
          httpHeaders: const {
            'Accept': 'image/*',
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return placeholder!;
    }
    
    final iconSize = width.isFinite && width > 0 ? width * 0.4 : 24.0;
    
    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: Icon(
        _getFileTypeIcon(),
        color: Colors.grey[600],
        size: iconSize,
      ),
    );
  }

  Widget _buildFallbackImage() {
    // 尝试使用备用URL
    String? fallbackUrl = _getFallbackUrl();
    if (fallbackUrl != null) {
      if (ApiConfig.isDevelopment) {
        print('Trying fallback URL: $fallbackUrl');
      }
      return CachedNetworkImage(
        imageUrl: fallbackUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) {
          if (ApiConfig.isDevelopment) {
            print('Fallback image also failed: $url, error: $error');
          }
          return _buildErrorWidget();
        },
        memCacheWidth: null,
        memCacheHeight: null,
        httpHeaders: const {
          'Accept': 'image/*',
        },
      );
    }
    
    return _buildErrorWidget();
  }

  String? _getFallbackUrl() {
    // 如果当前使用的是缩略图，尝试使用原始图片
    if (thumbnailPath != null && thumbnailPath!.isNotEmpty) {
      if (id != null && id!.isNotEmpty) {
        return '${ApiConfig.mediaUrl}/media/stream/$id';
      } else if (filePath != null && filePath!.isNotEmpty) {
        if (filePath!.startsWith('http')) {
          return filePath;
        } else {
          // 修复文件路径处理 - 如果路径已经包含media/stream，直接使用
          if (filePath!.startsWith('/media/stream/')) {
            String cleanPath = filePath!.substring(1); // 移除开头的斜杠
            return '${ApiConfig.mediaUrl}/$cleanPath';
          } else {
            // 否则按原来的逻辑处理
            String cleanPath = filePath!.startsWith('/') ? filePath!.substring(1) : filePath!;
            return '${ApiConfig.mediaUrl}/media/stream/$cleanPath';
          }
        }
      }
    }
    return null;
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return errorWidget!;
    }
    
    final iconSize = width.isFinite && width > 0 ? width * 0.4 : 24.0;
    
    return Container(
      width: width.isFinite ? width : null,
      height: height.isFinite ? height : null,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey[300],
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey[600],
            size: iconSize,
          ),
          if (width.isFinite && width > 60) // 只在足够宽时显示文本
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                '加载失败',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon() {
    if (mimeType != null) {
      final mime = mimeType!.toLowerCase();
      if (mime.contains('svg')) {
        return Icons.image;
      } else if (mime.contains('webp')) {
        return Icons.image;
      } else if (mime.contains('gif')) {
        return Icons.gif;
      } else if (mime.contains('png') || mime.contains('jpeg') || mime.contains('jpg')) {
        return Icons.image;
      }
    }
    
    if (filePath != null) {
      final path = filePath!.toLowerCase();
      if (path.endsWith('.svg')) {
        return Icons.image;
      } else if (path.endsWith('.webp')) {
        return Icons.image;
      } else if (path.endsWith('.gif')) {
        return Icons.gif;
      } else if (path.endsWith('.png') || path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return Icons.image;
      }
    }
    
    return Icons.image;
  }
}

/// 图片缩略图网格组件
/// 用于在网格布局中显示多个图片缩略图
class ImageThumbnailGrid extends StatelessWidget {
  final List<dynamic> items;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final Function(dynamic)? onItemTap;

  const ImageThumbnailGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onItemTap?.call(item),
          child: ImageThumbnail(
            thumbnailPath: item.thumbnailPath,
            filePath: item.filePath,
            mimeType: item.mimeType,
            width: double.infinity,
            height: double.infinity,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/album.dart';
import '../../models/content_item.dart';
import '../common/image_thumbnail.dart';

class AlbumImageManagementDialog extends StatefulWidget {
  final Album album;

  const AlbumImageManagementDialog({super.key, required this.album});

  @override
  State<AlbumImageManagementDialog> createState() => _AlbumImageManagementDialogState();
}

class _AlbumImageManagementDialogState extends State<AlbumImageManagementDialog> {
  final Set<String> _selectedImageIds = <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load available images when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentManagementProvider>().loadContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * (isMobile ? 0.95 : 0.9),
        height: MediaQuery.of(context).size.height * (isMobile ? 0.9 : 0.8),
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.photo_library, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '管理图片 - ${widget.album.title}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ],
            ),
            const Divider(height: 20),
            // Images content - responsive layout
            Expanded(
              child: isMobile 
                  ? _buildMobileLayout(context)
                  : _buildDesktopLayout(context),
            ),
            const Divider(height: 20),
            // Action buttons at bottom
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Available images
        Expanded(
          flex: 2,
          child: _buildAvailableImages(context),
        ),
        const SizedBox(width: 20),
        // Album images
        Expanded(
          flex: 2,
          child: _buildAlbumImages(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).primaryColor,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Theme.of(context).textTheme.bodyLarge?.color,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate, size: 16),
                      const SizedBox(width: 4),
                      Text('可用图片', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library, size: 16),
                      const SizedBox(width: 4),
                      Text('图集图片', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableImages(context),
                _buildAlbumImages(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableImages(BuildContext context) {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 获取已添加到图集的图片ID列表
        final addedImageIds = widget.album.images?.map((img) => img.imageId).where((id) => id != null).cast<String>().toSet() ?? <String>{};
        
        final availableImages = provider.content
            .where((content) => 
                content.isImage && 
                content.id != null &&
                !addedImageIds.contains(content.id!))
            .toList();

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.photo_library_outlined, 
                         color: Theme.of(context).primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '可用图片 (${availableImages.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedImageIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '已选择 ${_selectedImageIds.length} 张',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: availableImages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, 
                                 size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('暂无可用图片', 
                                 style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width < 768 ? 3 : 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: availableImages.length,
                        itemBuilder: (context, index) {
                          final image = availableImages[index];
                          final isSelected = _selectedImageIds.contains(image.id);
                          
                          return _ContentItemThumbnail(
                            image: image,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  if (image.id != null) {
                                    _selectedImageIds.remove(image.id!);
                                  }
                                } else {
                                  if (image.id != null) {
                                    _selectedImageIds.add(image.id!);
                                  }
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 16, 
        horizontal: isMobile ? 16 : 20
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isMobile 
          ? _buildMobileActionButtons(context)
          : _buildDesktopActionButtons(context),
    );
  }

  Widget _buildDesktopActionButtons(BuildContext context) {
    return Row(
      children: [
        // Primary action - Add selected
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _selectedImageIds.isEmpty || _isLoading
                ? null
                : () => _addSelectedImages(context),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text('添加选中 (${_selectedImageIds.length})'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Secondary actions
        OutlinedButton.icon(
          onPressed: (widget.album.imageIds?.isEmpty ?? true) || _isLoading
              ? null
              : () => _removeAllImages(context),
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text('清空图集'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () => _refreshImages(context),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('刷新'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action - Add selected
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedImageIds.isEmpty || _isLoading
                ? null
                : () => _addSelectedImages(context),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text('添加选中 (${_selectedImageIds.length})'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (widget.album.imageIds?.isEmpty ?? true) || _isLoading
                    ? null
                    : () => _removeAllImages(context),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('清空'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () => _refreshImages(context),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('刷新'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlbumImages(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.photo_album, 
                     color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '图集图片 (${widget.album.imageIds?.length ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.album.coverImageId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '已设置封面',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (widget.album.images?.isEmpty ?? true)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_album_outlined, 
                             size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('图集中暂无图片', 
                             style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('从左侧选择图片添加到图集', 
                             style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 768 ? 3 : 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.album.images?.length ?? 0,
                    itemBuilder: (context, index) {
                      final image = widget.album.images?[index];
                      if (image == null) return const SizedBox.shrink();
                      final isCover = widget.album.coverImageId == image.imageId;
                      
                      return _AlbumImageThumbnail(
                        image: image,
                        isCover: isCover,
                        onRemove: () => image.imageId != null ? _removeImage(context, image.imageId!) : null,
                        onSetCover: () => image.imageId != null ? _setCoverImage(context, image.imageId!) : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addSelectedImages(BuildContext context) async {
    if (_selectedImageIds.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AlbumProvider>().addImagesToAlbum(
        widget.album.id,
        _selectedImageIds.toList(),
      );

      setState(() {
        _selectedImageIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${_selectedImageIds.length} images to album'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeImage(BuildContext context, String imageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AlbumProvider>().removeImagesFromAlbum(
        widget.album.id,
        [imageId],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image removed from album')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeAllImages(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All Images'),
        content: const Text('Are you sure you want to remove all images from this album?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AlbumProvider>().removeImagesFromAlbum(
        widget.album.id,
        widget.album.imageIds ?? [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All images removed from album')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setCoverImage(BuildContext context, String imageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AlbumProvider>().setAlbumCover(
        widget.album.id,
        imageId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover image updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting cover: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshImages(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        context.read<ContentManagementProvider>().loadContent(refresh: true),
        context.read<AlbumProvider>().getAlbum(widget.album.id),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _ImageThumbnail extends StatelessWidget {
  final AlbumImage image;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImageThumbnail({
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Image area
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    ImageThumbnail(
                      id: image.imageId,
                      filePath: image.imagePath,
                      skipThumbnail: true,
                      mimeType: image.mimeType,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                      errorWidget: const Icon(Icons.broken_image, size: 24),
                    ),
                    if (isSelected)
                      Container(
                        color: Colors.blue.withOpacity(0.2),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info area
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      image.mimeType ?? '图片',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.blue[700] : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      image.mimeType ?? '未知格式',
                      style: TextStyle(
                        fontSize: 8,
                        color: isSelected ? Colors.blue[600] : Colors.grey[500],
                      ),
                    ),
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

class _AlbumImageThumbnail extends StatelessWidget {
  final AlbumImage image;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback onSetCover;

  const _AlbumImageThumbnail({
    required this.image,
    required this.isCover,
    required this.onRemove,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCover ? Colors.blue : Colors.grey,
          width: isCover ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            ImageThumbnail(
              id: image.imageId,
              filePath: image.imagePath,
              skipThumbnail: true,
              mimeType: image.mimeType,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.zero,
              errorWidget: const Icon(Icons.broken_image, size: 32),
            ),
            if (isCover)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            Positioned(
              bottom: 4,
              right: 4,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'set_cover':
                      onSetCover();
                      break;
                    case 'remove':
                      onRemove();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'set_cover',
                    child: Row(
                      children: [
                        Icon(Icons.star),
                        SizedBox(width: 8),
                        Text('Set as Cover'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentItemThumbnail extends StatelessWidget {
  final ContentItem image;
  final bool isSelected;
  final VoidCallback onTap;

  const _ContentItemThumbnail({
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              ImageThumbnail(
                id: image.id,
                filePath: image.filePath,
                skipThumbnail: true,
                mimeType: image.mimeType,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
                errorWidget: const Icon(Icons.broken_image, size: 32),
              ),
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 3 : 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              if (!isMobile) // 只在桌面端显示详细信息
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          image.title ?? 'Untitled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (image.mimeType != null)
                          Text(
                            image.mimeType!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


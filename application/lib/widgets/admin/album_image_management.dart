import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/album.dart';
import '../../models/content_item.dart';

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
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Manage Images - ${widget.album.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            // Content
            Expanded(
              child: Row(
                children: [
                  // Available images
                  Expanded(
                    child: _buildAvailableImages(context),
                  ),
                  const SizedBox(width: 16),
                  // Action buttons
                  _buildActionButtons(context),
                  const SizedBox(width: 16),
                  // Album images
                  Expanded(
                    child: _buildAlbumImages(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableImages(BuildContext context) {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final availableImages = provider.content
            .where((content) => 
                content.isImage && 
                !(widget.album.imageIds?.contains(content.id) ?? false))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Images (${availableImages.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: availableImages.length,
                itemBuilder: (context, index) {
                  final image = availableImages[index];
                  final isSelected = _selectedImageIds.contains(image.id);
                  
                  return _ImageThumbnail(
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
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _selectedImageIds.isEmpty || _isLoading
              ? null
              : () => _addSelectedImages(context),
          icon: const Icon(Icons.arrow_forward),
          label: Text('Add (${_selectedImageIds.length})'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: (widget.album.imageIds?.isEmpty ?? true) || _isLoading
              ? null
              : () => _removeAllImages(context),
          icon: const Icon(Icons.clear_all),
          label: const Text('Remove All'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _isLoading
              ? null
              : () => _refreshImages(context),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildAlbumImages(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Album Images (${widget.album.imageIds?.length ?? 0})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: (widget.album.images?.isEmpty ?? true)
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No images in album'),
                    ],
                  ),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.album.images?.length ?? 0,
                  itemBuilder: (context, index) {
                    final image = widget.album.images![index];
                    final isCover = widget.album.coverImageId == image.id;
                    
                    return _AlbumImageThumbnail(
                      image: image,
                      isCover: isCover,
                      onRemove: () => image.id != null ? _removeImage(context, image.id!) : null,
                      onSetCover: () => image.id != null ? _setCoverImage(context, image.id!) : null,
                    );
                  },
                ),
        ),
      ],
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
  final ContentItem image;
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
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                image.filePath ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 32);
                },
              ),
              if (isSelected)
                Container(
                  color: Colors.blue.withOpacity(0.3),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                      size: 32,
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

class _AlbumImageThumbnail extends StatelessWidget {
  final ContentItem image;
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
            Image.network(
              image.filePath ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 32);
              },
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


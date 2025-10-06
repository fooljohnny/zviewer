import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../models/album.dart';
import '../../models/content_item.dart';
import 'album_form.dart';
import 'album_image_management.dart';

class AlbumDetailsView extends StatefulWidget {
  final Album album;

  const AlbumDetailsView({super.key, required this.album});

  @override
  State<AlbumDetailsView> createState() => _AlbumDetailsViewState();
}

class _AlbumDetailsViewState extends State<AlbumDetailsView> {
  @override
  void initState() {
    super.initState();
    // Load album details when the view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().getAlbum(widget.album.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlbumProvider>(
      builder: (context, provider, child) {
        final album = provider.currentAlbum ?? widget.album;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(album.displayTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, album),
                tooltip: 'Edit Album',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmation(context, album),
                tooltip: 'Delete Album',
              ),
            ],
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Album header
                      _buildAlbumHeader(context, album),
                      const SizedBox(height: 24),
                      // Album info
                      _buildAlbumInfo(context, album),
                      const SizedBox(height: 24),
                      // Images section
                      _buildImagesSection(context, album),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildAlbumHeader(BuildContext context, Album album) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Cover image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: album.hasCover
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        album.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.photo_album, size: 48);
                        },
                      ),
                    )
                  : const Icon(Icons.photo_album, size: 48),
            ),
            const SizedBox(width: 16),
            // Album details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.displayTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    album.displayDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatusChip(status: album.status),
                      const SizedBox(width: 8),
                      _VisibilityChip(isPublic: album.isPublic),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoItem(
                        icon: Icons.person,
                        label: 'Created by',
                        value: album.userName,
                      ),
                      const SizedBox(width: 24),
                      _InfoItem(
                        icon: Icons.photo,
                        label: 'Images',
                        value: album.imageCountDisplayText,
                      ),
                      const SizedBox(width: 24),
                      _InfoItem(
                        icon: Icons.visibility,
                        label: 'Views',
                        value: album.viewCount.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(BuildContext context, Album album) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Album Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Created',
              value: album.formattedCreatedAt,
            ),
            _InfoRow(
              label: 'Updated',
              value: album.formattedUpdatedAt,
            ),
            _InfoRow(
              label: 'Tags',
              value: album.tagsDisplayText,
            ),
            _InfoRow(
              label: 'Status',
              value: album.statusDisplayText,
            ),
            _InfoRow(
              label: 'Visibility',
              value: album.isPublic ? 'Public' : 'Private',
            ),
            _InfoRow(
              label: 'Statistics',
              value: album.statsDisplayText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, Album album) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Images (${album.imageCount})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AlbumImageManagementDialog(album: album),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Images'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AlbumImageManagementDialog(album: album),
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_search),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (album.images?.isEmpty ?? true)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No images in this album'),
                      SizedBox(height: 8),
                      Text('Add images to get started'),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: album.images?.length ?? 0,
                itemBuilder: (context, index) {
                  final image = album.images![index];
                  return _ImageThumbnail(
                    image: image,
                    isCover: album.coverImageId == image.id,
                    onSetCover: () => image.id != null ? _setCoverImage(context, album, image.id!) : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (context) => AlbumFormDialog(album: album),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album'),
        content: Text('Are you sure you want to delete "${album.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AlbumProvider>().deleteAlbum(album.id);
              Navigator.of(context).pop(); // Close details view
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setCoverImage(BuildContext context, Album album, String imageId) {
    context.read<AlbumProvider>().setAlbumCover(album.id, imageId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cover image updated')),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AlbumStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case AlbumStatus.draft:
        color = Colors.grey;
        text = 'Draft';
        break;
      case AlbumStatus.published:
        color = Colors.green;
        text = 'Published';
        break;
      case AlbumStatus.archived:
        color = Colors.orange;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  final bool isPublic;

  const _VisibilityChip({required this.isPublic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isPublic ? Colors.green : Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isPublic ? Colors.green : Colors.blue).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 14,
            color: isPublic ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? Colors.green : Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
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
}

class _ImageThumbnail extends StatelessWidget {
  final ContentItem image;
  final bool isCover;
  final VoidCallback onSetCover;

  const _ImageThumbnail({
    required this.image,
    required this.isCover,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[300],
            border: isCover
                ? Border.all(color: Colors.blue, width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image.filePath ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 32);
              },
            ),
          ),
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
              if (value == 'set_cover') {
                onSetCover();
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
            ],
          ),
        ),
      ],
    );
  }
}

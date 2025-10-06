import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../models/album.dart';
import '../common/glassmorphism_card.dart';
import 'album_details.dart';
import 'album_form.dart';
import 'album_filters.dart';

class AlbumManagementView extends StatefulWidget {
  const AlbumManagementView({super.key});

  @override
  State<AlbumManagementView> createState() => _AlbumManagementViewState();
}

class _AlbumManagementViewState extends State<AlbumManagementView> {
  bool _isGridView = true;
  String _sortBy = 'createdAt';
  final String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    // Load albums when the view is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlbumProvider>().loadAlbums(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlbumProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header with filters and controls
            _buildHeader(context, provider),
            // Album list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.albums.isEmpty
                      ? _buildEmptyState(context)
                      : _isGridView
                          ? _buildGridView(context, provider)
                          : _buildListView(context, provider),
            ),
            // Load more button
            if (provider.currentPage < provider.totalPages)
              _buildLoadMoreButton(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, AlbumProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // 搜索和筛选行
          Row(
            children: [
              // 搜索框
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: GlassmorphismCard(
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.0,
                      ),
                      decoration: const InputDecoration(
                        hintText: '搜索图集...',
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        provider.setSearchQuery(value);
                      },
                      onSubmitted: (value) {
                        provider.searchAlbums(value);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 筛选按钮
              SizedBox(
                height: 48,
                child: GlassmorphismButton(
                  onPressed: _showFilterDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '筛选',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 创建图集按钮
              SizedBox(
                height: 48,
                child: GlassmorphismButton(
                  onPressed: () => _showCreateAlbumDialog(context),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '创建图集',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 控制按钮行
          Row(
            children: [
              // 视图切换按钮
              GlassmorphismButton(
                onPressed: () {
                  setState(() {
                    _isGridView = true;
                  });
                },
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_view,
                      color: _isGridView ? Colors.blue : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '网格',
                      style: TextStyle(
                        color: _isGridView ? Colors.blue : Colors.white70,
                        fontSize: 12,
                        fontWeight: _isGridView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GlassmorphismButton(
                onPressed: () {
                  setState(() {
                    _isGridView = false;
                  });
                },
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list,
                      color: !_isGridView ? Colors.blue : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '列表',
                      style: TextStyle(
                        color: !_isGridView ? Colors.blue : Colors.white70,
                        fontSize: 12,
                        fontWeight: !_isGridView ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 排序按钮
              GlassmorphismButton(
                onPressed: _showSortDialog,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '排序',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No albums found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first album or try adjusting your filters.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateAlbumDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Album'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, AlbumProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.albums.length,
      itemBuilder: (context, index) {
        final album = provider.albums[index];
        return _AlbumCard(
          album: album,
          onTap: () => _showAlbumDetails(context, album),
          onEdit: () => _showEditAlbumDialog(context, album),
          onDelete: () => _showDeleteConfirmation(context, album),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, AlbumProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: provider.albums.length,
      itemBuilder: (context, index) {
        final album = provider.albums[index];
        return _AlbumListItem(
          album: album,
          onTap: () => _showAlbumDetails(context, album),
          onEdit: () => _showEditAlbumDialog(context, album),
          onDelete: () => _showDeleteConfirmation(context, album),
        );
      },
    );
  }

  Widget _buildLoadMoreButton(BuildContext context, AlbumProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: provider.isLoadingMore
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () => provider.loadMoreAlbums(),
                child: const Text('Load More'),
              ),
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AlbumFormDialog(),
    );
  }

  void _showEditAlbumDialog(BuildContext context, Album album) {
    showDialog(
      context: context,
      builder: (context) => AlbumFormDialog(album: album),
    );
  }

  void _showAlbumDetails(BuildContext context, Album album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlbumDetailsView(album: album),
      ),
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选选项'),
        content: const Text('筛选功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('排序选项'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('创建时间'),
              leading: Radio<String>(
                value: 'createdAt',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  context.read<AlbumProvider>().setSorting(_sortBy, _sortOrder);
                  context.read<AlbumProvider>().applyFilters();
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('更新时间'),
              leading: Radio<String>(
                value: 'updatedAt',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  context.read<AlbumProvider>().setSorting(_sortBy, _sortOrder);
                  context.read<AlbumProvider>().applyFilters();
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: const Text('标题'),
              leading: Radio<String>(
                value: 'title',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  context.read<AlbumProvider>().setSorting(_sortBy, _sortOrder);
                  context.read<AlbumProvider>().applyFilters();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlbumCard({
    required this.album,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: album.hasCover
                          ? Image.network(
                              album.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.photo_album, size: 48);
                              },
                            )
                          : const Icon(Icons.photo_album, size: 48),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _AlbumStatusBadge(status: album.status),
                  ),
                  // Action menu
                  Positioned(
                    top: 8,
                    left: 8,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit();
                            break;
                          case 'delete':
                            onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Album info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${album.userName}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.photo,
                          size: 12,
                          color: Colors.white.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          album.imageCountDisplayText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 9,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          album.formattedCreatedAt,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
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
}

class _AlbumListItem extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AlbumListItem({
    required this.album,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey[300],
          backgroundImage: album.hasCover
              ? NetworkImage(album.coverImageUrl!)
              : null,
          child: album.hasCover
              ? null
              : const Icon(Icons.photo_album),
        ),
        title: Text(album.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('by ${album.userName}'),
            Row(
              children: [
                Text(album.imageCountDisplayText),
                const SizedBox(width: 16),
                Text(album.formattedCreatedAt),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AlbumStatusBadge(status: album.status),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AlbumStatusBadge extends StatelessWidget {
  final AlbumStatus status;

  const _AlbumStatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
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


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/content_item.dart';
import 'content_details.dart';
import 'bulk_actions.dart';
import 'content_filters.dart';

class ContentManagementView extends StatefulWidget {
  const ContentManagementView({super.key});

  @override
  State<ContentManagementView> createState() => _ContentManagementViewState();
}

class _ContentManagementViewState extends State<ContentManagementView> {
  bool _isGridView = true;
  String _sortBy = 'uploadedAt';
  String _sortOrder = 'desc';

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Header with filters and controls
            _buildHeader(context, provider),
            // Content list
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : provider.content.isEmpty
                      ? _buildEmptyState(context)
                      : _isGridView
                          ? _buildGridView(context, provider)
                          : _buildListView(context, provider),
            ),
            // Bulk actions bar
            if (provider.selectedContentIds.isNotEmpty)
              BulkActionsBar(
                selectedCount: provider.selectedContentIds.length,
                onBulkAction: (action, contentIds) {
                  provider.performBulkAction(action, contentIds);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ContentManagementProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Content Management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              // View toggle
              ToggleButtons(
                isSelected: [_isGridView, !_isGridView],
                onPressed: (index) {
                  setState(() {
                    _isGridView = index == 0;
                  });
                },
                children: const [
                  Icon(Icons.grid_view),
                  Icon(Icons.list),
                ],
              ),
              const SizedBox(width: 16),
              // Sort dropdown
              DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  provider.setSorting(_sortBy, _sortOrder);
                },
                items: const [
                  DropdownMenuItem(value: 'uploadedAt', child: Text('Date')),
                  DropdownMenuItem(value: 'title', child: Text('Title')),
                  DropdownMenuItem(value: 'userName', child: Text('User')),
                  DropdownMenuItem(value: 'status', child: Text('Status')),
                ],
              ),
              const SizedBox(width: 8),
              // Sort order toggle
              IconButton(
                icon: Icon(_sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward),
                onPressed: () {
                  setState(() {
                    _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                  });
                  provider.setSorting(_sortBy, _sortOrder);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters
          const ContentFilters(),
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
            Icons.photo_library_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No content found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context, ContentManagementProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.content.length,
      itemBuilder: (context, index) {
        final content = provider.content[index];
        return _ContentCard(
          content: content,
          isSelected: provider.selectedContentIds.contains(content.id),
          onTap: () => _showContentDetails(context, content),
          onSelectionChanged: (selected) {
            provider.toggleContentSelection(content.id, selected);
          },
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, ContentManagementProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: provider.content.length,
      itemBuilder: (context, index) {
        final content = provider.content[index];
        return _ContentListItem(
          content: content,
          isSelected: provider.selectedContentIds.contains(content.id),
          onTap: () => _showContentDetails(context, content),
          onSelectionChanged: (selected) {
            provider.toggleContentSelection(content.id, selected);
          },
        );
      },
    );
  }

  void _showContentDetails(BuildContext context, ContentItem content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ContentDetailsView(content: content),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItem content;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  const _ContentCard({
    required this.content,
    required this.isSelected,
    required this.onTap,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: content.isImage
                        ? Image.network(
                            content.filePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 48);
                            },
                          )
                        : const Icon(Icons.play_circle_outline, size: 48),
                  ),
                  // Selection checkbox
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => onSelectionChanged(value ?? false),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _StatusBadge(status: content.status),
                  ),
                ],
              ),
            ),
            // Content info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${content.userName}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(content.uploadedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ContentListItem extends StatelessWidget {
  final ContentItem content;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  const _ContentListItem({
    required this.content,
    required this.isSelected,
    required this.onTap,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) => onSelectionChanged(value ?? false),
        ),
        title: Text(content.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('by ${content.userName}'),
            Text(_formatDate(content.uploadedAt)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: content.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final ContentStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case ContentStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case ContentStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case ContentStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
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

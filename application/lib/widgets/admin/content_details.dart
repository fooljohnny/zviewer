import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/content_item.dart';
import '../../models/admin_action.dart';

class ContentDetailsView extends StatefulWidget {
  final ContentItem content;

  const ContentDetailsView({super.key, required this.content});

  @override
  State<ContentDetailsView> createState() => _ContentDetailsViewState();
}

class _ContentDetailsViewState extends State<ContentDetailsView> {
  late ContentItem _content;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _content = widget.content;
    _loadAdminActions();
  }

  Future<void> _loadAdminActions() async {
    final provider = context.read<ContentManagementProvider>();
    if (_content.id != null) {
      await provider.loadContentAdminActions(_content.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_content.title ?? 'Unknown Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadAdminActions(),
          ),
        ],
      ),
      body: Consumer<ContentManagementProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content preview
                _buildContentPreview(context),
                const SizedBox(height: 24),
                // Content information
                _buildContentInfo(context),
                const SizedBox(height: 24),
                // Action buttons
                _buildActionButtons(context, provider),
                const SizedBox(height: 24),
                // Admin actions history
                _buildAdminActionsHistory(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentPreview(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media preview
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.grey[300],
            child: _content.isImage
                ? Image.network(
                    _content.filePath ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64),
                            SizedBox(height: 8),
                            Text('Failed to load image'),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_outline, size: 64),
                        SizedBox(height: 8),
                        Text('Video Preview'),
                      ],
                    ),
                  ),
          ),
          // Status badge
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _StatusBadge(status: _content.status),
                const Spacer(),
                Text(
                  'Uploaded ${_formatDate(_content.uploadedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Content Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Title', value: _content.title ?? 'Unknown'),
            _InfoRow(label: 'Description', value: _content.description ?? 'No description'),
            _InfoRow(label: 'Type', value: _content.type.name.toUpperCase()),
            _InfoRow(label: 'User', value: _content.userName ?? 'Unknown'),
            _InfoRow(label: 'User ID', value: _content.userId ?? 'Unknown'),
            _InfoRow(label: 'File Path', value: _content.filePath ?? 'Unknown'),
            _InfoRow(
              label: 'Categories',
              value: (_content.categories?.isEmpty ?? true)
                  ? 'None'
                  : _content.categories!.join(', '),
            ),
            if (_content.approvedAt != null)
              _InfoRow(
                label: 'Approved At',
                value: _formatDate(_content.approvedAt!),
              ),
            if (_content.approvedBy != null)
              _InfoRow(label: 'Approved By', value: _content.approvedBy!),
            if (_content.rejectionReason != null)
              _InfoRow(
                label: 'Rejection Reason',
                value: _content.rejectionReason!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ContentManagementProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_content.isPending) ...[
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _approveContent(provider),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _rejectContent(provider),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _categorizeContent(provider),
                  icon: const Icon(Icons.category),
                  label: const Text('Categorize'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _deleteContent(provider),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionsHistory(BuildContext context, ContentManagementProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Actions History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (provider.contentAdminActions.isEmpty)
              const Text('No admin actions recorded')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.contentAdminActions.length,
                itemBuilder: (context, index) {
                  final action = provider.contentAdminActions[index];
                  return _AdminActionItem(action: action);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveContent(ContentManagementProvider provider) async {
    setState(() => _isLoading = true);
    try {
        if (_content.id != null) {
          await provider.approveContent(_content.id!);
        }
      setState(() {
        _content = _content.copyWith(
          status: ContentStatus.approved,
          approvedAt: DateTime.now(),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving content: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectContent(ContentManagementProvider provider) async {
    final reason = await _showReasonDialog('Reject Content');
    if (reason != null && reason.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        if (_content.id != null) {
          await provider.rejectContent(_content.id!, reason);
        }
        setState(() {
          _content = _content.copyWith(
            status: ContentStatus.rejected,
            rejectionReason: reason,
          );
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Content rejected successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting content: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _categorizeContent(ContentManagementProvider provider) async {
    // TODO: Implement category selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category management coming soon')),
    );
  }

  Future<void> _deleteContent(ContentManagementProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Content'),
        content: const Text('Are you sure you want to delete this content? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = await _showReasonDialog('Delete Content');
      if (reason != null && reason.isNotEmpty) {
        setState(() => _isLoading = true);
        try {
          if (_content.id != null) {
            await provider.deleteContent(_content.id!, reason);
          }
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Content deleted successfully')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting content: $e')),
            );
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<String?> _showReasonDialog(String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AdminActionItem extends StatelessWidget {
  final AdminAction action;

  const _AdminActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor(action.actionType),
        child: Icon(
          _getActionIcon(action.actionType),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(action.actionDisplayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (action.reason != null) Text(action.reason!),
          Text(
            _formatTimestamp(action.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Text(
        'Admin ID: ${action.adminId}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Color _getActionColor(AdminActionType actionType) {
    switch (actionType) {
      case AdminActionType.approve:
        return Colors.green;
      case AdminActionType.reject:
        return Colors.red;
      case AdminActionType.delete:
        return Colors.red.shade800;
      case AdminActionType.categorize:
        return Colors.blue;
      case AdminActionType.flag:
        return Colors.orange;
      case AdminActionType.unflag:
        return Colors.orange.shade300;
    }
  }

  IconData _getActionIcon(AdminActionType actionType) {
    switch (actionType) {
      case AdminActionType.approve:
        return Icons.check;
      case AdminActionType.reject:
        return Icons.close;
      case AdminActionType.delete:
        return Icons.delete;
      case AdminActionType.categorize:
        return Icons.category;
      case AdminActionType.flag:
        return Icons.flag;
      case AdminActionType.unflag:
        return Icons.flag_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

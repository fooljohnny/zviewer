import 'package:flutter/material.dart';

class BulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final Function(String action, List<String> contentIds) onBulkAction;

  const BulkActionsBar({
    super.key,
    required this.selectedCount,
    required this.onBulkAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount item${selectedCount == 1 ? '' : 's'} selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children: [
              _BulkActionButton(
                icon: Icons.check,
                label: 'Approve',
                color: Colors.green,
                onPressed: () => _showBulkActionDialog(
                  context,
                  'Approve Content',
                  'Are you sure you want to approve the selected content?',
                  'approve',
                ),
              ),
              _BulkActionButton(
                icon: Icons.close,
                label: 'Reject',
                color: Colors.red,
                onPressed: () => _showBulkActionDialog(
                  context,
                  'Reject Content',
                  'Are you sure you want to reject the selected content?',
                  'reject',
                ),
              ),
              _BulkActionButton(
                icon: Icons.category,
                label: 'Categorize',
                color: Colors.blue,
                onPressed: () => _showBulkActionDialog(
                  context,
                  'Categorize Content',
                  'Are you sure you want to categorize the selected content?',
                  'categorize',
                ),
              ),
              _BulkActionButton(
                icon: Icons.delete,
                label: 'Delete',
                color: Colors.red.shade800,
                onPressed: () => _showBulkActionDialog(
                  context,
                  'Delete Content',
                  'Are you sure you want to delete the selected content? This action cannot be undone.',
                  'delete',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBulkActionDialog(
    BuildContext context,
    String title,
    String message,
    String action,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBulkAction(action, []);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getActionColor(action),
              foregroundColor: Colors.white,
            ),
            child: Text(_getActionLabel(action)),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'categorize':
        return Colors.blue;
      case 'delete':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  String _getActionLabel(String action) {
    switch (action) {
      case 'approve':
        return 'Approve';
      case 'reject':
        return 'Reject';
      case 'categorize':
        return 'Categorize';
      case 'delete':
        return 'Delete';
      default:
        return 'Action';
    }
  }
}

class _BulkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _BulkActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
      ),
    );
  }
}

class BulkActionDialog extends StatefulWidget {
  final String action;
  final List<String> contentIds;
  final Function(String action, List<String> contentIds, Map<String, dynamic> metadata) onConfirm;

  const BulkActionDialog({
    super.key,
    required this.action,
    required this.contentIds,
    required this.onConfirm,
  });

  @override
  State<BulkActionDialog> createState() => _BulkActionDialogState();
}

class _BulkActionDialogState extends State<BulkActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _metadataController = TextEditingController();
  Map<String, dynamic> _metadata = {};

  @override
  void dispose() {
    _reasonController.dispose();
    _metadataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getDialogTitle()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You are about to ${widget.action} ${widget.contentIds.length} item${widget.contentIds.length == 1 ? '' : 's'}.'),
              const SizedBox(height: 16),
              if (_requiresReason())
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    hintText: 'Enter reason for ${widget.action}...',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (_requiresReason() && (value == null || value.isEmpty)) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
              if (widget.action == 'categorize') ...[
                const SizedBox(height: 16),
                const Text('Categories:'),
                const SizedBox(height: 8),
                // TODO: Implement category selection
                const Text('Category selection coming soon...'),
              ],
              if (widget.action == 'delete') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone. All selected content will be permanently deleted.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getActionColor(),
            foregroundColor: Colors.white,
          ),
          child: Text(_getActionLabel()),
        ),
      ],
    );
  }

  String _getDialogTitle() {
    switch (widget.action) {
      case 'approve':
        return 'Approve Content';
      case 'reject':
        return 'Reject Content';
      case 'categorize':
        return 'Categorize Content';
      case 'delete':
        return 'Delete Content';
      default:
        return 'Bulk Action';
    }
  }

  String _getActionLabel() {
    switch (widget.action) {
      case 'approve':
        return 'Approve';
      case 'reject':
        return 'Reject';
      case 'categorize':
        return 'Categorize';
      case 'delete':
        return 'Delete';
      default:
        return 'Confirm';
    }
  }

  Color _getActionColor() {
    switch (widget.action) {
      case 'approve':
        return Colors.green;
      case 'reject':
        return Colors.red;
      case 'categorize':
        return Colors.blue;
      case 'delete':
        return Colors.red.shade800;
      default:
        return Colors.grey;
    }
  }

  bool _requiresReason() {
    return widget.action == 'reject' || widget.action == 'delete';
  }

  void _confirmAction() {
    if (_formKey.currentState!.validate()) {
      final metadata = <String, dynamic>{
        if (_reasonController.text.isNotEmpty) 'reason': _reasonController.text,
        ..._metadata,
      };
      
      widget.onConfirm(widget.action, widget.contentIds, metadata);
      Navigator.of(context).pop();
    }
  }
}

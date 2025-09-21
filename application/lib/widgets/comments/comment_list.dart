import 'package:flutter/material.dart';
import '../../models/comment.dart';
import 'comment_item.dart';

class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Function(Comment comment)? onEditComment;
  final Function(Comment comment)? onDeleteComment;
  final bool canEdit;
  final bool canDelete;

  const CommentList({
    super.key,
    required this.comments,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.onEditComment,
    this.onDeleteComment,
    this.canEdit = false,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && comments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null && comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load comments',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    if (comments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share your thoughts!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'Comments (${comments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return CommentItem(
                comment: comment,
                onEdit: canEdit ? () => onEditComment?.call(comment) : null,
                onDelete: canDelete ? () => onDeleteComment?.call(comment) : null,
                canEdit: canEdit,
                canDelete: canDelete,
              );
            },
          ),
        ),
      ],
    );
  }
}


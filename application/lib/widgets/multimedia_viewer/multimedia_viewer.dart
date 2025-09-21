import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'image_viewer.dart';
import 'video_viewer.dart';
import '../comments/comment_input.dart';
import '../comments/comment_list.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';

class MultimediaViewer extends StatefulWidget {
  final String mediaPath;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const MultimediaViewer({
    super.key,
    required this.mediaPath,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<MultimediaViewer> createState() => _MultimediaViewerState();
}

class _MultimediaViewerState extends State<MultimediaViewer> {
  late String _mediaId;

  @override
  void initState() {
    super.initState();
    // Generate a media ID based on the file path
    _mediaId = widget.mediaPath.hashCode.toString();
    
    // Load comments for this media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().loadComments(_mediaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, CommentProvider>(
      builder: (context, authProvider, commentProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        
        return Column(
          children: [
            // Media viewer section
            Expanded(
              flex: 3,
              child: _buildMediaViewer(),
            ),
            // Comments section
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Comment input
                  CommentInput(
                    mediaId: _mediaId,
                    isAuthenticated: isAuthenticated,
                    isLoading: commentProvider.isLoading,
                    error: commentProvider.error,
                    onSubmit: (content) => _submitComment(content),
                    onClearError: () => commentProvider.clearError(),
                  ),
                  // Comment list
                  Expanded(
                    child: CommentList(
                      comments: commentProvider.comments,
                      isLoading: commentProvider.isLoading,
                      error: commentProvider.error,
                      onRetry: () => commentProvider.refreshComments(),
                      onEditComment: (comment) => _editComment(comment),
                      onDeleteComment: (comment) => _deleteComment(comment),
                      canEdit: isAuthenticated,
                      canDelete: isAuthenticated,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaViewer() {
    // Determine if the file is an image or video based on extension
    final extension = widget.mediaPath.toLowerCase().split('.').last;
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
    final isVideo = ['mp4', 'webm'].contains(extension);

    if (isImage) {
      return ImageViewer(
        imagePath: widget.mediaPath,
        onPrevious: widget.onPrevious,
        onNext: widget.onNext,
      );
    } else if (isVideo) {
      return VideoViewer(
        videoPath: widget.mediaPath,
        onPrevious: widget.onPrevious,
        onNext: widget.onNext,
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Unsupported media format',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              'Supported formats: JPG, PNG, WebP, MP4, WebM',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _submitComment(String content) async {
    final success = await context.read<CommentProvider>().postComment(
      content,
      _mediaId,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _editComment(comment) async {
    // TODO: Implement comment editing dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment editing not implemented yet'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteComment(comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
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

    if (confirmed == true && mounted) {
      final success = await context.read<CommentProvider>().deleteComment(comment.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

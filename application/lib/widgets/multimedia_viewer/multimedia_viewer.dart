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
  final String? albumDescription;

  const MultimediaViewer({
    super.key,
    required this.mediaPath,
    this.onPrevious,
    this.onNext,
    this.albumDescription,
  });

  @override
  State<MultimediaViewer> createState() => _MultimediaViewerState();
}

class _MultimediaViewerState extends State<MultimediaViewer> {
  late String _mediaId;
  late CommentProvider _commentProvider;

  @override
  void initState() {
    super.initState();
    // Generate a media ID based on the file path
    _mediaId = widget.mediaPath.hashCode.toString();
    
    // Initialize comment provider
    _commentProvider = CommentProvider();
    
    // Load comments for this media
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentProvider.loadComments(_mediaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isAuthenticated = authProvider.isAuthenticated;
        
        // For mobile, show full-screen image with description overlay
        return Stack(
          children: [
            // Full-screen media viewer
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: _buildMediaViewer(),
            ),
            // Description overlay (only for images)
            if (_isImageFile())
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDescriptionOverlay(),
              ),
            // Navigation controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildNavigationControls(),
            ),
          ],
        );
      },
    );
  }

  bool _isImageFile() {
    final extension = widget.mediaPath.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }

  Widget _buildDescriptionOverlay() {
    // Only show description if it exists
    if (widget.albumDescription == null || widget.albumDescription!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description text
            Text(
              '图集描述',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.albumDescription!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        // Previous/Next buttons
        Row(
          children: [
            if (widget.onPrevious != null)
              GestureDetector(
                onTap: widget.onPrevious,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            if (widget.onNext != null)
              GestureDetector(
                onTap: widget.onNext,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ],
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
    final success = await _commentProvider.postComment(content);
    
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
      final success = await _commentProvider.deleteComment('', comment.id);
      
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

  @override
  void dispose() {
    _commentProvider.dispose();
    super.dispose();
  }
}

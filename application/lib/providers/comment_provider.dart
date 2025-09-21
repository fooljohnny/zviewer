import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class CommentProvider with ChangeNotifier {
  final CommentService _commentService;
  
  // State
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;
  String? _currentMediaId;

  CommentProvider({CommentService? commentService})
      : _commentService = commentService ?? CommentService();

  // Getters
  List<Comment> get comments => List.unmodifiable(_comments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentMediaId => _currentMediaId;
  bool get hasComments => _comments.isNotEmpty;

  /// Load comments for a specific media item
  Future<void> loadComments(String mediaId) async {
    if (_currentMediaId == mediaId && _comments.isNotEmpty) {
      return; // Already loaded
    }

    _setLoading(true);
    _clearError();
    _currentMediaId = mediaId;

    try {
      final comments = await _commentService.getComments(mediaId);
      _comments = comments;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load comments: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Post a new comment
  Future<bool> postComment(String content, String mediaId) async {
    if (content.trim().isEmpty) {
      _setError('Comment cannot be empty');
      return false;
    }

    // Validate content
    final validationError = Comment.validateContent(content);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final newComment = await _commentService.postComment(
        content: content,
        mediaId: mediaId,
      );

      // Add to the beginning of the list (newest first)
      _comments.insert(0, newComment);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to post comment: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update a comment
  Future<bool> updateComment(String commentId, String content) async {
    if (content.trim().isEmpty) {
      _setError('Comment cannot be empty');
      return false;
    }

    // Validate content
    final validationError = Comment.validateContent(content);
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final updatedComment = await _commentService.updateComment(
        commentId: commentId,
        content: content,
      );

      // Find and replace the comment
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        _comments[index] = updatedComment;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _setError('Failed to update comment: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    _setLoading(true);
    _clearError();

    try {
      await _commentService.deleteComment(commentId);

      // Remove from the list
      _comments.removeWhere((c) => c.id == commentId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete comment: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh comments for current media
  Future<void> refreshComments() async {
    if (_currentMediaId != null) {
      await loadComments(_currentMediaId!);
    }
  }

  /// Clear comments and reset state
  void clearComments() {
    _comments.clear();
    _currentMediaId = null;
    _clearError();
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _commentService.dispose();
    super.dispose();
  }
}


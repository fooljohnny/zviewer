import 'package:flutter/foundation.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

/// 评论状态管理
class CommentProvider extends ChangeNotifier {
  final CommentService _commentService;
  
  // 状态管理
  final Map<String, List<Comment>> _comments = {};
  final Map<String, bool> _isLoading = {};
  final Map<String, String?> _errors = {};
  final Map<String, bool> _isSubmitting = {};
  
  // 当前媒体评论状态（用于多媒体查看器）
  List<Comment> _currentComments = [];
  bool _isCurrentLoading = false;
  String? _currentError;

  CommentProvider({CommentService? commentService}) 
      : _commentService = commentService ?? CommentService();

  // Getters
  List<Comment> getComments(String albumId) => _comments[albumId] ?? [];
  bool isLoading(String albumId) => _isLoading[albumId] ?? false;
  bool isSubmitting(String albumId) => _isSubmitting[albumId] ?? false;
  String? getError(String albumId) => _errors[albumId];
  
  // 当前媒体评论的getters（用于多媒体查看器）
  List<Comment> get comments => _currentComments;
  bool get isCurrentLoading => _isCurrentLoading;
  String? get currentError => _currentError;

  /// 加载图集评论
  Future<void> loadAlbumComments(String albumId) async {
    if (_isLoading[albumId] == true) return;

    _setLoading(albumId, true);
    _clearError(albumId);

    try {
      final comments = await _commentService.getAlbumComments(albumId);
      _comments[albumId] = comments;
      notifyListeners();
    } catch (e) {
      _setError(albumId, '加载评论失败: $e');
    } finally {
      _setLoading(albumId, false);
    }
  }

  /// 添加评论
  Future<bool> addComment(String albumId, String content, {String? parentId}) async {
    _setSubmitting(albumId, true);
    _clearError(albumId);

    try {
      final request = CreateCommentRequest(
        content: content,
        albumId: albumId,
        parentId: parentId,
      );

      final comment = await _commentService.addComment(request);
      if (comment != null) {
        _comments[albumId] = _comments[albumId] ?? [];
        _comments[albumId]!.add(comment);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(albumId, '添加评论失败: $e');
      return false;
    } finally {
      _setSubmitting(albumId, false);
    }
  }

  /// 删除评论
  Future<bool> deleteComment(String albumId, String commentId) async {
    try {
      final success = await _commentService.deleteComment(commentId);
      if (success) {
        _comments[albumId]?.removeWhere((comment) => comment.id == commentId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError(albumId, '删除评论失败: $e');
      return false;
    }
  }

  /// 点赞评论
  Future<bool> likeComment(String albumId, String commentId) async {
    try {
      final success = await _commentService.likeComment(commentId);
      if (success) {
        final commentIndex = _comments[albumId]?.indexWhere((c) => c.id == commentId);
        if (commentIndex != null && commentIndex >= 0) {
          final comment = _comments[albumId]![commentIndex];
          _comments[albumId]![commentIndex] = comment.copyWith(
            likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
            isLiked: !comment.isLiked,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError(albumId, '点赞失败: $e');
      return false;
    }
  }

  /// 取消点赞评论
  Future<bool> unlikeComment(String albumId, String commentId) async {
    try {
      final success = await _commentService.unlikeComment(commentId);
      if (success) {
        final commentIndex = _comments[albumId]?.indexWhere((c) => c.id == commentId);
        if (commentIndex != null && commentIndex >= 0) {
          final comment = _comments[albumId]![commentIndex];
          _comments[albumId]![commentIndex] = comment.copyWith(
            likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
            isLiked: !comment.isLiked,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError(albumId, '取消点赞失败: $e');
      return false;
    }
  }

  /// 清除错误
  void clearError(String albumId) {
    _clearError(albumId);
    notifyListeners();
  }

  /// 刷新评论
  Future<void> refreshComments(String albumId) async {
    _comments.remove(albumId);
    await loadAlbumComments(albumId);
  }

  // 私有方法
  void _setLoading(String albumId, bool loading) {
    _isLoading[albumId] = loading;
    notifyListeners();
  }

  void _setSubmitting(String albumId, bool submitting) {
    _isSubmitting[albumId] = submitting;
    notifyListeners();
  }

  void _setError(String albumId, String error) {
    _errors[albumId] = error;
    notifyListeners();
  }

  void _clearError(String albumId) {
    _errors.remove(albumId);
  }

  /// 加载评论（用于多媒体查看器）
  Future<void> loadComments(String mediaId) async {
    _isCurrentLoading = true;
    _currentError = null;
    notifyListeners();

    try {
      // 这里应该调用相应的API来获取媒体评论
      // 暂时使用空列表，实际实现需要根据API调整
      _currentComments = [];
      notifyListeners();
    } catch (e) {
      _currentError = '加载评论失败: $e';
      notifyListeners();
    } finally {
      _isCurrentLoading = false;
      notifyListeners();
    }
  }

  /// 发布评论（用于多媒体查看器）
  Future<bool> postComment(String content, {String? parentId}) async {
    _isCurrentLoading = true;
    _currentError = null;
    notifyListeners();

    try {
      // 这里应该调用相应的API来发布评论
      // 暂时返回成功，实际实现需要根据API调整
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
      notifyListeners();
      return true;
    } catch (e) {
      _currentError = '发布评论失败: $e';
      notifyListeners();
      return false;
    } finally {
      _isCurrentLoading = false;
      notifyListeners();
    }
  }

  /// 刷新评论（用于多媒体查看器）
  Future<void> refreshCurrentComments() async {
    await loadComments('');
  }

  /// 清除错误（用于多媒体查看器）
  void clearCurrentError() {
    _currentError = null;
    notifyListeners();
  }
}

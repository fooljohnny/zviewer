import 'dart:async';
import 'package:flutter/material.dart';
import '../services/danmaku_service.dart';

/// 弹幕评论状态管理
class DanmakuProvider extends ChangeNotifier {
  final DanmakuService _danmakuService = DanmakuService();
  final Map<String, List<DanmakuComment>> _comments = {};
  final Map<String, bool> _isLoading = {};
  final Map<String, String?> _errors = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// 获取评论列表
  List<DanmakuComment> getComments(String mediaId) {
    return _comments[mediaId] ?? [];
  }

  /// 是否正在加载
  bool isLoading(String mediaId) {
    return _isLoading[mediaId] ?? false;
  }

  /// 获取错误信息
  String? getError(String mediaId) {
    return _errors[mediaId];
  }

  /// 加载评论
  Future<void> loadComments(String mediaId) async {
    if (_isLoading[mediaId] == true) return;

    _setLoading(mediaId, true);
    _clearError(mediaId);

    try {
      // 订阅评论流
      _subscriptions[mediaId] = _danmakuService
          .getCommentsStream(mediaId)
          .listen((comments) {
        _comments[mediaId] = comments;
        notifyListeners();
      });

      // 获取现有评论
      _comments[mediaId] = _danmakuService.getComments(mediaId);
      notifyListeners();
    } catch (e) {
      _setError(mediaId, '加载评论失败: $e');
    } finally {
      _setLoading(mediaId, false);
    }
  }

  /// 添加评论
  Future<bool> addComment(String mediaId, String content, String author) async {
    _setLoading(mediaId, true);
    _clearError(mediaId);

    try {
      final success = await _danmakuService.addComment(mediaId, content, author);
      if (!success) {
        _setError(mediaId, '添加评论失败');
      }
      return success;
    } catch (e) {
      _setError(mediaId, '添加评论失败: $e');
      return false;
    } finally {
      _setLoading(mediaId, false);
    }
  }

  /// 删除评论
  Future<bool> deleteComment(String mediaId, String commentId) async {
    try {
      final success = await _danmakuService.deleteComment(mediaId, commentId);
      if (!success) {
        _setError(mediaId, '删除评论失败');
      }
      return success;
    } catch (e) {
      _setError(mediaId, '删除评论失败: $e');
      return false;
    }
  }

  /// 清空评论
  void clearComments(String mediaId) {
    _danmakuService.clearComments(mediaId);
  }

  /// 清除错误
  void clearError(String mediaId) {
    _clearError(mediaId);
    notifyListeners();
  }

  /// 设置加载状态
  void _setLoading(String mediaId, bool loading) {
    _isLoading[mediaId] = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String mediaId, String error) {
    _errors[mediaId] = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError(String mediaId) {
    _errors.remove(mediaId);
  }

  /// 取消订阅
  void unsubscribe(String mediaId) {
    _subscriptions[mediaId]?.cancel();
    _subscriptions.remove(mediaId);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _danmakuService.dispose();
    super.dispose();
  }
}


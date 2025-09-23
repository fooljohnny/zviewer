import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 弹幕评论服务
/// 管理弹幕评论的创建、存储和实时更新
class DanmakuService {
  static final DanmakuService _instance = DanmakuService._internal();
  factory DanmakuService() => _instance;
  DanmakuService._internal();

  final Map<String, List<DanmakuComment>> _comments = {};
  final Map<String, StreamController<List<DanmakuComment>>> _streamControllers = {};
  final math.Random _random = math.Random();

  /// 获取指定媒体的评论流
  Stream<List<DanmakuComment>> getCommentsStream(String mediaId) {
    if (!_streamControllers.containsKey(mediaId)) {
      _streamControllers[mediaId] = StreamController<List<DanmakuComment>>.broadcast();
      _comments[mediaId] = [];
    }
    return _streamControllers[mediaId]!.stream;
  }

  /// 添加评论
  Future<bool> addComment(String mediaId, String content, String author) async {
    try {
      final comment = DanmakuComment(
        id: _generateId(),
        content: content,
        author: author,
        timestamp: DateTime.now(),
        color: _getRandomColor(),
        speed: _getRandomSpeed(),
      );

      if (!_comments.containsKey(mediaId)) {
        _comments[mediaId] = [];
      }

      _comments[mediaId]!.add(comment);
      _notifyListeners(mediaId);

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  /// 获取评论列表
  List<DanmakuComment> getComments(String mediaId) {
    return _comments[mediaId] ?? [];
  }

  /// 删除评论
  Future<bool> deleteComment(String mediaId, String commentId) async {
    try {
      if (_comments.containsKey(mediaId)) {
        _comments[mediaId]!.removeWhere((comment) => comment.id == commentId);
        _notifyListeners(mediaId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// 清空评论
  void clearComments(String mediaId) {
    if (_comments.containsKey(mediaId)) {
      _comments[mediaId]!.clear();
      _notifyListeners(mediaId);
    }
  }

  /// 生成随机颜色
  Color _getRandomColor() {
    final colors = [
      Colors.white,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.yellow,
      Colors.cyan,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  /// 生成随机速度
  double _getRandomSpeed() {
    return 0.8 + _random.nextDouble() * 0.4; // 0.8-1.2倍速度
  }

  /// 生成唯一ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           _random.nextInt(1000).toString();
  }

  /// 通知监听器
  void _notifyListeners(String mediaId) {
    if (_streamControllers.containsKey(mediaId)) {
      _streamControllers[mediaId]!.add(_comments[mediaId] ?? []);
    }
  }

  /// 释放资源
  void dispose() {
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();
    _comments.clear();
  }
}

/// 弹幕评论数据模型
class DanmakuComment {
  final String id;
  final String content;
  final String author;
  final DateTime timestamp;
  final Color color;
  final double speed;

  const DanmakuComment({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    this.color = Colors.white,
    this.speed = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'timestamp': timestamp.toIso8601String(),
      'color': color.value,
      'speed': speed,
    };
  }

  factory DanmakuComment.fromJson(Map<String, dynamic> json) {
    return DanmakuComment(
      id: json['id'],
      content: json['content'],
      author: json['author'],
      timestamp: DateTime.parse(json['timestamp']),
      color: Color(json['color'] ?? Colors.white.value),
      speed: json['speed']?.toDouble() ?? 1.0,
    );
  }
}


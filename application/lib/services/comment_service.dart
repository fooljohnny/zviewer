import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/comment.dart';
import 'auth_service.dart';

/// 评论服务
class CommentService {
  final AuthService _authService = AuthService();

  /// 获取图集的评论列表
  Future<List<Comment>> getAlbumComments(String albumId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.commentsUrl}/album/$albumId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['comments'] != null) {
          return (data['comments'] as List)
              .map((comment) => Comment.fromJson(comment))
              .toList();
        }
      }
      
      throw Exception('获取评论失败: ${response.statusCode}');
    } catch (e) {
      print('Error getting album comments: $e');
      rethrow;
    }
  }

  /// 添加评论
  Future<Comment?> addComment(CreateCommentRequest request) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.post(
        Uri.parse(AppConfig.commentsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['comment'] != null) {
          return Comment.fromJson(data['comment']);
        }
      }
      
      throw Exception('添加评论失败: ${response.statusCode}');
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  /// 删除评论
  Future<bool> deleteComment(String commentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.commentsUrl}/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// 点赞评论
  Future<bool> likeComment(String commentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.commentsUrl}/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error liking comment: $e');
      return false;
    }
  }

  /// 取消点赞评论
  Future<bool> unlikeComment(String commentId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.commentsUrl}/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error unliking comment: $e');
      return false;
    }
  }
}
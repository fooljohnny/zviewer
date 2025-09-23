import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment.dart';
import '../config/api_config.dart';

class CommentService {
  static String get _baseUrl => ApiConfig.commentsUrl;
  
  final http.Client _client;
  final String? _authToken;

  CommentService({
    http.Client? client,
    String? authToken,
  }) : _client = client ?? http.Client(),
       _authToken = authToken;

  /// Post a new comment
  Future<Comment> postComment({
    required String content,
    required String mediaId,
  }) async {
    if (_authToken == null) {
      throw const CommentException('Authentication required to post comments');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'content': content.trim(),
          'mediaId': mediaId,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Comment.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const CommentException('Authentication failed');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw CommentException(error['message'] ?? 'Invalid comment data');
      } else {
        throw CommentException('Failed to post comment: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentException) rethrow;
      throw CommentException('Network error: ${e.toString()}');
    }
  }

  /// Get comments for a specific media item
  Future<List<Comment>> getComments(String mediaId) async {
    if (_authToken == null) {
      // Return empty list instead of throwing exception for better UX
      return [];
    }

    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/comments/$mediaId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final commentsList = data['comments'] as List<dynamic>;
        return commentsList
            .map((json) => Comment.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw const CommentException('Authentication failed');
      } else if (response.statusCode == 404) {
        return []; // No comments found
      } else {
        throw CommentException('Failed to fetch comments: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentException) rethrow;
      throw CommentException('Network error: ${e.toString()}');
    }
  }

  /// Update a comment
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    if (_authToken == null) {
      throw const CommentException('Authentication required to update comments');
    }

    try {
      final response = await _client.put(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'content': content.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Comment.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const CommentException('Authentication failed');
      } else if (response.statusCode == 403) {
        throw const CommentException('Not authorized to update this comment');
      } else if (response.statusCode == 404) {
        throw const CommentException('Comment not found');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw CommentException(error['message'] ?? 'Invalid comment data');
      } else {
        throw CommentException('Failed to update comment: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentException) rethrow;
      throw CommentException('Network error: ${e.toString()}');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    if (_authToken == null) {
      throw const CommentException('Authentication required to delete comments');
    }

    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/comments/$commentId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 204) {
        return; // Success
      } else if (response.statusCode == 401) {
        throw const CommentException('Authentication failed');
      } else if (response.statusCode == 403) {
        throw const CommentException('Not authorized to delete this comment');
      } else if (response.statusCode == 404) {
        throw const CommentException('Comment not found');
      } else {
        throw CommentException('Failed to delete comment: ${response.statusCode}');
      }
    } catch (e) {
      if (e is CommentException) rethrow;
      throw CommentException('Network error: ${e.toString()}');
    }
  }

  /// Update authentication token
  void updateAuthToken(String? token) {
    // This would be used to update the token when user logs in/out
    // For now, we'll create a new instance with the updated token
  }

  void dispose() {
    _client.close();
  }
}

class CommentException implements Exception {
  final String message;
  
  const CommentException(this.message);
  
  @override
  String toString() => 'CommentException: $message';
}

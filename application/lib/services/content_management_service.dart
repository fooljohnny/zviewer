import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content_item.dart';
import '../models/content_category.dart';
import '../models/admin_action.dart';

class ContentManagementService {
  static const String _baseUrl = 'https://api.zviewer.com/api/admin';
  final String? _authToken;

  ContentManagementService({String? authToken}) : _authToken = authToken;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Content Management Methods

  /// Get content list with filtering and search
  Future<ContentListResponse> getContentList({
    int page = 1,
    int limit = 20,
    ContentStatus? status,
    ContentType? type,
    String? search,
    String? userId,
    List<String>? categories,
    String sortBy = 'uploadedAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      if (status != null) {
        queryParams['status'] = status.name;
      }
      if (type != null) {
        queryParams['type'] = type.name;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }
      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }

      final uri = Uri.parse('$_baseUrl/content').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentListResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to fetch content list: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error fetching content list: $e');
    }
  }

  /// Get single content item by ID
  Future<ContentItem> getContentItem(String contentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentItem.fromJson(data['content']);
      } else {
        throw ContentManagementException(
          'Failed to fetch content item: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error fetching content item: $e');
    }
  }

  /// Approve content
  Future<ContentActionResponse> approveContent(String contentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId/approve');
      final response = await http.put(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentActionResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to approve content: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error approving content: $e');
    }
  }

  /// Reject content
  Future<ContentActionResponse> rejectContent(
    String contentId,
    String reason,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId/reject');
      final body = json.encode({'reason': reason});
      final response = await http.put(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentActionResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to reject content: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error rejecting content: $e');
    }
  }

  /// Delete content
  Future<ContentActionResponse> deleteContent(
    String contentId,
    String reason,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId');
      final body = json.encode({'reason': reason});
      final response = await http.delete(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentActionResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to delete content: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error deleting content: $e');
    }
  }

  /// Categorize content
  Future<ContentActionResponse> categorizeContent(
    String contentId,
    List<String> categories,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId/categorize');
      final body = json.encode({'categories': categories});
      final response = await http.put(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentActionResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to categorize content: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error categorizing content: $e');
    }
  }

  /// Bulk operations
  Future<BulkActionResponse> bulkAction(
    String action,
    List<String> contentIds, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/bulk');
      final body = json.encode({
        'action': action,
        'contentIds': contentIds,
        'metadata': metadata ?? {},
      });
      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BulkActionResponse.fromJson(data);
      } else {
        throw ContentManagementException(
          'Failed to perform bulk action: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error performing bulk action: $e');
    }
  }

  // Category Management Methods

  /// Get all categories
  Future<List<ContentCategory>> getCategories() async {
    try {
      final uri = Uri.parse('$_baseUrl/categories');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesJson = data['categories'] as List;
        return categoriesJson
            .map((json) => ContentCategory.fromJson(json))
            .toList();
      } else {
        throw ContentManagementException(
          'Failed to fetch categories: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error fetching categories: $e');
    }
  }

  /// Create new category
  Future<ContentCategory> createCategory(ContentCategory category) async {
    try {
      final uri = Uri.parse('$_baseUrl/categories');
      final body = json.encode(category.toJson());
      final response = await http.post(uri, headers: _headers, body: body);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return ContentCategory.fromJson(data['category']);
      } else {
        throw ContentManagementException(
          'Failed to create category: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error creating category: $e');
    }
  }

  /// Update category
  Future<ContentCategory> updateCategory(ContentCategory category) async {
    try {
      final uri = Uri.parse('$_baseUrl/categories/${category.id}');
      final body = json.encode(category.toJson());
      final response = await http.put(uri, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ContentCategory.fromJson(data['category']);
      } else {
        throw ContentManagementException(
          'Failed to update category: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error updating category: $e');
    }
  }

  /// Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      final uri = Uri.parse('$_baseUrl/categories/$categoryId');
      final response = await http.delete(uri, headers: _headers);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ContentManagementException(
          'Failed to delete category: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error deleting category: $e');
    }
  }

  // Audit and Admin Action Methods

  /// Get admin actions for content
  Future<List<AdminAction>> getContentAdminActions(String contentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/content/$contentId/actions');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final actionsJson = data['actions'] as List;
        return actionsJson
            .map((json) => AdminAction.fromJson(json))
            .toList();
      } else {
        throw ContentManagementException(
          'Failed to fetch admin actions: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error fetching admin actions: $e');
    }
  }

  /// Get recent admin actions
  Future<List<AdminAction>> getRecentAdminActions({
    int limit = 50,
    String? adminId,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (adminId != null) {
        queryParams['adminId'] = adminId;
      }

      final uri = Uri.parse('$_baseUrl/actions').replace(
        queryParameters: queryParams,
      );
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final actionsJson = data['actions'] as List;
        return actionsJson
            .map((json) => AdminAction.fromJson(json))
            .toList();
      } else {
        throw ContentManagementException(
          'Failed to fetch recent actions: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      throw ContentManagementException('Error fetching recent actions: $e');
    }
  }
}

// Response Models

class ContentListResponse {
  final List<ContentItem> content;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  ContentListResponse({
    required this.content,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory ContentListResponse.fromJson(Map<String, dynamic> json) {
    return ContentListResponse(
      content: (json['content'] as List)
          .map((item) => ContentItem.fromJson(item))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}

class ContentActionResponse {
  final bool success;
  final String message;
  final ContentItem? content;

  ContentActionResponse({
    required this.success,
    required this.message,
    this.content,
  });

  factory ContentActionResponse.fromJson(Map<String, dynamic> json) {
    return ContentActionResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      content: json['content'] != null
          ? ContentItem.fromJson(json['content'])
          : null,
    );
  }
}

class BulkActionResponse {
  final bool success;
  final int processed;
  final int failed;
  final List<String> errors;

  BulkActionResponse({
    required this.success,
    required this.processed,
    required this.failed,
    required this.errors,
  });

  factory BulkActionResponse.fromJson(Map<String, dynamic> json) {
    return BulkActionResponse(
      success: json['success'] as bool,
      processed: json['processed'] as int,
      failed: json['failed'] as int,
      errors: (json['errors'] as List).cast<String>(),
    );
  }
}

// Exception Classes

class ContentManagementException implements Exception {
  final String message;
  final int? statusCode;

  ContentManagementException(this.message, [this.statusCode]);

  @override
  String toString() => 'ContentManagementException: $message';
}

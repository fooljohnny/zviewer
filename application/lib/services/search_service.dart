import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/album.dart';
import '../models/content_item.dart';
import 'auth_service.dart';

/// 搜索服务
class SearchService {
  final AuthService _authService = AuthService();
  Timer? _debounceTimer;
  final Duration _debounceDelay = const Duration(milliseconds: 500);

  /// 搜索专辑
  Future<List<Album>> searchAlbums(String query, {
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final Map<String, dynamic> params = {
        'q': query,
        'page': page,
        'limit': limit,
      };

      // 添加筛选参数
      if (filters != null) {
        params.addAll(filters);
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/search/albums').replace(
          queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['albums'] != null) {
          return (data['albums'] as List)
              .map((album) => Album.fromJson(album))
              .toList();
        }
      }
      
      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e) {
      print('Error searching albums: $e');
      rethrow;
    }
  }

  /// 搜索内容项
  Future<List<ContentItem>> searchContent(String query, {
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final Map<String, dynamic> params = {
        'q': query,
        'page': page,
        'limit': limit,
      };

      // 添加筛选参数
      if (filters != null) {
        params.addAll(filters);
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/search/content').replace(
          queryParameters: params.map((key, value) => MapEntry(key, value.toString())),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['content'] != null) {
          return (data['content'] as List)
              .map((item) => ContentItem.fromJson(item))
              .toList();
        }
      }
      
      throw Exception('搜索失败: ${response.statusCode}');
    } catch (e) {
      print('Error searching content: $e');
      rethrow;
    }
  }

  /// 获取搜索建议
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/search/suggestions').replace(
          queryParameters: {'q': query},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['suggestions'] != null) {
          return (data['suggestions'] as List).cast<String>();
        }
      }
      
      return [];
    } catch (e) {
      print('Error getting search suggestions: $e');
      return [];
    }
  }

  /// 带防抖的搜索
  void debouncedSearch(
    String query,
    Function(List<Album>) onResults, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (query.trim().isNotEmpty) {
        searchAlbums(query, page: page, limit: limit, filters: filters)
            .then(onResults)
            .catchError((error) {
          print('Debounced search error: $error');
          onResults([]);
        });
      } else {
        onResults([]);
      }
    });
  }

  /// 带防抖的搜索内容项
  void debouncedSearchContent(
    String query,
    Function(List<ContentItem>) onResults, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (query.trim().isNotEmpty) {
        searchContent(query, page: page, limit: limit, filters: filters)
            .then(onResults)
            .catchError((error) {
          print('Debounced content search error: $error');
          onResults([]);
        });
      } else {
        onResults([]);
      }
    });
  }

  /// 带防抖的搜索建议
  void debouncedSuggestions(
    String query,
    Function(List<String>) onSuggestions,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (query.trim().isNotEmpty) {
        getSearchSuggestions(query)
            .then(onSuggestions)
            .catchError((error) {
          print('Debounced suggestions error: $error');
          onSuggestions([]);
        });
      } else {
        onSuggestions([]);
      }
    });
  }

  /// 取消所有待处理的搜索
  void cancelPendingSearches() {
    _debounceTimer?.cancel();
  }

  /// 释放资源
  void dispose() {
    _debounceTimer?.cancel();
  }
}

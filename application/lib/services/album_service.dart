import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/album.dart';
import '../config/api_config.dart';

class AlbumService {
  static String get _baseUrl => ApiConfig.adminUrl;
  static String get _publicUrl => ApiConfig.publicUrl;
  final Future<String?> Function() _getToken;

  AlbumService({Future<String?> Function()? getToken}) 
      : _getToken = getToken ?? (() async => null);

  Future<Map<String, String>> get _headers async {
    final headers = {
      'Content-Type': 'application/json',
    };
    final token = await _getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// 创建图集
  Future<AlbumActionResponse> createAlbum(CreateAlbumRequest request) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums');
      final response = await http.post(
        uri,
        headers: await _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to create album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error creating album: $e');
    }
  }

  /// 获取图集详情
  Future<AlbumActionResponse> getAlbum(String albumId) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId');
      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to get album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error getting album: $e');
    }
  }

  /// 获取图集列表
  Future<AlbumListResponse> getAlbums({
    int page = 1,
    int limit = 20,
    String? userId,
    bool publicOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (userId != null) {
        queryParams['user_id'] = userId;
      }
      if (publicOnly) {
        queryParams['public'] = 'true';
      }

      final baseUrl = publicOnly ? _publicUrl : _baseUrl;
      final uri = Uri.parse('$baseUrl/albums').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumListResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to get albums: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error getting albums: $e');
    }
  }

  /// 更新图集
  Future<AlbumActionResponse> updateAlbum(
    String albumId,
    UpdateAlbumRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId');
      final response = await http.put(
        uri,
        headers: await _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to update album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error updating album: $e');
    }
  }

  /// 删除图集
  Future<AlbumActionResponse> deleteAlbum(String albumId) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId');
      final response = await http.delete(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to delete album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error deleting album: $e');
    }
  }

  /// 添加图片到图集
  Future<AlbumActionResponse> addImagesToAlbum(
    String albumId,
    AddImageToAlbumRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId/images');
      final response = await http.post(
        uri,
        headers: await _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to add images to album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error adding images to album: $e');
    }
  }

  /// 从图集移除图片
  Future<AlbumActionResponse> removeImagesFromAlbum(
    String albumId,
    RemoveImageFromAlbumRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId/images');
      final response = await http.delete(
        uri,
        headers: await _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to remove images from album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error removing images from album: $e');
    }
  }

  /// 设置图集封面
  Future<AlbumActionResponse> setAlbumCover(
    String albumId,
    SetAlbumCoverRequest request,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/albums/$albumId/cover');
      final response = await http.put(
        uri,
        headers: await _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to set album cover: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error setting album cover: $e');
    }
  }

  /// 搜索图集
  Future<AlbumListResponse> searchAlbums({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$_baseUrl/albums/search').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumListResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to search albums: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error searching albums: $e');
    }
  }

  /// 获取公开图集列表
  Future<AlbumListResponse> getPublicAlbums({
    int page = 1,
    int limit = 20,
  }) async {
    return getAlbums(
      page: page,
      limit: limit,
      publicOnly: true,
    );
  }

  /// 获取公开图集详情
  Future<AlbumActionResponse> getPublicAlbum(String albumId) async {
    try {
      final uri = Uri.parse('$_publicUrl/albums/$albumId');
      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AlbumActionResponse.fromJson(data);
      } else {
        throw AlbumServiceException(
          'Failed to get public album: ${response.statusCode} - ${response.body}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is AlbumServiceException) {
        rethrow;
      }
      throw AlbumServiceException('Error getting public album: $e');
    }
  }

  /// 增加图集浏览次数
  Future<void> incrementViewCount(String albumId) async {
    try {
      // 这个操作通常不需要等待响应
      final uri = Uri.parse('$_baseUrl/albums/$albumId');
      await http.get(uri, headers: await _headers);
    } catch (e) {
      // 静默处理错误，不影响用户体验
      print('Failed to increment view count: $e');
    }
  }
}

/// 图集服务异常
class AlbumServiceException implements Exception {
  final String message;
  final int? statusCode;

  AlbumServiceException(this.message, [this.statusCode]);

  @override
  String toString() => 'AlbumServiceException: $message';
}

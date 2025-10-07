import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/album.dart';
import 'auth_service.dart';

/// 收藏服务
class FavoriteService {
  final AuthService _authService = AuthService();

  /// 检查图集是否被收藏
  Future<bool> isFavorited(String albumId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/favorites/check/$albumId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isFavorited'] ?? false;
      }
      
      throw Exception('检查收藏状态失败: ${response.statusCode}');
    } catch (e) {
      print('Error checking favorite status: $e');
      rethrow;
    }
  }

  /// 添加收藏
  Future<bool> addFavorite(String albumId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/favorites'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'albumId': albumId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      throw Exception('添加收藏失败: ${response.statusCode}');
    } catch (e) {
      print('Error adding favorite: $e');
      rethrow;
    }
  }

  /// 移除收藏
  Future<bool> removeFavorite(String albumId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/favorites/$albumId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      throw Exception('移除收藏失败: ${response.statusCode}');
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }

  /// 获取用户收藏的图集列表
  Future<List<Album>> getFavoriteAlbums() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('用户未登录');
      }

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/favorites'),
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
      
      throw Exception('获取收藏列表失败: ${response.statusCode}');
    } catch (e) {
      print('Error getting favorite albums: $e');
      rethrow;
    }
  }
}

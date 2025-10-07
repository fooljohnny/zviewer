import 'package:flutter/foundation.dart';
import '../models/album.dart';
import '../services/favorite_service.dart';

/// 收藏状态管理
class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService;
  
  // 状态管理
  final Map<String, bool> _isFavorited = {}; // 图集是否被收藏
  final Map<String, bool> _isLoading = {}; // 是否正在加载
  final Map<String, String?> _errors = {}; // 错误信息
  final Map<String, bool> _isToggling = {}; // 是否正在切换收藏状态
  
  FavoriteProvider({FavoriteService? favoriteService}) 
      : _favoriteService = favoriteService ?? FavoriteService();

  // Getters
  bool isFavorited(String albumId) => _isFavorited[albumId] ?? false;
  bool isLoading(String albumId) => _isLoading[albumId] ?? false;
  bool isToggling(String albumId) => _isToggling[albumId] ?? false;
  String? getError(String albumId) => _errors[albumId];

  /// 加载图集收藏状态
  Future<void> loadFavoriteStatus(String albumId) async {
    if (_isLoading[albumId] == true) return;

    _setLoading(albumId, true);
    _clearError(albumId);

    try {
      final isFavorited = await _favoriteService.isFavorited(albumId);
      _isFavorited[albumId] = isFavorited;
      notifyListeners();
    } catch (e) {
      _setError(albumId, '加载收藏状态失败: $e');
    } finally {
      _setLoading(albumId, false);
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String albumId) async {
    if (_isToggling[albumId] == true) return;

    _setToggling(albumId, true);
    _clearError(albumId);

    try {
      final currentStatus = _isFavorited[albumId] ?? false;
      if (currentStatus) {
        await _favoriteService.removeFavorite(albumId);
        _isFavorited[albumId] = false;
      } else {
        await _favoriteService.addFavorite(albumId);
        _isFavorited[albumId] = true;
      }
      notifyListeners();
    } catch (e) {
      _setError(albumId, '操作失败: $e');
    } finally {
      _setToggling(albumId, false);
    }
  }

  /// 添加收藏
  Future<void> addFavorite(String albumId) async {
    if (_isToggling[albumId] == true) return;

    _setToggling(albumId, true);
    _clearError(albumId);

    try {
      await _favoriteService.addFavorite(albumId);
      _isFavorited[albumId] = true;
      notifyListeners();
    } catch (e) {
      _setError(albumId, '收藏失败: $e');
    } finally {
      _setToggling(albumId, false);
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String albumId) async {
    if (_isToggling[albumId] == true) return;

    _setToggling(albumId, true);
    _clearError(albumId);

    try {
      await _favoriteService.removeFavorite(albumId);
      _isFavorited[albumId] = false;
      notifyListeners();
    } catch (e) {
      _setError(albumId, '取消收藏失败: $e');
    } finally {
      _setToggling(albumId, false);
    }
  }

  /// 获取用户收藏的图集列表
  Future<List<Album>> getFavoriteAlbums() async {
    try {
      return await _favoriteService.getFavoriteAlbums();
    } catch (e) {
      print('Error getting favorite albums: $e');
      return [];
    }
  }

  // 私有方法
  void _setLoading(String albumId, bool loading) {
    _isLoading[albumId] = loading;
  }

  void _setToggling(String albumId, bool toggling) {
    _isToggling[albumId] = toggling;
  }

  void _setError(String albumId, String error) {
    _errors[albumId] = error;
  }

  void _clearError(String albumId) {
    _errors.remove(albumId);
  }

  /// 清除所有状态
  void clear() {
    _isFavorited.clear();
    _isLoading.clear();
    _errors.clear();
    _isToggling.clear();
    notifyListeners();
  }
}

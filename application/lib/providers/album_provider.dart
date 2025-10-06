import 'package:flutter/foundation.dart';
import '../models/album.dart';
import '../services/album_service.dart';

class AlbumProvider extends ChangeNotifier {
  final AlbumService _service;

  // 状态管理
  List<Album> _albums = [];
  List<Album> _publicAlbums = [];
  Album? _currentAlbum;
  List<Album> _searchResults = [];
  
  // 筛选和搜索状态
  String _searchQuery = '';
  AlbumStatus? _selectedStatus;
  String _userFilter = '';
  bool _publicOnly = false;
  
  // 排序状态
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  
  // 分页状态
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalAlbums = 0;
  
  // 加载状态
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  AlbumProvider({required AlbumService service}) : _service = service;

  // Getters
  List<Album> get albums => _publicOnly ? _publicAlbums : _albums;
  Album? get currentAlbum => _currentAlbum;
  List<Album> get searchResults => _searchResults;
  
  String get searchQuery => _searchQuery;
  AlbumStatus? get selectedStatus => _selectedStatus;
  String get userFilter => _userFilter;
  bool get publicOnly => _publicOnly;
  
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalAlbums => _totalAlbums;
  
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;

  // 计算属性
  int get draftCount => _albums.where((album) => album.isDraft).length;
  int get publishedCount => _albums.where((album) => album.isPublished).length;
  int get archivedCount => _albums.where((album) => album.isArchived).length;

  // 图集管理方法

  /// 创建图集
  Future<void> createAlbum(CreateAlbumRequest request) async {
    print('🚀 AlbumProvider.createAlbum - Request: ${request.toJson()}');
    _setLoading(true);
    try {
      final response = await _service.createAlbum(request);
      print('🚀 AlbumProvider.createAlbum - Response: success=${response.success}, message=${response.message}, album=${response.album?.id}');
      
      if (response.success && response.album != null) {
        _albums.insert(0, response.album!);
        _totalAlbums++;
        _error = null;
        notifyListeners();
        print('✅ AlbumProvider.createAlbum - Album created successfully: ${response.album!.id}');
      } else {
        _error = response.message ?? 'Unknown error';
        print('❌ AlbumProvider.createAlbum - Failed: ${response.message}');
      }
    } catch (e, stackTrace) {
      print('❌ AlbumProvider.createAlbum ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      _error = e.toString();
      if (kDebugMode) {
        print('Error creating album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 加载图集列表
  Future<void> loadAlbums({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _setLoading(true);
    try {
      final response = await _service.getAlbums(
        page: _currentPage,
        limit: 20,
        userId: _userFilter.isNotEmpty ? _userFilter : null,
        publicOnly: _publicOnly,
      );

      if (refresh) {
        _albums = response.albums;
      } else {
        _albums.addAll(response.albums);
      }

      _totalPages = response.totalPages;
      _totalAlbums = response.total;
      _currentPage = response.page;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading albums: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 加载公开图集
  Future<void> loadPublicAlbums({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _setLoading(true);
    try {
      final response = await _service.getPublicAlbums(
        page: _currentPage,
        limit: 20,
      );

      if (refresh) {
        _publicAlbums = response.albums;
      } else {
        _publicAlbums.addAll(response.albums);
      }

      _totalPages = response.totalPages;
      _totalAlbums = response.total;
      _currentPage = response.page;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading public albums: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 获取图集详情
  Future<void> getAlbum(String albumId) async {
    _setLoading(true);
    try {
      final response = await _service.getAlbum(albumId);
      if (response.success && response.album != null) {
        _currentAlbum = response.album!;
        _error = null;
        
        // 更新列表中的图集
        final index = _albums.indexWhere((album) => album.id == albumId);
        if (index != -1) {
          _albums[index] = response.album!;
        }
        
        notifyListeners();
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error getting album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新图集
  Future<void> updateAlbum(String albumId, UpdateAlbumRequest request) async {
    _setLoading(true);
    try {
      final response = await _service.updateAlbum(albumId, request);
      if (response.success && response.album != null) {
        // 更新当前图集
        if (_currentAlbum?.id == albumId) {
          _currentAlbum = response.album!;
        }
        
        // 更新列表中的图集
        final index = _albums.indexWhere((album) => album.id == albumId);
        if (index != -1) {
          _albums[index] = response.album!;
        }
        
        _error = null;
        notifyListeners();
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error updating album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除图集
  Future<void> deleteAlbum(String albumId) async {
    _setLoading(true);
    try {
      final response = await _service.deleteAlbum(albumId);
      if (response.success) {
        _albums.removeWhere((album) => album.id == albumId);
        _publicAlbums.removeWhere((album) => album.id == albumId);
        
        if (_currentAlbum?.id == albumId) {
          _currentAlbum = null;
        }
        
        _totalAlbums--;
        _error = null;
        notifyListeners();
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error deleting album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 添加图片到图集
  Future<void> addImagesToAlbum(String albumId, List<String> imageIds) async {
    _setLoading(true);
    try {
      final request = AddImageToAlbumRequest(imageIds: imageIds);
      final response = await _service.addImagesToAlbum(albumId, request);
      
      if (response.success) {
        // 重新加载图集详情
        await getAlbum(albumId);
        _error = null;
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error adding images to album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 从图集移除图片
  Future<void> removeImagesFromAlbum(String albumId, List<String> imageIds) async {
    _setLoading(true);
    try {
      final request = RemoveImageFromAlbumRequest(imageIds: imageIds);
      final response = await _service.removeImagesFromAlbum(albumId, request);
      
      if (response.success) {
        // 重新加载图集详情
        await getAlbum(albumId);
        _error = null;
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error removing images from album: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 设置图集封面
  Future<void> setAlbumCover(String albumId, String imageId) async {
    _setLoading(true);
    try {
      final request = SetAlbumCoverRequest(imageId: imageId);
      final response = await _service.setAlbumCover(albumId, request);
      
      if (response.success) {
        // 重新加载图集详情
        await getAlbum(albumId);
        _error = null;
      } else {
        _error = response.message ?? 'Unknown error';
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error setting album cover: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索图集
  Future<void> searchAlbums(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      final response = await _service.searchAlbums(
        query: query,
        page: 1,
        limit: 50,
      );

      _searchResults = response.albums;
      _searchQuery = query;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error searching albums: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// 加载更多图集
  Future<void> loadMoreAlbums() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;

    _setLoadingMore(true);
    try {
      _currentPage++;
      final response = await _service.getAlbums(
        page: _currentPage,
        limit: 20,
        userId: _userFilter.isNotEmpty ? _userFilter : null,
        publicOnly: _publicOnly,
      );

      _albums.addAll(response.albums);
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading more albums: $e');
      }
    } finally {
      _setLoadingMore(false);
    }
  }

  // 筛选和搜索方法

  /// 设置搜索查询
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 设置状态筛选
  void setStatusFilter(AlbumStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  /// 设置用户筛选
  void setUserFilter(String user) {
    _userFilter = user;
    notifyListeners();
  }

  /// 设置公开筛选
  void setPublicOnly(bool publicOnly) {
    _publicOnly = publicOnly;
    notifyListeners();
  }

  /// 设置排序
  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
  }

  /// 清除所有筛选
  void clearAllFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _userFilter = '';
    _publicOnly = false;
    notifyListeners();
  }

  /// 应用筛选
  void applyFilters() {
    loadAlbums(refresh: true);
  }

  // 辅助方法

  /// 增加图集浏览次数
  Future<void> incrementViewCount(String albumId) async {
    try {
      await _service.incrementViewCount(albumId);
      
      // 更新本地数据
      final index = _albums.indexWhere((album) => album.id == albumId);
      if (index != -1) {
        final album = _albums[index];
        _albums[index] = album.copyWith(viewCount: album.viewCount + 1);
      }
      
      if (_currentAlbum?.id == albumId) {
        _currentAlbum = _currentAlbum!.copyWith(
          viewCount: _currentAlbum!.viewCount + 1,
        );
      }
      
      notifyListeners();
    } catch (e) {
      // 静默处理错误
      if (kDebugMode) {
        print('Error incrementing view count: $e');
      }
    }
  }

  /// 清空当前图集
  void clearCurrentAlbum() {
    _currentAlbum = null;
    notifyListeners();
  }

  /// 清空搜索结果
  void clearSearchResults() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  /// 清空错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 刷新所有数据
  Future<void> refreshAll() async {
    await Future.wait([
      loadAlbums(refresh: true),
      if (_publicOnly) loadPublicAlbums(refresh: true),
    ]);
  }

  // 私有方法

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }
}

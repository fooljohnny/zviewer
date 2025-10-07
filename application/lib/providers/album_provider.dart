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
  
  // 高级筛选状态
  Map<String, dynamic> _advancedFilters = {};
  List<Album> _filteredAlbums = [];
  
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
  List<Album> get albums {
    if (_advancedFilters.isNotEmpty) {
      return _filteredAlbums;
    }
    return _publicOnly ? _publicAlbums : _albums;
  }
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
        // 先将返回的专辑插入列表以便立即可见
        _albums.insert(0, response.album!);
        _totalAlbums++;
        _error = null;
        notifyListeners();
        print('✅ AlbumProvider.createAlbum - Album created successfully: ${response.album!.id}');

        // 紧接着拉取一次最新详情，确保 images/imageCount 等字段完整（后端可能未即时填充）
        try {
          final createdId = response.album!.id;
          final detail = await _service.getAlbum(createdId);
          if (detail.success && detail.album != null) {
            // 更新当前列表中的该专辑
            final idx = _albums.indexWhere((a) => a.id == createdId);
            if (idx != -1) {
              _albums[idx] = detail.album!;
            }
            // 如果当前详情就是该专辑，也同步更新
            if (_currentAlbum?.id == createdId) {
              _currentAlbum = detail.album!;
            }
            notifyListeners();
            print('✅ AlbumProvider.createAlbum - Refreshed album details with images for: $createdId');
          }
        } catch (e) {
          // 忽略刷新错误，不影响创建流程
          print('⚠️ AlbumProvider.createAlbum - Failed to refresh album details: $e');
        }
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

  /// 批量删除图集
  Future<void> deleteAlbums(List<String> albumIds) async {
    _setLoading(true);
    try {
      int successCount = 0;
      int failCount = 0;
      
      for (final albumId in albumIds) {
        try {
          final response = await _service.deleteAlbum(albumId);
          if (response.success) {
            _albums.removeWhere((album) => album.id == albumId);
            _publicAlbums.removeWhere((album) => album.id == albumId);
            
            if (_currentAlbum?.id == albumId) {
              _currentAlbum = null;
            }
            
            successCount++;
          } else {
            failCount++;
            if (kDebugMode) {
              print('Failed to delete album $albumId: ${response.message}');
            }
          }
        } catch (e) {
          failCount++;
          if (kDebugMode) {
            print('Error deleting album $albumId: $e');
          }
        }
      }
      
      _totalAlbums -= successCount;
      
      if (failCount > 0) {
        _error = '成功删除 $successCount 个图集，失败 $failCount 个';
      } else {
        _error = null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error in batch delete: $e');
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

  /// 应用高级筛选
  void applyAdvancedFilters(Map<String, dynamic> filters) {
    _advancedFilters = filters;
    _filteredAlbums = _performAdvancedFiltering();
    notifyListeners();
  }

  /// 清除高级筛选
  void clearAdvancedFilters() {
    _advancedFilters.clear();
    _filteredAlbums.clear();
    notifyListeners();
  }

  /// 执行高级筛选逻辑
  List<Album> _performAdvancedFiltering() {
    List<Album> albumsToFilter = _publicOnly ? _publicAlbums : _albums;
    
    // 搜索查询筛选
    if (_advancedFilters['searchQuery'] != null && 
        _advancedFilters['searchQuery'].toString().isNotEmpty) {
      final query = _advancedFilters['searchQuery'].toString().toLowerCase();
      albumsToFilter = albumsToFilter.where((album) {
        return album.title.toLowerCase().contains(query) ||
               album.description.toLowerCase().contains(query) ||
               (album.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false);
      }).toList();
    }

    // 状态筛选
    if (_advancedFilters['statuses'] != null && 
        (_advancedFilters['statuses'] as List).isNotEmpty) {
      final statuses = (_advancedFilters['statuses'] as List)
          .map((s) => AlbumStatus.values.firstWhere((e) => e.toString() == s))
          .toSet();
      albumsToFilter = albumsToFilter.where((album) => 
          statuses.contains(album.status)).toList();
    }

    // 日期筛选
    if (_advancedFilters['startDate'] != null) {
      final startDate = _advancedFilters['startDate'] as DateTime;
      albumsToFilter = albumsToFilter.where((album) => 
          album.createdAt.isAfter(startDate) || 
          album.createdAt.isAtSameMomentAs(startDate)).toList();
    }
    
    if (_advancedFilters['endDate'] != null) {
      final endDate = _advancedFilters['endDate'] as DateTime;
      albumsToFilter = albumsToFilter.where((album) => 
          album.createdAt.isBefore(endDate) || 
          album.createdAt.isAtSameMomentAs(endDate)).toList();
    }

    // 用户筛选
    if (_advancedFilters['userId'] != null && 
        _advancedFilters['userId'].toString().isNotEmpty) {
      final userId = _advancedFilters['userId'].toString();
      albumsToFilter = albumsToFilter.where((album) => 
          album.userId == userId).toList();
    }

    // 图片数量范围筛选
    if (_advancedFilters['imageCountMin'] != null) {
      final minCount = _advancedFilters['imageCountMin'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          (album.imageCount ?? 0) >= minCount).toList();
    }
    
    if (_advancedFilters['imageCountMax'] != null) {
      final maxCount = _advancedFilters['imageCountMax'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          (album.imageCount ?? 0) <= maxCount).toList();
    }

    // 浏览次数范围筛选
    if (_advancedFilters['viewCountMin'] != null) {
      final minViews = _advancedFilters['viewCountMin'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          album.viewCount >= minViews).toList();
    }
    
    if (_advancedFilters['viewCountMax'] != null) {
      final maxViews = _advancedFilters['viewCountMax'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          album.viewCount <= maxViews).toList();
    }

    // 点赞次数范围筛选
    if (_advancedFilters['likeCountMin'] != null) {
      final minLikes = _advancedFilters['likeCountMin'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          album.likeCount >= minLikes).toList();
    }
    
    if (_advancedFilters['likeCountMax'] != null) {
      final maxLikes = _advancedFilters['likeCountMax'] as int;
      albumsToFilter = albumsToFilter.where((album) => 
          album.likeCount <= maxLikes).toList();
    }

    // 标签筛选
    if (_advancedFilters['tags'] != null && 
        (_advancedFilters['tags'] as List).isNotEmpty) {
      final selectedTags = (_advancedFilters['tags'] as List).cast<String>();
      albumsToFilter = albumsToFilter.where((album) {
        if (album.tags == null) return false;
        return selectedTags.any((tag) => album.tags!.contains(tag));
      }).toList();
    }

    // 公开筛选
    if (_advancedFilters['showPublicOnly'] == true) {
      albumsToFilter = albumsToFilter.where((album) => album.isPublic).toList();
    }

    // 空专辑筛选
    if (_advancedFilters['showEmptyAlbums'] == false) {
      albumsToFilter = albumsToFilter.where((album) => 
          (album.imageCount ?? 0) > 0).toList();
    }

    // 排序
    final sortBy = _advancedFilters['sortBy'] ?? 'createdAt';
    final sortOrder = _advancedFilters['sortOrder'] ?? 'desc';
    
    albumsToFilter.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        case 'updatedAt':
          comparison = a.updatedAt.compareTo(b.updatedAt);
          break;
        case 'viewCount':
          comparison = a.viewCount.compareTo(b.viewCount);
          break;
        case 'likeCount':
          comparison = a.likeCount.compareTo(b.likeCount);
          break;
        case 'imageCount':
          comparison = (a.imageCount ?? 0).compareTo(b.imageCount ?? 0);
          break;
        case 'createdAt':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      
      return sortOrder == 'desc' ? -comparison : comparison;
    });

    return albumsToFilter;
  }
}

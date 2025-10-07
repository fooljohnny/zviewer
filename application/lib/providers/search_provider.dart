import 'package:flutter/foundation.dart';
import '../models/album.dart';
import '../models/content_item.dart';
import '../services/search_service.dart';

/// 搜索状态管理
class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  
  // 搜索状态
  String _searchQuery = '';
  List<Album> _searchResults = [];
  List<ContentItem> _contentSearchResults = [];
  List<String> _suggestions = [];
  
  // 加载状态
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  String? _searchError;
  
  // 搜索历史
  List<String> _searchHistory = [];
  static const int _maxHistorySize = 10;

  // Getters
  String get searchQuery => _searchQuery;
  List<Album> get searchResults => _searchResults;
  List<ContentItem> get contentSearchResults => _contentSearchResults;
  List<String> get suggestions => _suggestions;
  List<String> get searchHistory => _searchHistory;
  
  bool get isSearching => _isSearching;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get searchError => _searchError;
  
  bool get hasSearchResults => _searchResults.isNotEmpty;
  bool get hasContentSearchResults => _contentSearchResults.isNotEmpty;

  /// 设置搜索查询
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 搜索专辑
  Future<void> searchAlbums(String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      _searchResults.clear();
      _searchError = null;
      notifyListeners();
      return;
    }

    _setSearching(true);
    _searchError = null;
    _searchQuery = query;
    
    // 添加到搜索历史
    _addToSearchHistory(query);

    try {
      final results = await _searchService.searchAlbums(
        query,
        page: page,
        limit: limit,
        filters: filters,
      );
      
      _searchResults = results;
      notifyListeners();
    } catch (e) {
      _searchError = '搜索失败: $e';
      _searchResults.clear();
      notifyListeners();
    } finally {
      _setSearching(false);
    }
  }

  /// 搜索内容项
  Future<void> searchContent(String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      _contentSearchResults.clear();
      _searchError = null;
      notifyListeners();
      return;
    }

    _setSearching(true);
    _searchError = null;
    _searchQuery = query;
    
    // 添加到搜索历史
    _addToSearchHistory(query);

    try {
      final results = await _searchService.searchContent(
        query,
        page: page,
        limit: limit,
        filters: filters,
      );
      
      _contentSearchResults = results;
      notifyListeners();
    } catch (e) {
      _searchError = '搜索失败: $e';
      _contentSearchResults.clear();
      notifyListeners();
    } finally {
      _setSearching(false);
    }
  }

  /// 带防抖的搜索专辑
  void debouncedSearchAlbums(String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) {
    _searchQuery = query;
    notifyListeners();
    
    _searchService.debouncedSearch(
      query,
      (results) {
        _searchResults = results;
        _searchError = null;
        notifyListeners();
      },
      filters: filters,
      page: page,
      limit: limit,
    );
  }

  /// 带防抖的搜索内容项
  void debouncedSearchContent(String query, {
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) {
    _searchQuery = query;
    notifyListeners();
    
    _searchService.debouncedSearchContent(
      query,
      (results) {
        _contentSearchResults = results;
        _searchError = null;
        notifyListeners();
      },
      filters: filters,
      page: page,
      limit: limit,
    );
  }

  /// 获取搜索建议
  Future<void> getSuggestions(String query) async {
    if (query.trim().isEmpty) {
      _suggestions.clear();
      notifyListeners();
      return;
    }

    _setLoadingSuggestions(true);

    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      _suggestions = suggestions;
      notifyListeners();
    } catch (e) {
      _suggestions.clear();
      notifyListeners();
    } finally {
      _setLoadingSuggestions(false);
    }
  }

  /// 带防抖的搜索建议
  void debouncedSuggestions(String query) {
    _searchService.debouncedSuggestions(
      query,
      (suggestions) {
        _suggestions = suggestions;
        notifyListeners();
      },
    );
  }

  /// 清除搜索结果
  void clearSearchResults() {
    _searchResults.clear();
    _contentSearchResults.clear();
    _suggestions.clear();
    _searchQuery = '';
    _searchError = null;
    notifyListeners();
  }

  /// 清除搜索错误
  void clearSearchError() {
    _searchError = null;
    notifyListeners();
  }

  /// 从搜索历史中移除项目
  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
    notifyListeners();
  }

  /// 清除搜索历史
  void clearSearchHistory() {
    _searchHistory.clear();
    notifyListeners();
  }

  /// 取消所有待处理的搜索
  void cancelPendingSearches() {
    _searchService.cancelPendingSearches();
  }

  // 私有方法

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setLoadingSuggestions(bool loading) {
    _isLoadingSuggestions = loading;
    notifyListeners();
  }

  void _addToSearchHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;
    
    // 移除重复项
    _searchHistory.remove(trimmedQuery);
    
    // 添加到开头
    _searchHistory.insert(0, trimmedQuery);
    
    // 限制历史记录大小
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory = _searchHistory.take(_maxHistorySize).toList();
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _searchService.dispose();
    super.dispose();
  }
}

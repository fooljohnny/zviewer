import 'package:flutter/foundation.dart';
import '../models/content_item.dart';
import '../models/content_category.dart';
import '../models/admin_action.dart';
import '../services/content_management_service.dart';
import 'auth_provider.dart';

class ContentManagementProvider extends ChangeNotifier {
  final ContentManagementService _service;
  final AuthProvider _authProvider;

  // Content state
  List<ContentItem> _content = [];
  List<ContentCategory> _categories = [];
  List<AdminAction> _recentActions = [];
  List<AdminAction> _contentAdminActions = [];
  Set<String> _selectedContentIds = {};

  // Filtering and search state
  String _searchQuery = '';
  ContentStatus? _selectedStatus;
  ContentType? _selectedType;
  String _userFilter = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedCategories = {};

  // Sorting state
  String _sortBy = 'uploadedAt';
  String _sortOrder = 'desc';

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalContent = 0;

  // Loading state
  bool _isLoading = false;
  String? _error;

  ContentManagementProvider({
    required ContentManagementService service,
    required AuthProvider authProvider,
  }) : _service = service, _authProvider = authProvider;

  // Getters
  List<ContentItem> get content => _content;
  List<ContentCategory> get categories => _categories;
  List<AdminAction> get recentActions => _recentActions;
  List<AdminAction> get contentAdminActions => _contentAdminActions;
  Set<String> get selectedContentIds => _selectedContentIds;
  
  String get searchQuery => _searchQuery;
  ContentStatus? get selectedStatus => _selectedStatus;
  ContentType? get selectedType => _selectedType;
  String get userFilter => _userFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  Set<String> get selectedCategories => _selectedCategories;
  
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalContent => _totalContent;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed properties
  int get pendingContent => _content.where((item) => item.isPending).length;
  int get approvedContent => _content.where((item) => item.isApproved).length;
  int get rejectedContent => _content.where((item) => item.isRejected).length;

  // Content management methods
  Future<void> uploadFiles(List<UploadFile> files) async {
    _setLoading(true);
    try {
      final response = await _service.uploadFiles(files);
      
      if (response.success) {
        // Add uploaded content to the current list
        _content.addAll(response.uploadedContent);
        _totalContent += response.successfulUploads;
        _error = null;
        notifyListeners();
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error uploading files: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadContent({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _setLoading(true);
    try {
      // 实际调用服务加载内容
      final response = await _service.getContent(
        page: _currentPage,
        limit: 50,
        searchQuery: _searchQuery,
        status: _selectedStatus,
        type: _selectedType,
        userFilter: _userFilter,
        startDate: _startDate,
        endDate: _endDate,
        categories: _selectedCategories.toList(),
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      
      if (refresh) {
        _content = response.content;
      } else {
        _content.addAll(response.content);
      }

      _totalPages = response.totalPages;
      _totalContent = response.total;
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading content: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading categories: $e');
      }
    }
  }

  Future<void> loadRecentActions({int limit = 50}) async {
    try {
      _recentActions = await _service.getRecentAdminActions(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading recent actions: $e');
      }
    }
  }

  Future<void> loadContentAdminActions(String contentId) async {
    try {
      _contentAdminActions = await _service.getContentAdminActions(contentId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('Error loading content admin actions: $e');
      }
    }
  }

  // Content actions
  Future<void> approveContent(String contentId) async {
    try {
      await _service.approveContent(contentId);
      await _updateContentStatus(contentId, ContentStatus.approved);
      await loadRecentActions();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> rejectContent(String contentId, String reason) async {
    try {
      await _service.rejectContent(contentId, reason);
      await _updateContentStatus(contentId, ContentStatus.rejected);
      await loadRecentActions();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteContent(String contentId, String reason) async {
    try {
      await _service.deleteContent(contentId, reason);
      _content.removeWhere((item) => item.id == contentId);
      _selectedContentIds.remove(contentId);
      await loadRecentActions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> categorizeContent(String contentId, List<String> categories) async {
    try {
      await _service.categorizeContent(contentId, categories);
      await loadContent(refresh: true);
      await loadRecentActions();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Bulk actions
  Future<void> performBulkAction(String action, List<String> contentIds) async {
    try {
      final metadata = <String, dynamic>{};
      await _service.bulkAction(action, contentIds, metadata: metadata);
      
      // Update local state based on action
      switch (action) {
        case 'approve':
          for (final id in contentIds) {
            await _updateContentStatus(id, ContentStatus.approved);
          }
          break;
        case 'reject':
          for (final id in contentIds) {
            await _updateContentStatus(id, ContentStatus.rejected);
          }
          break;
        case 'delete':
          _content.removeWhere((item) => contentIds.contains(item.id));
          _selectedContentIds.removeAll(contentIds);
          break;
        case 'categorize':
          await loadContent(refresh: true);
          break;
      }
      
      await loadRecentActions();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Category management
  Future<void> createCategory(ContentCategory category) async {
    try {
      final createdCategory = await _service.createCategory(category);
      _categories.add(createdCategory);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateCategory(ContentCategory category) async {
    try {
      final updatedCategory = await _service.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _service.deleteCategory(categoryId);
      _categories.removeWhere((c) => c.id == categoryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // Filtering and search
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(ContentStatus? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setTypeFilter(ContentType? type) {
    _selectedType = type;
    notifyListeners();
  }

  void setUserFilter(String user) {
    _userFilter = user;
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void toggleCategoryFilter(String categoryId, bool selected) {
    if (selected) {
      _selectedCategories.add(categoryId);
    } else {
      _selectedCategories.remove(categoryId);
    }
    notifyListeners();
  }

  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedType = null;
    _userFilter = '';
    _startDate = null;
    _endDate = null;
    _selectedCategories.clear();
    notifyListeners();
  }

  void applyFilters() {
    loadContent(refresh: true);
  }

  // Selection management
  void toggleContentSelection(String contentId, bool selected) {
    if (selected) {
      _selectedContentIds.add(contentId);
    } else {
      _selectedContentIds.remove(contentId);
    }
    notifyListeners();
  }

  void selectAllContent() {
    _selectedContentIds = _content.map((item) => item.id).toSet();
    notifyListeners();
  }

  void clearSelection() {
    _selectedContentIds.clear();
    notifyListeners();
  }

  // Pagination
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages && !_isLoading) {
      _currentPage++;
      await loadContent();
    }
  }

  Future<void> loadPreviousPage() async {
    if (_currentPage > 1 && !_isLoading) {
      _currentPage--;
      await loadContent();
    }
  }

  // Helper methods
  Future<void> _updateContentStatus(String contentId, ContentStatus status) async {
    final index = _content.indexWhere((item) => item.id == contentId);
    if (index != -1) {
      _content[index] = _content[index].copyWith(
        status: status,
        approvedAt: status == ContentStatus.approved ? DateTime.now() : _content[index].approvedAt,
        approvedBy: status == ContentStatus.approved ? _authProvider.user?.id : _content[index].approvedBy,
      );
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }


  // Error handling
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadContent(refresh: true),
      loadCategories(),
      loadRecentActions(),
    ]);
  }
}

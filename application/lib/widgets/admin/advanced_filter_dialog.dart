import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../models/album.dart';
import '../../services/filter_persistence_service.dart';

/// 高级筛选对话框
class AdvancedFilterDialog extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  const AdvancedFilterDialog({super.key, this.initialFilters});

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // 搜索相关
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  // 状态筛选
  Set<AlbumStatus> _selectedStatuses = <AlbumStatus>{};
  
  // 日期筛选
  DateTime? _startDate;
  DateTime? _endDate;
  
  // 用户筛选
  String _selectedUserId = '';
  List<String> _availableUsers = [];
  
  // 数值范围筛选
  RangeValues _imageCountRange = const RangeValues(0, 100);
  RangeValues _viewCountRange = const RangeValues(0, 1000);
  RangeValues _likeCountRange = const RangeValues(0, 100);
  
  // 标签筛选
  Set<String> _selectedTags = <String>{};
  List<String> _availableTags = [];
  
  // 排序
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';
  
  // 其他选项
  bool _showPublicOnly = false;
  bool _showEmptyAlbums = true;
  
  // 预设管理
  final FilterPersistenceService _persistenceService = FilterPersistenceService();
  Map<String, Map<String, dynamic>> _presets = {};
  String? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFilters() {
    if (widget.initialFilters != null) {
      _searchQuery = widget.initialFilters!['searchQuery'] ?? '';
      _searchController.text = _searchQuery;
      
      if (widget.initialFilters!['statuses'] != null) {
        _selectedStatuses = Set<AlbumStatus>.from(
          (widget.initialFilters!['statuses'] as List)
              .map((s) => AlbumStatus.values.firstWhere((e) => e.toString() == s))
        );
      }
      
      _startDate = widget.initialFilters!['startDate'];
      _endDate = widget.initialFilters!['endDate'];
      _selectedUserId = widget.initialFilters!['userId'] ?? '';
      _showPublicOnly = widget.initialFilters!['showPublicOnly'] ?? false;
      _showEmptyAlbums = widget.initialFilters!['showEmptyAlbums'] ?? true;
      _sortBy = widget.initialFilters!['sortBy'] ?? 'createdAt';
      _sortOrder = widget.initialFilters!['sortOrder'] ?? 'desc';
    }
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
      _loadTags();
      _loadPresets();
    });
  }

  void _loadUsers() {
    // 从现有的专辑中获取用户列表
    final albums = context.read<AlbumProvider>().albums;
    final users = <String, String>{};
    
    for (final album in albums) {
      users[album.userId] = album.userName;
    }
    
    setState(() {
      _availableUsers = users.entries
          .map((e) => '${e.value} (${e.key})')
          .toList();
    });
  }

  void _loadTags() {
    // 从现有的专辑中获取标签列表
    final albums = context.read<AlbumProvider>().albums;
    final tags = <String>{};
    
    for (final album in albums) {
      if (album.tags != null) {
        tags.addAll(album.tags!);
      }
    }
    
    setState(() {
      _availableTags = tags.toList()..sort();
    });
  }

  Future<void> _loadPresets() async {
    final presets = await _persistenceService.getFilterPresets();
    setState(() {
      _presets = presets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchSection(),
                      const SizedBox(height: 24),
                      _buildStatusFilter(),
                      const SizedBox(height: 24),
                      _buildDateFilter(),
                      const SizedBox(height: 24),
                      _buildUserFilter(),
                      const SizedBox(height: 24),
                      _buildRangeFilters(),
                      const SizedBox(height: 24),
                      _buildTagFilter(),
                      const SizedBox(height: 24),
                      _buildSortOptions(),
                      const SizedBox(height: 24),
                      _buildOtherOptions(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.filter_list, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            '高级筛选',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // 预设管理按钮
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'save':
                _showSavePresetDialog();
                break;
              case 'load':
                _showLoadPresetDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.save),
                  SizedBox(width: 8),
                  Text('保存预设'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'load',
              child: Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(width: 8),
                  Text('加载预设'),
                ],
              ),
            ),
          ],
          child: const Icon(Icons.bookmark),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '搜索',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '搜索专辑标题、描述或标签...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '状态筛选',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AlbumStatus.values.map((status) {
            final isSelected = _selectedStatuses.contains(status);
            return FilterChip(
              label: Text(_getStatusText(status)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '创建日期筛选',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                            : '开始日期',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('至'),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectEndDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _endDate != null
                            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                            : '结束日期',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_startDate != null || _endDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('清除日期筛选'),
            ),
          ),
      ],
    );
  }

  Widget _buildUserFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '作者筛选',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedUserId.isEmpty ? null : _selectedUserId,
          decoration: const InputDecoration(
            hintText: '选择作者',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('所有作者'),
            ),
            ..._availableUsers.map((user) => DropdownMenuItem<String>(
              value: user,
              child: Text(user),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedUserId = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildRangeFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '数值范围筛选',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _buildRangeSlider(
          title: '图片数量',
          range: _imageCountRange,
          onChanged: (value) => setState(() => _imageCountRange = value),
          min: 0,
          max: 100,
        ),
        const SizedBox(height: 16),
        _buildRangeSlider(
          title: '浏览次数',
          range: _viewCountRange,
          onChanged: (value) => setState(() => _viewCountRange = value),
          min: 0,
          max: 1000,
        ),
        const SizedBox(height: 16),
        _buildRangeSlider(
          title: '点赞次数',
          range: _likeCountRange,
          onChanged: (value) => setState(() => _likeCountRange = value),
          min: 0,
          max: 100,
        ),
      ],
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required RangeValues range,
    required ValueChanged<RangeValues> onChanged,
    required double min,
    required double max,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ${range.start.round()} - ${range.end.round()}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        RangeSlider(
          values: range,
          min: min,
          max: max,
          divisions: 20,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTagFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '标签筛选',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (_availableTags.isEmpty)
          const Text(
            '暂无可用标签',
            style: TextStyle(color: Colors.grey),
          )
        else
          Wrap(
            spacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSortOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '排序选项',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: '排序字段',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'createdAt', child: Text('创建时间')),
                  DropdownMenuItem(value: 'updatedAt', child: Text('更新时间')),
                  DropdownMenuItem(value: 'title', child: Text('标题')),
                  DropdownMenuItem(value: 'viewCount', child: Text('浏览次数')),
                  DropdownMenuItem(value: 'likeCount', child: Text('点赞次数')),
                  DropdownMenuItem(value: 'imageCount', child: Text('图片数量')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value ?? 'createdAt';
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortOrder,
                decoration: const InputDecoration(
                  labelText: '排序顺序',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'desc', child: Text('降序')),
                  DropdownMenuItem(value: 'asc', child: Text('升序')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value ?? 'desc';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOtherOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '其他选项',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('仅显示公开专辑'),
          value: _showPublicOnly,
          onChanged: (value) {
            setState(() {
              _showPublicOnly = value ?? false;
            });
          },
        ),
        CheckboxListTile(
          title: const Text('包含空专辑'),
          value: _showEmptyAlbums,
          onChanged: (value) {
            setState(() {
              _showEmptyAlbums = value ?? true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: _clearAllFilters,
          icon: const Icon(Icons.clear_all),
          label: const Text('清除所有筛选'),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('应用筛选'),
            ),
          ],
        ),
      ],
    );
  }

  String _getStatusText(AlbumStatus status) {
    switch (status) {
      case AlbumStatus.draft:
        return '草稿';
      case AlbumStatus.published:
        return '已发布';
      case AlbumStatus.archived:
        return '已归档';
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStatuses.clear();
      _startDate = null;
      _endDate = null;
      _selectedUserId = '';
      _imageCountRange = const RangeValues(0, 100);
      _viewCountRange = const RangeValues(0, 1000);
      _likeCountRange = const RangeValues(0, 100);
      _selectedTags.clear();
      _sortBy = 'createdAt';
      _sortOrder = 'desc';
      _showPublicOnly = false;
      _showEmptyAlbums = true;
    });
  }

  void _applyFilters() {
    final filters = {
      'searchQuery': _searchQuery,
      'statuses': _selectedStatuses.map((s) => s.toString()).toList(),
      'startDate': _startDate,
      'endDate': _endDate,
      'userId': _selectedUserId,
      'imageCountMin': _imageCountRange.start.round(),
      'imageCountMax': _imageCountRange.end.round(),
      'viewCountMin': _viewCountRange.start.round(),
      'viewCountMax': _viewCountRange.end.round(),
      'likeCountMin': _likeCountRange.start.round(),
      'likeCountMax': _likeCountRange.end.round(),
      'tags': _selectedTags.toList(),
      'sortBy': _sortBy,
      'sortOrder': _sortOrder,
      'showPublicOnly': _showPublicOnly,
      'showEmptyAlbums': _showEmptyAlbums,
    };

    // 应用筛选到 AlbumProvider
    context.read<AlbumProvider>().applyAdvancedFilters(filters);
    
    // 保存最后使用的筛选条件
    _persistenceService.saveLastUsedFilters(filters);
    
    Navigator.of(context).pop(filters);
  }

  void _showSavePresetDialog() {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存筛选预设'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '预设名称',
            hintText: '输入预设名称...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                _saveCurrentFiltersAsPreset(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLoadPresetDialog() {
    if (_presets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无保存的预设')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加载筛选预设'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final presetName = _presets.keys.elementAt(index);
              return ListTile(
                title: Text(presetName),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deletePreset(presetName),
                ),
                onTap: () {
                  _loadPreset(presetName);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentFiltersAsPreset(String name) async {
    final filters = _getCurrentFilters();
    await _persistenceService.saveFilterPreset(name, filters);
    await _loadPresets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('预设 "$name" 已保存')),
    );
  }

  void _loadPreset(String name) {
    final preset = _presets[name];
    if (preset != null) {
      _applyPreset(preset);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已加载预设 "$name"')),
      );
    }
  }

  Future<void> _deletePreset(String name) async {
    await _persistenceService.deleteFilterPreset(name);
    await _loadPresets();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('预设 "$name" 已删除')),
    );
  }

  Map<String, dynamic> _getCurrentFilters() {
    return {
      'searchQuery': _searchQuery,
      'statuses': _selectedStatuses.map((s) => s.toString()).toList(),
      'startDate': _startDate,
      'endDate': _endDate,
      'userId': _selectedUserId,
      'imageCountMin': _imageCountRange.start.round(),
      'imageCountMax': _imageCountRange.end.round(),
      'viewCountMin': _viewCountRange.start.round(),
      'viewCountMax': _viewCountRange.end.round(),
      'likeCountMin': _likeCountRange.start.round(),
      'likeCountMax': _likeCountRange.end.round(),
      'tags': _selectedTags.toList(),
      'sortBy': _sortBy,
      'sortOrder': _sortOrder,
      'showPublicOnly': _showPublicOnly,
      'showEmptyAlbums': _showEmptyAlbums,
    };
  }

  void _applyPreset(Map<String, dynamic> preset) {
    setState(() {
      _searchQuery = preset['searchQuery'] ?? '';
      _searchController.text = _searchQuery;
      
      if (preset['statuses'] != null) {
        _selectedStatuses = Set<AlbumStatus>.from(
          (preset['statuses'] as List)
              .map((s) => AlbumStatus.values.firstWhere((e) => e.toString() == s))
        );
      }
      
      _startDate = preset['startDate'];
      _endDate = preset['endDate'];
      _selectedUserId = preset['userId'] ?? '';
      _imageCountRange = RangeValues(
        (preset['imageCountMin'] ?? 0).toDouble(),
        (preset['imageCountMax'] ?? 100).toDouble(),
      );
      _viewCountRange = RangeValues(
        (preset['viewCountMin'] ?? 0).toDouble(),
        (preset['viewCountMax'] ?? 1000).toDouble(),
      );
      _likeCountRange = RangeValues(
        (preset['likeCountMin'] ?? 0).toDouble(),
        (preset['likeCountMax'] ?? 100).toDouble(),
      );
      _selectedTags = Set<String>.from(preset['tags'] ?? []);
      _sortBy = preset['sortBy'] ?? 'createdAt';
      _sortOrder = preset['sortOrder'] ?? 'desc';
      _showPublicOnly = preset['showPublicOnly'] ?? false;
      _showEmptyAlbums = preset['showEmptyAlbums'] ?? true;
    });
  }
}

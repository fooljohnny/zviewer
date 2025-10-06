import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/content_management_provider.dart';
import '../../services/content_management_service.dart';
import '../../models/content_item.dart';
import '../common/glassmorphism_card.dart';
import '../common/modern_background.dart';
import '../common/zviewer_logo.dart';
import '../common/image_thumbnail.dart';
import 'album_management.dart';

/// 资源管理页面
/// 支持对后台服务的多媒体文件和图集进行查看、更换、增加、编辑信息
class AdminResourceManagement extends StatefulWidget {
  const AdminResourceManagement({super.key});

  @override
  State<AdminResourceManagement> createState() => _AdminResourceManagementState();
}

class _AdminResourceManagementState extends State<AdminResourceManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '全部';
  String _sortBy = '创建时间';
  bool _isAscending = false;
  int _selectedTabIndex = 0; // 0: 文件管理, 1: 图集管理
  
  // 批量选择相关状态
  bool _isSelectionMode = false;
  final Set<String> _selectedFileIds = <String>{};

  final List<String> _categories = ['全部', '图片', '视频', '音频', '文档', '图集'];
  final List<String> _sortOptions = ['创建时间', '文件名', '大小', '类型'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentManagementProvider>().loadContent(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 批量选择相关方法
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedFileIds.clear();
      }
    });
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFileIds.contains(fileId)) {
        _selectedFileIds.remove(fileId);
      } else {
        _selectedFileIds.add(fileId);
      }
    });
  }

  void _selectAllFiles(List<dynamic> files) {
    setState(() {
      _selectedFileIds.clear();
      for (var file in files) {
        _selectedFileIds.add(file.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedFileIds.clear();
    });
  }

  bool _isFileSelected(String fileId) {
    return _selectedFileIds.contains(fileId);
  }

  // 批量操作方法
  void _batchDownload() {
    if (_selectedFileIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量下载'),
        content: Text('确定要下载 ${_selectedFileIds.length} 个文件吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBatchDownload();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _batchDelete() {
    if (_selectedFileIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定要删除 ${_selectedFileIds.length} 个文件吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBatchDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _batchMoveToAlbum() {
    if (_selectedFileIds.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移动到相册'),
        content: Text('确定要将 ${_selectedFileIds.length} 个文件移动到相册吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBatchMoveToAlbum();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBatchDownload() async {
    try {
      // TODO: 实现批量下载逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('开始下载 ${_selectedFileIds.length} 个文件...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('下载失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performBatchDelete() async {
    try {
      final contentProvider = context.read<ContentManagementProvider>();
      
      // 批量删除文件
      for (String fileId in _selectedFileIds) {
        await contentProvider.deleteContent(fileId, '批量删除');
      }
      
      // 清空选择
      _clearSelection();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功删除 ${_selectedFileIds.length} 个文件'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performBatchMoveToAlbum() async {
    try {
      // TODO: 实现批量移动到相册逻辑
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('开始移动 ${_selectedFileIds.length} 个文件到相册...'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('移动失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 头部
              _buildHeader(),
              
              // 标签页
              _buildTabBar(),
              
              // 搜索和筛选栏
              if (_selectedTabIndex == 0) _buildSearchAndFilterBar(),
              
              // 批量操作工具栏
              if (_selectedTabIndex == 0 && _isSelectionMode) _buildBatchToolbar(),
              
              // 内容区域
              Expanded(
                child: _selectedTabIndex == 0 ? _buildFileList() : _buildAlbumManagement(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedTabIndex == 0 ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildBatchToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 选中数量显示
          Icon(
            Icons.check_circle,
            color: Colors.blue[300],
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '已选择 ${_selectedFileIds.length} 个文件',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 全选/取消全选按钮
          TextButton.icon(
            onPressed: () {
              final contentProvider = context.read<ContentManagementProvider>();
              final allFiles = _filterContent(contentProvider.content);
              if (_selectedFileIds.length == allFiles.length) {
                _clearSelection();
              } else {
                _selectAllFiles(allFiles);
              }
            },
            icon: Icon(
              _selectedFileIds.length == _filterContent(context.read<ContentManagementProvider>().content).length
                  ? Icons.check_box_outline_blank
                  : Icons.check_box,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _selectedFileIds.length == _filterContent(context.read<ContentManagementProvider>().content).length
                  ? '取消全选'
                  : '全选',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          // 批量操作按钮
          _buildBatchActionButton(
            icon: Icons.download,
            label: '下载',
            onPressed: _selectedFileIds.isNotEmpty ? _batchDownload : null,
          ),
          const SizedBox(width: 8),
          _buildBatchActionButton(
            icon: Icons.delete,
            label: '删除',
            onPressed: _selectedFileIds.isNotEmpty ? _batchDelete : null,
          ),
          const SizedBox(width: 8),
          _buildBatchActionButton(
            icon: Icons.folder,
            label: '移动到相册',
            onPressed: _selectedFileIds.isNotEmpty ? _batchMoveToAlbum : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('文件管理', 0, Icons.folder),
          ),
          Expanded(
            child: _buildTabButton('图集管理', 1, Icons.photo_library),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
        
        // 当切换到文件管理页面时，刷新数据
        if (index == 0) {
          final provider = context.read<ContentManagementProvider>();
          provider.loadContent(refresh: true);
          // 清除可能存在的重复数据
          provider.removeDuplicates();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumManagement() {
    return const AlbumManagementView();
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const ZViewerLogoMedium(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '资源管理',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '管理多媒体文件和图集',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // 批量选择模式切换按钮（仅在文件管理标签页显示）
          if (_selectedTabIndex == 0) ...[
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSelectionMode 
                    ? Colors.blue.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
              ),
              child: IconButton(
                onPressed: _toggleSelectionMode,
                icon: Icon(
                  _isSelectionMode ? Icons.check_circle : Icons.select_all,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: _isSelectionMode ? '退出选择模式' : '批量选择',
              ),
            ),
          ],
          const SizedBox(width: 12),
          // 关闭按钮 - 右上角
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: IconButton(
              onPressed: () {
                // 返回到首页
                Navigator.of(context).pushReplacementNamed('/');
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileStats() {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '共 ${provider.content.length} 个文件',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 可以添加其他统计信息，比如筛选后的数量
            if (_searchQuery.isNotEmpty || _selectedCategory != '全部')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: Colors.blue.withOpacity(0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '已筛选',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // 搜索和筛选行
          Row(
            children: [
              // 搜索框
              Expanded(
                child: SizedBox(
                  height: 48, // 固定高度，与筛选按钮保持一致
                  child: GlassmorphismCard(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center, // 垂直居中对齐
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.0, // 设置行高为1.0，避免额外空间
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索文件...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          height: 1.0,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.7),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.white.withOpacity(0.7),
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                        isCollapsed: false,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 筛选按钮
              SizedBox(
                height: 48, // 固定高度，与搜索框保持一致
                child: GlassmorphismButton(
                  onPressed: _showFilterDialog,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '筛选',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 文件统计信息
          _buildFileStats(),
          
          const SizedBox(height: 12),
          
          // 快速筛选标签
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.8),
                                    Colors.blue.withOpacity(0.6),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.8)
                                : Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  '加载失败: ${provider.error}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.loadContent(),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final filteredContent = _filterContent(provider.content);

        if (filteredContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? '没有找到匹配的文件'
                      : '暂无文件',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredContent.length,
          itemBuilder: (context, index) {
            final media = filteredContent[index];
            return _buildFileItem(media, index);
          },
        );
      },
    );
  }

  List<dynamic> _filterContent(List<dynamic> content) {
    var filtered = content.where((media) {
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final title = media.title?.toLowerCase() ?? '';
        if (!title.contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // 分类过滤
      if (_selectedCategory != '全部') {
        switch (_selectedCategory) {
          case '图片':
            if (media.type != ContentType.image) {
              return false;
            }
            break;
          case '视频':
            if (media.type != ContentType.video) {
              return false;
            }
            break;
          case '音频':
            if (!_isAudioFile(media)) {
              return false;
            }
            break;
          case '文档':
            if (!_isDocumentFile(media)) {
              return false;
            }
            break;
        }
      }

      return true;
    }).toList();

    // 排序
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case '文件名':
          comparison = (a.title ?? '').compareTo(b.title ?? '');
          break;
        case '大小':
          comparison = (a.fileSize ?? 0).compareTo(b.fileSize ?? 0);
          break;
        case '类型':
          comparison = _getTypeDisplayName(a.type).compareTo(_getTypeDisplayName(b.type));
          break;
        case '创建时间':
        default:
          comparison = (a.uploadedAt ?? DateTime.now())
              .compareTo(b.uploadedAt ?? DateTime.now());
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildFileItem(dynamic media, int index) {
    final isSelected = _isFileSelected(media.id);
    
    return GlassmorphismCard(
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleFileSelection(media.id);
          } else {
            _showFileDetails(media);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 缩略图区域
            Expanded(
              flex: 3,
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 120,
                  maxHeight: 140,
                ),
                child: Stack(
                children: [
                  // 图片缩略图
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: ImageThumbnail(
                      id: media.id,
                      thumbnailPath: media.thumbnailPath,
                      filePath: media.filePath,
                      mimeType: media.mimeType,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 文件类型图标覆盖层
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getFileTypeColorForMedia(media).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getFileTypeIconForMedia(media),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // 选择框（仅在选择模式下显示）
                  if (_isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleFileSelection(media.id),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Colors.blue 
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Colors.blue 
                                  : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                    ),
                  // 右上角操作按钮（非选择模式下显示）
                  if (!_isSelectionMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        onSelected: (value) => _handleFileAction(value, media),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('编辑信息'),
                          ),
                          const PopupMenuItem(
                            value: 'replace',
                            child: Text('更换文件'),
                          ),
                          const PopupMenuItem(
                            value: 'download',
                            child: Text('下载'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('删除'),
                          ),
                        ],
                      ),
                  ),
                  // 视频播放按钮
                  if (media.type == ContentType.video)
                    const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                ],
                ),
              ),
            ),
            // 文件信息区域
            Container(
              constraints: const BoxConstraints(
                minHeight: 70,
                maxHeight: 80, // 进一步减少最大高度
              ),
              padding: const EdgeInsets.fromLTRB(4, 3, 4, 3), // 进一步减少padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 文件名 - 占用更多空间
                  Expanded(
                    flex: 2,
                    child: Text(
                      media.title ?? '未知文件',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10, // 进一步减小字体
                        fontWeight: FontWeight.w600,
                        height: 1.1, // 进一步减少行高
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 文件类型和大小 - 使用剩余空间
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 文件类型
                        Text(
                          _getFileTypeDisplayName(media),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 7, // 进一步减小字体
                            fontWeight: FontWeight.w500,
                            height: 1.0, // 进一步减少行高
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 文件大小
                        Text(
                          _formatFileSize(media.fileSize),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 6, // 进一步减小字体
                            height: 1.0, // 进一步减少行高
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // 上传时间
                        Text(
                          _formatDate(media.uploadedAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 6, // 进一步减小字体
                            height: 1.0, // 进一步减少行高
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showAddFileDialog,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }


  Color _getFileTypeColorForMedia(dynamic media) {
    // 首先检查ContentType
    if (media.type == ContentType.image) {
      return Colors.green;
    } else if (media.type == ContentType.video) {
      return Colors.red;
    }
    
    // 然后检查MIME类型
    if (media.mimeType != null) {
      final mime = media.mimeType!.toLowerCase();
      if (mime.startsWith('audio/')) {
        return Colors.orange;
      } else if (mime.startsWith('application/pdf') || 
                 mime.startsWith('application/msword') ||
                 mime.startsWith('application/vnd.openxmlformats-officedocument') ||
                 mime.startsWith('text/')) {
        return Colors.blue;
      }
    }
    
    // 最后检查文件扩展名
    if (media.filePath != null) {
      final path = media.filePath!.toLowerCase();
      if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.flac') || 
          path.endsWith('.aac') || path.endsWith('.ogg')) {
        return Colors.orange;
      } else if (path.endsWith('.pdf') || path.endsWith('.doc') || path.endsWith('.docx') || 
                 path.endsWith('.txt') || path.endsWith('.rtf')) {
        return Colors.blue;
      }
    }
    
    return Colors.grey;
  }


  IconData _getFileTypeIconForMedia(dynamic media) {
    // 首先检查ContentType
    if (media.type == ContentType.image) {
      return Icons.image;
    } else if (media.type == ContentType.video) {
      return Icons.videocam;
    }
    
    // 然后检查MIME类型
    if (media.mimeType != null) {
      final mime = media.mimeType!.toLowerCase();
      if (mime.startsWith('audio/')) {
        return Icons.audiotrack;
      } else if (mime.startsWith('application/pdf') || 
                 mime.startsWith('application/msword') ||
                 mime.startsWith('application/vnd.openxmlformats-officedocument') ||
                 mime.startsWith('text/')) {
        return Icons.description;
      }
    }
    
    // 最后检查文件扩展名
    if (media.filePath != null) {
      final path = media.filePath!.toLowerCase();
      if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.flac') || 
          path.endsWith('.aac') || path.endsWith('.ogg')) {
        return Icons.audiotrack;
      } else if (path.endsWith('.pdf') || path.endsWith('.doc') || path.endsWith('.docx') || 
                 path.endsWith('.txt') || path.endsWith('.rtf')) {
        return Icons.description;
      }
    }
    
    return Icons.insert_drive_file;
  }

  String _getTypeDisplayName(ContentType? type) {
    switch (type) {
      case ContentType.image:
        return '图片';
      case ContentType.video:
        return '视频';
      default:
        return '未知类型';
    }
  }

  String _getFileTypeDisplayName(dynamic media) {
    // 首先检查ContentType
    if (media.type == ContentType.image) {
      return '图片';
    } else if (media.type == ContentType.video) {
      return '视频';
    }
    
    // 然后检查MIME类型
    if (media.mimeType != null) {
      final mime = media.mimeType!.toLowerCase();
      if (mime.startsWith('audio/')) {
        return '音频';
      } else if (mime.startsWith('application/pdf') || 
                 mime.startsWith('application/msword') ||
                 mime.startsWith('application/vnd.openxmlformats-officedocument') ||
                 mime.startsWith('text/')) {
        return '文档';
      }
    }
    
    // 最后检查文件扩展名
    if (media.filePath != null) {
      final path = media.filePath!.toLowerCase();
      if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.flac') || 
          path.endsWith('.aac') || path.endsWith('.ogg')) {
        return '音频';
      } else if (path.endsWith('.pdf') || path.endsWith('.doc') || path.endsWith('.docx') || 
                 path.endsWith('.txt') || path.endsWith('.rtf')) {
        return '文档';
      }
    }
    
    return '未知类型';
  }

  String _formatFileSize(int? size) {
    if (size == null) return '未知大小';
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未知时间';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // 移动端：2列
    } else if (screenWidth < 900) {
      return 3; // 平板端：3列
    } else if (screenWidth < 1200) {
      return 4; // 小桌面：4列
    } else {
      return 5; // 大桌面：5列
    }
  }


  bool _isAudioFile(dynamic media) {
    if (media.mimeType != null) {
      final mime = media.mimeType!.toLowerCase();
      return mime.startsWith('audio/');
    }
    if (media.filePath != null) {
      final path = media.filePath!.toLowerCase();
      return path.endsWith('.mp3') || 
             path.endsWith('.wav') || 
             path.endsWith('.flac') || 
             path.endsWith('.aac') || 
             path.endsWith('.ogg');
    }
    return false;
  }

  bool _isDocumentFile(dynamic media) {
    if (media.mimeType != null) {
      final mime = media.mimeType!.toLowerCase();
      return mime.startsWith('application/pdf') ||
             mime.startsWith('application/msword') ||
             mime.startsWith('application/vnd.openxmlformats-officedocument') ||
             mime.startsWith('text/');
    }
    if (media.filePath != null) {
      final path = media.filePath!.toLowerCase();
      return path.endsWith('.pdf') || 
             path.endsWith('.doc') || 
             path.endsWith('.docx') || 
             path.endsWith('.txt') || 
             path.endsWith('.rtf');
    }
    return false;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选和排序'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _sortBy,
              decoration: const InputDecoration(
                labelText: '排序方式',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: _sortOptions.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? '创建时间';
                });
              },
            ),
            SwitchListTile(
              title: const Text('升序'),
              value: _isAscending,
              onChanged: (value) {
                setState(() {
                  _isAscending = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFileDetails(dynamic media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(media.title ?? '文件详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${_getTypeDisplayName(media.type)}'),
            Text('大小: ${_formatFileSize(media.fileSize)}'),
            Text('创建时间: ${_formatDate(media.uploadedAt)}'),
            if (media.description != null)
              Text('描述: ${media.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleFileAction('edit', media);
            },
            child: const Text('编辑'),
          ),
        ],
      ),
    );
  }

  void _handleFileAction(String action, dynamic media) {
    switch (action) {
      case 'edit':
        _showEditFileDialog(media);
        break;
      case 'replace':
        _showReplaceFileDialog(media);
        break;
      case 'download':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载功能开发中')),
        );
        break;
      case 'delete':
        _showDeleteConfirmDialog(media);
        break;
    }
  }

  void _showEditFileDialog(dynamic media) {
    final titleController = TextEditingController(text: media.title ?? '');
    final descriptionController = TextEditingController(text: media.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑文件信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '文件名',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 这里应该调用API更新文件信息
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件信息已更新')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showReplaceFileDialog(dynamic media) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('更换文件功能开发中')),
    );
  }

  void _showDeleteConfirmDialog(dynamic media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除文件 "${media.title ?? '未知文件'}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 这里应该调用API删除文件
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件已删除')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddFileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassmorphismCard(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '上传文件',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择要上传的多媒体文件',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.image,
                          label: '图片',
                          onTap: () => _pickFiles(FileType.image),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.videocam,
                          label: '视频',
                          onTap: () => _pickFiles(FileType.video),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildUploadButton(
                          icon: Icons.audiotrack,
                          label: '音频',
                          onTap: () => _pickFiles(FileType.audio),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUploadButton(
                    icon: Icons.folder_open,
                    label: '所有文件',
                    onTap: () => _pickFiles(FileType.any),
                    isWide: true,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '取消',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isWide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(FileType fileType) async {
    try {
      Navigator.of(context).pop(); // 关闭对话框
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        await _uploadFiles(result.files);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('文件选择失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadFiles(List<PlatformFile> files) async {
    try {
      // 显示上传进度
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.transparent,
          content: GlassmorphismCard(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '正在上传 ${files.length} 个文件...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 转换文件格式
      final uploadFiles = files.map((file) => UploadFile(
        path: file.path ?? '',
        name: file.name,
        title: file.name,
        description: '',
        category: _getFileCategory(file.extension),
        tags: [],
      )).toList();

      // 调用实际上传API
      await context.read<ContentManagementProvider>().uploadFiles(uploadFiles);

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功上传 ${files.length} 个文件'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileCategory(String? extension) {
    if (extension == null) return '其他';
    
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return '图片';
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
        return '视频';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        return '音频';
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return '文档';
      default:
        return '其他';
    }
  }
}

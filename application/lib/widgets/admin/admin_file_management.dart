import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/content_management_provider.dart';
import '../common/glassmorphism_card.dart';
import '../common/zviewer_logo.dart';

/// 管理文件页面
/// 支持对后台服务的多媒体文件进行查看、更换、增加、编辑信息
class AdminFileManagement extends StatefulWidget {
  const AdminFileManagement({super.key});

  @override
  State<AdminFileManagement> createState() => _AdminFileManagementState();
}

class _AdminFileManagementState extends State<AdminFileManagement> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = '全部';
  String _sortBy = '创建时间';
  bool _isAscending = false;

  final List<String> _categories = ['全部', '图片', '视频', '音频', '文档'];
  final List<String> _sortOptions = ['创建时间', '文件名', '大小', '类型'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentManagementProvider>().loadContent();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              // 头部
              _buildHeader(),
              
              // 搜索和筛选栏
              _buildSearchAndFilterBar(),
              
              // 文件列表
              Expanded(
                child: _buildFileList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF3A3A3C),
        ],
      ),
    );
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
                  '文件管理',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '管理多媒体文件',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          _buildStatsCard(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        return GlassmorphismCard(
          child: Column(
            children: [
              Text(
                '${provider.content.length}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '总文件数',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // 搜索框
          Row(
            children: [
              Expanded(
                child: GlassmorphismCard(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '搜索文件...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 筛选按钮
              GlassmorphismButton(
                onPressed: _showFilterDialog,
                child: const Icon(
                  Icons.filter_list,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // 快速筛选标签
          SingleChildScrollView(
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blue.withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
        // 这里可以根据实际的文件类型进行过滤
        // 暂时返回所有内容
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
          comparison = (a.type ?? '').compareTo(b.type ?? '');
          break;
        case '创建时间':
        default:
          comparison = (a.createdAt ?? DateTime.now())
              .compareTo(b.createdAt ?? DateTime.now());
          break;
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Widget _buildFileItem(dynamic media, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphismCard(
        child: InkWell(
          onTap: () => _showFileDetails(media),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 文件图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getFileTypeColor(media.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileTypeIcon(media.type),
                    color: _getFileTypeColor(media.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // 文件信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title ?? '未知文件',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${media.type ?? '未知类型'} • ${_formatFileSize(media.fileSize)} • ${_formatDate(media.createdAt)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 操作按钮
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white.withOpacity(0.7),
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
              ],
            ),
          ),
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

  Color _getFileTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.green;
      case 'video':
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.red;
      case 'audio':
      case 'mp3':
      case 'wav':
        return Colors.orange;
      case 'document':
      case 'pdf':
      case 'doc':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getFileTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'video':
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'audio':
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'document':
      case 'pdf':
      case 'doc':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('筛选和排序'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(labelText: '排序方式'),
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
            Text('类型: ${media.type ?? '未知'}'),
            Text('大小: ${_formatFileSize(media.fileSize)}'),
            Text('创建时间: ${_formatDate(media.createdAt)}'),
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
              decoration: const InputDecoration(labelText: '文件名'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: '描述'),
              maxLines: 3,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加文件功能开发中')),
    );
  }
}

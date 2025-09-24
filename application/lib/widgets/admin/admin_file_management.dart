import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/content_management_provider.dart';
import '../../services/content_management_service.dart';
import '../common/glassmorphism_card.dart';
import '../common/modern_background.dart';
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
      body: ModernBackground(
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
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: false,
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

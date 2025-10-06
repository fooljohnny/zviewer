import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/content_management_provider.dart';
import '../../models/album.dart';
import '../../models/content_item.dart';
import '../common/image_thumbnail.dart';
import 'album_image_management.dart';

class AlbumFormDialog extends StatefulWidget {
  final Album? album;

  const AlbumFormDialog({super.key, this.album});

  @override
  State<AlbumFormDialog> createState() => _AlbumFormDialogState();
}

class _AlbumFormDialogState extends State<AlbumFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  AlbumStatus _selectedStatus = AlbumStatus.draft;
  bool _isPublic = true;
  bool _isLoading = false;
  final Set<String> _selectedImageIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.album != null) {
      _titleController.text = widget.album!.title;
      _descriptionController.text = widget.album!.description;
      _tagsController.text = widget.album!.tags?.join(', ') ?? '';
      _selectedStatus = widget.album!.status;
      _isPublic = widget.album!.isPublic;
    } else {
      // Load available images for new album
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadAvailableImages();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.album != null;
    
    return AlertDialog(
      title: Text(isEditing ? '编辑图集' : '创建图集'),
      content: SizedBox(
        width: 500,
        height: 600, // 设置固定高度
        child: Form(
          key: _formKey,
          child: SingleChildScrollView( // 添加滚动支持
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  hintText: '请输入图集标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '标题不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述 *',
                  hintText: '请输入图集描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '描述不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Tags field
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: '标签',
                  hintText: '请输入标签，用逗号分隔',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Status dropdown
              DropdownButtonFormField<AlbumStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: '状态',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AlbumStatus.draft,
                    child: Text('草稿'),
                  ),
                  DropdownMenuItem(
                    value: AlbumStatus.published,
                    child: Text('已发布'),
                  ),
                  DropdownMenuItem(
                    value: AlbumStatus.archived,
                    child: Text('已归档'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Public checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value ?? false;
                      });
                    },
                  ),
                  const Text('公开此图集'),
                ],
              ),
              const SizedBox(height: 16),
              // Image selection section (for creating)
              if (!isEditing) ...[
                const Divider(),
                const Text(
                  '选择图片 *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('已选择: ${_selectedImageIds.length} 张图片'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 150, // 减少高度
                  child: _buildImageSelection(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loadAvailableImages,
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新图片'),
                    ),
                    const Spacer(), // 添加弹性空间，避免与底部按钮重叠
                  ],
                ),
              ],
              // Image management section (for editing)
              if (isEditing) ...[
                const Divider(),
                const Text(
                  '图片管理',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('此图集包含 ${widget.album!.imageCount} 张图片'),
                const SizedBox(height: 8),
                Row(
                  children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AlbumImageManagementDialog(album: widget.album!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('添加图片'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AlbumImageManagementDialog(album: widget.album!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_search),
                  label: const Text('管理图片'),
                ),
                  ],
                ),
              ],
            ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '更新' : '创建'),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (widget.album != null) {
        // Update existing album
        final request = UpdateAlbumRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: tags,
          isPublic: _isPublic,
          status: _selectedStatus,
        );

        await context.read<AlbumProvider>().updateAlbum(
          widget.album!.id,
          request,
        );
      } else {
        // Create new album - require at least one image
        if (_selectedImageIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请至少选择一张图片'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final request = CreateAlbumRequest(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageIds: _selectedImageIds.toList(),
          tags: tags,
          isPublic: _isPublic,
        );

        await context.read<AlbumProvider>().createAlbum(request);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.album != null
                  ? '图集更新成功'
                  : '图集创建成功',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadAvailableImages() {
    context.read<ContentManagementProvider>().loadContent(refresh: true);
  }

  Widget _buildImageSelection() {
    return Consumer<ContentManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 调试信息
        print('AlbumForm - Total content items: ${provider.content.length}');
        print('AlbumForm - Provider error: ${provider.error}');
        
        // 显示所有文件的详细信息
        print('AlbumForm - All files:');
        for (var item in provider.content) {
          print('  - File: ${item.title}, mimeType: ${item.mimeType}, id: ${item.id}, type: ${item.type}');
        }
        
        final images = provider.content.where((item) => 
          item.mimeType?.startsWith('image/') == true || 
          item.type == ContentType.image
        ).toList();

        print('AlbumForm - Filtered images: ${images.length}');
        for (var image in images.take(3)) {
          print('  - Image: ${image.title}, mimeType: ${image.mimeType}, id: ${image.id}');
        }

        if (images.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text('暂无可用图片 (总共 ${provider.content.length} 个文件)'),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '错误: ${provider.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadAvailableImages,
                  child: const Text('重新加载'),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 增加列数以适应较小高度
            childAspectRatio: 1,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            final isSelected = _selectedImageIds.contains(image.id);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    if (image.id != null) {
                      _selectedImageIds.remove(image.id!);
                    }
                  } else {
                    if (image.id != null) {
                      _selectedImageIds.add(image.id!);
                    }
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      ImageThumbnail(
                        id: image.id,
                        thumbnailPath: image.thumbnailPath,
                        filePath: image.filePath,
                        mimeType: image.mimeType,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(Icons.broken_image, size: 32),
                      ),
                      if (isSelected)
                        Container(
                          color: Colors.blue.withOpacity(0.3),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

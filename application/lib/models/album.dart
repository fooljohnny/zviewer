import 'package:json_annotation/json_annotation.dart';

part 'album.g.dart';

/// 图集状态枚举
enum AlbumStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
}

/// 图集数据模型
@JsonSerializable()
class Album {
  final String id;
  final String title;
  final String description;
  final String? coverImageId; // 封面图片ID
  final String? coverImagePath; // 封面图片路径
  final String? coverThumbnailPath; // 封面缩略图路径
  final List<String>? imageIds; // 图片ID列表
  final List<AlbumImage>? images; // 图片列表（从服务器获取）
  final AlbumStatus status;
  final String userId;
  final String userName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;
  final int? imageCount; // 图片数量
  final List<String>? tags; // 标签
  final bool isPublic; // 是否公开
  final int viewCount; // 浏览次数
  final int likeCount; // 点赞次数
  final int? favoriteCount; // 收藏次数
  final bool? isFavorited; // 当前用户是否已收藏

  const Album({
    required this.id,
    required this.title,
    required this.description,
    this.coverImageId,
    this.coverImagePath,
    this.coverThumbnailPath,
    this.imageIds,
    this.images,
    required this.status,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
    this.imageCount,
    this.tags,
    required this.isPublic,
    required this.viewCount,
    required this.likeCount,
    this.favoriteCount,
    this.isFavorited,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 Album.fromJson - Raw JSON: $json');
      print('🔍 Album.fromJson - id type: ${json['id'].runtimeType}, value: ${json['id']}');
      print('🔍 Album.fromJson - title type: ${json['title'].runtimeType}, value: ${json['title']}');
      print('🔍 Album.fromJson - description type: ${json['description'].runtimeType}, value: ${json['description']}');
      print('🔍 Album.fromJson - imageIds type: ${json['imageIds'].runtimeType}, value: ${json['imageIds']}');
      print('🔍 Album.fromJson - tags type: ${json['tags'].runtimeType}, value: ${json['tags']}');
      print('🔍 Album.fromJson - metadata type: ${json['metadata'].runtimeType}, value: ${json['metadata']}');
      return _$AlbumFromJson(json);
    } catch (e, stackTrace) {
      print('❌ Album.fromJson ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$AlbumToJson(this);

  Album copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageId,
    String? coverImagePath,
    String? coverThumbnailPath,
    List<String>? imageIds,
    List<AlbumImage>? images,
    AlbumStatus? status,
    String? userId,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    int? imageCount,
    List<String>? tags,
    bool? isPublic,
    int? viewCount,
    int? likeCount,
    int? favoriteCount,
    bool? isFavorited,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageId: coverImageId ?? this.coverImageId,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverThumbnailPath: coverThumbnailPath ?? this.coverThumbnailPath,
      imageIds: imageIds ?? this.imageIds,
      images: images ?? this.images,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      imageCount: imageCount ?? this.imageCount,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Album &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.coverImageId == coverImageId &&
        other.coverImagePath == coverImagePath &&
        other.coverThumbnailPath == coverThumbnailPath &&
        other.imageIds == imageIds &&
        other.images == images &&
        other.status == status &&
        other.userId == userId &&
        other.userName == userName &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.metadata == metadata &&
        other.imageCount == imageCount &&
        other.tags == tags &&
        other.isPublic == isPublic &&
        other.viewCount == viewCount &&
        other.likeCount == likeCount &&
        other.favoriteCount == favoriteCount &&
        other.isFavorited == isFavorited;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      title,
      description,
      coverImageId,
      coverImagePath,
      coverThumbnailPath,
      imageIds,
      images,
      status,
      userId,
      userName,
      createdAt,
      updatedAt,
      metadata,
      imageCount,
      tags,
      isPublic,
      viewCount,
      likeCount,
      favoriteCount,
      isFavorited,
    ]);
  }

  @override
  String toString() {
    return 'Album(id: $id, title: $title, status: $status, imageCount: $imageCount)';
  }

  // 验证方法
  bool get isValid {
    return id.isNotEmpty &&
        title.isNotEmpty &&
        description.isNotEmpty &&
        userId.isNotEmpty &&
        userName.isNotEmpty;
  }

  bool get isDraft => status == AlbumStatus.draft;
  bool get isPublished => status == AlbumStatus.published;
  bool get isArchived => status == AlbumStatus.archived;
  bool get hasCover => coverImageUrl != null && coverImageUrl!.isNotEmpty;
  bool get isEmpty => imageIds?.isEmpty ?? true;
  bool get isNotEmpty => imageIds?.isNotEmpty ?? false;

  /// 获取封面图片URL，优先使用缩略图
  String? get coverImageUrl => coverThumbnailPath ?? coverImagePath;
  
  /// 获取显示标题，如果为空则返回默认值
  String get displayTitle => title.isNotEmpty ? title : '未命名图集';
  
  /// 获取显示描述，如果为空则返回默认值
  String get displayDescription => description.isNotEmpty ? description : '暂无描述';
  
  /// 获取格式化的创建时间
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 7) {
      return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 获取格式化的更新时间
  String get formattedUpdatedAt {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inDays > 7) {
      return '${updatedAt.year}-${updatedAt.month.toString().padLeft(2, '0')}-${updatedAt.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
  
  /// 获取状态显示文本
  String get statusDisplayText {
    switch (status) {
      case AlbumStatus.draft:
        return '草稿';
      case AlbumStatus.published:
        return '已发布';
      case AlbumStatus.archived:
        return '已归档';
    }
  }
  
  /// 获取状态颜色
  int get statusColor {
    switch (status) {
      case AlbumStatus.draft:
        return 0xFF9E9E9E; // 灰色
      case AlbumStatus.published:
        return 0xFF4CAF50; // 绿色
      case AlbumStatus.archived:
        return 0xFFFF9800; // 橙色
    }
  }
  
  /// 获取标签显示文本
  String get tagsDisplayText => (tags?.isEmpty ?? true) ? '无标签' : tags!.join(', ');
  
  /// 获取图片数量显示文本
  String get imageCountDisplayText {
    if (imageCount == 0) return '暂无图片';
    if (imageCount == 1) return '1张图片';
    return '$imageCount张图片';
  }
  
  /// 获取浏览和点赞统计文本
  String get statsDisplayText {
    final parts = <String>[];
    if (viewCount > 0) parts.add('$viewCount次浏览');
    if (likeCount > 0) parts.add('$likeCount个赞');
    return parts.isEmpty ? '暂无统计' : parts.join(' · ');
  }
  
  /// 检查是否包含指定图片
  bool containsImage(String imageId) => imageIds?.contains(imageId) ?? false;
  
  /// 获取图片在列表中的位置
  int getImageIndex(String imageId) => imageIds?.indexOf(imageId) ?? -1;
  
  /// 获取下一张图片ID
  String? getNextImageId(String currentImageId) {
    if (imageIds == null) return null;
    final index = imageIds!.indexOf(currentImageId);
    if (index == -1 || index >= imageIds!.length - 1) return null;
    return imageIds![index + 1];
  }
  
  /// 获取上一张图片ID
  String? getPreviousImageId(String currentImageId) {
    if (imageIds == null) return null;
    final index = imageIds!.indexOf(currentImageId);
    if (index <= 0) return null;
    return imageIds![index - 1];
  }
}

/// 图集创建请求
@JsonSerializable()
class CreateAlbumRequest {
  final String? title;
  final String? description;
  final List<String>? imageIds;
  final List<String>? tags;
  final bool isPublic;
  final String? coverImageId;

  const CreateAlbumRequest({
    this.title,
    this.description,
    this.imageIds,
    this.tags,
    required this.isPublic,
    this.coverImageId,
  });

  factory CreateAlbumRequest.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 CreateAlbumRequest.fromJson - Raw JSON: $json');
      print('🔍 CreateAlbumRequest.fromJson - title type: ${json['title'].runtimeType}, value: ${json['title']}');
      print('🔍 CreateAlbumRequest.fromJson - description type: ${json['description'].runtimeType}, value: ${json['description']}');
      print('🔍 CreateAlbumRequest.fromJson - imageIds type: ${json['imageIds'].runtimeType}, value: ${json['imageIds']}');
      print('🔍 CreateAlbumRequest.fromJson - tags type: ${json['tags'].runtimeType}, value: ${json['tags']}');
      print('🔍 CreateAlbumRequest.fromJson - isPublic type: ${json['isPublic'].runtimeType}, value: ${json['isPublic']}');
      return _$CreateAlbumRequestFromJson(json);
    } catch (e, stackTrace) {
      print('❌ CreateAlbumRequest.fromJson ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$CreateAlbumRequestToJson(this);
}

/// 图集更新请求
@JsonSerializable()
class UpdateAlbumRequest {
  final String? title;
  final String? description;
  final List<String>? imageIds;
  final String? coverImageId;
  final List<String>? tags;
  final bool? isPublic;
  final AlbumStatus? status;

  const UpdateAlbumRequest({
    this.title,
    this.description,
    this.imageIds,
    this.coverImageId,
    this.tags,
    this.isPublic,
    this.status,
  });

  factory UpdateAlbumRequest.fromJson(Map<String, dynamic> json) => 
      _$UpdateAlbumRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAlbumRequestToJson(this);
}

/// 图集列表响应
@JsonSerializable()
class AlbumListResponse {
  final List<Album> albums;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const AlbumListResponse({
    required this.albums,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AlbumListResponse.fromJson(Map<String, dynamic> json) => 
      _$AlbumListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumListResponseToJson(this);
}

/// 图集操作响应
@JsonSerializable()
class AlbumActionResponse {
  final bool success;
  final String? message;
  final Album? album;

  const AlbumActionResponse({
    required this.success,
    this.message,
    this.album,
  });

  factory AlbumActionResponse.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 AlbumActionResponse.fromJson - Raw JSON: $json');
      print('🔍 AlbumActionResponse.fromJson - success type: ${json['success'].runtimeType}, value: ${json['success']}');
      print('🔍 AlbumActionResponse.fromJson - message type: ${json['message'].runtimeType}, value: ${json['message']}');
      print('🔍 AlbumActionResponse.fromJson - album type: ${json['album'].runtimeType}, value: ${json['album']}');
      return _$AlbumActionResponseFromJson(json);
    } catch (e, stackTrace) {
      print('❌ AlbumActionResponse.fromJson ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() => _$AlbumActionResponseToJson(this);
}

/// 添加图片到图集请求
@JsonSerializable()
class AddImageToAlbumRequest {
  final List<String>? imageIds;

  const AddImageToAlbumRequest({
    this.imageIds,
  });

  factory AddImageToAlbumRequest.fromJson(Map<String, dynamic> json) => 
      _$AddImageToAlbumRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AddImageToAlbumRequestToJson(this);
}

/// 从图集移除图片请求
@JsonSerializable()
class RemoveImageFromAlbumRequest {
  final List<String>? imageIds;

  const RemoveImageFromAlbumRequest({
    this.imageIds,
  });

  factory RemoveImageFromAlbumRequest.fromJson(Map<String, dynamic> json) => 
      _$RemoveImageFromAlbumRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RemoveImageFromAlbumRequestToJson(this);
}

/// 设置图集封面请求
@JsonSerializable()
class SetAlbumCoverRequest {
  final String? imageId;

  const SetAlbumCoverRequest({
    this.imageId,
  });

  factory SetAlbumCoverRequest.fromJson(Map<String, dynamic> json) => 
      _$SetAlbumCoverRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SetAlbumCoverRequestToJson(this);
}

/// 图集图片模型
@JsonSerializable()
class AlbumImage {
  final String? id;
  final String? albumId;
  final String? imageId;
  final String? imagePath;
  final String? thumbnailPath;
  final String? mimeType;
  final int? fileSize;
  final int? width;
  final int? height;
  final int? sortOrder;
  final DateTime? addedAt;
  final String? addedBy;

  const AlbumImage({
    this.id,
    this.albumId,
    this.imageId,
    this.imagePath,
    this.thumbnailPath,
    this.mimeType,
    this.fileSize,
    this.width,
    this.height,
    this.sortOrder,
    this.addedAt,
    this.addedBy,
  });

  factory AlbumImage.fromJson(Map<String, dynamic> json) => 
      _$AlbumImageFromJson(json);
  Map<String, dynamic> toJson() => _$AlbumImageToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlbumImage &&
        other.id == id &&
        other.albumId == albumId &&
        other.imageId == imageId;
  }

  @override
  int get hashCode => Object.hash(id, albumId, imageId);

  @override
  String toString() => 'AlbumImage(id: $id, albumId: $albumId, imageId: $imageId)';
}


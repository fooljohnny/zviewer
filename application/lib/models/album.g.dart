// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Album _$AlbumFromJson(Map<String, dynamic> json) => Album(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coverImageId: json['coverImageId'] as String?,
      coverImagePath: json['coverImagePath'] as String?,
      coverThumbnailPath: json['coverThumbnailPath'] as String?,
      imageIds: (json['imageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => AlbumImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecode(_$AlbumStatusEnumMap, json['status']),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      imageCount: (json['imageCount'] as num?)?.toInt(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isPublic: json['isPublic'] as bool,
      viewCount: (json['viewCount'] as num).toInt(),
      likeCount: (json['likeCount'] as num).toInt(),
      favoriteCount: (json['favoriteCount'] as num?)?.toInt(),
      isFavorited: json['isFavorited'] as bool?,
    );

Map<String, dynamic> _$AlbumToJson(Album instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'coverImageId': instance.coverImageId,
      'coverImagePath': instance.coverImagePath,
      'coverThumbnailPath': instance.coverThumbnailPath,
      'imageIds': instance.imageIds,
      'images': instance.images,
      'status': _$AlbumStatusEnumMap[instance.status]!,
      'userId': instance.userId,
      'userName': instance.userName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
      'imageCount': instance.imageCount,
      'tags': instance.tags,
      'isPublic': instance.isPublic,
      'viewCount': instance.viewCount,
      'likeCount': instance.likeCount,
      'favoriteCount': instance.favoriteCount,
      'isFavorited': instance.isFavorited,
    };

const _$AlbumStatusEnumMap = {
  AlbumStatus.draft: 'draft',
  AlbumStatus.published: 'published',
  AlbumStatus.archived: 'archived',
};

CreateAlbumRequest _$CreateAlbumRequestFromJson(Map<String, dynamic> json) =>
    CreateAlbumRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageIds: (json['imageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isPublic: json['isPublic'] as bool,
      coverImageId: json['coverImageId'] as String?,
    );

Map<String, dynamic> _$CreateAlbumRequestToJson(CreateAlbumRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'imageIds': instance.imageIds,
      'tags': instance.tags,
      'isPublic': instance.isPublic,
      'coverImageId': instance.coverImageId,
    };

UpdateAlbumRequest _$UpdateAlbumRequestFromJson(Map<String, dynamic> json) =>
    UpdateAlbumRequest(
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageIds: (json['imageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      coverImageId: json['coverImageId'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      isPublic: json['isPublic'] as bool?,
      status: $enumDecodeNullable(_$AlbumStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$UpdateAlbumRequestToJson(UpdateAlbumRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'imageIds': instance.imageIds,
      'coverImageId': instance.coverImageId,
      'tags': instance.tags,
      'isPublic': instance.isPublic,
      'status': _$AlbumStatusEnumMap[instance.status],
    };

AlbumListResponse _$AlbumListResponseFromJson(Map<String, dynamic> json) =>
    AlbumListResponse(
      albums: (json['albums'] as List<dynamic>)
          .map((e) => Album.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$AlbumListResponseToJson(AlbumListResponse instance) =>
    <String, dynamic>{
      'albums': instance.albums,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'totalPages': instance.totalPages,
    };

AlbumActionResponse _$AlbumActionResponseFromJson(Map<String, dynamic> json) =>
    AlbumActionResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      album: json['album'] == null
          ? null
          : Album.fromJson(json['album'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AlbumActionResponseToJson(
        AlbumActionResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'album': instance.album,
    };

AddImageToAlbumRequest _$AddImageToAlbumRequestFromJson(
        Map<String, dynamic> json) =>
    AddImageToAlbumRequest(
      imageIds: (json['imageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$AddImageToAlbumRequestToJson(
        AddImageToAlbumRequest instance) =>
    <String, dynamic>{
      'imageIds': instance.imageIds,
    };

RemoveImageFromAlbumRequest _$RemoveImageFromAlbumRequestFromJson(
        Map<String, dynamic> json) =>
    RemoveImageFromAlbumRequest(
      imageIds: (json['imageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$RemoveImageFromAlbumRequestToJson(
        RemoveImageFromAlbumRequest instance) =>
    <String, dynamic>{
      'imageIds': instance.imageIds,
    };

SetAlbumCoverRequest _$SetAlbumCoverRequestFromJson(
        Map<String, dynamic> json) =>
    SetAlbumCoverRequest(
      imageId: json['imageId'] as String?,
    );

Map<String, dynamic> _$SetAlbumCoverRequestToJson(
        SetAlbumCoverRequest instance) =>
    <String, dynamic>{
      'imageId': instance.imageId,
    };

AlbumImage _$AlbumImageFromJson(Map<String, dynamic> json) => AlbumImage(
      id: json['id'] as String?,
      albumId: json['albumId'] as String?,
      imageId: json['imageId'] as String?,
      imagePath: json['imagePath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      mimeType: json['mimeType'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      addedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
      addedBy: json['addedBy'] as String?,
    );

Map<String, dynamic> _$AlbumImageToJson(AlbumImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'albumId': instance.albumId,
      'imageId': instance.imageId,
      'imagePath': instance.imagePath,
      'thumbnailPath': instance.thumbnailPath,
      'mimeType': instance.mimeType,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'sortOrder': instance.sortOrder,
      'addedAt': instance.addedAt?.toIso8601String(),
      'addedBy': instance.addedBy,
    };

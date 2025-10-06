// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentItem _$ContentItemFromJson(Map<String, dynamic> json) => ContentItem(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      filePath: json['filePath'] as String?,
      type: $enumDecode(_$ContentTypeEnumMap, json['type']),
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      status: $enumDecode(_$ContentStatusEnumMap, json['status']),
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      approvedBy: json['approvedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      mimeType: json['mimeType'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );

Map<String, dynamic> _$ContentItemToJson(ContentItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'filePath': instance.filePath,
      'type': _$ContentTypeEnumMap[instance.type]!,
      'userId': instance.userId,
      'userName': instance.userName,
      'status': _$ContentStatusEnumMap[instance.status]!,
      'categories': instance.categories,
      'uploadedAt': instance.uploadedAt.toIso8601String(),
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'approvedBy': instance.approvedBy,
      'rejectionReason': instance.rejectionReason,
      'metadata': instance.metadata,
      'fileSize': instance.fileSize,
      'mimeType': instance.mimeType,
      'thumbnailPath': instance.thumbnailPath,
    };

const _$ContentTypeEnumMap = {
  ContentType.image: 'image',
  ContentType.video: 'video',
};

const _$ContentStatusEnumMap = {
  ContentStatus.pending: 'pending',
  ContentStatus.approved: 'approved',
  ContentStatus.rejected: 'rejected',
};

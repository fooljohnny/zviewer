// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      albumId: json['albumId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      parentId: json['parentId'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorAvatar': instance.authorAvatar,
      'albumId': instance.albumId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'parentId': instance.parentId,
      'likeCount': instance.likeCount,
      'isLiked': instance.isLiked,
    };

CreateCommentRequest _$CreateCommentRequestFromJson(
        Map<String, dynamic> json) =>
    CreateCommentRequest(
      content: json['content'] as String,
      albumId: json['albumId'] as String,
      parentId: json['parentId'] as String?,
    );

Map<String, dynamic> _$CreateCommentRequestToJson(
        CreateCommentRequest instance) =>
    <String, dynamic>{
      'content': instance.content,
      'albumId': instance.albumId,
      'parentId': instance.parentId,
    };

CommentResponse _$CommentResponseFromJson(Map<String, dynamic> json) =>
    CommentResponse(
      success: json['success'] as bool,
      message: json['message'] as String?,
      comment: json['comment'] == null
          ? null
          : Comment.fromJson(json['comment'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CommentResponseToJson(CommentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'comment': instance.comment,
      'comments': instance.comments,
    };

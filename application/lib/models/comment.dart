import 'package:json_annotation/json_annotation.dart';

part 'comment.g.dart';

/// 评论数据模型
@JsonSerializable()
class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String albumId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? parentId; // 用于回复功能
  final int likeCount;
  final bool isLiked;

  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.albumId,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.parentId,
    this.likeCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);

  Comment copyWith({
    String? id,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? albumId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? parentId,
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      albumId: albumId ?? this.albumId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Comment(id: $id, content: $content, author: $authorName)';

  // 计算属性
  bool get isReply => parentId != null;
  String get displayContent => isDeleted ? '该评论已被删除' : content;
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
}

/// 创建评论请求
@JsonSerializable()
class CreateCommentRequest {
  final String content;
  final String albumId;
  final String? parentId;

  const CreateCommentRequest({
    required this.content,
    required this.albumId,
    this.parentId,
  });

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateCommentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCommentRequestToJson(this);
}

/// 评论响应
@JsonSerializable()
class CommentResponse {
  final bool success;
  final String? message;
  final Comment? comment;
  final List<Comment>? comments;

  const CommentResponse({
    required this.success,
    this.message,
    this.comment,
    this.comments,
  });

  factory CommentResponse.fromJson(Map<String, dynamic> json) => 
      _$CommentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CommentResponseToJson(this);
}
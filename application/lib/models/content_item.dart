import 'package:json_annotation/json_annotation.dart';

part 'content_item.g.dart';

enum ContentType {
  @JsonValue('image')
  image,
  @JsonValue('video')
  video,
}

enum ContentStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
}

@JsonSerializable()
class ContentItem {
  final String? id;
  final String? title;
  final String? description;
  final String? filePath;
  final ContentType type;
  final String? userId;
  final String? userName;
  final ContentStatus status;
  final List<String>? categories;
  final DateTime uploadedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectionReason;
  final Map<String, dynamic>? metadata;
  final int? fileSize;
  final String? mimeType;
  final String? thumbnailPath;

  const ContentItem({
    this.id,
    this.title,
    this.description,
    this.filePath,
    required this.type,
    this.userId,
    this.userName,
    required this.status,
    this.categories,
    required this.uploadedAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectionReason,
    this.metadata,
    this.fileSize,
    this.mimeType,
    this.thumbnailPath,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    try {
      print('🔍 ContentItem.fromJson - Raw JSON: $json');
      print('🔍 ContentItem.fromJson - id type: ${json['id'].runtimeType}, value: ${json['id']}');
      print('🔍 ContentItem.fromJson - title type: ${json['title'].runtimeType}, value: ${json['title']}');
      print('🔍 ContentItem.fromJson - description type: ${json['description'].runtimeType}, value: ${json['description']}');
      print('🔍 ContentItem.fromJson - filePath type: ${json['filePath'].runtimeType}, value: ${json['filePath']}');
      print('🔍 ContentItem.fromJson - userId type: ${json['userId'].runtimeType}, value: ${json['userId']}');
      print('🔍 ContentItem.fromJson - userName type: ${json['userName'].runtimeType}, value: ${json['userName']}');
      print('🔍 ContentItem.fromJson - categories type: ${json['categories'].runtimeType}, value: ${json['categories']}');
      print('🔍 ContentItem.fromJson - metadata type: ${json['metadata'].runtimeType}, value: ${json['metadata']}');
      return _$ContentItemFromJson(json);
    } catch (e, stackTrace) {
      print('❌ ContentItem.fromJson ERROR: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() => _$ContentItemToJson(this);

  ContentItem copyWith({
    String? id,
    String? title,
    String? description,
    String? filePath,
    ContentType? type,
    String? userId,
    String? userName,
    ContentStatus? status,
    List<String>? categories,
    DateTime? uploadedAt,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectionReason,
    Map<String, dynamic>? metadata,
    int? fileSize,
    String? mimeType,
    String? thumbnailPath,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      status: status ?? this.status,
      categories: categories ?? this.categories,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      metadata: metadata ?? this.metadata,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentItem &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.filePath == filePath &&
        other.type == type &&
        other.userId == userId &&
        other.userName == userName &&
        other.status == status &&
        other.categories == categories &&
        other.uploadedAt == uploadedAt &&
        other.approvedAt == approvedAt &&
        other.approvedBy == approvedBy &&
        other.rejectionReason == rejectionReason &&
        other.metadata == metadata &&
        other.fileSize == fileSize &&
        other.mimeType == mimeType &&
        other.thumbnailPath == thumbnailPath;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      filePath,
      type,
      userId,
      userName,
      status,
      categories,
      uploadedAt,
      approvedAt,
      approvedBy,
      rejectionReason,
      metadata,
      fileSize,
      mimeType,
      thumbnailPath,
    );
  }

  @override
  String toString() {
    return 'ContentItem(id: $id, title: $title, type: $type, status: $status, userId: $userId)';
  }

  // Validation methods
  bool get isValid {
    return (id?.isNotEmpty ?? false) &&
        (title?.isNotEmpty ?? false) &&
        (description?.isNotEmpty ?? false) &&
        (filePath?.isNotEmpty ?? false) &&
        (userId?.isNotEmpty ?? false) &&
        (userName?.isNotEmpty ?? false) &&
        (categories?.isNotEmpty ?? false);
  }

  bool get isPending => status == ContentStatus.pending;
  bool get isApproved => status == ContentStatus.approved;
  bool get isRejected => status == ContentStatus.rejected;
  bool get isImage => type == ContentType.image;
  bool get isVideo => type == ContentType.video;
}

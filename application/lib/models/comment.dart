class Comment {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String mediaId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.mediaId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      content: json['content'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      mediaId: json['mediaId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'mediaId': mediaId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? content,
    String? authorId,
    String? authorName,
    String? mediaId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      mediaId: mediaId ?? this.mediaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.content == content &&
        other.authorId == authorId &&
        other.authorName == authorName &&
        other.mediaId == mediaId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      content,
      authorId,
      authorName,
      mediaId,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: $content, authorId: $authorId, authorName: $authorName, mediaId: $mediaId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  /// Validates comment content
  static String? validateContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return 'Comment cannot be empty';
    }
    if (content.trim().length < 3) {
      return 'Comment must be at least 3 characters long';
    }
    if (content.trim().length > 500) {
      return 'Comment must be less than 500 characters';
    }
    return null;
  }
}


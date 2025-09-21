import 'package:json_annotation/json_annotation.dart';

part 'admin_action.g.dart';

enum AdminActionType {
  @JsonValue('approve')
  approve,
  @JsonValue('reject')
  reject,
  @JsonValue('delete')
  delete,
  @JsonValue('categorize')
  categorize,
  @JsonValue('flag')
  flag,
  @JsonValue('unflag')
  unflag,
}

@JsonSerializable()
class AdminAction {
  final String id;
  final String adminId;
  final AdminActionType actionType;
  final String contentId;
  final String? reason;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AdminAction({
    required this.id,
    required this.adminId,
    required this.actionType,
    required this.contentId,
    this.reason,
    required this.timestamp,
    required this.metadata,
  });

  factory AdminAction.fromJson(Map<String, dynamic> json) =>
      _$AdminActionFromJson(json);

  Map<String, dynamic> toJson() => _$AdminActionToJson(this);

  AdminAction copyWith({
    String? id,
    String? adminId,
    AdminActionType? actionType,
    String? contentId,
    String? reason,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AdminAction(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      actionType: actionType ?? this.actionType,
      contentId: contentId ?? this.contentId,
      reason: reason ?? this.reason,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminAction &&
        other.id == id &&
        other.adminId == adminId &&
        other.actionType == actionType &&
        other.contentId == contentId &&
        other.reason == reason &&
        other.timestamp == timestamp &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      adminId,
      actionType,
      contentId,
      reason,
      timestamp,
      metadata,
    );
  }

  @override
  String toString() {
    return 'AdminAction(id: $id, actionType: $actionType, contentId: $contentId, timestamp: $timestamp)';
  }

  // Validation methods
  bool get isValid {
    return id.isNotEmpty &&
        adminId.isNotEmpty &&
        contentId.isNotEmpty &&
        metadata.isNotEmpty;
  }

  // Helper methods
  String get actionDisplayName {
    switch (actionType) {
      case AdminActionType.approve:
        return 'Approved';
      case AdminActionType.reject:
        return 'Rejected';
      case AdminActionType.delete:
        return 'Deleted';
      case AdminActionType.categorize:
        return 'Categorized';
      case AdminActionType.flag:
        return 'Flagged';
      case AdminActionType.unflag:
        return 'Unflagged';
    }
  }

  String get actionDescription {
    final baseDescription = actionDisplayName;
    if (reason != null && reason!.isNotEmpty) {
      return '$baseDescription: $reason';
    }
    return baseDescription;
  }

  bool get requiresReason {
    return actionType == AdminActionType.reject ||
        actionType == AdminActionType.delete ||
        actionType == AdminActionType.flag;
  }

  // Factory methods for common actions
  factory AdminAction.approve({
    required String id,
    required String adminId,
    required String contentId,
    Map<String, dynamic>? metadata,
  }) {
    return AdminAction(
      id: id,
      adminId: adminId,
      actionType: AdminActionType.approve,
      contentId: contentId,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  factory AdminAction.reject({
    required String id,
    required String adminId,
    required String contentId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return AdminAction(
      id: id,
      adminId: adminId,
      actionType: AdminActionType.reject,
      contentId: contentId,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  factory AdminAction.delete({
    required String id,
    required String adminId,
    required String contentId,
    required String reason,
    Map<String, dynamic>? metadata,
  }) {
    return AdminAction(
      id: id,
      adminId: adminId,
      actionType: AdminActionType.delete,
      contentId: contentId,
      reason: reason,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  factory AdminAction.categorize({
    required String id,
    required String adminId,
    required String contentId,
    required List<String> categories,
    Map<String, dynamic>? metadata,
  }) {
    return AdminAction(
      id: id,
      adminId: adminId,
      actionType: AdminActionType.categorize,
      contentId: contentId,
      timestamp: DateTime.now(),
      metadata: {
        ...metadata ?? {},
        'categories': categories,
      },
    );
  }
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminAction _$AdminActionFromJson(Map<String, dynamic> json) => AdminAction(
      id: json['id'] as String,
      adminId: json['adminId'] as String,
      actionType: $enumDecode(_$AdminActionTypeEnumMap, json['actionType']),
      contentId: json['contentId'] as String,
      reason: json['reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$AdminActionToJson(AdminAction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'adminId': instance.adminId,
      'actionType': _$AdminActionTypeEnumMap[instance.actionType]!,
      'contentId': instance.contentId,
      'reason': instance.reason,
      'timestamp': instance.timestamp.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$AdminActionTypeEnumMap = {
  AdminActionType.approve: 'approve',
  AdminActionType.reject: 'reject',
  AdminActionType.delete: 'delete',
  AdminActionType.categorize: 'categorize',
  AdminActionType.flag: 'flag',
  AdminActionType.unflag: 'unflag',
};

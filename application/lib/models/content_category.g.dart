// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentCategory _$ContentCategoryFromJson(Map<String, dynamic> json) =>
    ContentCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$ContentCategoryToJson(ContentCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'color': instance.color,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
    };

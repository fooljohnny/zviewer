import 'package:json_annotation/json_annotation.dart';

part 'content_category.g.dart';

@JsonSerializable()
class ContentCategory {
  final String id;
  final String name;
  final String description;
  final String color;
  final DateTime createdAt;
  final bool isActive;

  const ContentCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.isActive,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) =>
      _$ContentCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ContentCategoryToJson(this);

  ContentCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ContentCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContentCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.color == color &&
        other.createdAt == createdAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      color,
      createdAt,
      isActive,
    );
  }

  @override
  String toString() {
    return 'ContentCategory(id: $id, name: $name, isActive: $isActive)';
  }

  // Validation methods
  bool get isValid {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        description.isNotEmpty &&
        color.isNotEmpty &&
        _isValidColor(color);
  }

  bool _isValidColor(String color) {
    // Check if color is a valid hex color (with or without #)
    final hexPattern = RegExp(r'^#?[0-9A-Fa-f]{6}$');
    return hexPattern.hasMatch(color);
  }

  // Helper methods
  String get displayColor {
    // Ensure color has # prefix
    return color.startsWith('#') ? color : '#$color';
  }

  String get shortDescription {
    if (description.length <= 50) return description;
    return '${description.substring(0, 47)}...';
  }
}

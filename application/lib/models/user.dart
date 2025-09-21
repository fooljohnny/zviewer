import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('admin')
  admin,
  @JsonValue('moderator')
  moderator,
}

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.user,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.role == role &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, displayName, role, createdAt, lastLoginAt);
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, role: $role, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }

  // Helper methods
  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator || role == UserRole.admin;
  bool get isUser => role == UserRole.user;
}

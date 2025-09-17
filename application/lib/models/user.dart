class User {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, displayName, createdAt, lastLoginAt);
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, createdAt: $createdAt, lastLoginAt: $lastLoginAt)';
  }
}

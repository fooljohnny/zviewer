import 'user.dart';

class AuthResponse {
  final String token;
  final User user;
  final DateTime expiresAt;

  const AuthResponse({
    required this.token,
    required this.user,
    required this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResponse &&
        other.token == token &&
        other.user == user &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return Object.hash(token, user, expiresAt);
  }

  @override
  String toString() {
    return 'AuthResponse(token: $token, user: $user, expiresAt: $expiresAt)';
  }
}

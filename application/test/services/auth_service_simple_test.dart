import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/services/auth_service.dart';
import 'package:zviewer/models/user.dart';

void main() {
  group('AuthService', () {

    group('AuthException', () {
      test('should create AuthException with message', () {
        // Arrange
        const message = 'Test error message';

        // Act
        const exception = AuthException(message);

        // Assert
        expect(exception.message, equals(message));
        expect(exception.toString(), equals('AuthException: $message'));
      });
    });

    group('User model', () {
      test('should create User from JSON', () {
        // Arrange
        final json = {
          'id': '1',
          'email': 'test@example.com',
          'displayName': 'Test User',
          'createdAt': '2024-01-01T00:00:00Z',
          'lastLoginAt': '2024-01-01T00:00:00Z',
        };

        // Act
        final user = User.fromJson(json);

        // Assert
        expect(user.id, equals('1'));
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test User'));
        expect(user.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
        expect(user.lastLoginAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should convert User to JSON', () {
        // Arrange
        final user = User(
          id: '1',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime(2024, 1, 1),
          lastLoginAt: DateTime(2024, 1, 1),
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['id'], equals('1'));
        expect(json['email'], equals('test@example.com'));
        expect(json['displayName'], equals('Test User'));
        expect(json['createdAt'], equals('2024-01-01T00:00:00.000'));
        expect(json['lastLoginAt'], equals('2024-01-01T00:00:00.000'));
      });
    });
  });
}

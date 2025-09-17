import 'package:flutter_test/flutter_test.dart';
import 'package:zviewer/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(authProvider.user, isNull);
        expect(authProvider.isLoading, isFalse);
        expect(authProvider.error, isNull);
        expect(authProvider.isAuthenticated, isFalse);
        expect(authProvider.isInitialized, isFalse);
      });
    });

    group('clearError', () {
      test('should clear error message', () {
        // Act
        authProvider.clearError();

        // Assert
        expect(authProvider.error, isNull);
      });
    });
  });
}

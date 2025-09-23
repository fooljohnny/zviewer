import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../config/api_config.dart';

class AuthService {
  static String get _baseUrl => ApiConfig.authUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Login with email and password
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // Register new user
  Future<AuthResponse> register(String email, String password, String confirmPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
        await _storeAuthData(authResponse);
        return authResponse;
      } else {
        final errorData = jsonDecode(response.body);
        throw AuthException(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Network error: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) {
        await http.post(
          Uri.parse('$_baseUrl/api/auth/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      // Log error but don't throw - we still want to clear local data
      // Log error but don't throw - we still want to clear local data
      // print('Logout API call failed: $e');
    } finally {
      await _clearAuthData();
    }
  }

  // Get current user profile
  Future<User?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        return User.fromJson(userData);
      } else {
        // Token might be invalid, clear stored data
        await _clearAuthData();
        return null;
      }
    } catch (e) {
      // print('Get current user failed: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return false;

    // Check if token is still valid by making a simple API call
    try {
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Store authentication data securely
  Future<void> _storeAuthData(AuthResponse authResponse) async {
    await _storage.write(key: _tokenKey, value: authResponse.token);
    await _storage.write(key: _userKey, value: jsonEncode(authResponse.user.toJson()));
  }

  // Clear stored authentication data
  Future<void> _clearAuthData() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Get stored user data
  Future<User?> getStoredUser() async {
    try {
      final userData = await _storage.read(key: _userKey);
      if (userData != null) {
        return User.fromJson(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      // print('Failed to get stored user: $e');
      return null;
    }
  }
}

// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

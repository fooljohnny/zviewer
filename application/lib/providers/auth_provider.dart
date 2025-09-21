import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isModerator => _user?.isModerator ?? false;

  // Initialize authentication state
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _setLoading(true);
    try {
      final user = await _authService.getStoredUser();
      if (user != null) {
        // Verify token is still valid
        final isValid = await _authService.isAuthenticated();
        if (isValid) {
          _user = user;
        } else {
          // Token is invalid, clear stored data
          await _authService.logout();
        }
      }
    } catch (e) {
      _setError('Failed to initialize authentication: ${e.toString()}');
    } finally {
      _setLoading(false);
      _isInitialized = true;
    }
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authResponse = await _authService.login(email, password);
      _user = authResponse.user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register new user
  Future<bool> register(String email, String password, String confirmPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authResponse = await _authService.register(email, password, confirmPassword);
      _user = authResponse.user;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.logout();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;
    
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      } else {
        // User session expired
        await logout();
      }
    } catch (e) {
      _setError('Failed to refresh user data: ${e.toString()}');
    }
  }

  // Clear error
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

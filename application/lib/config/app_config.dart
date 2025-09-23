import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static Map<String, dynamic>? _config;
  
  // Initialize configuration from JSON file
  static Future<void> initialize() async {
    if (_config != null) return;
    
    try {
      final String configString = await rootBundle.loadString('assets/config/app_config.json');
      _config = json.decode(configString);
    } catch (e) {
      // Fallback to default configuration
      _config = {
        'environment': 'development',
        'api': {
          'development': {
            'baseUrl': 'http://localhost:8080',
            'timeout': 30000,
            'retryAttempts': 3
          },
          'production': {
            'baseUrl': 'https://api.zviewer.com',
            'timeout': 30000,
            'retryAttempts': 3
          }
        },
        'app': {
          'name': 'ZViewer',
          'version': '1.0.0',
          'debug': true
        }
      };
    }
  }
  
  // Environment detection
  static bool get _isDevelopment => _config?['environment'] == 'development';
  
  // API Configuration
  static String get _devBaseUrl => _config?['api']?['development']?['baseUrl'] ?? 'http://localhost:8080';
  static String get _prodBaseUrl => _config?['api']?['production']?['baseUrl'] ?? 'https://api.zviewer.com';
  
  // Get the appropriate base URL based on environment
  static String get baseUrl => _isDevelopment ? _devBaseUrl : _prodBaseUrl;
  
  // API endpoints
  static String get authUrl => '$baseUrl/api/auth';
  static String get commentsUrl => '$baseUrl/api/comments';
  static String get paymentsUrl => '$baseUrl/api/payments';
  static String get adminUrl => '$baseUrl/api/admin';
  static String get healthUrl => '$baseUrl/health';
  
  // App Configuration
  static const String appName = 'ZViewer';
  static const String appVersion = '1.0.0';
  
  // Debug Configuration
  static bool get enableDebugLogs => _isDevelopment;
  static bool get enableNetworkLogs => _isDevelopment;
  
  // Timeout Configuration
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 15);
  
  // Storage Configuration
  static const String tokenStorageKey = 'auth_token';
  static const String userStorageKey = 'user_data';
  static const String settingsStorageKey = 'app_settings';
  
  // Debug information
  static void printConfig() {
    if (enableDebugLogs) {
      print('=== ZViewer Configuration ===');
      print('Environment: ${_isDevelopment ? "Development" : "Production"}');
      print('Base URL: $baseUrl');
      print('Auth URL: $authUrl');
      print('Comments URL: $commentsUrl');
      print('Payments URL: $paymentsUrl');
      print('Admin URL: $adminUrl');
      print('Health URL: $healthUrl');
      print('Debug Logs: $enableDebugLogs');
      print('Network Logs: $enableNetworkLogs');
      print('============================');
    }
  }
  
  // Check if running in development mode
  static bool get isDevelopment => _isDevelopment;
  static bool get isProduction => !_isDevelopment;
  
  // Platform specific configuration
  static bool get isWindows => Platform.isWindows;
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWeb => Platform.isWindows && Platform.environment.containsKey('FLUTTER_WEB');
}

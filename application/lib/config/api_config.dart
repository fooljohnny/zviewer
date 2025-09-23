import 'app_config.dart';

class ApiConfig {
  // Get the appropriate base URL based on environment
  static String get baseUrl => AppConfig.baseUrl;
  
  // API endpoints
  static String get authUrl => AppConfig.authUrl;
  static String get commentsUrl => AppConfig.commentsUrl;
  static String get paymentsUrl => AppConfig.paymentsUrl;
  static String get adminUrl => AppConfig.adminUrl;
  static String get healthUrl => AppConfig.healthUrl;
  
  // Debug information
  static void printConfig() {
    AppConfig.printConfig();
  }
}

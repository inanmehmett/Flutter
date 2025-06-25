class AppConfig {
  static const String baseURL =
      'https://api.example.com'; // Replace with your actual API URL
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheTimeout = Duration(hours: 1);
  static const int maxRequestsPerMinute = 60;
  static const String appName = 'Daily English';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const bool isDebug = true;
  static const String apiBaseUrl = 'http://192.168.1.100:5173';
  static const String apiVersion = ''; // Remove version from path
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}

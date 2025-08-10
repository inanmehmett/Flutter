import 'package:flutter/foundation.dart';

class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001',
  );
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheTimeout = Duration(hours: 1);
  static const int maxRequestsPerMinute = 60;
  static const String appName = 'Daily English';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const bool isDebug = kDebugMode; // Sadece debug modda true
  static const String apiVersion = '';
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Google Sign-In iOS Client ID (update with your actual iOS OAuth client ID)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '847755051165-9iqsq2hihodb9ol5md50glur83p60qni.apps.googleusercontent.com',
  );

  // Google Sign-In Web Client ID (used as serverClientId on Android to obtain idToken)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '847755051165-9iqsq2hihodb9ol5md50glur83p60qni.apps.googleusercontent.com',
  );
}

import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'local_config.dart';

class AppConfig {
  // Centralized API base URL resolution
  // Priority:
  // 1) --dart-define API_BASE_URL (CI/production or manual override)
  // 2) Platform defaults (web uses same origin; iOS simulator 127.0.0.1; Android emulator 10.0.2.2)
  // 3) LocalConfig.lanBaseUrl for physical devices or when defaults fail
  static String get apiBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      return 'http://localhost:5001';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // Prefer LAN for physical device; simulator will still work with LAN
        return LocalConfig.lanBaseUrl;
      case TargetPlatform.android:
        // Android emulator host loopback
        return 'http://10.0.2.2:5001';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:5001';
      default:
        return LocalConfig.lanBaseUrl;
    }
  }
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

  // Google Sign-In iOS Client ID (must match the reversed scheme in iOS Info.plist)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '847755051165-dai44916j8q7aoa0idlbibib04n4tff5.apps.googleusercontent.com',
  );

  // Google Sign-In Web Client ID (used as serverClientId on Android to obtain idToken)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '847755051165-dai44916j8q7aoa0idlbibib04n4tff5.apps.googleusercontent.com',
  );
}

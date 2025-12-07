import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../network/api_client.dart';
import '../utils/logger.dart';
import '../config/app_config.dart';
import 'package:flutter/foundation.dart';

/// Enhanced crash tracking service with grouping, prioritization, and breadcrumbs
/// 
/// Features:
/// - Crash grouping (similar crashes grouped together)
/// - Priority levels (fatal, high, medium, low)
/// - Breadcrumbs (user actions before crash)
/// - Device and user context
/// - Debouncing to prevent spam
@lazySingleton
class CrashTrackingService {
  final ApiClient _api;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  PackageInfo? _packageInfo;
  String? _userId;
  Map<String, String> _customKeys = {};
  
  // Breadcrumbs: Track user actions before crash
  final List<Map<String, dynamic>> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 30;
  
  // Debouncing for non-fatal errors to prevent excessive API calls
  final Map<String, DateTime> _lastErrorTime = {};

  CrashTrackingService(this._api) {
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      Logger.warning('Failed to get package info: $e');
    }
  }

  /// Set user identifier for crash reports
  void setUserIdentifier(String? userId) {
    _userId = userId;
    if (userId != null) {
      _customKeys['user_id'] = userId;
    } else {
      _customKeys.remove('user_id');
    }
  }

  /// Set custom key for crash reports
  void setCustomKey(String key, String value) {
    _customKeys[key] = value;
  }

  /// Clear custom key
  void clearCustomKey(String key) {
    _customKeys.remove(key);
  }

  /// Clear all custom keys
  void clearAllCustomKeys() {
    _customKeys.clear();
  }

  /// Add breadcrumb (user action before crash)
  /// Useful for debugging - shows what user was doing before crash
  void addBreadcrumb(String message, {Map<String, dynamic>? data}) {
    _breadcrumbs.add({
      'message': message,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      if (data != null) 'data': data,
    });

    // Keep only last N breadcrumbs
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Clear breadcrumbs
  void clearBreadcrumbs() {
    _breadcrumbs.clear();
  }

  /// Record a Flutter error
  Future<void> recordFlutterError(
    FlutterErrorDetails errorDetails, {
    bool fatal = false,
  }) async {
    try {
      // For fatal errors, always send immediately
      // For non-fatal errors, debounce to prevent spam
      if (!fatal) {
        final errorKey = _getErrorKey(
          errorDetails.exceptionAsString(),
          'FlutterError',
        );
        final now = DateTime.now();
        final lastSent = _lastErrorTime[errorKey];
        
        if (lastSent != null && now.difference(lastSent) < AppConfig.crashReportDebounce) {
          // Skip - same error was sent recently
          if (kDebugMode) {
            print('⚠️ [CrashTracking] Skipping duplicate error report (debounced)');
          }
          return;
        }
        
        _lastErrorTime[errorKey] = now;
      }
      
      await _sendCrashReport(
        errorMessage: errorDetails.exceptionAsString(),
        stackTrace: errorDetails.stack?.toString(),
        errorType: 'FlutterError',
        isFatal: fatal,
        priority: fatal ? 'fatal' : 'high',
      );
    } catch (e) {
      // Don't log - we don't want crash reporting to crash the app
      if (kDebugMode) {
        print('⚠️ Failed to send crash report: $e');
      }
    }
  }

  /// Record a platform error (non-Flutter errors)
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    try {
      // For fatal errors, always send immediately
      // For non-fatal errors, debounce to prevent spam
      if (!fatal) {
        final errorKey = _getErrorKey(error.toString(), 'PlatformError');
        final now = DateTime.now();
        final lastSent = _lastErrorTime[errorKey];
        
        if (lastSent != null && now.difference(lastSent) < AppConfig.crashReportDebounce) {
          // Skip - same error was sent recently
          if (kDebugMode) {
            print('⚠️ [CrashTracking] Skipping duplicate error report (debounced)');
          }
          return;
        }
        
        _lastErrorTime[errorKey] = now;
      }
      
      await _sendCrashReport(
        errorMessage: error.toString(),
        stackTrace: stackTrace?.toString(),
        errorType: 'PlatformError',
        isFatal: fatal,
        priority: fatal ? 'fatal' : 'medium',
      );
    } catch (e) {
      // Don't log - we don't want crash reporting to crash the app
      if (kDebugMode) {
        print('⚠️ Failed to send crash report: $e');
      }
    }
  }
  
  /// Generate a unique key for an error to track duplicates
  String _getErrorKey(String errorMessage, String errorType) {
    // Use first 100 characters of error message + error type as key
    final messageHash = errorMessage.length > 100 
        ? errorMessage.substring(0, 100) 
        : errorMessage;
    return '$errorType:${messageHash.hashCode}';
  }

  /// Record a non-fatal error with custom priority
  Future<void> recordNonFatalError(
    String errorMessage, {
    StackTrace? stackTrace,
    String priority = 'low',
    Map<String, dynamic>? context,
  }) async {
    try {
      // Add context as custom keys before sending
      if (context != null) {
        context.forEach((key, value) {
          setCustomKey(key, value.toString());
        });
      }
      
      // Debounce check for non-fatal errors
      final errorKey = _getErrorKey(errorMessage, 'NonFatalError');
      final now = DateTime.now();
      final lastSent = _lastErrorTime[errorKey];
      
      if (lastSent != null && now.difference(lastSent) < AppConfig.crashReportDebounce) {
        // Skip - same error was sent recently
        if (kDebugMode) {
          print('⚠️ [CrashTracking] Skipping duplicate error report (debounced)');
        }
        return;
      }
      
      _lastErrorTime[errorKey] = now;
      
      // Send with custom priority
      await _sendCrashReport(
        errorMessage: errorMessage,
        stackTrace: stackTrace?.toString(),
        errorType: 'NonFatalError',
        isFatal: false,
        priority: priority,
      );
    } catch (e) {
      // Don't log - we don't want crash reporting to crash the app
      if (kDebugMode) {
        print('⚠️ Failed to send non-fatal error report: $e');
      }
    }
  }

  /// Send crash report to backend
  Future<void> _sendCrashReport({
    required String errorMessage,
    String? stackTrace,
    required String errorType,
    required bool isFatal,
    required String priority,
  }) async {
    try {
      // Get device info
      String? devicePlatform;
      String? deviceModel;
      String? osVersion;

      try {
        if (Platform.isAndroid) {
          devicePlatform = 'android';
          final androidInfo = await _deviceInfo.androidInfo;
          deviceModel = androidInfo.model;
          osVersion = 'Android ${androidInfo.version.release}';
        } else if (Platform.isIOS) {
          devicePlatform = 'ios';
          final iosInfo = await _deviceInfo.iosInfo;
          deviceModel = iosInfo.model;
          osVersion = 'iOS ${iosInfo.systemVersion}';
        }
      } catch (e) {
        // Ignore device info errors
      }

      final request = {
        'errorMessage': errorMessage,
        if (stackTrace != null) 'stackTrace': stackTrace,
        'errorType': errorType,
        'isFatal': isFatal,
        'priority': priority,
        'occurredAt': DateTime.now().toUtc().toIso8601String(),
        if (devicePlatform != null) 'devicePlatform': devicePlatform,
        if (_packageInfo != null) 'appVersion': _packageInfo!.version,
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (osVersion != null) 'osVersion': osVersion,
        if (_customKeys.isNotEmpty) 'context': _customKeys,
        if (_breadcrumbs.isNotEmpty) 'breadcrumbs': _breadcrumbs,
      };

      // Try to send crash report (don't wait for response in fatal cases)
      if (isFatal) {
        // For fatal crashes, send asynchronously without waiting
        _api.post('/api/crash', data: request).catchError((e) {
          // Ignore errors - app is crashing anyway
          return null;
        });
      } else {
        // For non-fatal errors, try to send but don't block
        _api.post('/api/crash', data: request).catchError((e) {
          // Ignore errors - analytics must not break UX
          return null;
        });
      }
    } catch (e) {
      // Don't throw - we don't want crash reporting to crash the app
      if (kDebugMode) {
        print('⚠️ Failed to prepare crash report: $e');
      }
    }
  }
}




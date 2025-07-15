import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class Logger {
  static void debug(String message) {
    if (AppConfig.isDebug) {
      print('🐛 [DEBUG] $message');
    }
  }

  static void info(String message) {
    if (AppConfig.isDebug) {
      print('ℹ️ [INFO] $message');
    }
  }

  static void warning(String message) {
    if (AppConfig.isDebug) {
      print('⚠️ [WARNING] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (AppConfig.isDebug) {
      print('❌ [ERROR] $message');
      if (error != null) {
        print('❌ [ERROR] Details: $error');
      }
      if (stackTrace != null) {
        print('❌ [ERROR] Stack trace: $stackTrace');
      }
    }
  }

  static void network(String message) {
    if (AppConfig.isDebug) {
      print('🌐 [NETWORK] $message');
    }
  }

  static void auth(String message) {
    if (AppConfig.isDebug) {
      print('🔐 [AUTH] $message');
    }
  }

  static void book(String message) {
    if (AppConfig.isDebug) {
      print('📚 [BOOK] $message');
    }
  }

  static void cache(String message) {
    if (AppConfig.isDebug) {
      print('💾 [CACHE] $message');
    }
  }
} 
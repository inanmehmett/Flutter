import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';

/// Rate limiting configuration for different endpoint categories
class RateLimitConfig {
  final int maxRequestsPerMinute;
  final Duration windowDuration;

  const RateLimitConfig({
    required this.maxRequestsPerMinute,
    this.windowDuration = const Duration(minutes: 1),
  });

  // Predefined configurations for different endpoint types
  static const RateLimitConfig study = RateLimitConfig(maxRequestsPerMinute: 120); // Quiz, vocabulary, reading
  static const RateLimitConfig user = RateLimitConfig(maxRequestsPerMinute: 100); // Profile, user data (increased from 60)
  static const RateLimitConfig auth = RateLimitConfig(maxRequestsPerMinute: 10); // Login, registration
  static const RateLimitConfig reading = RateLimitConfig(maxRequestsPerMinute: 80); // Reading texts, pages
  static const RateLimitConfig userinfo = RateLimitConfig(maxRequestsPerMinute: 30); // OpenIddict userinfo (frequent but should be limited)
  static const RateLimitConfig defaultConfig = RateLimitConfig(maxRequestsPerMinute: 80); // Default for other endpoints
}

/// Rate limiting interceptor to prevent excessive API requests
/// Implements client-side rate limiting to complement server-side limits
/// Uses endpoint-specific limits based on usage patterns
class RateLimitInterceptor extends Interceptor {
  final Map<String, List<DateTime>> _requestHistory = {};
  final RateLimitConfig defaultConfig;

  RateLimitInterceptor({
    RateLimitConfig? defaultConfig,
  }) : defaultConfig = defaultConfig ?? RateLimitConfig.defaultConfig;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Skip rate limiting for certain endpoints
    if (_shouldSkipRateLimit(options.path)) {
      handler.next(options);
      return;
    }

    // Get endpoint-specific rate limit configuration
    final config = _getRateLimitConfig(options.path);
    final key = _getRateLimitKey(options);
    final now = DateTime.now();

    // Clean old requests outside the window
    _cleanOldRequests(key, now, config.windowDuration);

    // Check if limit exceeded
    final requests = _requestHistory[key] ?? [];
    if (requests.length >= config.maxRequestsPerMinute) {
      final oldestRequest = requests.first;
      final waitTime = config.windowDuration - now.difference(oldestRequest);
      
      if (waitTime.inMilliseconds > 0) {
        Logger.warning('Request rate limit exceeded for ${options.path}. Limit: ${config.maxRequestsPerMinute}/min. Waiting ${waitTime.inSeconds}s...');
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Rate limit exceeded. Please wait ${waitTime.inSeconds} seconds.',
            type: DioExceptionType.connectionTimeout,
          ),
        );
      }
    }

    // Record this request
    requests.add(now);
    _requestHistory[key] = requests;

    handler.next(options);
  }

  /// Get rate limit configuration based on endpoint path
  RateLimitConfig _getRateLimitConfig(String path) {
    // OpenIddict userinfo endpoint - frequently called but should be limited
    // This endpoint is called by auth interceptor and various auth checks
    if (path.contains('/connect/userinfo')) {
      return RateLimitConfig.userinfo;
    }

    // Study endpoints: Quiz, vocabulary, flashcards
    if (path.contains('/api/quiz') ||
        path.contains('/api/ApiUserVocabulary') ||
        path.contains('/vocabulary') ||
        path.contains('/flashcard') ||
        path.contains('/review') ||
        path.contains('/session')) {
      return RateLimitConfig.study;
    }

    // Reading endpoints: Reading texts, pages, progress
    if (path.contains('/api/reading') ||
        path.contains('/api/books') ||
        path.contains('/api/reading-texts') ||
        path.contains('/reading-quiz')) {
      return RateLimitConfig.reading;
    }

    // Auth endpoints: Login, registration, token refresh
    // Note: /connect/token is for token refresh, should be limited
    if (path.contains('/connect/token') ||
        path.contains('/api/authentication') ||
        path.contains('/api/auth') ||
        path.contains('/register') ||
        path.contains('/login')) {
      return RateLimitConfig.auth;
    }

    // User endpoints: Profile, settings, progress stats
    // Includes UserProfile/GetProfileData and similar endpoints
    if (path.contains('/api/me') ||
        path.contains('/api/user') ||
        path.contains('/api/ApiProgressStats') ||
        path.contains('/api/ApiUser') ||
        path.contains('/UserProfile') ||
        path.contains('/api/ApiUserProfile')) {
      return RateLimitConfig.user;
    }

    // Default for other endpoints
    return defaultConfig;
  }

  String _getRateLimitKey(RequestOptions options) {
    // Use endpoint path as key
    // For authenticated requests, you might want to include user ID in the future
    return options.path;
  }

  bool _shouldSkipRateLimit(String path) {
    // Skip rate limiting for health checks, static files, crash reporting, analytics events, etc.
    // Crash reporting and analytics events are critical and should not be rate limited on client side
    // Backend handles rate limiting for these endpoints
    return path.contains('/health') ||
           path.contains('/swagger') ||
           path.contains('wwwroot') ||
           path.contains('/api/crash') ||
           path.contains('/api/events');
  }

  void _cleanOldRequests(String key, DateTime now, Duration windowDuration) {
    final requests = _requestHistory[key];
    if (requests == null) return;

    // Remove requests older than the window
    _requestHistory[key] = requests
        .where((timestamp) => now.difference(timestamp) < windowDuration)
        .toList();
  }

  void clearHistory() {
    _requestHistory.clear();
  }
}


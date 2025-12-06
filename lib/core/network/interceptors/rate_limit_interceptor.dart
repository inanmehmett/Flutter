import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../../utils/logger.dart';

/// Rate limiting interceptor to prevent excessive API requests
/// Implements client-side rate limiting to complement server-side limits
class RateLimitInterceptor extends Interceptor {
  final Map<String, List<DateTime>> _requestHistory = {};
  final int maxRequestsPerMinute;
  final Duration windowDuration;

  RateLimitInterceptor({
    this.maxRequestsPerMinute = 60, // Default: 60 requests per minute
    this.windowDuration = const Duration(minutes: 1),
  });

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

    final key = _getRateLimitKey(options);
    final now = DateTime.now();

    // Clean old requests outside the window
    _cleanOldRequests(key, now);

    // Check if limit exceeded
    final requests = _requestHistory[key] ?? [];
    if (requests.length >= maxRequestsPerMinute) {
      final oldestRequest = requests.first;
      final waitTime = windowDuration - now.difference(oldestRequest);
      
      if (waitTime.inMilliseconds > 0) {
        Logger.warning('Request rate limit exceeded for $key. Waiting ${waitTime.inSeconds}s...');
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

  String _getRateLimitKey(RequestOptions options) {
    // Use endpoint path as key (you can customize this)
    // For authenticated requests, you might want to include user ID
    return options.path;
  }

  bool _shouldSkipRateLimit(String path) {
    // Skip rate limiting for health checks, static files, crash reporting, etc.
    // Crash reporting is critical and should not be rate limited on client side
    return path.contains('/health') ||
           path.contains('/swagger') ||
           path.contains('wwwroot') ||
           path.contains('/api/crash');
  }

  void _cleanOldRequests(String key, DateTime now) {
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


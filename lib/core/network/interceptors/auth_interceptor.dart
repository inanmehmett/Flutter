import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

/// Interceptor for handling authentication tokens and automatic token refresh
class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  static const bool _debugMode = false; // Set to true for debug logging
  
  // Token refresh state to prevent infinite loops
  DateTime? _lastRefreshAttempt;
  static const Duration _refreshCooldown = Duration(seconds: 5);

  AuthInterceptor(this._secureStorage);

  void _debugPrint(String message) {
    if (_debugMode) {
      // ignore: avoid_print
      print('🔐 [AuthInterceptor] $message');
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    _debugPrint('Request: ${options.method} ${options.path}');

    // Set correct content type for token endpoint
    if (options.path.contains('/connect/token')) {
      options.contentType = Headers.formUrlEncodedContentType;
    }

    // Check if this is a request that doesn't need a token
    final isPublicRequest = options.path.contains('/connect/token') ||
        options.path.contains('/connect/register') ||
        options.path.contains('/connect/logout');
    
    // Always attach client timezone offset so backend can compute local day boundary for streak
    try {
      final tzOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      options.headers['X-Client-TZ-Offset'] = tzOffsetMinutes.toString();
    } catch (_) {}

    // Attach token for authenticated requests
    if (!isPublicRequest) {
      try {
        final token = await _secureStorage.getAccessToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          _debugPrint('✅ Authorization header added');
        }
      } catch (e) {
        _debugPrint('❌ Error getting token: $e');
      }
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _debugPrint('Response: ${response.statusCode} ${response.requestOptions.path}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    
    _debugPrint('Error: $statusCode ${err.requestOptions.method} $path');

    // Handle 401 Unauthorized - attempt token refresh
    if (statusCode == 401 && !path.contains('/connect/token')) {
      // Prevent infinite loops: don't refresh if we just tried recently
      final now = DateTime.now();
      if (_lastRefreshAttempt != null && 
          now.difference(_lastRefreshAttempt!) < _refreshCooldown) {
        _debugPrint('⚠️ Refresh cooldown active, skipping refresh');
        await _clearTokensIfNeeded();
        handler.next(err);
        return;
      }

      // Check if this request already attempted refresh (prevent retry loops)
      final retryCount = err.requestOptions.extra['_refreshRetryCount'] as int? ?? 0;
      if (retryCount > 0) {
        _debugPrint('⚠️ Request already attempted refresh, skipping');
        await _clearTokensIfNeeded();
        handler.next(err);
        return;
      }

      try {
        _lastRefreshAttempt = now;
        final refreshToken = await _secureStorage.getRefreshToken();

        if (refreshToken == null || refreshToken.isEmpty) {
          _debugPrint('❌ No refresh token available');
          await _clearTokensIfNeeded();
          handler.next(err);
          return;
        }

        _debugPrint('🔄 Attempting token refresh...');

        // Use a fresh Dio instance for token refresh (no interceptors)
        final refreshDio = Dio(BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          headers: {'Content-Type': Headers.formUrlEncodedContentType},
        ));

        final refreshResponse = await refreshDio.post(
          '/connect/token',
          data: {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          },
        );

        if (refreshResponse.statusCode == 200) {
          final data = refreshResponse.data is Map<String, dynamic>
            ? refreshResponse.data as Map<String, dynamic>
            : <String, dynamic>{};
          
          final newAccessToken = data['access_token'] ?? data['accessToken'];
          final newRefreshToken = data['refresh_token'] ?? data['refreshToken'];
          final expiresIn = data['expires_in'] ?? 3600;

          if (newAccessToken != null && 
              newRefreshToken != null && 
              newAccessToken is String && 
              newRefreshToken is String) {
            await _secureStorage.saveTokens(
              accessToken: newAccessToken,
              refreshToken: newRefreshToken,
              expiresIn: expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 3600,
            );
            _debugPrint('✅ Token refreshed successfully');

            // Retry original request with new token
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            err.requestOptions.extra['_refreshRetryCount'] = retryCount + 1;

            try {
              final dio = err.requestOptions.extra['dio'] as Dio?;
              if (dio != null) {
                _debugPrint('🔄 Retrying original request...');
                final retryResponse = await dio.fetch(err.requestOptions);
                handler.resolve(retryResponse);
                return;
              }
            } catch (retryError) {
              _debugPrint('❌ Retry failed: $retryError');
              // Continue to error propagation
            }
          }
        }

        // Refresh failed - clear tokens
        _debugPrint('❌ Token refresh failed (status: ${refreshResponse.statusCode})');
        await _clearTokensIfNeeded();
      } catch (refreshError) {
        _debugPrint('❌ Token refresh error: $refreshError');
        await _clearTokensIfNeeded();
      }

      // Propagate original error
      handler.next(err);
      return;
    }

    // For all other errors, just propagate
    handler.next(err);
  }

  /// Clear tokens if needed (silent failure)
  Future<void> _clearTokensIfNeeded() async {
    try {
      await _secureStorage.clearTokens();
      _debugPrint('✅ Tokens cleared');
    } catch (e) {
      _debugPrint('⚠️ Error clearing tokens: $e');
    }
  }
}
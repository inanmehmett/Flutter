import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage) {
    print('🔐 [AuthInterceptor] ===== INITIALIZATION =====');
    print('🔐 [AuthInterceptor] AuthInterceptor created');
    print('🔐 [AuthInterceptor] SecureStorageService: ${_secureStorage.runtimeType}');
    print('🔐 [AuthInterceptor] ===== INITIALIZATION COMPLETE =====');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    print('🔐 [AuthInterceptor] ===== REQUEST INTERCEPTION =====');
    print('🔐 [AuthInterceptor] URL: ${options.uri}');
    print('🔐 [AuthInterceptor] Method: ${options.method}');
    print('🔐 [AuthInterceptor] Path: ${options.path}');
    print('🔐 [AuthInterceptor] Headers: ${options.headers}');
    print('🔐 [AuthInterceptor] Extra: ${options.extra}');

    // Set correct content type for token endpoint
    if (options.path.contains('/connect/token')) {
      options.contentType = Headers.formUrlEncodedContentType;
    }

    // Check if this is a request that doesn't need a token
    final isPublicRequest = options.path.contains('/connect/token') ||
        options.path.contains('/connect/register') ||
        options.path.contains('/connect/logout');
    
    // All /api/ endpoints require authentication
    final isAuthRequest = !isPublicRequest;

    // Always attach client timezone offset so backend can compute local day boundary for streak
    try {
      final tzOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      options.headers['X-Client-TZ-Offset'] = tzOffsetMinutes.toString();
      print('🔐 [AuthInterceptor] X-Client-TZ-Offset: ${options.headers['X-Client-TZ-Offset']}');
    } catch (_) {}

    print('🔐 [AuthInterceptor] Is auth request: $isAuthRequest');

    if (isAuthRequest) {
      print('🔐 [AuthInterceptor] Getting token for auth request...');
      try {
        final token = await _secureStorage.getAccessToken();
        if (token != null) {
          print('🔐 [AuthInterceptor] ✅ Token found: ${token.substring(0, 10)}...');
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [AuthInterceptor] ✅ Authorization header added');
        } else {
          print('🔐 [AuthInterceptor] ⚠️ No token found for auth request');
        }
        // Authorization attached above; TZ offset already set globally
      } catch (e) {
        print('🔐 [AuthInterceptor] ❌ Error getting token: $e');
      }
    } else {
      print('🔐 [AuthInterceptor] Skipping token for public request');
    }

    print('🔐 [AuthInterceptor] Final headers: ${options.headers}');
    print('🔐 [AuthInterceptor] ===== REQUEST INTERCEPTION END =====');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('🔐 [AuthInterceptor] ===== RESPONSE INTERCEPTION =====');
    print('🔐 [AuthInterceptor] Status Code: ${response.statusCode}');
    print('🔐 [AuthInterceptor] URL: ${response.requestOptions.uri}');
    print('🔐 [AuthInterceptor] Method: ${response.requestOptions.method}');
    print('🔐 [AuthInterceptor] Response Data: ${response.data}');
    print('🔐 [AuthInterceptor] ===== RESPONSE INTERCEPTION END =====');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    print('🔐 [AuthInterceptor] ===== ERROR INTERCEPTION =====');
    print('🔐 [AuthInterceptor] Error Type: ${err.type}');
    print('🔐 [AuthInterceptor] Status Code: ${err.response?.statusCode}');
    print('🔐 [AuthInterceptor] URL: ${err.requestOptions.uri}');
    print('🔐 [AuthInterceptor] Method: ${err.requestOptions.method}');
    print('🔐 [AuthInterceptor] Error Response: ${err.response?.data}');
    print('🔐 [AuthInterceptor] Error Message: ${err.message}');

    if (err.response?.statusCode == 401) {
      print('🔐 [AuthInterceptor] ❌ 401 Unauthorized - Token may be invalid or expired');

      try {
        // Try to refresh the token via OpenIddict token endpoint
        final refreshToken = await _secureStorage.getRefreshToken();
        print('🔐 [AuthInterceptor] Refresh token: ${refreshToken?.substring(0, 10)}...');

        if (refreshToken != null && refreshToken.isNotEmpty) {
          print('🔐 [AuthInterceptor] 🔄 Attempting token refresh...');

          // Use a fresh Dio for token refresh only
          final refreshDio = Dio(BaseOptions(
            baseUrl: err.requestOptions.baseUrl,
            headers: {'Content-Type': Headers.formUrlEncodedContentType},
          ));

          print('🔐 [AuthInterceptor] Making refresh token request...');
          final refreshResponse = await refreshDio.post(
            '/connect/token',
            data: {
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken,
            },
          );
          print('🔐 [AuthInterceptor] Refresh response status: ${refreshResponse.statusCode}');
          print('🔐 [AuthInterceptor] Refresh response data: ${refreshResponse.data}');

          if (refreshResponse.statusCode == 200) {
            final data = refreshResponse.data is Map<String, dynamic>
                ? refreshResponse.data as Map<String, dynamic>
                : {};
            final newAccessToken = data['access_token'] ?? data['accessToken'];
            final newRefreshToken = data['refresh_token'] ?? data['refreshToken'];
            final expiresIn = data['expires_in'] ?? 3600;

            print('🔐 [AuthInterceptor] New access token: ${newAccessToken?.substring(0, 10)}...');
            print('🔐 [AuthInterceptor] New refresh token: ${newRefreshToken?.substring(0, 10)}...');
            print('🔐 [AuthInterceptor] Expires in: $expiresIn seconds');

            if (newAccessToken != null && newRefreshToken != null) {
              await _secureStorage.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                expiresIn: expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 3600,
              );
              print('🔐 [AuthInterceptor] ✅ Token refreshed successfully');

              // Retry the original request with new token using the original Dio instance
              err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              
              // Get the Dio instance that made the original request
              final dio = err.requestOptions.extra['dio'] as Dio?;
              print('🔐 [AuthInterceptor] Original Dio instance: ${dio != null ? "found" : "not found"}');
              
              if (dio != null) {
                print('🔐 [AuthInterceptor] 🔄 Retrying original request with new token...');
                final retryResponse = await dio.fetch(err.requestOptions);
                print('🔐 [AuthInterceptor] ✅ Original request retry successful');
                handler.resolve(retryResponse);
                return;
              } else {
                print('🔐 [AuthInterceptor] ❌ Original Dio instance not found in request options');
              }
            } else {
              print('🔐 [AuthInterceptor] ❌ New tokens are null in refresh response');
            }
          } else {
            print('🔐 [AuthInterceptor] ❌ Refresh request failed with status: ${refreshResponse.statusCode}');
            print('🔐 [AuthInterceptor] Clearing tokens due to refresh failure...');
            try {
              await _secureStorage.clearTokens();
              print('🔐 [AuthInterceptor] ✅ Tokens cleared due to refresh failure');
            } catch (e) {
              print('🔐 [AuthInterceptor] ⚠️ Error clearing tokens: $e');
            }
          }
        } else {
          print('🔐 [AuthInterceptor] ❌ No refresh token found or refresh token is empty');
          print('🔐 [AuthInterceptor] Clearing all tokens and redirecting to login...');
          try {
            await _secureStorage.clearTokens();
            print('🔐 [AuthInterceptor] ✅ Tokens cleared due to missing refresh token');
          } catch (e) {
            print('🔐 [AuthInterceptor] ⚠️ Error clearing tokens: $e');
          }
        }
      } catch (refreshError) {
        print('🔐 [AuthInterceptor] ❌ Token refresh failed: $refreshError');
        print('🔐 [AuthInterceptor] Clearing tokens due to refresh error...');
        try {
          await _secureStorage.clearTokens();
          print('🔐 [AuthInterceptor] ✅ Tokens cleared due to refresh error');
        } catch (e) {
          print('🔐 [AuthInterceptor] ⚠️ Error clearing tokens: $e');
        }
      }

      // If refresh fails, just let the error propagate
      print('🔐 [AuthInterceptor] ❌ Token refresh failed, letting error propagate');
      handler.next(err);
      return;
    }

    print('🔐 [AuthInterceptor] ===== ERROR INTERCEPTION END =====');
    handler.next(err);
  }
}
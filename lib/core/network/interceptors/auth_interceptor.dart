import 'package:dio/dio.dart';
import '../../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;

  AuthInterceptor(this._secureStorage) {
    print('🔐 [AuthInterceptor] ===== INITIALIZATION =====');
    print('🔐 [AuthInterceptor] AuthInterceptor created');
    print(
        '🔐 [AuthInterceptor] SecureStorageService: ${_secureStorage.runtimeType}');
    print('🔐 [AuthInterceptor] ===== INITIALIZATION COMPLETE =====');
  }

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('🔐 [AuthInterceptor] ===== REQUEST INTERCEPTION =====');
    print('🔐 [AuthInterceptor] URL: ${options.uri}');
    print('🔐 [AuthInterceptor] Method: ${options.method}');
    print('🔐 [AuthInterceptor] Path: ${options.path}');

    // Check if this is an auth-related request that doesn't need a token
    final isAuthRequest = options.path.contains('/auth/') ||
        options.path.contains('/register') ||
        options.path.contains('/login');

    print('🔐 [AuthInterceptor] Is auth request: $isAuthRequest');

    if (!isAuthRequest) {
      print('🔐 [AuthInterceptor] Getting token for non-auth request...');
      try {
        final token = await _secureStorage.getAccessToken();
        if (token != null) {
          print(
              '🔐 [AuthInterceptor] ✅ Token found: ${token.substring(0, 10)}...');
          options.headers['Authorization'] = 'Bearer $token';
          print('🔐 [AuthInterceptor] ✅ Authorization header added');
        } else {
          print(
              '🔐 [AuthInterceptor] ⚠️ No token found, proceeding without authorization');
        }
      } catch (e) {
        print('🔐 [AuthInterceptor] ❌ Error getting token: $e');
      }
    } else {
      print('🔐 [AuthInterceptor] Skipping token for auth request');
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

    if (err.response?.statusCode == 401) {
      print('🔐 [AuthInterceptor] ❌ 401 Unauthorized - Token may be invalid or expired');
      
      try {
        // Try to refresh the token
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken != null) {
          print('🔐 [AuthInterceptor] 🔄 Attempting token refresh...');
          
          // Create a new Dio instance for refresh request
          final refreshDio = Dio();
          final refreshResponse = await refreshDio.post(
            '${err.requestOptions.baseUrl}/auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          
          if (refreshResponse.statusCode == 200) {
            final newAccessToken = refreshResponse.data['accessToken'];
            final newRefreshToken = refreshResponse.data['refreshToken'];
            
            // Save new tokens
            await _secureStorage.saveAccessToken(newAccessToken);
            await _secureStorage.saveRefreshToken(newRefreshToken);
            
            print('🔐 [AuthInterceptor] ✅ Token refreshed successfully');
            
            // Retry the original request with new token
            err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await refreshDio.fetch(err.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        }
      } catch (refreshError) {
        print('🔐 [AuthInterceptor] ❌ Token refresh failed: $refreshError');
      }
      
      // If refresh fails, clear tokens and let the error propagate
      print('🔐 [AuthInterceptor] 🗑️ Clearing tokens due to refresh failure');
      await _secureStorage.clearTokens();
    }

    print('🔐 [AuthInterceptor] ===== ERROR INTERCEPTION END =====');
    super.onError(err, handler);
  }
}

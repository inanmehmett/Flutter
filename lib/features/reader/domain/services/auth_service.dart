import 'package:daily_english/core/cache/cache_manager.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../entities/user.dart';

@singleton
class AuthService {
  final Dio _dio;
  final CacheManager _cacheManager;
  final SecureStorageService _secureStorage;
  static const String _tokenKey = 'auth_token';

  AuthService(
    this._dio,
    this._cacheManager,
    this._secureStorage,
  );

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        await _secureStorage.saveTokens(
          accessToken: token,
          refreshToken: data['refresh_token'] ?? '',
          expiresIn: data['expires_in'] ?? 3600,
        );
        return token;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        await _secureStorage.saveTokens(
          accessToken: token,
          refreshToken: data['refresh_token'] ?? '',
          expiresIn: data['expires_in'] ?? 3600,
        );
        return token;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _secureStorage.clearTokens();
      await _cacheManager.clearCache();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.getAccessToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<String?> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['token'] as String;
        await _secureStorage.saveTokens(
          accessToken: newToken,
          refreshToken: data['refresh_token'] ?? refreshToken,
          expiresIn: data['expires_in'] ?? 3600,
        );
        return newToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {'email': email},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

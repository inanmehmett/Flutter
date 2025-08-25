import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../models/user_profile.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/config/app_config.dart';

abstract class AuthServiceProtocol {
  Future<UserProfile> login(
      String userNameOrEmail, String password, bool rememberMe);
  Future<UserProfile> register(
      String email, String userName, String password, String confirmPassword);
  Future<void> logout();
  Future<UserProfile> fetchUserProfile();
  Future<void> updateProfileImage(File image);
  Future<void> updateUserProfile(UserProfile profile);
  Future<bool> resetPassword({required String email});
  Future<UserProfile> googleLogin({required String idToken});
}

@singleton
class AuthService implements AuthServiceProtocol {
  final NetworkManager _networkManager;
  final FlutterSecureStorage _secureStorage;
  final CacheManager _cacheManager;
  final String _baseUrl;

  AuthService(
    this._networkManager,
    this._secureStorage,
    this._cacheManager,
  ) : _baseUrl = AppConfig.apiBaseUrl {
    print('🔐 [AuthService] Initialized with baseUrl: $_baseUrl');
    print('🔐 [AuthService] NetworkManager: ${_networkManager.runtimeType}');
  }

  @override
  Future<UserProfile> login(
      String userNameOrEmail, String password, bool rememberMe) async {
    print('🔐 [AuthService] ===== LOGIN START =====');
    print('🔐 [AuthService] Username/Email: $userNameOrEmail');
    print('🔐 [AuthService] Remember Me: $rememberMe');
    print('🔐 [AuthService] NetworkManager: ${_networkManager.runtimeType}');
    print('🔐 [AuthService] Base URL: $_baseUrl');

    try {
      // OpenIddict password grant ile login
      final formData = {
        'grant_type': 'password',
        'username': userNameOrEmail.toLowerCase().trim(),
        'password': password,
        'scope': 'offline_access roles profile email',
      };

      print('🔐 [AuthService] Making POST request to /connect/token (password grant)...');

      final response = await _networkManager.post(
        '/connect/token',
        data: formData,
      );

      print('🔐 [AuthService] ===== LOGIN RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Login successful!');

        final accessToken = response.data['access_token'] ?? response.data['accessToken'];
        final refreshToken = response.data['refresh_token'] ?? response.data['refreshToken'];
        final expiresIn = response.data['expires_in'] ?? 3600;

        print('🔐 [AuthService] Saving tokens...');
        await _saveTokens(
          accessToken: '$accessToken',
          refreshToken: '$refreshToken',
          expiresIn: expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 3600,
        );
        print('🔐 [AuthService] ✅ Tokens saved successfully');

        // Profile çek
        final userProfile = await fetchUserProfile();
        print('🔐 [AuthService] ===== LOGIN END =====');
        return userProfile;
      } else {
        print('🔐 [AuthService] ❌ Login failed - Status code: ${response.statusCode}');
        throw AuthError.invalidCredentials;
      }
    } on DioException catch (e) {
      print('🔐 [AuthService] ===== LOGIN DIO ERROR =====');
      print('🔐 [AuthService] Error Type: ${e.type}');
      print('🔐 [AuthService] Error Message: ${e.message}');
      print('🔐 [AuthService] Error Response: ${e.response?.data}');
      print('🔐 [AuthService] Error Status Code: ${e.response?.statusCode}');
      print('🔐 [AuthService] Request URL: ${e.requestOptions.uri}');
      print('🔐 [AuthService] Request Method: ${e.requestOptions.method}');
      print('🔐 [AuthService] Request Data: ${e.requestOptions.data}');

      if (e.response?.statusCode == 401) {
        print('🔐 [AuthService] ❌ 401 Unauthorized - Invalid credentials');
        throw AuthError.invalidCredentials;
      } else if (e.response?.statusCode == 400) {
        print('🔐 [AuthService] ❌ 400 Bad Request - Server error');
        throw AuthError.serverError;
      } else {
        print('🔐 [AuthService] ❌ Network error');
        throw AuthError.networkError;
      }
    } catch (e) {
      print('🔐 [AuthService] ===== LOGIN GENERAL ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<UserProfile> register(String email, String userName, String password,
      String confirmPassword) async {
    print('🔐 [AuthService] ===== REGISTER START =====');
    print('🔐 [AuthService] Email: $email');
    print('🔐 [AuthService] Username: $userName');
    print('🔐 [AuthService] Password length: ${password.length}');
    print(
        '🔐 [AuthService] Confirm password length: ${confirmPassword.length}');
    print('🔐 [AuthService] NetworkManager: ${_networkManager.runtimeType}');
    print('🔐 [AuthService] Base URL: $_baseUrl');

    try {
      final requestData = {
        'Email': email.trim(),
        'UserName': userName.trim(),
        'Password': password,
      };

      print('🔐 [AuthService] Making POST request to /connect/register...');

      final response = await _networkManager.post(
        '/connect/register',
        data: requestData,
      );

      print('🔐 [AuthService] ===== REGISTER RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Registration successful!');

        // Opsiyonel: otomatik login yapılabilir, şimdilik profil dummy dönüyoruz
        final userProfile = UserProfile(
          id: response.data['userId']?.toString() ?? '',
          userName: userName,
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        print('🔐 [AuthService] ===== REGISTER END =====');
        return userProfile;
      } else {
        print('🔐 [AuthService] ❌ Registration failed - Status code: ${response.statusCode}');
        throw AuthError.serverError;
      }
    } on DioException catch (e) {
      print('🔐 [AuthService] ===== REGISTER DIO ERROR =====');
      print('🔐 [AuthService] Error Type: ${e.type}');
      print('🔐 [AuthService] Error Message: ${e.message}');
      print('🔐 [AuthService] Error Response: ${e.response?.data}');
      print('🔐 [AuthService] Error Status Code: ${e.response?.statusCode}');
      print('🔐 [AuthService] Request URL: ${e.requestOptions.uri}');
      print('🔐 [AuthService] Request Method: ${e.requestOptions.method}');
      print('🔐 [AuthService] Request Data: ${e.requestOptions.data}');
      // Backend 400: { error: "Username already exists" } gibi net mesaj döndürüyor.
      if (e.response?.statusCode == 400) {
        final data = e.response?.data;
        final message = (data is Map && data['error'] is String)
            ? (data['error'] as String)
            : 'Registration failed';
        // İşlenebilir mesajı bloc'ta göstermek için Exception at
        throw Exception(message);
      }
      throw AuthError.serverError;
    } catch (e) {
      print('🔐 [AuthService] ===== REGISTER GENERAL ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<void> logout() async {
    print('🔐 [AuthService] ===== LOGOUT START =====');

    try {
      print('🔐 [AuthService] Making GET request to /connect/logout...');
      await _networkManager.get('/connect/logout');
      print('🔐 [AuthService] ✅ Logout API call successful');
    } catch (e) {
      print('🔐 [AuthService] ⚠️ Logout API call failed: $e');
      print('🔐 [AuthService] Continuing with local cleanup...');
    }

    // Clear tokens
    print('🔐 [AuthService] Clearing tokens...');
    await _clearTokens();
    print('🔐 [AuthService] ✅ Tokens cleared');

    // Clear cache
    print('🔐 [AuthService] Clearing cache...');
    await _cacheManager.clearAll();
    // Clear in-memory HTTP cache
    try {
      _networkManager.clearHttpCache();
    } catch (_) {}
    print('🔐 [AuthService] ✅ Cache cleared');

    print('🔐 [AuthService] ✅ Logout completed successfully');
    print('🔐 [AuthService] ===== LOGOUT END =====');
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    print('🔐 [AuthService] ===== FETCH USER PROFILE START =====');

    try {
      print('🔐 [AuthService] Getting access token...');
      final token = await _getAccessToken();
      if (token == null) {
        print('🔐 [AuthService] ❌ No access token found');
        throw AuthError.invalidCredentials;
      }
      print(
          '🔐 [AuthService] ✅ Access token found: ${token.substring(0, 10)}...');

      print('🔐 [AuthService] Making GET request to /api/ApiUserProfile...');
      final response = await _networkManager.get('/api/ApiUserProfile');

      print('🔐 [AuthService] ===== FETCH PROFILE RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Profile fetch successful!');
        final data = response.data as Map<String, dynamic>;

        String? processProfileImageUrl(String? profileImageUrl) {
          if (profileImageUrl == null || profileImageUrl.isEmpty) return null;
          if (profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://')) {
            return profileImageUrl;
          }
          if (profileImageUrl.startsWith('file://')) {
            return profileImageUrl.replaceFirst('file://', AppConfig.apiBaseUrl);
          }
          if (profileImageUrl.startsWith('/')) {
            return '${AppConfig.apiBaseUrl}$profileImageUrl';
          }
          return '${AppConfig.apiBaseUrl}/$profileImageUrl';
        }

        final userProfile = UserProfile(
          id: data['id']?.toString() ?? '',
          userName: data['userName']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          createdAt: DateTime.tryParse('${data['createdAt']}') ?? DateTime.now(),
          updatedAt: DateTime.tryParse('${data['updatedAt']}') ?? DateTime.now(),
          isActive: true,
          profileImageUrl: processProfileImageUrl(data['profileImageUrl']?.toString()),
          bio: data['bio']?.toString(),
          level: (data['subLevel'] as num?)?.toInt(),
          levelName: data['levelName']?.toString(),
          levelDisplay: data['levelDisplay']?.toString(),
          experiencePoints: (data['experiencePoints'] as num?)?.toInt(),
          totalReadBooks: (data['totalReadBooks'] as num?)?.toInt(),
          totalQuizScore: (data['totalQuizScore'] as num?)?.toInt(),
          currentStreak: (data['currentStreak'] as num?)?.toInt(),
          longestStreak: (data['longestStreak'] as num?)?.toInt(),
        );
        print('🔐 [AuthService] ===== FETCH USER PROFILE END =====');
        return userProfile;
      } else {
        print('🔐 [AuthService] ❌ Profile fetch failed - Status code: ${response.statusCode}');
        throw AuthError.serverError;
      }
    } on DioException catch (e) {
      print('🔐 [AuthService] ===== FETCH PROFILE DIO ERROR =====');
      print('🔐 [AuthService] Error Type: ${e.type}');
      print('🔐 [AuthService] Error Message: ${e.message}');
      print('🔐 [AuthService] Error Response: ${e.response?.data}');
      print('🔐 [AuthService] Error Status Code: ${e.response?.statusCode}');
      print('🔐 [AuthService] Request URL: ${e.requestOptions.uri}');
      print('🔐 [AuthService] Request Method: ${e.requestOptions.method}');

      if (e.response?.statusCode == 401) {
        print('🔐 [AuthService] ❌ 401 Unauthorized - Invalid token');
        throw AuthError.invalidCredentials;
      } else {
        print('🔐 [AuthService] ❌ Network error');
        throw AuthError.networkError;
      }
    } catch (e) {
      print('🔐 [AuthService] ===== FETCH PROFILE GENERAL ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    print('🔐 [AuthService] ===== UPDATE USER PROFILE START =====');

    try {
      final token = await _getAccessToken();
      if (token == null) {
        print('🔐 [AuthService] ❌ No access token found');
        throw AuthError.invalidCredentials;
      }

      final profileData = profile.toJson();

      print('🔐 [AuthService] Making PUT request to /api/ApiUserProfile...');
      await _networkManager.put(
        '/api/ApiUserProfile',
        data: profileData,
      );
    } catch (e) {
      print('🔐 [AuthService] ===== UPDATE USER PROFILE ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<void> updateProfileImage(File image) async {
    // Upload to backend profile-picture endpoint
    print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE START =====');
    print('🔐 [AuthService] Image path: ${image.path}');
    print('🔐 [AuthService] Image size: ${await image.length()} bytes');

    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw AuthError.invalidCredentials;
      }

      final formData = FormData.fromMap({
        'profilePicture': await MultipartFile.fromFile(image.path),
      });

      print('🔐 [AuthService] Making POST request to /api/ApiUserProfile/profile-picture...');
      final resp = await _networkManager.post(
        '/api/ApiUserProfile/profile-picture',
        data: formData,
      );
      print('🔐 [AuthService] Upload response: ${resp.statusCode} ${resp.data}');
    } catch (e) {
      print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<bool> resetPassword({required String email}) async {
    // Not implemented on backend; keep as stub
    print('🔐 [AuthService] ===== RESET PASSWORD START =====');
    return false;
  }

  @override
  Future<UserProfile> googleLogin({required String idToken}) async {
    try {
      final response = await _networkManager.post(
        '/connect/token',
        data: {
          'grant_type': 'google_oauth',
          'id_token': idToken,
          'scope': 'offline_access roles profile email',
        },
      );
      if (response.statusCode == 200) {
        final accessToken = response.data['access_token'] ?? response.data['accessToken'];
        final refreshToken = response.data['refresh_token'] ?? response.data['refreshToken'];
        final expiresIn = response.data['expires_in'] ?? 3600;
        await _saveTokens(
          accessToken: '$accessToken',
          refreshToken: '$refreshToken',
          expiresIn: expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 3600,
        );
        return await fetchUserProfile();
      }
      throw AuthError.invalidCredentials;
    } catch (e) {
      print('🔐 [AuthService] Google login error: $e');
      throw AuthError.networkError;
    }
  }

  // Helper methods
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    print('🔐 [AuthService] ===== SAVE TOKENS START =====');
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    try {
      await _secureStorage.write(key: 'access_token', value: accessToken);
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      await _secureStorage.write(
        key: 'token_expires_at',
        value: expiresAt.toIso8601String(),
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> _clearTokens() async {
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      await _secureStorage.delete(key: 'token_expires_at');
    } catch (e) {
      throw e;
    }
  }

  Future<String?> _getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        final expiresAtString = await _secureStorage.read(key: 'token_expires_at');
        if (expiresAtString != null) {
          final expiresAt = DateTime.parse(expiresAtString);
          if (DateTime.now().isAfter(expiresAt)) {
            return null;
          }
        }
      }
      return token;
    } catch (e) {
      return null;
    }
  }
}

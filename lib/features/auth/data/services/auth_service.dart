import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../models/user_profile.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/network/network_manager.dart';

abstract class AuthServiceProtocol {
  Future<UserProfile> login(
      String userNameOrEmail, String password, bool rememberMe);
  Future<UserProfile> register(
      String email, String userName, String password, String confirmPassword);
  Future<void> logout();
  Future<UserProfile> fetchUserProfile();
  Future<void> updateProfileImage(File image);
  Future<void> updateUserProfile(UserProfile profile);
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
    @Named('baseUrl') this._baseUrl,
  ) {
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
      final requestData = {
        'usernameOrEmail': userNameOrEmail.toLowerCase().trim(),
        'password': password,
        'rememberMe': rememberMe,
      };

      print('🔐 [AuthService] Request data: ${json.encode(requestData)}');
      print('🔐 [AuthService] Making POST request to /api/auth/login...');

      final response = await _networkManager.post(
        '/api/auth/login',
        data: requestData,
      );

      print('🔐 [AuthService] ===== LOGIN RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Login successful!');
        final loginResponse = LoginResponse.fromJson(response.data);
        print('🔐 [AuthService] User ID: ${loginResponse.userId}');
        print('🔐 [AuthService] Username: ${loginResponse.userName}');
        print('🔐 [AuthService] Email: ${loginResponse.email}');

        // Save tokens
        final accessToken = 'dummy_token_${loginResponse.userId}';
        final refreshToken = 'dummy_refresh_${loginResponse.userId}';
        print('🔐 [AuthService] Saving tokens...');
        print('🔐 [AuthService] Access Token: $accessToken');
        print('🔐 [AuthService] Refresh Token: $refreshToken');

        await _saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: 3600,
        );
        print('🔐 [AuthService] ✅ Tokens saved successfully');

        // Return user profile
        final userProfile = UserProfile(
          id: loginResponse.userId,
          userName: loginResponse.userName,
          email: loginResponse.email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        print(
            '🔐 [AuthService] ✅ Returning user profile: ${userProfile.userName}');
        print('🔐 [AuthService] ===== LOGIN END =====');
        return userProfile;
      } else {
        print(
            '🔐 [AuthService] ❌ Login failed - Status code: ${response.statusCode}');
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
        final errorResponse = SimpleResponse.fromJson(e.response?.data);
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
        'ConfirmPassword': confirmPassword,
      };

      print('🔐 [AuthService] Request data: ${json.encode(requestData)}');
      print('🔐 [AuthService] Making POST request to /api/auth/register...');

      final response = await _networkManager.post(
        '/api/auth/register',
        data: requestData,
      );

      print('🔐 [AuthService] ===== REGISTER RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Registration successful!');

        // Return a basic user profile
        final userProfile = UserProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userName: userName,
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
        );

        print(
            '🔐 [AuthService] ✅ Returning user profile: ${userProfile.userName}');
        print('🔐 [AuthService] ===== REGISTER END =====');
        return userProfile;
      } else {
        print(
            '🔐 [AuthService] ❌ Registration failed - Status code: ${response.statusCode}');
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
      print('🔐 [AuthService] Making POST request to /api/auth/logout...');
      await _networkManager.post('/api/auth/logout');
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

      print('🔐 [AuthService] Making GET request to /api/UserProfile...');
      print('🔐 [AuthService] NetworkManager: ${_networkManager.runtimeType}');
      print('🔐 [AuthService] Base URL: $_baseUrl');

      // Note: NetworkManager doesn't support custom headers directly
      // We'll need to use the auth interceptor for token management
      final response = await _networkManager.get('/api/UserProfile');

      print('🔐 [AuthService] ===== FETCH PROFILE RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Headers: ${response.headers}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Profile fetch successful!');
        final userProfile = UserProfile.fromJson(response.data);
        print(
            '🔐 [AuthService] Decoded profile: ${userProfile.userName} (${userProfile.email})');
        print('🔐 [AuthService] ===== FETCH USER PROFILE END =====');
        return userProfile;
      } else {
        print(
            '🔐 [AuthService] ❌ Profile fetch failed - Status code: ${response.statusCode}');
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
  Future<void> updateProfileImage(File image) async {
    print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE START =====');
    print('🔐 [AuthService] Image path: ${image.path}');
    print('🔐 [AuthService] Image size: ${await image.length()} bytes');

    try {
      print('🔐 [AuthService] Getting access token...');
      final token = await _getAccessToken();
      if (token == null) {
        print('🔐 [AuthService] ❌ No access token found');
        throw AuthError.invalidCredentials;
      }
      print(
          '🔐 [AuthService] ✅ Access token found: ${token.substring(0, 10)}...');

      print('🔐 [AuthService] Creating form data...');
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path),
      });
      print('🔐 [AuthService] Form data created successfully');

      print(
          '🔐 [AuthService] Making POST request to /api/auth/profile/image...');
      final response = await _networkManager.post(
        '/api/auth/profile/image',
        data: formData,
      );

      print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ Profile image updated successfully');
        print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE END =====');
      } else {
        print(
            '🔐 [AuthService] ❌ Profile image update failed - Status code: ${response.statusCode}');
        throw AuthError.serverError;
      }
    } catch (e) {
      print('🔐 [AuthService] ===== UPDATE PROFILE IMAGE ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    print('🔐 [AuthService] ===== UPDATE USER PROFILE START =====');
    print(
        '🔐 [AuthService] Profile to update: ${profile.userName} (${profile.email})');

    try {
      print('🔐 [AuthService] Getting access token...');
      final token = await _getAccessToken();
      if (token == null) {
        print('🔐 [AuthService] ❌ No access token found');
        throw AuthError.invalidCredentials;
      }
      print(
          '🔐 [AuthService] ✅ Access token found: ${token.substring(0, 10)}...');

      final profileData = profile.toJson();
      print('🔐 [AuthService] Profile data: ${json.encode(profileData)}');

      print('🔐 [AuthService] Making PUT request to /api/user/profile...');
      final response = await _networkManager.put(
        '/api/user/profile',
        data: profileData,
      );

      print('🔐 [AuthService] ===== UPDATE USER PROFILE RESPONSE =====');
      print('🔐 [AuthService] Status Code: ${response.statusCode}');
      print('🔐 [AuthService] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        print('🔐 [AuthService] ✅ User profile updated successfully');
        print('🔐 [AuthService] ===== UPDATE USER PROFILE END =====');
      } else {
        print(
            '🔐 [AuthService] ❌ User profile update failed - Status code: ${response.statusCode}');
        throw AuthError.serverError;
      }
    } catch (e) {
      print('🔐 [AuthService] ===== UPDATE USER PROFILE ERROR =====');
      print('🔐 [AuthService] Error: $e');
      print('🔐 [AuthService] Error Type: ${e.runtimeType}');
      throw AuthError.unknown;
    }
  }

  // Helper methods
  Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    print('🔐 [AuthService] ===== SAVE TOKENS START =====');
    print('🔐 [AuthService] Access Token: ${accessToken.substring(0, 10)}...');
    print(
        '🔐 [AuthService] Refresh Token: ${refreshToken.substring(0, 10)}...');
    print('🔐 [AuthService] Expires In: $expiresIn seconds');

    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    print('🔐 [AuthService] Token expires at: $expiresAt');

    try {
      print('🔐 [AuthService] Saving access token...');
      await _secureStorage.write(key: 'access_token', value: accessToken);
      print('🔐 [AuthService] ✅ Access token saved');

      print('🔐 [AuthService] Saving refresh token...');
      await _secureStorage.write(key: 'refresh_token', value: refreshToken);
      print('🔐 [AuthService] ✅ Refresh token saved');

      print('🔐 [AuthService] Saving token expiration...');
      await _secureStorage.write(
        key: 'token_expires_at',
        value: expiresAt.toIso8601String(),
      );
      print('🔐 [AuthService] ✅ Token expiration saved');

      print('🔐 [AuthService] ✅ All tokens saved successfully');
      print('🔐 [AuthService] ===== SAVE TOKENS END =====');
    } catch (e) {
      print('🔐 [AuthService] ❌ Error saving tokens: $e');
      throw e;
    }
  }

  Future<void> _clearTokens() async {
    print('🔐 [AuthService] ===== CLEAR TOKENS START =====');

    try {
      print('🔐 [AuthService] Deleting access token...');
      await _secureStorage.delete(key: 'access_token');
      print('🔐 [AuthService] ✅ Access token deleted');

      print('🔐 [AuthService] Deleting refresh token...');
      await _secureStorage.delete(key: 'refresh_token');
      print('🔐 [AuthService] ✅ Refresh token deleted');

      print('🔐 [AuthService] Deleting token expiration...');
      await _secureStorage.delete(key: 'token_expires_at');
      print('🔐 [AuthService] ✅ Token expiration deleted');

      print('🔐 [AuthService] ✅ All tokens cleared successfully');
      print('🔐 [AuthService] ===== CLEAR TOKENS END =====');
    } catch (e) {
      print('🔐 [AuthService] ❌ Error clearing tokens: $e');
      throw e;
    }
  }

  Future<String?> _getAccessToken() async {
    print('🔐 [AuthService] ===== GET ACCESS TOKEN START =====');

    try {
      print('🔐 [AuthService] Reading access token from secure storage...');
      final token = await _secureStorage.read(key: 'access_token');

      if (token != null) {
        print(
            '🔐 [AuthService] ✅ Access token found: ${token.substring(0, 10)}...');

        // Check if token is expired
        print('🔐 [AuthService] Checking token expiration...');
        final expiresAtString =
            await _secureStorage.read(key: 'token_expires_at');
        if (expiresAtString != null) {
          final expiresAt = DateTime.parse(expiresAtString);
          final now = DateTime.now();
          print('🔐 [AuthService] Token expires at: $expiresAt');
          print('🔐 [AuthService] Current time: $now');

          if (now.isAfter(expiresAt)) {
            print('🔐 [AuthService] ❌ Token is expired');
            print('🔐 [AuthService] ===== GET ACCESS TOKEN END =====');
            return null;
          } else {
            print('🔐 [AuthService] ✅ Token is still valid');
          }
        } else {
          print(
              '🔐 [AuthService] ⚠️ No expiration date found, assuming token is valid');
        }
      } else {
        print('🔐 [AuthService] ❌ No access token found');
      }

      print('🔐 [AuthService] ===== GET ACCESS TOKEN END =====');
      return token;
    } catch (e) {
      print('🔐 [AuthService] ❌ Error getting access token: $e');
      print('🔐 [AuthService] ===== GET ACCESS TOKEN END =====');
      return null;
    }
  }
}

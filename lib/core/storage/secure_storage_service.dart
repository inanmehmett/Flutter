import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@singleton
class SecureStorageService {
  final FlutterSecureStorage _storage;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresInKey = 'expires_in';

  SecureStorageService(this._storage);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _expiresInKey, value: expiresIn.toString()),
    ]);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<int?> getExpiresIn() async {
    final value = await _storage.read(key: _expiresInKey);
    return value != null ? int.parse(value) : null;
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresInKey),
    ]);
  }

  Future<bool> isTokenValid() async {
    final expirationString = await _storage.read(key: _expiresInKey);
    if (expirationString == null) return false;

    final expirationDate =
        DateTime.now().add(Duration(seconds: int.parse(expirationString)));
    final currentDate = DateTime.now();

    // Add a 5-minute buffer to account for network latency
    final bufferTime = const Duration(minutes: 5);
    final adjustedExpirationDate = expirationDate.subtract(bufferTime);

    return currentDate.isBefore(adjustedExpirationDate);
  }
}

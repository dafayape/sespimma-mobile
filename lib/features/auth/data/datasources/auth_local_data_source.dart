import 'dart:developer' as developer;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();

  Future<void> saveUserJson(String userJson);

  Future<String?> getUserJson();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  const AuthLocalDataSourceImpl({required this.secureStorage});

  static const String _accessTokenKey = 'ACCESS_TOKEN';
  static const String _refreshTokenKey = 'REFRESH_TOKEN';
  static const String _userJsonKey = 'USER_JSON';

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      secureStorage.write(key: _accessTokenKey, value: accessToken),
      secureStorage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  @override
  Future<String?> getAccessToken() async {
    try {
      final res = await secureStorage.read(key: _accessTokenKey);
      developer.log('AuthLocalDataSource getAccessToken read: ${res != null ? "success (len: ${res.length})" : "null"}', name: 'AuthLocal');
      return res;
    } catch (e) {
      developer.log('AuthLocalDataSource getAccessToken exception: $e', name: 'AuthLocal');
      await secureStorage.deleteAll();
      return null;
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      await secureStorage.deleteAll();
      return null;
    }
  }

  @override
  Future<void> clearTokens() async {
    await Future.wait([
      secureStorage.delete(key: _accessTokenKey),
      secureStorage.delete(key: _refreshTokenKey),
      secureStorage.delete(key: _userJsonKey),
    ]);
  }

  @override
  Future<void> saveUserJson(String userJson) async {
    await secureStorage.write(key: _userJsonKey, value: userJson);
  }

  @override
  Future<String?> getUserJson() async {
    try {
      return await secureStorage.read(key: _userJsonKey);
    } catch (_) {
      return null;
    }
  }
}

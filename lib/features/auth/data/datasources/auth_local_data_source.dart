import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<void> clearTokens();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;

  const AuthLocalDataSourceImpl({required this.secureStorage});

  static const String _accessTokenKey = 'ACCESS_TOKEN';
  static const String _refreshTokenKey = 'REFRESH_TOKEN';

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
      return await secureStorage.read(key: _accessTokenKey);
    } catch (e) {
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
    ]);
  }
}

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String nrp,
    required String password,
    required String fcmToken,
  });

  Future<bool> isLoggedIn();

  Future<void> logout();
}

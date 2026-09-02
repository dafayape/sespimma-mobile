import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String nrp,
    required String password,
    required String fcmToken,
    bool force = false,
  });

  Future<bool> isLoggedIn();

  Future<void> logout();

  Future<void> updateProfilePhoto(String photoPath);

  Future<void> deleteProfilePhoto();

  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);

  Future<UserEntity?> getSavedUser();

  Future<UserEntity> fetchFreshProfile();
}

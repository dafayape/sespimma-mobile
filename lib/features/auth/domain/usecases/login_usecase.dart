import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<UserEntity> execute({
    required String nrp,
    required String password,
    required String fcmToken,
  }) {
    return repository.login(nrp: nrp, password: password, fcmToken: fcmToken);
  }
}

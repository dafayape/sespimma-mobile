import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String nrp;
  final String password;
  final String fcmToken;

  const LoginSubmitted({
    required this.nrp,
    required this.password,
    required this.fcmToken,
  });

  @override
  List<Object> get props => [nrp, password, fcmToken];
}

class UpdateProfilePhotoRequested extends AuthEvent {
  final String? photoPath;

  const UpdateProfilePhotoRequested(this.photoPath);

  @override
  List<Object> get props => [photoPath ?? ''];
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const ChangePasswordRequested({
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [oldPassword, newPassword];
}

class ResetPasswordRequested extends AuthEvent {
  final String nrp;
  final String newPassword;

  const ResetPasswordRequested({required this.nrp, required this.newPassword});

  @override
  List<Object> get props => [nrp, newPassword];
}

class VerifyNrpRequested extends AuthEvent {
  final String nrp;

  const VerifyNrpRequested(this.nrp);

  @override
  List<Object> get props => [nrp];
}

class AutoLoginRequested extends AuthEvent {
  final UserEntity user;

  const AutoLoginRequested(this.user);

  @override
  List<Object> get props => [user];
}

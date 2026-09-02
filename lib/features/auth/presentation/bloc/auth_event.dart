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
  final bool force;

  const LoginSubmitted({
    required this.nrp,
    required this.password,
    required this.fcmToken,
    this.force = false,
  });

  @override
  List<Object> get props => [nrp, password, fcmToken, force];
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

/// Single, consistent "force logout" trigger — dispatched whenever the
/// app determines the current session is no longer valid, from either of
/// two independent call sites:
///  - `injection_container.dart`'s Dio interceptor, when a 401 comes back
///    and the token-refresh attempt also fails (or there's no refresh
///    token to try).
///  - `BackgroundLocationService.onSessionExpired`, when the background
///    isolate's location ping gets a 401 (see that stream's doc).
/// Both cases mean the server has revoked this device's session (e.g. the
/// same account logged in elsewhere), so the outcome is the same either
/// way: clear local session state, stop background tracking, and send the
/// user back to the login screen with a visible reason.
class ForceLogoutRequested extends AuthEvent {
  final String reason;

  const ForceLogoutRequested({
    this.reason = 'Sesi Anda telah berakhir, silakan login kembali.',
  });

  @override
  List<Object> get props => [reason];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class RefreshProfileRequested extends AuthEvent {
  const RefreshProfileRequested();
}

import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/background_location_service.dart';
import '../../../../core/services/session_heartbeat_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/serdik_real_data.dart';
import '../../data/datasources/patun_real_data.dart';
import '../../data/datasources/gadik_real_data.dart';
import '../../data/datasources/korsis_real_data.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final AuthRepository authRepository;

  AuthBloc({
    required this.loginUseCase,
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<UpdateProfilePhotoRequested>(_onUpdateProfilePhotoRequested);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<VerifyNrpRequested>(_onVerifyNrpRequested);
    on<AutoLoginRequested>(_onAutoLoginRequested);
    on<ForceLogoutRequested>(_onForceLogoutRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshProfileRequested>(_onRefreshProfileRequested);
  }

  Future<void> _onAutoLoginRequested(
    AutoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthSuccess(event.user));
    _startTrackingSession(event.user);
    SessionHeartbeatService.start();

    try {
      final freshUser = await authRepository.fetchFreshProfile();
      emit(AuthSuccess(freshUser));
    } catch (e) {
      developer.log(
        'AutoLogin: fetchFreshProfile failed: $e',
        name: 'AuthBloc',
      );
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await loginUseCase.execute(
        nrp: event.nrp,
        password: event.password,
        fcmToken: event.fcmToken,
        force: event.force,
      );

      emit(AuthSuccess(user));
      _startTrackingSession(user);
      SessionHeartbeatService.start();
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      final isConflict = e is ActiveSessionException ||
          errorMessage.toLowerCase().contains('sedang digunakan') ||
          errorMessage.toLowerCase().contains('is_active_session');
      emit(AuthFailure(errorMessage, isSessionConflict: isConflict));
    }
  }

  /// Starts the realtime location background service for the session that
  /// just began (fresh login or auto-login on app relaunch with a saved
  /// session). No-ops for non-serdik roles / when serdikId can't be
  /// resolved to a numeric id — tracking only applies to students.
  /// Fire-and-forget on purpose: a tracking-start hiccup should never block
  /// the login flow.
  void _startTrackingSession(UserEntity user) {
    final studentId = user.serdikId;
    if (studentId == null || studentId.isEmpty || int.tryParse(studentId) == null) {
      developer.log(
        'Skipping BackgroundLocationService.start(): no numeric serdikId for this user (role=${user.roleId})',
        name: 'AuthBloc',
      );
      return;
    }
    BackgroundLocationService.start(studentId: studentId).catchError((e) {
      developer.log('BackgroundLocationService.start() failed: $e', name: 'AuthBloc');
    });
  }

  /// The single "force logout" trigger reused by both the Dio interceptor
  /// (token-refresh failure, `injection_container.dart`) and the
  /// background-isolate session-expired signal
  /// (`BackgroundLocationService.onSessionExpired`, wired up in
  /// `main.dart`). Clears local session/tokens and stops background
  /// tracking via [AuthRepository.logout] (idempotent — safe even if
  /// tracking was already stopped), then emits [AuthLoggedOut] so the
  /// top-level listener can navigate to the login screen with [reason].
  Future<void> _onForceLogoutRequested(
    ForceLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthSuccess) return;

    SessionHeartbeatService.stop();
    try {
      await authRepository.logout();
    } catch (e) {
      developer.log(
        'ForceLogoutRequested: logout() failed: $e',
        name: 'AuthBloc',
      );
    }
    emit(AuthLoggedOut(event.reason));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    SessionHeartbeatService.stop();
    try {
      await authRepository.logout();
    } catch (e) {
      developer.log(
        'LogoutRequested: logout() failed: $e',
        name: 'AuthBloc',
      );
    }
    emit(AuthInitial());
  }

  Future<void> _onRefreshProfileRequested(
    RefreshProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthSuccess) {
      final currentUser = (state as AuthSuccess).user;
      try {
        final freshUser = await authRepository.fetchFreshProfile();
        if (freshUser != currentUser) {
          developer.log('Profile updated from server', name: 'AuthBloc');
          emit(AuthSuccess(freshUser));
        }
      } catch (e) {
        final errStr = e.toString();
        if (errStr.contains('401') || errStr.toLowerCase().contains('unauthorized')) {
          developer.log(
            'RefreshProfile: 401 detected, triggering force logout',
            name: 'AuthBloc',
          );
          SessionHeartbeatService.stop();
          add(const ForceLogoutRequested());
        } else {
          developer.log(
            'RefreshProfile: fetchFreshProfile error: $e',
            name: 'AuthBloc',
          );
        }
      }
    }
  }

  Future<void> _onUpdateProfilePhotoRequested(
    UpdateProfilePhotoRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthSuccess) {
      final currentUser = (state as AuthSuccess).user;
      final currentState = state;

      emit(AuthLoading());

      try {
        if (event.photoPath != null) {
          await authRepository.updateProfilePhoto(event.photoPath!);
        } else {
          await authRepository.deleteProfilePhoto();
        }

        final updatedUser = currentUser.copyWith(
          profilePhoto: event.photoPath,
          clearProfilePhoto: event.photoPath == null,
        );

        try {
          final freshUser = await authRepository.fetchFreshProfile();
          emit(AuthSuccess(freshUser));
        } catch (_) {
          emit(AuthSuccess(updatedUser));
        }
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
        emit(currentState);
      }
    }
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthSuccess) {
      final currentState = state;

      emit(AuthLoading());

      try {
        await authRepository.changePassword(
          event.oldPassword,
          event.newPassword,
          event.newPassword,
        );
        SessionHeartbeatService.stop();
        try {
          await authRepository.logout();
        } catch (_) {}
        emit(PasswordChangeSuccess());
        emit(AuthInitial());
      } catch (e) {
        emit(AuthFailure(e.toString().replaceAll('Exception: ', '')));
        emit(currentState);
      }
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    emit(AuthLoading());

    await Future.delayed(const Duration(milliseconds: 1200));

    emit(currentState);
  }

  Future<void> _onVerifyNrpRequested(
    VerifyNrpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await Future.delayed(const Duration(milliseconds: 500));

    bool exists = false;

    if (SerdikRealData.records.any(
      (r) =>
          r['nrp'] == event.nrp ||
          r['no_serdik'] == event.nrp ||
          r['nik'] == event.nrp,
    )) {
      exists = true;
    } else if (PatunRealData.records.any((r) => r['nrp_nip'] == event.nrp)) {
      exists = true;
    } else if (GadikRealData.records.any((r) => r['nrp_nip'] == event.nrp)) {
      exists = true;
    } else if (KorsisRealData.records.any((r) => r['nrp_nip'] == event.nrp)) {
      exists = true;
    }

    if (exists) {
      emit(AuthNrpValidationSuccess(event.nrp));
      emit(AuthInitial());
    } else {
      final label = event.nrp.length > 8 ? 'NIP' : 'NRP';
      emit(AuthFailure('$label tidak valid atau tidak ada di dalam database'));
    }
  }
}

import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/background_location_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
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
  }

  void _onAutoLoginRequested(
    AutoLoginRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthSuccess(event.user));
    _startTrackingSession(event.user);
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
      );

      emit(AuthSuccess(user));
      _startTrackingSession(user);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(errorMessage));
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
        }

        final updatedUser = currentUser.copyWith(
          profilePhoto: event.photoPath,
          clearProfilePhoto: event.photoPath == null,
        );

        emit(AuthSuccess(updatedUser));
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
      final currentUser = (state as AuthSuccess).user;
      final currentState = state;

      emit(AuthLoading());

      try {
        await authRepository.changePassword(
          event.oldPassword,
          event.newPassword,
          event.newPassword,
        );
        emit(AuthSuccess(currentUser));
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

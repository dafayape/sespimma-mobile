import 'package:flutter_bloc/flutter_bloc.dart';

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
  }

  void _onAutoLoginRequested(
    AutoLoginRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthSuccess(event.user));
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
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      emit(AuthFailure(errorMessage));
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

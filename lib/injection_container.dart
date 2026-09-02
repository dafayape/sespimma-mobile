import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'core/local_database_helper.dart';
import 'core/network/certificate_pinning_interceptor.dart';
import 'core/utils/app_logger.dart';
import 'features/attendance/data/datasources/kegiatan_remote_data_source.dart';
import 'features/attendance/data/datasources/absensi_remote_data_source.dart';
import 'features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'features/assessment/data/datasources/inbox_remote_data_source.dart';
import 'features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'features/assignment/data/datasources/assignment_remote_data_source.dart';
import 'features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'features/report/data/datasources/report_remote_data_source.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source_mock.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

final sl = GetIt.instance;

/// Dispatches the single, consistent "force logout" trigger (see
/// `ForceLogoutRequested` doc) from this interceptor's refresh-failure
/// path. `AuthBloc` is registered as a lazy singleton (not a factory)
/// specifically so `sl<AuthBloc>()` here resolves to the SAME instance
/// `main.dart`'s `BlocProvider(create: (_) => di.sl<AuthBloc>())` hands to
/// the widget tree — a factory would hand back an orphaned instance no
/// screen is listening to. This interceptor runs outside the widget tree
/// and has no BuildContext, so GetIt is the only way to reach it.
void _forceLogout() {
  try {
    final authBloc = sl<AuthBloc>();
    if (authBloc.state is AuthSuccess) {
      authBloc.add(const ForceLogoutRequested());
    }
  } catch (e) {
    developer.log(
      '_forceLogout: failed to dispatch ForceLogoutRequested: $e',
      name: 'DioInterceptor',
    );
  }
}

Future<void> init() async {
  await _initExternal();
  await _initCore();

  _initFeatures();
}

Future<void> _initExternal() async {
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: dotenv.env['API_BASE_URL'] ?? '',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );

    // Certificate pinning: no-ops (with a logged warning) until a real
    // production fingerprint is filled in — see file for reasoning.
    dio.interceptors.add(CertificatePinningGuardInterceptor());

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          developer.log('onRequest interceptor: path=${options.path}', name: 'DioInterceptor');
          if (!options.path.contains('/auth/login') &&
              !options.path.contains('/auth/refresh-token')) {
            final authLocalDataSource = sl<AuthLocalDataSource>();
            try {
              final token = await authLocalDataSource.getAccessToken();
              developer.log('onRequest token resolved: ${token != null ? "YES" : "NO"}', name: 'DioInterceptor');
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (e) {
              developer.log('onRequest error reading token: $e', name: 'DioInterceptor');
            }
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 &&
              !e.requestOptions.path.contains('/auth/login') &&
              !e.requestOptions.path.contains('/auth/logout') &&
              !e.requestOptions.path.contains('/auth/refresh-token')) {
            final authLocalDataSource = sl<AuthLocalDataSource>();
            final refreshToken = await authLocalDataSource.getRefreshToken();

            if (refreshToken != null) {
              try {
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: dotenv.env['API_BASE_URL'] ?? '',
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 15),
                    contentType: 'application/json',
                  ),
                );

                final response = await refreshDio.post(
                  '/auth/refresh-token',
                  data: {'refresh_token': refreshToken},
                );

                if (response.statusCode == 200 && response.data != null) {
                  final newAccessToken = response.data['access_token'] as String;

                  await authLocalDataSource.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: refreshToken,
                  );

                  final options = e.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';

                  final cloneResponse = await dio.fetch(options);
                  return handler.resolve(cloneResponse);
                }
              } catch (refreshError) {
                await authLocalDataSource.clearTokens();
                _forceLogout();
              }
            } else {
              await authLocalDataSource.clearTokens();
              _forceLogout();
            }
          }
          return handler.next(e);
        },
      ),
    );
    dio.interceptors.add(
      TalkerDioLogger(
        talker: talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseMessage: true,
          printErrorMessage: true,
        ),
      ),
    );

    return dio;
  });
}

Future<void> _initCore() async {
  final dbHelper = LocalDatabaseHelper.instance;
  await dbHelper.database;

  sl.registerLazySingleton<LocalDatabaseHelper>(() => dbHelper);
}

void _initFeatures() {
  _initAuthFeature();
  _initAbsensiFeature();
  _initPenilaianFeature();
}

void _initAuthFeature() {
  // Lazy singleton (not a factory): this must be the SAME instance the
  // widget tree's BlocProvider uses, so that the Dio interceptor above
  // (which has no BuildContext and can only reach it via `sl<AuthBloc>()`)
  // dispatches ForceLogoutRequested to the bloc a top-level listener is
  // actually watching, rather than an unrelated throwaway instance.
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc(
    loginUseCase: sl(),
    authRepository: sl(),
  ));

  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  final bool useDummy = dotenv.env['USE_DUMMY_DATA'] == 'true';

  if (useDummy) {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceMock(),
    );
  } else {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(dio: sl()),
    );
  }

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl()),
  );
}

void _initAbsensiFeature() {
  sl.registerLazySingleton<KegiatanRemoteDataSource>(
    () => KegiatanRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<AbsensiRemoteDataSource>(
    () => AbsensiRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSourceImpl(dio: sl()),
  );
}

void _initPenilaianFeature() {
  sl.registerLazySingleton<InboxRemoteDataSource>(
    () => InboxRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<AssessmentRemoteDataSource>(
    () => AssessmentRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<AssignmentRemoteDataSource>(
    () => AssignmentRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSource(dio: sl()),
  );
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSource(dio: sl()),
  );
}

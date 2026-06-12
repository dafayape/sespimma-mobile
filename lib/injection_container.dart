import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'core/local_database_helper.dart';
import 'core/utils/app_logger.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/datasources/auth_remote_data_source_mock.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

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

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final authLocalDataSource = sl<AuthLocalDataSource>();
          final token = await authLocalDataSource.getAccessToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await sl<AuthLocalDataSource>().clearTokens();
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
  sl.registerFactory<AuthBloc>(() => AuthBloc(loginUseCase: sl()));

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

void _initAbsensiFeature() {}

void _initPenilaianFeature() {}

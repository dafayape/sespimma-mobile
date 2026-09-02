import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sespimma/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/auth/domain/repositories/auth_repository.dart';
import 'package:sespimma/features/auth/domain/usecases/login_usecase.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_event.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockLoginUseCase mockLoginUseCase;
  late MockAuthRepository mockAuthRepository;

  const tUser = UserEntity(
    userId: '1',
    name: 'Test User',
    roleId: 'siswa',
    pokjar: 'POKJAR I',
    nrp: '12345678',
    nosis: 'SD-01',
    pangkat: 'AKP',
    angkatan: '75',
    agama: 'Islam',
    jenisKelamin: 'Laki-laki',
    jabatan: '-',
    noSerdik: 'SD-01',
    nik: '1234567890',
    jabatanSenat: '-',
    tempatLahir: 'Jakarta',
    noHandphone: '08123456789',
    pendidikanTerakhir: 'S1',
    alamatLengkap: 'Jl. Test',
    email: 'test@example.com',
    noTelepon: '08123456789',
    kelompok: 'A',
    diktukAwal: 'SIP',
    tahunDiktuk: '2015',
    personel: 'Ya',
    satker: 'Polrestabes',
    eselon: '-',
    golongan: '-',
    nilaiAkademik: 80.0,
    nilaiMental: 80.0,
    nilaiJasmani: 80.0,
    serdikId: '1',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockAuthRepository = MockAuthRepository();
  });

  group('AuthBloc - Active Session & Force Login', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(() => mockLoginUseCase.execute(
              nrp: '12345678',
              password: 'password123',
              fcmToken: 'DUMMY',
              force: false,
            )).thenAnswer((_) async => tUser);
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );
      },
      act: (bloc) => bloc.add(const LoginSubmitted(
        nrp: '12345678',
        password: 'password123',
        fcmToken: 'DUMMY',
        force: false,
      )),
      expect: () => [
        AuthLoading(),
        const AuthSuccess(tUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure(isSessionConflict: true)] when ActiveSessionException is thrown',
      build: () {
        when(() => mockLoginUseCase.execute(
              nrp: '12345678',
              password: 'password123',
              fcmToken: 'DUMMY',
              force: false,
            )).thenThrow(ActiveSessionException('Akun sedang digunakan di perangkat lain.'));
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );
      },
      act: (bloc) => bloc.add(const LoginSubmitted(
        nrp: '12345678',
        password: 'password123',
        fcmToken: 'DUMMY',
        force: false,
      )),
      expect: () => [
        AuthLoading(),
        const AuthFailure(
          'Akun sedang digunakan di perangkat lain.',
          isSessionConflict: true,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when force login succeeds after active session conflict',
      build: () {
        when(() => mockLoginUseCase.execute(
              nrp: '12345678',
              password: 'password123',
              fcmToken: 'DUMMY',
              force: true,
            )).thenAnswer((_) async => tUser);
        return AuthBloc(
          loginUseCase: mockLoginUseCase,
          authRepository: mockAuthRepository,
        );
      },
      act: (bloc) => bloc.add(const LoginSubmitted(
        nrp: '12345678',
        password: 'password123',
        fcmToken: 'DUMMY',
        force: true,
      )),
      expect: () => [
        AuthLoading(),
        const AuthSuccess(tUser),
      ],
    );
  });
}

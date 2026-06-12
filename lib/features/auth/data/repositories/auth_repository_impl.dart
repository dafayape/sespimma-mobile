import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/auth/domain/repositories/auth_repository.dart';
import 'package:sespimma/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sespimma/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sespimma/features/auth/data/models/login_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<UserEntity> login({
    required String nrp,
    required String password,
    required String fcmToken,
  }) async {
    final loginResponse = await remoteDataSource.login(
      LoginRequest(nrp: nrp, password: password, fcmToken: fcmToken),
    );

    await localDataSource.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    return UserEntity(
      userId: loginResponse.userId,
      name: loginResponse.name,
      roleId: loginResponse.roleId,
      pokjar: loginResponse.pokjar,
      nrp: loginResponse.nrp,
      nosis: loginResponse.nosis,
      pangkat: loginResponse.pangkat,
      angkatan: loginResponse.angkatan,
      agama: loginResponse.agama,
      jenisKelamin: loginResponse.jenisKelamin,
      jabatan: loginResponse.jabatan,
      tanggalLahir: loginResponse.tanggalLahir,
      noSerdik: loginResponse.noSerdik,
      nik: loginResponse.nik,
      jabatanSenat: loginResponse.jabatanSenat,
      tempatLahir: loginResponse.tempatLahir,
      noHandphone: loginResponse.noHandphone,
      pendidikanTerakhir: loginResponse.pendidikanTerakhir,
      alamatLengkap: loginResponse.alamatLengkap,
      email: loginResponse.email,
      noTelepon: loginResponse.noTelepon,
      kelompok: loginResponse.kelompok,
      diktukAwal: loginResponse.diktukAwal,
      tahunDiktuk: loginResponse.tahunDiktuk,
      personel: loginResponse.personel,
      satker: loginResponse.satker,
      eselon: loginResponse.eselon,
      golongan: loginResponse.golongan,
      isNakApproved: loginResponse.isNakApproved,
      nilaiAkademik: loginResponse.nilaiAkademik,
      nilaiMental: loginResponse.nilaiMental,
      nilaiJasmani: loginResponse.nilaiJasmani,
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearTokens();
  }
}

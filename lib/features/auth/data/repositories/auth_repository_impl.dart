import 'dart:convert';
import 'package:sespimma/core/services/background_location_service.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/auth/domain/repositories/auth_repository.dart';
import 'package:sespimma/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sespimma/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sespimma/features/auth/data/models/login_request.dart';
import 'package:sespimma/features/attendance/data/services/location_sync_service.dart';

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
    bool force = false,
  }) async {
    final loginResponse = await remoteDataSource.login(
      LoginRequest(
        nrp: nrp,
        password: password,
        fcmToken: fcmToken,
        force: force,
      ),
    );

    const allowedMobileRoles = {'siswa', 'serdik', 'gadik', 'patun', 'korsis', 'pimpinan'};
    final role = loginResponse.roleId.toLowerCase();

    if (!allowedMobileRoles.contains(role)) {
      throw Exception(
        'Akun ini hanya dapat diakses melalui web.',
      );
    }

    await localDataSource.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
    );

    final user = UserEntity(
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
      serdikId: loginResponse.serdikId,
      profilePhoto: loginResponse.profilePhoto,
    );

    try {
      await localDataSource.saveUserJson(json.encode(_userToMap(user)));
    } catch (_) {}

    return user;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await localDataSource.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    try {
      LocationSyncService().stopSyncing();
    } catch (_) {}
    try {
      await BackgroundLocationService.stop();
    } catch (_) {}
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Ignored to ensure local token cleanup still succeeds even if offline
    } finally {
      await localDataSource.clearTokens();
    }
  }

  @override
  Future<void> updateProfilePhoto(String photoPath) async {
    await remoteDataSource.updateProfilePhoto(photoPath);
  }

  @override
  Future<void> deleteProfilePhoto() async {
    await remoteDataSource.deleteProfilePhoto();
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    await remoteDataSource.changePassword(currentPassword, newPassword, confirmPassword);
    await localDataSource.clearSavedPassword();
  }

  @override
  Future<UserEntity?> getSavedUser() async {
    try {
      final userJson = await localDataSource.getUserJson();
      if (userJson != null) {
        final map = json.decode(userJson) as Map<String, dynamic>;
        final user = _userFromMap(map);
        const allowedMobileRoles = {'siswa', 'serdik', 'gadik', 'patun', 'korsis', 'pimpinan'};
        if (allowedMobileRoles.contains(user.roleId.toLowerCase())) {
          return user;
        } else {
          await localDataSource.clearTokens();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<UserEntity> fetchFreshProfile() async {
    final loginResponse = await remoteDataSource.getProfile();

    final user = UserEntity(
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
      serdikId: loginResponse.serdikId,
      profilePhoto: loginResponse.profilePhoto,
    );

    try {
      await localDataSource.saveUserJson(json.encode(_userToMap(user)));
    } catch (_) {}

    return user;
  }

  Map<String, dynamic> _userToMap(UserEntity user) {
    return {
      'userId': user.userId,
      'name': user.name,
      'roleId': user.roleId,
      'pokjar': user.pokjar,
      'nrp': user.nrp,
      'nosis': user.nosis,
      'pangkat': user.pangkat,
      'angkatan': user.angkatan,
      'agama': user.agama,
      'jenisKelamin': user.jenisKelamin,
      'jabatan': user.jabatan,
      'tanggalLahir': user.tanggalLahir,
      'umur': user.umur,
      'isNakApproved': user.isNakApproved,
      'profilePhoto': user.profilePhoto,
      'noSerdik': user.noSerdik,
      'nik': user.nik,
      'jabatanSenat': user.jabatanSenat,
      'tempatLahir': user.tempatLahir,
      'noHandphone': user.noHandphone,
      'pendidikanTerakhir': user.pendidikanTerakhir,
      'alamatLengkap': user.alamatLengkap,
      'email': user.email,
      'noTelepon': user.noTelepon,
      'kelompok': user.kelompok,
      'diktukAwal': user.diktukAwal,
      'tahunDiktuk': user.tahunDiktuk,
      'personel': user.personel,
      'satker': user.satker,
      'eselon': user.eselon,
      'golongan': user.golongan,
      'nilaiAkademik': user.nilaiAkademik,
      'nilaiMental': user.nilaiMental,
      'nilaiJasmani': user.nilaiJasmani,
      'serdikId': user.serdikId,
    };
  }

  UserEntity _userFromMap(Map<String, dynamic> map) {
    return UserEntity(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      roleId: map['roleId'] ?? '',
      pokjar: map['pokjar'] ?? '',
      nrp: map['nrp'] ?? '',
      nosis: map['nosis'] ?? '',
      pangkat: map['pangkat'] ?? '',
      angkatan: map['angkatan'] ?? '',
      agama: map['agama'] ?? '',
      jenisKelamin: map['jenisKelamin'] ?? '',
      jabatan: map['jabatan'] ?? '',
      tanggalLahir: map['tanggalLahir'],
      umur: map['umur'],
      isNakApproved: map['isNakApproved'],
      profilePhoto: map['profilePhoto'],
      noSerdik: map['noSerdik'] ?? '',
      nik: map['nik'] ?? '',
      jabatanSenat: map['jabatanSenat'] ?? '',
      tempatLahir: map['tempatLahir'] ?? '',
      noHandphone: map['noHandphone'] ?? '',
      pendidikanTerakhir: map['pendidikanTerakhir'] ?? '',
      alamatLengkap: map['alamatLengkap'] ?? '',
      email: map['email'] ?? '',
      noTelepon: map['noTelepon'] ?? '',
      kelompok: map['kelompok'] ?? '',
      diktukAwal: map['diktukAwal'] ?? '',
      tahunDiktuk: map['tahunDiktuk'] ?? '',
      personel: map['personel'] ?? '',
      satker: map['satker'] ?? '',
      eselon: map['eselon'] ?? '',
      golongan: map['golongan'] ?? '',
      nilaiAkademik: (map['nilaiAkademik'] as num?)?.toDouble() ?? 0.0,
      nilaiMental: (map['nilaiMental'] as num?)?.toDouble() ?? 0.0,
      nilaiJasmani: (map['nilaiJasmani'] as num?)?.toDouble() ?? 0.0,
      serdikId: map['serdikId'],
    );
  }
}

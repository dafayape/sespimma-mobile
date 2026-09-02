import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

class ActiveSessionException implements Exception {
  final String message;
  ActiveSessionException(this.message);

  @override
  String toString() => message;
}

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<LoginResponse> getProfile();
  Future<void> logout();
  Future<void> updateProfilePhoto(String photoPath);
  Future<void> deleteProfilePhoto();
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'nrp_nip': request.nrp,
          'password': request.password,
          if (request.fcmToken.isNotEmpty) 'fcm_token': request.fcmToken,
          'device': 'MOBILE',
          'force': request.force,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          (data['token'] != null || data['access_token'] != null)) {
        return LoginResponse.fromJson(_normalize(data));
      }

      final message = (data is Map)
          ? (data['error'] ?? data['message'] ?? 'Login failed')
          : 'Login failed';
      throw Exception(message);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final errorMsg = (data['error'] ?? data['message'] ?? 'Server error').toString();
        final isConflict = e.response?.statusCode == 409 ||
            data['is_active_session'] == true ||
            errorMsg.contains('sedang digunakan');
        if (isConflict) {
          throw ActiveSessionException(errorMsg);
        }
        throw Exception(errorMsg);
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout');
      }

      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      if (e is ActiveSessionException) rethrow;
      throw Exception(e.toString());
    }
  }

  @override
  Future<LoginResponse> getProfile() async {
    try {
      final response = await dio.get('/profile');
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final userMap = (data['user'] as Map?) ?? const {};
        final dataMap = (data['data'] as Map?) ?? const {};

        final photo = userMap['foto_profil'] ?? dataMap['foto_profil'] ?? dataMap['profile_photo'] ?? '';

        final merged = <String, dynamic>{
          'user': {
            ...dataMap,
            ...userMap,
            'foto_profil': photo,
            'profile_photo': photo,
          }
        };

        return LoginResponse.fromJson(_normalize(merged));
      }
      throw Exception('Gagal memuat profil terbaru');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(data['error'] ?? data['message'] ?? 'Server error');
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(data['error'] ?? data['message'] ?? 'Server error');
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateProfilePhoto(String photoPath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath),
        'label': 'Foto Profil',
      });
      await dio.post('/profile/foto', data: formData);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(
          data['error'] ?? data['message'] ?? 'Gagal mengunggah foto profil',
        );
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteProfilePhoto() async {
    try {
      await dio.delete('/profile/foto');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(
          data['error'] ?? data['message'] ?? 'Gagal menghapus foto profil',
        );
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      await dio.patch(
        '/profile/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': confirmPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(
          data['error'] ?? data['message'] ?? 'Gagal mengubah kata sandi',
        );
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Map<String, dynamic> _normalize(Map data) {
    final userMap = (data['user'] as Map?) ?? const {};
    final dataMap = (data['data'] as Map?) ?? const {};
    final roleDataMap = (data['role_data'] as Map?) ?? const {};
    final token = data['access_token'] ?? data['token'];

    final user = <String, dynamic>{
      ...roleDataMap,
      ...dataMap,
      ...userMap,
    };

    final roleRaw = (user['role'] ?? user['role_id'])?.toString();
    final roleMapped = _mapRole(roleRaw);

    final String jabatanVal = (user['jabatan'] ??
            user['jabatan_struktural'] ??
            user['jabatan_kepanitiaan'])
        ?.toString() ??
        '-';

    return {
      'user_id': (user['user_id'] ?? user['id'])?.toString() ?? '-',
      'name': user['nama_lengkap'] ?? user['nama'] ?? user['name'] ?? user['email'] ?? '-',
      'role_id': roleMapped,
      'pokjar': user['pokjar'] ?? user['kelompok_kelas'] ?? '-',
      'nrp': user['nrp'] ?? user['nrp_nip'] ?? '-',
      'nosis': user['nosis'] ?? '-',
      'pangkat': user['pangkat'] ?? '-',
      'angkatan': user['angkatan'] ?? '-',
      'agama': user['agama'] ?? '-',
      'jenis_kelamin': user['jenis_kelamin'] ?? '-',
      'jabatan': jabatanVal,
      'no_serdik': user['no_serdik'] ?? user['nosis'] ?? '-',
      'nik': user['nik'] ?? '-',
      'jabatan_senat': user['jabatan_senat'] ?? user['peran_pengasuhan'] ?? user['jabatan_kepanitiaan'] ?? '-',
      'tempat_lahir': user['tempat_lahir'] ?? '-',
      'no_handphone': user['no_handphone'] ?? '-',
      'pendidikan_terakhir': user['pendidikan_terakhir'] ?? '-',
      'alamat_lengkap': user['alamat_lengkap'] ?? user['alamat'] ?? '-',
      'email': user['email'] ?? '-',
      'no_telepon': user['no_telepon'] ?? '-',
      'kelompok': user['kelompok'] ?? user['pokjar'] ?? user['kelompok_kelas'] ?? '-',
      'diktuk_awal': user['diktuk_awal'] ?? '-',
      'tahun_diktuk': user['tahun_diktuk']?.toString() ?? '-',
      'personel': (user['personel'] ?? user['is_personel'])?.toString() ?? '-',
      'satker': user['satker'] ?? '-',
      'tanggal_lahir': user['tanggal_lahir'] ?? '1990-01-01',
      'eselon': user['eselon'] ?? '-',
      'golongan': user['golongan'] ?? '-',
      'is_nak_approved': user['is_nak_approved'] ?? false,
      'nilai_akademik': (user['nilai_akademik'] as num?)?.toDouble() ?? 0.0,
      'nilai_mental': (user['nilai_mental'] as num?)?.toDouble() ?? 0.0,
      'nilai_jasmani': (user['nilai_jasmani'] as num?)?.toDouble() ?? 0.0,
      'serdik_id': user['serdik_id']?.toString(),
      'profile_photo': user['profile_photo'] ?? user['foto_profil'] ?? user['profilePhoto'] ?? '',
      'access_token': token,
      'refresh_token': data['refresh_token'] ?? token,
    };
  }

  /// Menerjemahkan peran dari backend ke kosakata internal aplikasi ini.
  ///
  /// Backend menyeragamkan nama perannya (admin+superadmin melebur menjadi
  /// `operator`, `serdik` menjadi `peserta_didik`, dan seterusnya). Aplikasi ini
  /// masih memakai sebutan lamanya di puluhan tempat — navigasi, layar profil,
  /// FAQ — dan menerjemahkan di satu gerbang jauh lebih aman daripada menyisir
  /// semuanya.
  ///
  /// Nama lama tetap didaftar supaya versi aplikasi ini juga tetap bekerja
  /// terhadap server yang belum diperbarui.
  String _mapRole(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'peserta_didik':
      case 'serdik':
      case 'students':
        return 'siswa';
      case 'operator':
      case 'admin':
      case 'superadmin':
        return 'operator';
      case 'kasespimma':
      case 'pimpinan':
        return 'pimpinan';
      case 'perwira_penuntun':
      case 'patun':
        return 'patun';
      case 'tenaga_pendidik':
      case 'gadik':
        return 'gadik';
      case 'korsis':
        return 'korsis';
      case 'developer':
        return 'developer';
      default:
        return role ?? '-';
    }
  }
}

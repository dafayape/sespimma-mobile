import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
  Future<void> logout();
  Future<void> updateProfilePhoto(String photoPath);
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'nrp_nip': request.nrp, 'password': request.password},
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map && (data['token'] != null || data['access_token'] != null)) {
        return LoginResponse.fromJson(_normalize(data));
      }

      final message = (data is Map)
          ? (data['error'] ?? data['message'] ?? 'Login failed')
          : 'Login failed';
      throw Exception(message);
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(data['error'] ?? data['message'] ?? 'Server error');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout');
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
        throw Exception(data['error'] ?? data['message'] ?? 'Gagal mengunggah foto profil');
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      await dio.patch('/profile/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final data = e.response!.data as Map;
        throw Exception(data['error'] ?? data['message'] ?? 'Gagal mengubah kata sandi');
      }
      throw Exception(e.message ?? 'Network error');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Map<String, dynamic> _normalize(Map data) {
    final user = (data['user'] as Map?) ?? const {};
    final token = data['access_token'] ?? data['token'];

    final roleRaw = (user['role'] ?? user['role_id'])?.toString();
    final roleMapped = _mapRole(roleRaw);

    return {
      'user_id': (user['user_id'] ?? user['id'])?.toString() ?? '-',
      'name': user['name'] ?? user['email'] ?? '-',
      'role_id': roleMapped,
      'pokjar': user['pokjar'] ?? '-',
      'nrp': user['nrp'] ?? user['nrp_nip'] ?? '-',
      'nosis': user['nosis'] ?? '-',
      'pangkat': user['pangkat'] ?? '-',
      'angkatan': user['angkatan'] ?? '-',
      'agama': user['agama'] ?? '-',
      'jenis_kelamin': user['jenis_kelamin'] ?? '-',
      'jabatan': user['jabatan'] ?? '-',
      'no_serdik': user['no_serdik'] ?? user['nosis'] ?? '-',
      'nik': user['nik'] ?? '-',
      'jabatan_senat': user['jabatan_senat'] ?? '-',
      'tempat_lahir': user['tempat_lahir'] ?? '-',
      'no_handphone': user['no_handphone'] ?? '-',
      'pendidikan_terakhir': user['pendidikan_terakhir'] ?? '-',
      'alamat_lengkap': user['alamat_lengkap'] ?? user['alamat'] ?? '-',
      'email': user['email'] ?? '-',
      'no_telepon': user['no_telepon'] ?? '-',
      'kelompok': user['kelompok'] ?? user['pokjar'] ?? '-',
      'diktuk_awal': user['diktuk_awal'] ?? '-',
      'tahun_diktuk': user['tahun_diktuk']?.toString() ?? '-',
      'personel': user['personel']?.toString() ?? '-',
      'satker': user['satker'] ?? '-',
      'tanggal_lahir': user['tanggal_lahir'] ?? '1990-01-01',
      'eselon': user['eselon'] ?? '-',
      'golongan': user['golongan'] ?? '-',
      'is_nak_approved': user['is_nak_approved'] ?? false,
      'nilai_akademik': (user['nilai_akademik'] as num?)?.toDouble() ?? 0.0,
      'nilai_mental': (user['nilai_mental'] as num?)?.toDouble() ?? 0.0,
      'nilai_jasmani': (user['nilai_jasmani'] as num?)?.toDouble() ?? 0.0,
      'serdik_id': user['serdik_id']?.toString(),
      'access_token': token,
      'refresh_token': data['refresh_token'] ?? token,
    };
  }

  String _mapRole(String? role) {
    switch (role) {
      case 'serdik':
      case 'students':
        return 'siswa';
      case 'admin':
        return 'operator';
      default:
        return role ?? '-';
    }
  }
}

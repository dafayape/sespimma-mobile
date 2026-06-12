import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponse> login(LoginRequest request);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  const AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        '/login',
        data: {'nrp_nip': request.nrp, 'password': request.password},
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map && data['token'] != null) {
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

  Map<String, dynamic> _normalize(Map data) {
    final user = (data['user'] as Map?) ?? const {};
    final token = data['token'];

    return {
      'user_id': user['id']?.toString() ?? '-',
      'name': user['name'] ?? user['email'] ?? '-',
      'role_id': _mapRole(user['role']?.toString()),
      'pokjar': user['pokjar'] ?? '-',
      'nrp': user['nrp_nip'] ?? '-',
      'pangkat': user['pangkat'] ?? '-',
      'angkatan': user['angkatan'] ?? '-',
      'agama': user['agama'] ?? '-',
      'jabatan': user['jabatan'] ?? '-',
      'email': user['email'] ?? '-',
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

import 'package:dio/dio.dart';

class AbsensiRemoteDataSource {
  final Dio dio;

  AbsensiRemoteDataSource({required this.dio});

  /// Submits attendance check-in to the backend.
  /// Returns the response map with status, is_late, datetime, activity_name.
  /// Throws on error.
  Future<Map<String, dynamic>> checkIn({
    required String kegiatanId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await dio.post(
      '/mobile/absensi',
      data: {
        'kegiatan_id': kegiatanId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// Submits student leave request (izin) to the backend.
  /// Throws on error.
  Future<void> submitIzin({
    required String kegiatanId,
    required String serdikId,
    required DateTime startTime,
    required DateTime endTime,
    required String description,
    required String filePath,
    required String izinType,
  }) async {
    final formData = FormData.fromMap({
      'kegiatan_id': kegiatanId,
      'serdik_id': serdikId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'description': description,
      'izin_type': izinType,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    await dio.post(
      '/izin',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await dio.get('/api/mobile/attendance/history');
      if (response.data != null && response.data['data'] != null) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      }
      return [];
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Gagal mengambil riwayat absensi');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

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
}

import 'package:dio/dio.dart';

class ReportRemoteDataSource {
  final Dio dio;

  const ReportRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> getLaporanPerkembangan(String serdikId) async {
    try {
      final response = await dio.get('/laporan/perkembangan/$serdikId');
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Failed to load report data');
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
}

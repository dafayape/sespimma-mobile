import 'package:dio/dio.dart';

class DashboardRemoteDataSource {
  final Dio dio;

  DashboardRemoteDataSource({required this.dio});

  Future<Map<String, dynamic>> getSerdikDashboard() async {
    try {
      final response = await dio.get('/mobile/beranda');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to load dashboard data');
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

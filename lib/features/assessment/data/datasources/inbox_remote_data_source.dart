import 'package:dio/dio.dart';
import '../models/korsis_inbox_mock_data.dart';

class InboxRemoteDataSource {
  final Dio dio;

  InboxRemoteDataSource({required this.dio});

  Future<List<InboxItem>> getInbox({String? pokjar, String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      
      queryParams['status'] = status ?? 'pending';
      
      if (pokjar != null && pokjar != 'Semua Pokjar') {
        queryParams['pokjar'] = pokjar;
      }

      final response = await dio.get(
        '/inbox',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final rawData = response.data;
        final List<dynamic> dataList;
        if (rawData is Map && rawData['data'] is List) {
          dataList = rawData['data'];
        } else if (rawData is List) {
          dataList = rawData;
        } else {
          throw Exception('Unexpected response format');
        }
        return dataList.map((json) => InboxItem.fromJson(json)).toList();
      }
      throw Exception('Failed to load inbox data');
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

  Future<void> updateStatus(String id, String status) async {
    try {
      final response = await dio.put(
        '/korsis/inbox/$id/status',
        data: {'status': status},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update status');
      }
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

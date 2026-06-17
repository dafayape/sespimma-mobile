import 'package:dio/dio.dart';

class AssessmentRemoteDataSource {
  final Dio dio;

  AssessmentRemoteDataSource({required this.dio});

  Future<List<Map<String, dynamic>>> getStudents({String? search, String? pokjar}) async {
    try {
      final params = <String, dynamic>{
        'limit': 1000,
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      final response = await dio.get('/students', queryParameters: params);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['data'] is List) {
          final List<dynamic> list = data['data'];
          return list.map((json) => Map<String, dynamic>.from(json)).toList();
        }
      }
      throw Exception('Failed to load students');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<int>> getGradedStatus(String category) async {
    try {
      final response = await dio.get('/assessment/graded-status', queryParameters: {'category': category});
      if (response.statusCode == 200 && response.data is Map) {
        final List<dynamic> list = response.data['graded_serdik_ids'] ?? [];
        return list.map((id) => id as int).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getAcademic(String noSerdik) async {
    final response = await dio.get('/assessment/academic/$noSerdik');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateAcademic(String noSerdik, Map<String, dynamic> data) async {
    await dio.put('/assessment/academic/$noSerdik', data: data);
  }

  Future<Map<String, dynamic>> getMental(String noSerdik) async {
    final response = await dio.get('/assessment/mental/$noSerdik');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateMental(String noSerdik, Map<String, dynamic> data) async {
    await dio.put('/assessment/mental/$noSerdik', data: data);
  }

  Future<Map<String, dynamic>> getPhysical(String noSerdik) async {
    final response = await dio.get('/assessment/physical/$noSerdik');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updatePhysical(String noSerdik, Map<String, dynamic> data) async {
    await dio.put('/assessment/physical/$noSerdik', data: data);
  }

  Future<Map<String, dynamic>> getHealth(String noSerdik) async {
    final response = await dio.get('/health/$noSerdik');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateHealthScoreA(String noSerdik, double score) async {
    await dio.put('/health/$noSerdik/score-a', data: {'score': score});
  }

  Future<void> updateHealthScoreB(String noSerdik, double score) async {
    await dio.put('/health/$noSerdik/score-b', data: {'score': score});
  }

  Future<void> createHealthRecord(String noSerdik, Map<String, dynamic> data) async {
    await dio.post('/health/$noSerdik/records', data: data);
  }
}

import 'package:dio/dio.dart';

class AssessmentRemoteDataSource {
  final Dio dio;

  AssessmentRemoteDataSource({required this.dio});

  Future<List<Map<String, dynamic>>> getStudents({String? search, String? pokjar, int? onlyActiveAngkatan}) async {
    try {
      final params = <String, dynamic>{
        'limit': 1000,
      };
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      if (onlyActiveAngkatan != null) {
        params['only_active_angkatan'] = onlyActiveAngkatan;
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

  Future<List<Map<String, dynamic>>> getAllMentalScores() async {
    try {
      final response = await dio.get('/assessment/mental');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data;
        return list.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      throw Exception('Failed to load all mental scores');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getPoints(String category) async {
    try {
      final response = await dio.get('/points/category/$category');
      if (response.statusCode == 200) {
        final List<dynamic> list = response.data;
        return list.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      throw Exception('Failed to load points for category $category');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> submitUserReward(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/user_rewards', data: data);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit user reward');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> submitPunishmentLog(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/punishment_logs', data: data);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to submit punishment log');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> submitPrestasiInput({
    required List<int> userIds,
    required List<int> itemIds,
    required String notes,
    required dynamic file,
  }) async {
    try {
      MultipartFile? multipartFile;
      if (file is String) {
        multipartFile = await MultipartFile.fromFile(
          file,
          filename: file.split('/').last,
        );
      } else if (file != null && file.path is String) {
        multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: (file.path as String).split('/').last,
        );
      }

      final mapData = <String, dynamic>{
        'targets': '[${userIds.join(",")}]',
        'items': '[${itemIds.join(",")}]',
        'notes': notes,
      };
      if (multipartFile != null) {
        mapData['file'] = multipartFile;
      }

      final formData = FormData.fromMap(mapData);

      final response = await dio.post('/mental/prestasi/input', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data?['message'] ?? 'Gagal menyimpan prestasi');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> submitPelanggaranInput({
    required List<int> userIds,
    required List<int> itemIds,
    required String notes,
    required dynamic file,
  }) async {
    try {
      MultipartFile? multipartFile;
      if (file is String) {
        multipartFile = await MultipartFile.fromFile(
          file,
          filename: file.split('/').last,
        );
      } else if (file != null && file.path is String) {
        multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: (file.path as String).split('/').last,
        );
      }

      final mapData = <String, dynamic>{
        'targets': '[${userIds.join(",")}]',
        'items': '[${itemIds.join(",")}]',
        'notes': notes,
      };
      if (multipartFile != null) {
        mapData['file'] = multipartFile;
      }

      final formData = FormData.fromMap(mapData);

      final response = await dio.post('/mental/pelanggaran/input', data: formData);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(response.data?['message'] ?? 'Gagal menyimpan pelanggaran');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, double>> getMentalRecapMap() async {
    try {
      final response = await dio.get(
        '/mental/prestasi/recap',
        queryParameters: {'limit': 1000, 'fast': 1},
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final List<dynamic> list = response.data['data'] ?? [];
        final map = <String, double>{};
        for (var item in list) {
          if (item is Map) {
            final uid = (item['user_id'] ?? item['serdik_id'] ?? item['id'])?.toString();
            final score = (item['nilai_mental'] ?? item['na'] ?? item['nilai_akhir'] ?? item['mental_score']) as num?;
            if (uid != null && score != null) {
              map[uid] = score.toDouble();
            }
          }
        }
        return map;
      }
    } catch (e) {
      // Gracefully ignore timeout or error, background load won't block UI
    }
    return {};
  }
}

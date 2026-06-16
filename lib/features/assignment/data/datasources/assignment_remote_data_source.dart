import 'package:dio/dio.dart';
import '../models/assignment_model.dart';

class AssignmentRemoteDataSource {
  final Dio dio;

  AssignmentRemoteDataSource({required this.dio});

  // Serdik (Student) endpoints
  Future<List<AssignmentModel>> getAssignments() async {
    try {
      final response = await dio.get('/assignments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AssignmentModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load assignments');
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

  Future<void> submitAssignment({
    required String assignmentId,
    required String fileName,
    required String fileUrl,
  }) async {
    try {
      final response = await dio.post(
        '/assignments/submissions',
        data: {
          'assignment_id': assignmentId,
          'file_name': fileName,
          'file_url': fileUrl,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to submit assignment');
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

  // Gadik (Teacher) endpoints
  Future<String> createAssignment({
    required String judul,
    required String jenisTugas,
    required String deadline,
    required String targetPokjar,
    required String instruksi,
    String? turunanTugas,
    String? fileName,
    String? fileUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'judul': judul,
        'jenis_tugas': jenisTugas,
        'deadline': deadline,
        'target_pokjar': targetPokjar,
        'instruksi': instruksi,
      };
      if (turunanTugas != null) data['turunan_tugas'] = turunanTugas;
      if (fileName != null) data['file_name'] = fileName;
      if (fileUrl != null) data['file_url'] = fileUrl;

      final response = await dio.post(
        '/gadik/assignments',
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['id'] as String;
      }
      throw Exception('Failed to create assignment');
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

  Future<List<Map<String, dynamic>>> getSubmissions(String assignmentId) async {
    try {
      final response = await dio.get('/gadik/assignments/$assignmentId/submissions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return List<Map<String, dynamic>>.from(data);
      }
      throw Exception('Failed to load submissions');
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

  Future<void> gradeSubmission({
    required String submissionId,
    required double nilaiAkhir,
    String? catatanPengajar,
    double? scoreMateri,
    double? scorePenulisan,
    double? scorePaparan,
    double? scoreKeaktifan,
    double? scoreUjian,
    double? scoreKeaktifanPerseorangan,
    double? scoreProdukPerseorangan,
    double? scoreTataRuang,
    bool isRemedial = false,
  }) async {
    try {
      final data = <String, dynamic>{
        'nilaiAkhir': nilaiAkhir,
        'isRemedial': isRemedial,
      };
      if (catatanPengajar != null) data['catatanPengajar'] = catatanPengajar;
      if (scoreMateri != null) data['scoreMateri'] = scoreMateri;
      if (scorePenulisan != null) data['scorePenulisan'] = scorePenulisan;
      if (scorePaparan != null) data['scorePaparan'] = scorePaparan;
      if (scoreKeaktifan != null) data['scoreKeaktifan'] = scoreKeaktifan;
      if (scoreUjian != null) data['scoreUjian'] = scoreUjian;
      if (scoreKeaktifanPerseorangan != null) {
        data['scoreKeaktifanPerseorangan'] = scoreKeaktifanPerseorangan;
      }
      if (scoreProdukPerseorangan != null) {
        data['scoreProdukPerseorangan'] = scoreProdukPerseorangan;
      }
      if (scoreTataRuang != null) data['scoreTataRuang'] = scoreTataRuang;

      final response = await dio.post(
        '/gadik/assignments/submissions/$submissionId/grade',
        data: data,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to grade submission');
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

  Future<List<AssignmentModel>> getGadikAssignments() async {
    try {
      final response = await dio.get('/gadik/assignments');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => AssignmentModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load gadik assignments');
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

  Future<void> deleteAssignment(String id) async {
    try {
      final response = await dio.delete('/gadik/assignments/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete assignment');
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

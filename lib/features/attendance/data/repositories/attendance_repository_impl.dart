import '../../domain/entities/attendance_entity.dart';
import '../../domain/entities/attendance_report_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<AttendanceEntity>> getAttendances() async {
    throw UnimplementedError();
  }

  @override
  Future<AttendanceEntity> getAttendanceDetail(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> submitAttendance(AttendanceEntity attendance) async {
    throw UnimplementedError();
  }

  @override
  Future<List<AttendanceReportEntity>> getReports(
    String pokjar, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await remoteDataSource.getReports(
      pokjar,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<AttendanceReportEntity> generateCurrentReport(String pokjar) async {
    return await remoteDataSource.generateCurrentReport(pokjar);
  }
}

import '../entities/attendance_entity.dart';
import '../entities/attendance_report_entity.dart';

abstract interface class AttendanceRepository {
  Future<List<AttendanceEntity>> getAttendances();
  Future<AttendanceEntity> getAttendanceDetail(String id);
  Future<void> submitAttendance(AttendanceEntity attendance);

  Future<List<AttendanceReportEntity>> getReports(
    String pokjar, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<AttendanceReportEntity> generateCurrentReport(String pokjar);
}

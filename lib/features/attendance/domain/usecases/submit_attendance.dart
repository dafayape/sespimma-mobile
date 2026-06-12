import 'package:sespimma/core/usecases/usecase.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

final class SubmitAttendance implements UseCase<void, AttendanceEntity> {
  final AttendanceRepository _repository;
  const SubmitAttendance(this._repository);

  @override
  Future<void> call(AttendanceEntity params) =>
      _repository.submitAttendance(params);
}

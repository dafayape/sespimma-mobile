import 'package:sespimma/core/usecases/usecase.dart';
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

final class GetAttendances
    implements UseCase<List<AttendanceEntity>, NoParams> {
  final AttendanceRepository _repository;
  const GetAttendances(this._repository);

  @override
  Future<List<AttendanceEntity>> call(NoParams params) =>
      _repository.getAttendances();
}

import 'package:sespimma/core/usecases/usecase.dart';
import '../entities/assignment_entity.dart';
import '../repositories/assignment_repository.dart';

final class GetAssignmentDetail implements UseCase<AssignmentEntity, String> {
  final AssignmentRepository _repository;
  const GetAssignmentDetail(this._repository);

  @override
  Future<AssignmentEntity> call(String params) =>
      _repository.getAssignmentDetail(params);
}

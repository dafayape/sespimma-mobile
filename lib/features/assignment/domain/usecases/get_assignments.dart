import 'package:sespimma/core/usecases/usecase.dart';
import '../entities/assignment_entity.dart';
import '../repositories/assignment_repository.dart';

final class GetAssignments
    implements UseCase<List<AssignmentEntity>, NoParams> {
  final AssignmentRepository _repository;
  const GetAssignments(this._repository);

  @override
  Future<List<AssignmentEntity>> call(NoParams params) =>
      _repository.getAssignments();
}

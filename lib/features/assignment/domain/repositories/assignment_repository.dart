import '../entities/assignment_entity.dart';

abstract interface class AssignmentRepository {
  Future<List<AssignmentEntity>> getAssignments();
  Future<AssignmentEntity> getAssignmentDetail(String id);
  Future<void> submitAssignment(AssignmentEntity assignment);
}

final class AssignmentEntity {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime? dueDate;
  final DateTime? submittedAt;
  final String? assignedTo;
  final String? assignedBy;
  final String? pokjar;
  final String? attachmentUrl;
  final double? score;

  const AssignmentEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
    this.submittedAt,
    this.assignedTo,
    this.assignedBy,
    this.pokjar,
    this.attachmentUrl,
    this.score,
  });
}

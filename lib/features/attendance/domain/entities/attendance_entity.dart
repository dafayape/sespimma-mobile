final class AttendanceEntity {
  final String id;
  final DateTime date;
  final String status;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? method;
  final String? note;

  const AttendanceEntity({
    required this.id,
    required this.date,
    required this.status,
    this.location,
    this.latitude,
    this.longitude,
    this.method,
    this.note,
  });
}

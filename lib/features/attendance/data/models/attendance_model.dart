import 'package:equatable/equatable.dart';

class AttendanceModel extends Equatable {
  final String id;
  final String userId;
  final String type;
  final String status;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final bool isLocationValid;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.isLocationValid = false,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isLocationValid: json['is_location_valid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'is_location_valid': isLocationValid,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? status,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    bool? isLocationValid,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLocationValid: isLocationValid ?? this.isLocationValid,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    status,
    timestamp,
    latitude,
    longitude,
    isLocationValid,
  ];
}

class AttendanceSummaryModel extends Equatable {
  final int presentCount;
  final int permissionCount;
  final int absentCount;

  const AttendanceSummaryModel({
    required this.presentCount,
    required this.permissionCount,
    required this.absentCount,
  });

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryModel(
      presentCount: json['present_count'] as int? ?? 0,
      permissionCount: json['permission_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'present_count': presentCount,
      'permission_count': permissionCount,
      'absent_count': absentCount,
    };
  }

  AttendanceSummaryModel copyWith({
    int? presentCount,
    int? permissionCount,
    int? absentCount,
  }) {
    return AttendanceSummaryModel(
      presentCount: presentCount ?? this.presentCount,
      permissionCount: permissionCount ?? this.permissionCount,
      absentCount: absentCount ?? this.absentCount,
    );
  }

  @override
  List<Object?> get props => [presentCount, permissionCount, absentCount];
}

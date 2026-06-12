import 'package:equatable/equatable.dart';
import '../../domain/entities/attendance_report_entity.dart';

abstract class PatunReportState extends Equatable {
  const PatunReportState();

  @override
  List<Object?> get props => [];
}

class PatunReportInitial extends PatunReportState {}

class PatunReportLoading extends PatunReportState {}

class PatunReportLoaded extends PatunReportState {
  final List<AttendanceReportEntity> reports;

  const PatunReportLoaded({required this.reports});

  @override
  List<Object?> get props => [reports];
}

class PatunReportError extends PatunReportState {
  final String message;

  const PatunReportError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PatunReportGeneratedSuccess extends PatunReportState {
  final String message;

  const PatunReportGeneratedSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

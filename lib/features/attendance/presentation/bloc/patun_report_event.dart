import 'package:equatable/equatable.dart';

abstract class PatunReportEvent extends Equatable {
  const PatunReportEvent();

  @override
  List<Object?> get props => [];
}

class FetchPatunReports extends PatunReportEvent {
  final String pokjar;
  final DateTime? startDate;
  final DateTime? endDate;

  const FetchPatunReports({required this.pokjar, this.startDate, this.endDate});

  @override
  List<Object?> get props => [pokjar, startDate, endDate];
}

class GenerateCurrentReport extends PatunReportEvent {
  final String pokjar;

  const GenerateCurrentReport({required this.pokjar});

  @override
  List<Object?> get props => [pokjar];
}

class CheckAutoGenerateReport extends PatunReportEvent {
  final String pokjar;

  const CheckAutoGenerateReport({required this.pokjar});

  @override
  List<Object?> get props => [pokjar];
}

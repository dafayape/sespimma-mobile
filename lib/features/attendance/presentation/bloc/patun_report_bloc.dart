import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/attendance_repository.dart';
import 'patun_report_event.dart';
import 'patun_report_state.dart';

class PatunReportBloc extends Bloc<PatunReportEvent, PatunReportState> {
  final AttendanceRepository repository;

  PatunReportBloc({required this.repository}) : super(PatunReportInitial()) {
    on<FetchPatunReports>(_onFetchPatunReports);
    on<GenerateCurrentReport>(_onGenerateCurrentReport);
    on<CheckAutoGenerateReport>(_onCheckAutoGenerateReport);
  }

  Future<void> _onFetchPatunReports(
    FetchPatunReports event,
    Emitter<PatunReportState> emit,
  ) async {
    emit(PatunReportLoading());
    try {
      final reports = await repository.getReports(
        event.pokjar,
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(PatunReportLoaded(reports: reports));
    } catch (e) {
      emit(PatunReportError(message: e.toString()));
    }
  }

  Future<void> _onGenerateCurrentReport(
    GenerateCurrentReport event,
    Emitter<PatunReportState> emit,
  ) async {
    final currentState = state;
    emit(PatunReportLoading());
    try {
      await repository.generateCurrentReport(event.pokjar);
      emit(
        const PatunReportGeneratedSuccess(
          message: 'Berhasil men-generate laporan kehadiran terkini.',
        ),
      );

      add(FetchPatunReports(pokjar: event.pokjar));
    } catch (e) {
      emit(PatunReportError(message: e.toString()));

      if (currentState is PatunReportLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onCheckAutoGenerateReport(
    CheckAutoGenerateReport event,
    Emitter<PatunReportState> emit,
  ) async {
    final now = DateTime.now();
    if (now.hour >= 23) {
      try {
        final reports = await repository.getReports(
          event.pokjar,
          startDate: DateTime(now.year, now.month, now.day),
          endDate: DateTime(now.year, now.month, now.day),
        );

        if (reports.isEmpty) {
          add(GenerateCurrentReport(pokjar: event.pokjar));
          return;
        }
      } catch (_) {}
    }

    add(FetchPatunReports(pokjar: event.pokjar));
  }
}

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/attendance/data/services/pdf_report_service.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/attendance/domain/entities/attendance_report_entity.dart';
import '../bloc/patun_report_bloc.dart';
import '../bloc/patun_report_event.dart';
import '../bloc/patun_report_state.dart';
import 'package:sespimma/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:sespimma/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:sespimma/injection_container.dart';

class PatunAttendanceReportScreen extends StatelessWidget {
  final String pokjar;

  const PatunAttendanceReportScreen({super.key, required this.pokjar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PatunReportBloc(
        repository: AttendanceRepositoryImpl(
          remoteDataSource: sl<AttendanceRemoteDataSource>(),
        ),
      )..add(CheckAutoGenerateReport(pokjar: pokjar)),
      child: _PatunAttendanceReportView(pokjar: pokjar),
    );
  }
}

class _PatunAttendanceReportView extends StatefulWidget {
  final String pokjar;

  const _PatunAttendanceReportView({required this.pokjar});

  @override
  State<_PatunAttendanceReportView> createState() =>
      _PatunAttendanceReportViewState();
}

class _PatunAttendanceReportViewState
    extends State<_PatunAttendanceReportView> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  bool _isGeneratingPdf = false;
  DateTimeRange? _selectedDateRange;

  void _generateReportForToday(BuildContext context) {
    HapticFeedback.mediumImpact();

    if (AttendanceZones.activeZones.isEmpty) {
      AppNotifier.showError(context, 'Tidak ada kegiatan aktif hari ini.');
      return;
    }

    context.read<PatunReportBloc>().add(
      GenerateCurrentReport(pokjar: widget.pokjar),
    );
  }

  void _generateAndDownloadPdf(
    BuildContext context,
    AttendanceReportEntity report,
  ) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    HapticFeedback.mediumImpact();
    AppNotifier.showSuccess(context, 'Membuat laporan PDF...');

    try {
      await PdfReportService.generateAndDownloadReport(
        pokjar: widget.pokjar,
        date: report.date,
        reportEntity: report,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppNotifier.showError(context, 'Gagal membuat laporan: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial =
        _selectedDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryNavy,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      if (!context.mounted) return;
      context.read<PatunReportBloc>().add(
        FetchPatunReports(
          pokjar: widget.pokjar,
          startDate: picked.start,
          endDate: picked.end,
        ),
      );
    }
  }

  void _clearDateRange(BuildContext context) {
    setState(() {
      _selectedDateRange = null;
    });
    context.read<PatunReportBloc>().add(
      FetchPatunReports(pokjar: widget.pokjar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PatunReportBloc, PatunReportState>(
      listener: (context, state) {
        if (state is PatunReportGeneratedSuccess) {
          AppNotifier.showSuccess(context, state.message);
        } else if (state is PatunReportError) {
          AppNotifier.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: _primaryNavy,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Laporan Kehadiran',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: AppDimensions.fontXxl,
            ),
          ),
          actions: [
            BlocBuilder<PatunReportBloc, PatunReportState>(
              builder: (context, state) {
                if (state is PatunReportLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(
                    Icons.autorenew_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Generate Laporan Terkini',
                  onPressed: () => _generateReportForToday(context),
                );
              },
            ),
            IconButton(
              icon: Icon(
                _selectedDateRange != null
                    ? Icons.calendar_month_rounded
                    : Icons.calendar_today_rounded,
                color: _selectedDateRange != null
                    ? Colors.tealAccent
                    : Colors.white,
              ),
              tooltip: 'Filter Tanggal',
              onPressed: () => _pickDateRange(context),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedDateRange != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.lg,
                  vertical: AppDimensions.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: Text(
                      '${DateFormat('dd MMM', 'id_ID').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDateRange!.end)}',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal,
                      ),
                    ),
                    backgroundColor: Colors.teal.shade50,
                    deleteIcon: Icon(
                      Icons.cancel,
                      size: AppDimensions.iconSm + 4,
                      color: Colors.teal.shade800,
                    ),
                    onDeleted: () => _clearDateRange(context),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      side: BorderSide(color: Colors.teal.shade100),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: BlocBuilder<PatunReportBloc, PatunReportState>(
                buildWhen: (previous, current) =>
                    current is PatunReportLoaded ||
                    current is PatunReportLoading ||
                    current is PatunReportError,
                builder: (context, state) {
                  if (state is PatunReportLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is PatunReportLoaded) {
                    if (state.reports.isEmpty) {
                      return Center(
                        child: Text(
                          _selectedDateRange != null
                              ? 'Tidak ada laporan pada tanggal tersebut'
                              : 'Belum ada laporan yang di-generate',
                          style: TextStyle(
                            color: Colors.blueGrey.shade400,
                            fontSize: AppDimensions.fontMd,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      itemCount: state.reports.length,
                      itemBuilder: (context, index) {
                        final report = state.reports[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateSection(report.date),
                            _buildReportCard(context, report),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    );
                  } else if (state is PatunReportError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(DateTime date) {
    final String dateStr = DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.md,
        left: AppDimensions.xs,
      ),
      child: Text(
        dateStr,
        style: TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w800,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, AttendanceReportEntity report) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: _isGeneratingPdf
            ? null
            : () => _generateAndDownloadPdf(context, report),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laporan Kegiatan Rutin',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm + 1,
                        fontWeight: FontWeight.w700,
                        color: _primaryNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dibuat otomatis secara objektif',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXs,
                        fontWeight: FontWeight.w400,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH.mm').format(report.date),
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w400,
                            color: Colors.blueGrey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: _isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.green,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        Icons.download_rounded,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

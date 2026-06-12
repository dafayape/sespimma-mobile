import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/attendance/presentation/pages/attendance_qr_scanner_screen.dart';
import 'package:sespimma/features/attendance/presentation/widgets/geofence_map_widget.dart';
import 'package:sespimma/features/attendance/presentation/widgets/zone_info_sheet.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/features/attendance/presentation/widgets/empty_zone_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/leave_form_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_status_chip.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_floating_info.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_action_buttons.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/attendance/data/services/location_sync_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isInRadius = false;
  bool _isGpsLoading = true;
  bool _hasGpsError = false;
  bool _isSubmitting = false;
  bool _isFakeGps = false;
  bool _isAttended = false;
  DateTime? _lastSubmitTime;

  List<AttendanceZone> _zones = AttendanceZones.activeZones;
  AttendanceZone? _activeZone;

  late final AnimationController _chipController;
  late final Animation<double> _chipScale;

  @override
  void initState() {
    super.initState();
    _chipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _chipScale = CurvedAnimation(
      parent: _chipController,
      curve: Curves.elasticOut,
    );

    LocationSyncService().startSyncing('202602003001');
  }

  @override
  void dispose() {
    LocationSyncService().stopSyncing();
    _chipController.dispose();
    super.dispose();
  }

  void _onLocationDetected(
    AttendanceZone? activeZone,
    double distance,
    bool isFakeGps,
  ) {
    final inRadius = activeZone != null;
    final changed = inRadius != _isInRadius;

    if (isFakeGps && !_isFakeGps) {
      HapticFeedback.heavyImpact();
      AppNotifier.showError(
        context,
        'Terdeteksi Manipulasi Lokasi (Fake GPS). Absensi diblokir!',
      );
    } else if (changed && !_isGpsLoading && !isFakeGps) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _activeZone = activeZone;
      _isInRadius = inRadius && !isFakeGps;
      _isFakeGps = isFakeGps;
      _isGpsLoading = false;
    });

    if (changed && !isFakeGps) {
      _chipController.forward(from: 0.0);
    }
  }

  Future<void> _openQRScanner() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const AttendanceQrScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final String scannedZoneId = result['zoneId'];
      final matchedZone = _zones
          .where((z) => z.id == scannedZoneId)
          .firstOrNull;

      if (matchedZone != null) {
        final bool isNotStarted = DateTime.now().isBefore(
          matchedZone.startTime,
        );
        if (isNotStarted) {
          AppNotifier.showWarning(context, 'Maaf kegiatan ini belum dimulai');
          return;
        }

        AppNotifier.showSuccess(
          context,
          'QR Code Valid: ${matchedZone.activityName}. Mengirim presensi...',
        );
        setState(() => _activeZone = matchedZone);
        _submitAttendance(fromQr: true);
      } else {
        AppNotifier.showError(
          context,
          'Kegiatan tidak ditemukan atau tidak aktif saat ini.',
        );
      }
    }
  }

  Future<void> _submitAttendance({bool fromQr = false}) async {
    final bool isNotStarted =
        _activeZone != null && DateTime.now().isBefore(_activeZone!.startTime);
    if (isNotStarted) {
      AppNotifier.showWarning(context, 'Maaf kegiatan ini belum dimulai');
      return;
    }

    if (_isSubmitting ||
        (!fromQr && !_isInRadius) ||
        _isFakeGps ||
        _isAttended) {
      return;
    }

    if (_isAttended) {
      AppNotifier.showWarning(
        context,
        'Anda sudah melakukan presensi untuk sesi ini.',
      );
      return;
    }

    final bool isAlpha =
        _activeZone != null && DateTime.now().isAfter(_activeZone!.cutoffTime);
    if (isAlpha) {
      HapticFeedback.vibrate();
      final punishmentCode = _activeZone!.isTraining
          ? 'P_D_12 (-0.80)'
          : 'P_D_05 (-0.90)';
      _showErrorDialog(
        'Absensi Ditutup',
        'Waktu toleransi kehadiran untuk sesi ini telah sepenuhnya berakhir. Status Anda otomatis tercatat sebagai TANPA KETERANGAN.\n\nSanksi pelanggaran: $punishmentCode',
      );
      return;
    }

    if (_lastSubmitTime != null) {
      HapticFeedback.vibrate();
      _showErrorDialog(
        'Absensi Ditolak',
        'Sistem mendeteksi Anda telah berhasil melakukan presensi pada sesi kegiatan ini.',
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    HapticFeedback.heavyImpact();

    setState(() {
      _isSubmitting = false;
      _lastSubmitTime = DateTime.now();
      _isAttended = true;
      PimpinanMockData.attendanceReportCount += 1;
    });

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";
    final activityName = _activeZone?.activityName ?? 'Kegiatan Presensi';

    bool isLate = _activeZone != null && now.isAfter(_activeZone!.deadline);
    bool isLateFromIzin = false;

    final approvedIzin = KorsisInboxMockData.items
        .where((i) => i.isIzin && i.status == 'approved')
        .firstOrNull;
    if (_activeZone != null &&
        approvedIzin != null &&
        approvedIzin.izinStartTime != null &&
        approvedIzin.izinEndTime != null) {
      final izinStartDt = DateTime(
        now.year,
        now.month,
        now.day,
        approvedIzin.izinStartTime!.hour,
        approvedIzin.izinStartTime!.minute,
      );
      final izinEndDt = DateTime(
        now.year,
        now.month,
        now.day,
        approvedIzin.izinEndTime!.hour,
        approvedIzin.izinEndTime!.minute,
      );

      if (_activeZone!.deadline.isAfter(izinStartDt) &&
              _activeZone!.deadline.isBefore(izinEndDt) ||
          _activeZone!.deadline.isAtSameMomentAs(izinStartDt)) {
        if (now.isAfter(izinEndDt)) {
          isLate = true;
          isLateFromIzin = true;
        } else {
          isLate = false;
        }
      }
    }

    PimpinanMockData.addAttendance({
      'id': 'att_${now.millisecondsSinceEpoch}',
      'title': activityName,
      'date': '${now.day}-${now.month}-${now.year}',
      'time': timeStr,
      'dateTime': now,
      'status': isLate ? 'Telat' : 'Hadir',
      'type': isLate ? 'telat' : 'hadir',
      'method': fromQr ? 'QR Code' : 'Geofencing',
      'verification': 'Valid',
      'location': _activeZone?.name ?? 'Lokasi Sespimma',
      'device': 'Perangkat Serdik',
      'image': 'assets/images/avatar.png',
      'waktuPelaksanaan': _activeZone != null
          ? '${_activeZone!.startTime.hour.toString().padLeft(2, '0')}.${_activeZone!.startTime.minute.toString().padLeft(2, '0')} - ${_activeZone!.endTime.hour.toString().padLeft(2, '0')}.${_activeZone!.endTime.minute.toString().padLeft(2, '0')}'
          : '-',
      'waktuBatasAbsen': _activeZone != null
          ? '${_activeZone!.deadline.hour.toString().padLeft(2, '0')}.${_activeZone!.deadline.minute.toString().padLeft(2, '0')}'
          : '-',
      'pembuatZona': _activeZone?.creator ?? '-',
    });

    if (isLate) {
      final actLower = activityName.toLowerCase();
      final isApelOrOlga =
          actLower.contains('apel pagi') ||
          actLower.contains('apel malam') ||
          actLower.contains('olahraga pagi') ||
          actLower.contains('olga pagi');
      String punishmentCode = 'P_D_02';
      double pointsToDeduct = -0.53;
      String desc = 'Terlambat mengikuti kegiatan kelas/ceramah/pengarahan';

      if (isLateFromIzin) {
        punishmentCode = 'P_D_03';
        pointsToDeduct = -0.50;
        desc =
            'Terlambat kembali pada waktu ijin/IBL tanpa alasan yang dapat dipertanggungjawabkan';
      } else if (isApelOrOlga) {
        punishmentCode = 'P_D_04';
        pointsToDeduct = -0.50;
        desc = 'Terlambat mengikuti apel/olahraga/kegiatan lain';
      } else if (fromQr || _isInRadius) {
        punishmentCode = 'P_D_01';
        pointsToDeduct = -0.50;
        desc = 'Terlambat mengikuti kegiatan yang telah ditentukan';
      }

      String sName = 'Dummy User';
      String sPangkat = 'AKP';
      String sNosis = '000000';
      String sPokjar = 'POKJAR I';

      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        sName = authState.user.name;
        sPangkat = authState.user.pangkat;
        sNosis = authState.user.noSerdik.isNotEmpty
            ? authState.user.noSerdik
            : authState.user.nrp;
        sPokjar = authState.user.pokjar.isNotEmpty
            ? authState.user.pokjar
            : 'POKJAR I';
      }

      KorsisInboxMockData.addRecord(
        InboxItem(
          id: 'auto_punish_${now.millisecondsSinceEpoch}',
          serdikName: sName,
          pangkat: sPangkat,
          nosis: sNosis,
          pokjar: sPokjar,
          isReward: false,
          senderName: 'Sistem (Otomatis)',
          timestamp: now,
          points: pointsToDeduct,
          description: desc,
          rewardPunishmentName: '$punishmentCode | PUNISHMENT | DISIPLIN',
          status: 'disetujui',
        ),
      );

      AppNotifier.showWarning(
        context,
        isLateFromIzin
            ? 'Tercatat masuk di jam $timeStr (Terlambat Izin) untuk $activityName.\nSanksi pelanggaran: $punishmentCode ($pointsToDeduct)'
            : 'Tercatat masuk di jam $timeStr (Terlambat) untuk $activityName.\nSanksi pelanggaran: $punishmentCode ($pointsToDeduct)',
      );
    } else {
      AppNotifier.showSuccess(
        context,
        'Berhasil absen di jam $timeStr untuk kegiatan $activityName.',
      );
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        title: Row(
          children: [
            const Icon(AppIcons.warningOctagonFill, color: AppColors.dangerRed),
            const SizedBox(width: AppDimensions.md),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'MENGERTI',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoneInfo(BuildContext context, [AttendanceZone? specificZone]) {
    final zoneToShow = specificZone ?? _activeZone;

    if (zoneToShow == null || _isGpsLoading) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXxl),
          ),
        ),
        builder: (sheetCtx) =>
            EmptyZoneSheet(onToggleMakerindo: _onToggleMakerindo),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      builder: (sheetCtx) => ZoneInfoSheet(
        zone: zoneToShow,
        onLeaveRequest: () {
          Navigator.pop(sheetCtx);
          _showLeaveForm(context);
        },
        onToggleMakerindo: _onToggleMakerindo,
      ),
    );
  }

  void _onToggleMakerindo(bool val) {
    Navigator.pop(context);
    setState(() {
      AttendanceZones.isMakerindoEnabled = val;
      _zones = AttendanceZones.activeZones;
    });
    HapticFeedback.mediumImpact();
    final status = val ? 'Diaktifkan' : 'Dinonaktifkan';
    if (val) {
      AppNotifier.showSuccess(context, 'Simulasi Zona Makerindo $status!');
    } else {
      AppNotifier.showWarning(context, 'Simulasi Zona Makerindo $status!');
    }
  }

  void _showLeaveForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      builder: (ctx) => LeaveFormSheet(
        onSuccess: () {
          AppNotifier.showSuccess(
            context,
            'Permohonan Izin Berhasil Diajukan ke Korsis.',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Zona',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_zones.isNotEmpty)
            IconButton(
              icon: const Icon(
                AppIcons.infoBold,
                size: AppDimensions.iconSm + 2,
              ),
              tooltip: 'Info Zona',
              splashRadius: AppDimensions.radiusXxl,
              onPressed: () {
                HapticFeedback.selectionClick();
                _showZoneInfo(context, _activeZone);
              },
            ),
        ],
      ),
      body: GeofenceMapWidget(
        zones: _zones,
        onLocationDetected: _onLocationDetected,
        onGpsStateChanged: (hasError) {
          if (mounted && _hasGpsError != hasError) {
            setState(() => _hasGpsError = hasError);
          }
        },
        onReload: () {
          setState(() => _zones = AttendanceZones.activeZones);
          AppNotifier.showSuccess(
            context,
            'Daftar Radius dan Geofence berhasil diperbarui!',
          );
        },
        onRadiusTap: (tappedZone) => _showZoneInfo(context, tappedZone),
        contentOverlay: Stack(
          children: [
            if (!_hasGpsError)
              Positioned(
                top: AppDimensions.lg,
                left: 0,
                right: 0,
                child: Center(
                  child: AttendanceStatusChip(
                    zones: _zones,
                    activeZone: _activeZone,
                    isGpsLoading: _isGpsLoading,
                    isFakeGps: _isFakeGps,
                    isInRadius: _isInRadius,
                    chipScale: _chipScale,
                  ),
                ),
              ),
            if (!_hasGpsError)
              Positioned(
                bottom: AppDimensions.xxxl,
                left: 0,
                right: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.lg,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child:
                                (_activeZone != null &&
                                    !_isGpsLoading &&
                                    _isInRadius &&
                                    !_isFakeGps)
                                ? AttendanceFloatingInfo(
                                    activeZone: _activeZone!,
                                    isInRadius: _isInRadius,
                                    onTapInfo: () => _showZoneInfo(context),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(width: AppDimensions.lg),
                          AttendanceActionButtons(
                            isAttended: _isAttended,
                            isInRadius: _isInRadius,
                            isSubmitting: _isSubmitting,
                            activeZone: _activeZone,
                            onOpenQr: _openQRScanner,
                            onSubmit: _submitAttendance,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

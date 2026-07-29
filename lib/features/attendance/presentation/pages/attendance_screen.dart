import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/attendance/presentation/pages/attendance_qr_scanner_screen.dart';
import 'package:sespimma/features/attendance/presentation/widgets/geofence_map_widget.dart';
import 'package:sespimma/features/attendance/presentation/widgets/zone_info_sheet.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/features/attendance/presentation/widgets/empty_zone_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/leave_form_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_status_chip.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_floating_info.dart';
import 'package:sespimma/features/attendance/presentation/widgets/attendance_action_buttons.dart';
import 'package:sespimma/core/services/background_location_service.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/attendance/data/services/location_sync_service.dart';
import 'package:sespimma/features/attendance/data/datasources/kegiatan_remote_data_source.dart';
import 'package:sespimma/features/attendance/data/datasources/absensi_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

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

  List<AttendanceZone> _zones = [];
  AttendanceZone? _activeZone;

  late final AnimationController _chipController;
  late final Animation<double> _chipScale;
  StreamSubscription<Map<String, dynamic>?>? _fakeGpsPingSub;

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

    _fetchZonesFromApi();
    // Local-only geofence enter/exit notifications. Realtime location
    // pings to the backend run independently in BackgroundLocationService
    // (started at login / auto-login, stopped at logout — see AuthBloc /
    // AuthRepositoryImpl) regardless of whether this screen is mounted.
    LocationSyncService().startSyncing();

    // Surface a warning if the background ping loop detects a mocked
    // (fake GPS) reading. Only observable while this screen is open — see
    // BackgroundLocationService.onFakeGpsDetected doc.
    _fakeGpsPingSub = BackgroundLocationService.onFakeGpsDetected.listen((_) {
      if (!mounted) return;
      AppNotifier.showError(
        context,
        'Lokasi palsu (fake GPS) terdeteksi, presensi tidak akan tercatat.',
      );
    });
  }

  Future<void> _fetchZonesFromApi() async {
    if (!mounted) return;
    try {
      final kegiatanSource = sl<KegiatanRemoteDataSource>();
      final zones = await kegiatanSource.fetchActiveZones();
      if (mounted) {
        AttendanceZones.setZonesFromApi(zones);
        setState(() {
          _zones = AttendanceZones.activeZones;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _zones = AttendanceZones.activeZones;
        });
      }
    }
  }

  @override
  void dispose() {
    LocationSyncService().stopSyncing();
    _fakeGpsPingSub?.cancel();
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
      // Best-effort context for the background ping loop — lets pings
      // carry the correct activity_location_id even if this screen closes
      // right after.
      BackgroundLocationService.updateActivityLocation(
        activeZone != null ? int.tryParse(activeZone.id) : null,
      );
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
      final String? qrDate = result['date'];
      
      final now = DateTime.now();
      final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      if (qrDate != null && qrDate != todayStr) {
        AppNotifier.showError(
          context,
          'QR Code ini kedaluwarsa atau bukan jadwal untuk hari ini.',
        );
        return;
      }

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

    try {
      double lat = 0.0;
      double lng = 0.0;
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        if (_activeZone != null) {
          lat = _activeZone!.latitude;
          lng = _activeZone!.longitude;
        }
      }

      final absensiSource = sl<AbsensiRemoteDataSource>();
      final result = await absensiSource.checkIn(
        kegiatanId: _activeZone!.id,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();

      final bool serverIsLate = result['is_late'] == true;

      setState(() {
        _isSubmitting = false;
        _lastSubmitTime = DateTime.now();
        _isAttended = true;
        PimpinanMockData.attendanceReportCount += 1;
      });

      final now = DateTime.now();
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";
      final activityName = result['activity_name'] ?? _activeZone?.activityName ?? 'Kegiatan Presensi';

      // Keep mock data in sync for pimpinan dashboard (until Tahap 4)
      PimpinanMockData.addAttendance({
        'id': 'att_${now.millisecondsSinceEpoch}',
        'title': activityName,
        'date': '${now.day}-${now.month}-${now.year}',
        'time': timeStr,
        'dateTime': now,
        'status': serverIsLate ? 'Telat' : 'Hadir',
        'type': serverIsLate ? 'telat' : 'hadir',
        'method': fromQr ? 'QR Code' : 'Geofencing',
        'verification': 'Valid',
        'location': _activeZone?.name ?? 'Lokasi Sespimma',
        'device': 'Perangkat Serdik',
        'image': 'assets/images/avatar.png',
      });

      if (serverIsLate) {
        AppNotifier.showWarning(
          context,
          'Tercatat masuk di jam $timeStr (Terlambat) untuk $activityName.',
        );
      } else {
        AppNotifier.showSuccess(
          context,
          'Berhasil absen di jam $timeStr untuk kegiatan $activityName.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String errorMsg = 'Gagal melakukan absensi';
      final errStr = e.toString();
      if (errStr.contains('mengajukan izin')) {
        errorMsg = 'Anda tidak bisa absen hadir karena sudah mengajukan izin untuk kegiatan ini';
        setState(() => _isAttended = true);
      } else if (errStr.contains('409') || errStr.contains('sudah melakukan')) {
        errorMsg = 'Anda sudah melakukan presensi untuk kegiatan ini hari ini';
        setState(() => _isAttended = true);
      } else if (errStr.contains('403') || errStr.contains('ditutup')) {
        errorMsg = 'Waktu absensi sudah ditutup';
      } else if (errStr.contains('404')) {
        errorMsg = 'Kegiatan tidak ditemukan';
      }

      AppNotifier.showError(context, errorMsg);
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
          _showLeaveForm(context, zoneToShow);
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

  void _showLeaveForm(BuildContext context, AttendanceZone zone) {
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
        kegiatanId: zone.id,
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
          'Absen',
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
        onReload: () async {
          await _fetchZonesFromApi();
          if (!mounted) return;
          AppNotifier.showSuccess(
            this.context,
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

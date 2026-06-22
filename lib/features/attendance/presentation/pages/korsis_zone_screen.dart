import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/attendance/presentation/pages/korsis_zone_marking_screen.dart';
import 'package:sespimma/features/attendance/presentation/widgets/geofence_map_widget.dart';
import 'package:sespimma/features/attendance/presentation/widgets/korsis_zone_info_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/korsis_zone_qr_sheet.dart';
import 'package:sespimma/injection_container.dart';

import 'package:sespimma/features/attendance/data/datasources/kegiatan_remote_data_source.dart';

class KorsisZoneScreen extends StatefulWidget {
  const KorsisZoneScreen({super.key});

  @override
  State<KorsisZoneScreen> createState() => _KorsisZoneScreenState();
}

class _KorsisZoneScreenState extends State<KorsisZoneScreen> {
  List<AttendanceZone> _zones = [];
  bool _isLocating = true;
  bool _hasLocationError = false;
  List<Map<String, dynamic>> _serdikMarkers = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadZones();
    _fetchZonesFromApi();
    _fetchLiveLocations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchZonesFromApi();
        _fetchLiveLocations();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchZonesFromApi() async {
    try {
      final kegiatanSource = sl<KegiatanRemoteDataSource>();
      final zones = await kegiatanSource.fetchActiveZones();
      if (mounted) {
        AttendanceZones.setZonesFromApi(zones);
        _loadZones();
      }
    } catch (_) {}
  }

  Future<void> _fetchLiveLocations() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/mobile/location/live');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> dataList = response.data['data'] ?? [];
        final List<Map<String, dynamic>> generated = [];
        const Distance distanceCalc = Distance();

        for (var item in dataList) {
          final mapItem = Map<String, dynamic>.from(item);
          final double lat = (mapItem['latitude'] as num?)?.toDouble() ?? 0.0;
          final double lng = (mapItem['longitude'] as num?)?.toDouble() ?? 0.0;

          double distanceOffset = 999999.0;
          if (_zones.isNotEmpty) {
            distanceOffset = distanceCalc.as(
              LengthUnit.Meter,
              LatLng(lat, lng),
              LatLng(_zones.first.latitude, _zones.first.longitude),
            );
          }

          // Convert backend status to display status
          String status = 'Belum Absen';
          Color color = Colors.grey;
          
          final backendStatus = mapItem['status']?.toString().toLowerCase() ?? 'tk';
          if (backendStatus == 'hadir') {
            status = 'Hadir';
            color = Colors.green.shade600;
          } else if (backendStatus == 'sakit') {
            status = 'Sakit';
            color = Colors.pink.shade400;
          } else if (backendStatus == 'izin') {
            status = 'Izin';
            color = Colors.orange;
          } else {
            if (_zones.isNotEmpty) {
              final zone = _zones.first;
              final now = DateTime.now();
              if (now.isAfter(zone.cutoffTime)) {
                status = 'Tanpa Keterangan';
                color = Colors.red.shade600;
              } else {
                status = 'Belum Absen';
                color = Colors.grey;
              }
            } else {
              status = 'Belum Absen';
              color = Colors.grey;
            }
          }

          final serdikData = {
            'no_serdik': mapItem['nrp'] ?? '',
            'nama_lengkap': mapItem['name'] ?? '',
            'pangkat': mapItem['pangkat'] ?? '',
            'profile_photo': mapItem['profile_photo'],
            'mock_lat': lat,
            'mock_lng': lng,
            'mock_status': status,
            'mock_color': color,
            'mock_distance': distanceOffset,
          };
          generated.add(serdikData);
        }

        if (mounted) {
          setState(() {
            _serdikMarkers = generated;
          });
        }
      }
    } catch (e) {
      // ignore
    }
  }

  void _loadZones() {
    setState(() {
      _zones = AttendanceZones.activeZones;
      if (_zones.isEmpty) {
        _isLocating = false;
      }
    });
  }

  void _showZoneInfo(BuildContext context, AttendanceZone zone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      builder: (_) => KorsisZoneInfoSheet(
        zone: zone,
        onDeleted: () async {
          try {
            final dio = sl<Dio>();
            await dio.delete('/attendance/zones/${zone.id}');
            if (!context.mounted) return;
            AttendanceZones.removeZone(zone.id);
            _loadZones();
            AppNotifier.showSuccess(context, 'Zona berhasil dihapus.');
          } catch (e) {
            if (!context.mounted) return;
            AppNotifier.showError(context, 'Gagal menghapus zona dari server: $e');
          }
        },
      ),
    );
  }

  void _showQrCodes() {
    if (_zones.isEmpty) {
      AppNotifier.showWarning(
        context,
        'Belum ada zona aktif untuk menampilkan QR Code',
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KorsisZoneQrSheet(zones: _zones),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const fabHeight = 56.0;
    const gap = 8.0;
    final fabBase = bottomPad + fabHeight + gap + 16;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manajemen Zona',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [
          if (!_hasLocationError)
            IconButton(
              icon: Icon(
                AppIcons.qrCode,
                color: _isLocating
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.white,
              ),
              tooltip: 'Tampilkan QR Code Zona',
              onPressed: _isLocating
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _showQrCodes();
                    },
            ),
        ],
      ),
      body: GeofenceMapWidget(
        zones: _zones,
        serdikMarkers: _serdikMarkers,
        onLocationDetected: (zone, dist, isFake) {
          if (_isLocating) {
            setState(() => _isLocating = false);
          }
        },
        onGpsStateChanged: (hasError) {
          if (_hasLocationError != hasError) {
            setState(() => _hasLocationError = hasError);
          }
          if (hasError && _isLocating) {
            setState(() => _isLocating = false);
          }
        },
        onReload: _loadZones,
        fabBottomBase: fabBase,
        onRadiusTap: (tappedZone) {
          HapticFeedback.selectionClick();
          _showZoneInfo(context, tappedZone);
        },
        customFab: _hasLocationError
            ? null
            : FloatingActionButton(
                onPressed: _isLocating
                    ? null
                    : () async {
                        HapticFeedback.selectionClick();
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KorsisZoneMarkingScreen(),
                          ),
                        );
                        if (result == true) _loadZones();
                      },
                backgroundColor: AppColors.primaryNavy,
                elevation: 6,
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
      ),
    );
  }
}

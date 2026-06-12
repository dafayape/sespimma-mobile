import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/attendance/data/services/location_sync_service.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunGeofenceMapWidget extends StatefulWidget {
  final String pokjar;

  const PatunGeofenceMapWidget({super.key, required this.pokjar});

  @override
  State<PatunGeofenceMapWidget> createState() => _PatunGeofenceMapWidgetState();
}

class _PatunGeofenceMapWidgetState extends State<PatunGeofenceMapWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final MapController _mapController;
  MapTileMode _tileMode = MapTileMode.normal;
  bool _isRefreshingMap = false;
  bool _isLoading = false;

  LatLng? _userLatLng;
  Timer? _refreshTimer;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  List<AttendanceZone> _zones = AttendanceZones.activeZones;
  List<Map<String, dynamic>> _serdikMarkers = [];

  static const double _defaultZoom = 19.0;
  static const Color _primaryNavy = Color(0xFF001C40);

  LatLng get _firstZoneLatLng {
    if (_zones.isEmpty) return const LatLng(-6.824003, 107.640779);
    return LatLng(_zones.first.latitude, _zones.first.longitude);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mapController = MapController();
    _setupPulseAnimation();

    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      if (!mounted) return;
      if (status == ServiceStatus.disabled) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(
          context,
          'Layanan GPS mati. Harap aktifkan lokasi di pengaturan HP agar dapat melakukan monitoring.',
          duration: const Duration(days: 365),
        );
      } else if (status == ServiceStatus.enabled) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _checkPermissionsAndStartTracking();
      }
    });

    _checkPermissionsAndStartTracking();
    _generateMockSerdikData();

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _generateMockSerdikData();
      }
    });
  }

  void _setLoadingState(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_userLatLng == null) {
        _checkPermissionsAndStartTracking();
      }
    }
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _setLoadingState(false);
      AppNotifier.showError(
        context,
        'Layanan GPS mati. Harap aktifkan lokasi di pengaturan HP agar dapat melakukan monitoring.',
        duration: const Duration(days: 365),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        _setLoadingState(false);
        AppNotifier.showError(
          context,
          'Izin akses lokasi ditolak. Aplikasi tidak dapat melacak posisi Anda.',
          duration: const Duration(days: 365),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _setLoadingState(false);
      AppNotifier.showError(
        context,
        'Izin lokasi ditolak permanen. Silakan izinkan akses lokasi melalui Pengaturan HP.',
        duration: const Duration(days: 365),
      );
      return;
    }

    if (mounted) {}

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) {
            if (mounted && pos.latitude.isFinite && pos.longitude.isFinite) {
              setState(() {
                _userLatLng = LatLng(pos.latitude, pos.longitude);
              });
            }
          },
          onError: (dynamic _) {},
          cancelOnError: false,
        );

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted && current.latitude.isFinite && current.longitude.isFinite) {
        setState(() {
          _userLatLng = LatLng(current.latitude, current.longitude);
        });
        _animateTo(_userLatLng!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(
          context,
          'Gagal mendapatkan posisi GPS. Pastikan sinyal GPS stabil.',
          duration: const Duration(days: 365),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant PatunGeofenceMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pokjar != widget.pokjar) {
      _generateMockSerdikData();
    }
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _serviceStatusSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _generateMockSerdikData() {
    final baseList = SerdikRealData.records
        .where(
          (r) => widget.pokjar.isEmpty || r['kelompok_kelas'] == widget.pokjar,
        )
        .toList();

    final List<Map<String, dynamic>> generated = [];
    const Distance distanceCalc = Distance();

    for (int i = 0; i < baseList.length; i++) {
      final serdik = Map<String, dynamic>.from(baseList[i]);
      final noSerdik = serdik['no_serdik']?.toString() ?? '';

      final backendData = MockBackendDatabase.serdikLocations[noSerdik];

      if (backendData == null) continue;

      final double lat = backendData['latitude'];
      final double lng = backendData['longitude'];

      double distanceOffset = 999999.0;
      if (_zones.isNotEmpty) {
        distanceOffset = distanceCalc.as(
          LengthUnit.Meter,
          LatLng(lat, lng),
          LatLng(_zones.first.latitude, _zones.first.longitude),
        );
      }

      String status = 'Belum Absen';
      Color color = Colors.grey;

      if (_zones.isNotEmpty) {
        final zone = _zones.first;
        final now = DateTime.now();
        if (distanceOffset <= zone.radiusMeters) {
          if (now.isAfter(zone.deadline)) {
            status = 'Telat';
            color = Colors.yellow.shade700;
          } else {
            status = 'Hadir';
            color = Colors.grey;
          }
        } else {
          if (now.isAfter(zone.cutoffTime)) {
            status = 'Tanpa Keterangan';
            color = Colors.red.shade600;
          } else {
            status = 'Belum Absen';
            color = Colors.grey;
          }
        }
      }

      serdik['mock_lat'] = lat;
      serdik['mock_lng'] = lng;
      serdik['mock_status'] = status;
      serdik['mock_color'] = color;
      serdik['mock_distance'] = distanceOffset;

      generated.add(serdik);
    }

    setState(() {
      _serdikMarkers = generated;
    });
  }

  void _animateTo(LatLng target) {
    _mapController.move(target, _defaultZoom);
  }

  void _centerOnUser() {
    if (_userLatLng != null) {
      _animateTo(_userLatLng!);
    } else {
      _centerOnZone();
    }
  }

  void _centerOnZone() {
    _animateTo(_firstZoneLatLng);
  }

  void _showSerdikInfo(Map<String, dynamic> serdik) {
    HapticFeedback.lightImpact();
    final String name = serdik['nama_lengkap'] ?? '-';
    final String pangkat = serdik['pangkat'] ?? '-';
    final String noSerdik = serdik['no_serdik'] ?? '-';
    final String status = serdik['mock_status'] ?? '-';
    final double distance = serdik['mock_distance'] ?? 999.0;
    final String? profilePhoto = serdik['profile_photo'];

    final bool isInsideZone =
        _zones.isNotEmpty && distance <= _zones.first.radiusMeters;
    final zoneName = _zones.isNotEmpty ? _zones.first.name : '-';
    final activityName = _zones.isNotEmpty ? _zones.first.activityName : '-';

    Color badgeColor = Colors.grey;
    if (status == 'Hadir') {
      badgeColor = Colors.green.shade600;
    } else if (status == 'Telat') {
      badgeColor = Colors.yellow.shade700;
    } else if (status == 'Tanpa Keterangan') {
      badgeColor = Colors.red.shade600;
    } else if (status == 'Sakit') {
      badgeColor = Colors.pink.shade400;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: AvatarHelper.getAvatar(profilePhoto),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontLg,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pangkat • $noSerdik',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (status == 'Izin')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Izin',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.person,
                                    size: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AKBP Budi Setiawan',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontXs,
                                  fontWeight: FontWeight.w800,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.mapPinFill,
                        color: _primaryNavy,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Lokasi Realtime',
                              style: TextStyle(
                                fontSize: AppDimensions.fontXs,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isInsideZone
                                  ? '$activityName\n$zoneName'
                                  : 'Luar Zona',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontMd,
                                fontWeight: FontWeight.w800,
                                color: _primaryNavy,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLayerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Jenis Peta',
                style: TextStyle(
                  fontSize: AppDimensions.fontXl + 1,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              Row(
                children: [
                  Expanded(
                    child: _buildLayerOption(
                      ctx,
                      'Normal',
                      MapTileMode.normal,
                      AppIcons.mapTrifoldFill,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildLayerOption(
                      ctx,
                      'Satelit',
                      MapTileMode.satellite,
                      AppIcons.globeHemisphereWestFill,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLayerOption(
    BuildContext ctx,
    String title,
    MapTileMode mode,
    IconData fallbackIcon,
  ) {
    final isActive = _tileMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tileMode = mode);
        Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? _primaryNavy.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isActive ? _primaryNavy : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallbackIcon,
              size: 36,
              color: isActive ? _primaryNavy : Colors.blueGrey,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? _primaryNavy : Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isLoading) _buildLoadingOverlay(),
        _buildMap(),
        _buildControls(),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _firstZoneLatLng,
        initialZoom: _defaultZoom,
        minZoom: 10,
        maxZoom: 22,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileMode.tileUrl,
          subdomains: _tileMode.subdomains,
          userAgentPackageName: 'com.sespimma.mobile',
          maxZoom: 22,
          maxNativeZoom: 19,
        ),
        PolygonLayer(
          polygons: _zones
              .where(
                (zone) =>
                    zone.polygonPoints != null &&
                    zone.polygonPoints!.isNotEmpty,
              )
              .map((zone) {
                return Polygon(
                  points: zone.polygonPoints!,
                  color: _primaryNavy.withValues(alpha: 0.1),
                  borderColor: _primaryNavy,
                  borderStrokeWidth: 2.0,
                );
              })
              .toList(),
        ),
        CircleLayer(
          circles: _zones
              .where(
                (zone) =>
                    zone.polygonPoints == null || zone.polygonPoints!.isEmpty,
              )
              .map((zone) {
                return CircleMarker(
                  point: LatLng(zone.latitude, zone.longitude),
                  radius: zone.radiusMeters,
                  useRadiusInMeter: true,
                  color: _primaryNavy.withValues(alpha: 0.1),
                  borderColor: _primaryNavy,
                  borderStrokeWidth: 2.0,
                );
              })
              .toList(),
        ),
        MarkerLayer(
          markers: [
            ..._serdikMarkers.map((serdik) {
              final double lat = serdik['mock_lat'];
              final double lng = serdik['mock_lng'];
              final Color color = serdik['mock_color'];

              return Marker(
                point: LatLng(lat, lng),
                width: 14,
                height: 14,
                child: GestureDetector(
                  onTap: () => _showSerdikInfo(serdik),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_userLatLng != null)
              Marker(
                point: _userLatLng!,
                width: 60,
                height: 60,
                child: _buildUserMarker(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserMarker() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (_pulseAnimation.value * 0.8),
              child: Opacity(
                opacity: (1.0 - _pulseAnimation.value).clamp(0.0, 1.0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryNavy.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryNavy,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _primaryNavy.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: AppDimensions.xxxl,
      right: AppDimensions.lg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(
            icon: AppIcons.buildingsFill,
            onTap: () {
              HapticFeedback.selectionClick();
              _centerOnZone();
            },
          ),
          const SizedBox(height: AppDimensions.md),
          _buildFab(
            icon: _isRefreshingMap
                ? Icons.more_horiz
                : AppIcons.arrowsClockwiseBold,
            onTap: _isRefreshingMap
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    setState(() => _isRefreshingMap = true);
                    await Future.delayed(const Duration(milliseconds: 1000));
                    if (mounted) {
                      setState(() {
                        _zones = AttendanceZones.activeZones;
                        _generateMockSerdikData();
                        _isRefreshingMap = false;
                      });
                    }
                  },
          ),
          const SizedBox(height: AppDimensions.md),
          _buildFab(
            icon: AppIcons.stackBold,
            onTap: () {
              HapticFeedback.lightImpact();
              _showLayerBottomSheet();
            },
          ),
          const SizedBox(height: AppDimensions.md),
          _buildFab(
            icon: Icons.my_location_rounded,
            onTap: () {
              HapticFeedback.selectionClick();
              _centerOnUser();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFab({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: _primaryNavy,
            size: AppDimensions.iconDefault + 2,
          ),
        ),
      ),
    );
  }
}

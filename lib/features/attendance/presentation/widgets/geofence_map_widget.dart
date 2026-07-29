import 'package:sespimma/core/constants/app_dimensions.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
// `hide ServiceStatus`: both this package and geolocator export a
// `ServiceStatus` type; the file already uses geolocator's (GPS
// enabled/disabled), so permission_handler's same-named export is hidden
// here. `show Permission` alone would also hide the `.request()`
// extension method (PermissionActions), which is why this isn't scoped
// down further.
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

import '../../domain/models/map_tile_mode.dart';

const bool showAuditDebug = false;
const bool showGeofenceCircles = true;

class GeofenceMapWidget extends StatefulWidget {
  final List<AttendanceZone> zones;
  final Function(
    AttendanceZone? activeZone,
    double distanceMeters,
    bool isFakeGps,
  )
  onLocationDetected;
  final ValueChanged<bool>? onGpsStateChanged;
  final VoidCallback? onReload;
  final Function(AttendanceZone tappedZone)? onRadiusTap;

  final double? fabBottomBase;
  final Widget? customFab;
  final Widget? contentOverlay;
  final List<Map<String, dynamic>>? serdikMarkers;

  const GeofenceMapWidget({
    super.key,
    required this.zones,
    required this.onLocationDetected,
    this.onGpsStateChanged,
    this.onReload,
    this.onRadiusTap,
    this.fabBottomBase,
    this.customFab,
    this.contentOverlay,
    this.serdikMarkers,
  });

  @override
  State<GeofenceMapWidget> createState() => _GeofenceMapWidgetState();
}

class _GeofenceMapWidgetState extends State<GeofenceMapWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isInRadius = false;
  bool _isLoading = true;
  bool _isRefreshingMap = false;
  bool _isLocationServiceEnabled = true;
  LatLng? _userLatLng;

  MapTileMode _tileMode = MapTileMode.satellite;

  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _dangerRed = Color(0xFFD32F2F);
  static const double _defaultZoom = 19.0;

  LatLng get _firstZoneLatLng {
    if (widget.zones.isEmpty) return const LatLng(-6.824003, 107.640779);
    return LatLng(widget.zones.first.latitude, widget.zones.first.longitude);
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
          _isLocationServiceEnabled = false;
        });
        widget.onGpsStateChanged?.call(true);
        AppNotifier.showError(
          context,
          'Layanan GPS dimatikan. Harap aktifkan kembali lokasi di pengaturan HP agar dapat melakukan presensi.',
          duration: const Duration(days: 365),
        );
      } else if (status == ServiceStatus.enabled) {
        setState(() {
          _isLocationServiceEnabled = true;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _setLoadingState(true);
        _checkPermissionsAndStartTracking();
      }
    });

    _checkPermissionsAndStartTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_userLatLng == null) {
        _setLoadingState(true);
        _checkPermissionsAndStartTracking();
      }
    }
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndStartTracking() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _isLocationServiceEnabled = false;
      });
      _setLoadingState(false);
      widget.onGpsStateChanged?.call(true);
      AppNotifier.showError(
        context,
        'Layanan GPS mati. Harap aktifkan lokasi di pengaturan HP agar dapat melakukan presensi.',
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
        widget.onGpsStateChanged?.call(true);
        AppNotifier.showError(
          context,
          'Izin akses lokasi ditolak. Aplikasi tidak dapat memverifikasi presensi Anda.',
          duration: const Duration(days: 365),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _setLoadingState(false);
      widget.onGpsStateChanged?.call(true);
      AppNotifier.showError(
        context,
        'Izin lokasi ditolak permanen. Silakan izinkan akses lokasi melalui Pengaturan HP.',
        duration: const Duration(days: 365),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLocationServiceEnabled = true;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      widget.onGpsStateChanged?.call(false);
    }

    // Background realtime tracking (BackgroundLocationService) needs
    // "Always" authorization on iOS — "When In Use" (just granted above)
    // is not enough for iOS to keep delivering position updates while the
    // app is backgrounded. `Geolocator.requestPermission()` can't perform
    // this upgrade itself: once a permission decision already exists,
    // its native iOS handler short-circuits and returns the current
    // status without prompting again (see geolocator_apple's
    // PermissionHandler.m). `permission_handler`'s locationAlways request
    // does support the upgrade (it calls CLLocationManager's
    // requestAlwaysAuthorization when currently authorizedWhenInUse), and
    // Apple's guidelines require "When In Use" to already be granted
    // before that succeeds — which is exactly the state at this point in
    // the flow. Fire-and-forget: a denial here just means background
    // tracking degrades to foreground-only, it must never block this
    // (foreground) attendance map from starting.
    if (Platform.isIOS) {
      unawaited(Permission.locationAlways.request());
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position pos) {
            if (pos.isMocked) {
              if (mounted) {
                setState(() {
                  _isInRadius = false;
                  _isLoading = false;
                });
                widget.onLocationDetected(null, -1.0, true);
              }
              return;
            }
            _updateFromPosition(pos.latitude, pos.longitude, false);
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
      if (mounted) {
        if (current.isMocked) {
          setState(() {
            _isInRadius = false;
            _isLoading = false;
          });
          widget.onLocationDetected(null, -1.0, true);
        } else {
          _updateFromPosition(current.latitude, current.longitude, false);
          _animateTo(LatLng(current.latitude, current.longitude));
        }
      }
    } catch (_) {
      if (mounted) {
        widget.onGpsStateChanged?.call(true);
        AppNotifier.showError(
          context,
          'Gagal mendapatkan posisi GPS. Pastikan sinyal GPS stabil.',
          duration: const Duration(days: 365),
        );
      }
    }
  }

  void _updateFromPosition(
    double lat,
    double lng,
    bool isFakeGps, {
    List<AttendanceZone>? overrideZones,
  }) {
    final zonesToUse = List<AttendanceZone>.from(overrideZones ?? widget.zones)
      ..sort((a, b) => a.radiusMeters.compareTo(b.radiusMeters));

    if (zonesToUse.isEmpty) {
      if (mounted) {
        setState(() {
          _userLatLng = LatLng(lat, lng);
          _isInRadius = false;
          _isLoading = false;
        });
        widget.onLocationDetected(null, -1.0, isFakeGps);
      }
      return;
    }

    AttendanceZone? matchedZone;
    double finalDistance = -1.0;

    for (final zone in zonesToUse) {
      if (zone.polygonPoints != null && zone.polygonPoints!.isNotEmpty) {
        final mpPoint = mp.LatLng(lat, lng);
        final mpPolygon = zone.polygonPoints!
            .map((p) => mp.LatLng(p.latitude, p.longitude))
            .toList();

        if (mp.PolygonUtil.containsLocation(mpPoint, mpPolygon, false)) {
          matchedZone = zone;
          finalDistance = Geolocator.distanceBetween(
            zone.latitude,
            zone.longitude,
            lat,
            lng,
          );
          break;
        }
      } else {
        final distance = Geolocator.distanceBetween(
          zone.latitude,
          zone.longitude,
          lat,
          lng,
        );
        if (distance <= zone.radiusMeters) {
          matchedZone = zone;
          finalDistance = distance;
          break;
        }
      }
    }

    if (matchedZone == null && zonesToUse.isNotEmpty) {
      finalDistance = Geolocator.distanceBetween(
        zonesToUse.first.latitude,
        zonesToUse.first.longitude,
        lat,
        lng,
      );
    }

    bool inRadius = matchedZone != null;

    if (mounted) {
      setState(() {
        _userLatLng = LatLng(lat, lng);
        _isInRadius = inRadius;
        _isLoading = false;
      });
      widget.onLocationDetected(matchedZone, finalDistance, isFakeGps);
    }
  }

  void _setLoadingState(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  void _animateTo(LatLng target) {
    _mapController.move(target, _defaultZoom);
  }

  void _centerOnUser() {
    if (_userLatLng != null) {
      _animateTo(_userLatLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMap(),
        _buildMapControls(),
        if (widget.contentOverlay != null && _isLocationServiceEnabled)
          Positioned.fill(child: widget.contentOverlay!),
        if (widget.customFab != null && _isLocationServiceEnabled)
          Positioned(
            right: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
            child: widget.customFab!,
          ),
        if (_isLoading) _buildLoadingOverlay(),
        _buildAuditDebugPanel(),
      ],
    );
  }

  Widget _buildAuditDebugPanel() {
    if (!showAuditDebug || _userLatLng == null) return const SizedBox.shrink();

    double minDistance = double.infinity;
    AttendanceZone? nearest;

    for (final zone in widget.zones) {
      final d = Geolocator.distanceBetween(
        zone.latitude,
        zone.longitude,
        _userLatLng!.latitude,
        _userLatLng!.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        nearest = zone;
      }
    }

    return Positioned(
      top: 80,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.sm + 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🛰️ AUDIT LOCATION DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white24, height: 8),
            Text(
              'User: ${_userLatLng!.latitude.toStringAsFixed(6)}, ${_userLatLng!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: AppDimensions.fontSm,
                fontFamily: 'monospace',
              ),
            ),
            if (nearest != null) ...[
              Text(
                'Zone: ${nearest.name}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: AppDimensions.fontSm,
                ),
              ),
              Text(
                'Dist: ${minDistance.toStringAsFixed(2)}m / Radius: ${nearest.radiusMeters}m',
                style: TextStyle(
                  color: minDistance <= nearest.radiusMeters
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontSize: AppDimensions.fontSm + 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
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
        onTap: (tapPosition, point) {
          for (final zone in widget.zones) {
            bool isInside = false;

            if (zone.polygonPoints != null && zone.polygonPoints!.isNotEmpty) {
              final mpPoint = mp.LatLng(point.latitude, point.longitude);
              final mpPolygon = zone.polygonPoints!
                  .map((p) => mp.LatLng(p.latitude, p.longitude))
                  .toList();
              isInside = mp.PolygonUtil.containsLocation(
                mpPoint,
                mpPolygon,
                false,
              );
            } else {
              final distance = Geolocator.distanceBetween(
                zone.latitude,
                zone.longitude,
                point.latitude,
                point.longitude,
              );
              isInside = distance <= zone.radiusMeters;
            }

            if (isInside) {
              HapticFeedback.selectionClick();
              widget.onRadiusTap?.call(zone);
              break;
            }
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _tileMode.tileUrl,
          subdomains: _tileMode.subdomains,
          userAgentPackageName: 'com.sespimma.mobile',
          maxZoom: 22,
          maxNativeZoom: 19,
        ),
        if (showGeofenceCircles)
          PolygonLayer(
            polygons: widget.zones
                .where(
                  (zone) =>
                      zone.polygonPoints != null &&
                      zone.polygonPoints!.isNotEmpty,
                )
                .map((zone) {
                  bool isInside = false;
                  if (_userLatLng != null) {
                    final mpPoint = mp.LatLng(
                      _userLatLng!.latitude,
                      _userLatLng!.longitude,
                    );
                    final mpPolygon = zone.polygonPoints!
                        .map((p) => mp.LatLng(p.latitude, p.longitude))
                        .toList();
                    isInside = mp.PolygonUtil.containsLocation(
                      mpPoint,
                      mpPolygon,
                      false,
                    );
                  }
                  final Color ringColor = isInside ? _successGreen : _dangerRed;

                  return Polygon(
                    points: zone.polygonPoints!,
                    color: ringColor.withValues(alpha: 0.15),
                    borderColor: ringColor,
                    borderStrokeWidth: 2.0,
                  );
                })
                .toList(),
          ),
        if (showGeofenceCircles)
          CircleLayer(
            circles: widget.zones
                .where(
                  (zone) =>
                      zone.polygonPoints == null || zone.polygonPoints!.isEmpty,
                )
                .map((zone) {
                  bool isInside = false;
                  if (_userLatLng != null) {
                    final distance = Geolocator.distanceBetween(
                      zone.latitude,
                      zone.longitude,
                      _userLatLng!.latitude,
                      _userLatLng!.longitude,
                    );
                    isInside = distance <= zone.radiusMeters;
                  }
                  final Color ringColor = isInside ? _successGreen : _dangerRed;

                  return CircleMarker(
                    point: LatLng(zone.latitude, zone.longitude),
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: ringColor.withValues(alpha: 0.15),
                    borderColor: ringColor,
                    borderStrokeWidth: 2.0,
                  );
                })
                .toList(),
          ),
        MarkerLayer(
          markers: [
            if (widget.serdikMarkers != null)
              ...widget.serdikMarkers!.map((serdik) {
                final double lat = (serdik['mock_lat'] as num?)?.toDouble() ?? (serdik['latitude'] as num?)?.toDouble() ?? 0.0;
                final double lng = (serdik['mock_lng'] as num?)?.toDouble() ?? (serdik['longitude'] as num?)?.toDouble() ?? 0.0;
                final Color color = (serdik['mock_color'] ?? Colors.grey) as Color;
                final String? profilePhoto = serdik['profile_photo'] as String?;

                return Marker(
                  point: LatLng(lat, lng),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showSerdikInfo(serdik),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withValues(alpha: 0.2),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: color, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: profilePhoto != null && profilePhoto.isNotEmpty && profilePhoto != "/default-avatar.png"
                                ? Image(
                                    image: AvatarHelper.getAvatar(profilePhoto),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 18,
                                      color: color,
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 18,
                                    color: color,
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
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
                    color: (_isInRadius ? _successGreen : _dangerRed)
                        .withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isInRadius ? _successGreen : _dangerRed,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: (_isInRadius ? _successGreen : _dangerRed)
                        .withValues(alpha: 0.5),
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

  void _showSerdikInfo(Map<String, dynamic> serdik) {
    HapticFeedback.lightImpact();
    final String name = serdik['nama_lengkap'] ?? '-';
    final String pangkat = serdik['pangkat'] ?? '-';
    final String noSerdik = serdik['no_serdik'] ?? '-';
    final String status = serdik['mock_status'] ?? '-';
    final double distance = (serdik['mock_distance'] as num?)?.toDouble() ?? 999.0;
    final String? profilePhoto = serdik['profile_photo'] as String?;

    final bool isInsideZone =
        widget.zones.isNotEmpty && distance <= widget.zones.first.radiusMeters;
    final zoneName = widget.zones.isNotEmpty ? widget.zones.first.name : '-';
    final activityName = widget.zones.isNotEmpty ? widget.zones.first.activityName : '-';

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
                              color: Color(0xFF001C40),
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
                        color: Color(0xFF001C40),
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
                                color: Color(0xFF001C40),
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

  Widget _buildMapControls() {
    if (!_isLocationServiceEnabled) return const SizedBox.shrink();

    final base =
        widget.fabBottomBase ?? (MediaQuery.of(context).size.height * 0.25);
    return Positioned(
      bottom: base,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMapFab(
            tooltip: 'Refresh Lokasi',
            child: _isRefreshingMap
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _primaryNavy,
                    ),
                  )
                : const Icon(
                    AppIcons.arrowsClockwiseBold,
                    color: _primaryNavy,
                    size: AppDimensions.iconDefault + 2,
                  ),
            onTap: _isRefreshingMap
                ? null
                : () async {
                    HapticFeedback.mediumImpact();
                    setState(() => _isRefreshingMap = true);
                    await Future.delayed(const Duration(milliseconds: 1200));
                    if (mounted) {
                      setState(() => _isRefreshingMap = false);
                      widget.onReload?.call();
                      final latestZones = AttendanceZones.activeZones;
                      if (_userLatLng != null) {
                        _updateFromPosition(
                          _userLatLng!.latitude,
                          _userLatLng!.longitude,
                          false,
                          overrideZones: latestZones,
                        );
                      }

                      if (latestZones.isNotEmpty) {
                        final firstZone = LatLng(
                          latestZones.first.latitude,
                          latestZones.first.longitude,
                        );
                        _animateTo(firstZone);
                      }

                      AppNotifier.showSuccess(
                        context,
                        'Zona telah diperbaharui',
                      );
                    }
                  },
          ),
          const SizedBox(height: 8),

          _buildMapFab(
            tooltip: 'Jenis Peta',
            child: const Icon(
              AppIcons.stackBold,
              color: Color(0xFF001C40),
              size: AppDimensions.iconDefault + 2,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _showLayerBottomSheet();
            },
          ),
          const SizedBox(height: 8),

          _buildMapFab(
            tooltip: 'Pusat ke Lokasi',
            child: const Icon(
              AppIcons.crosshairBold,
              color: Color(0xFF001C40),
              size: AppDimensions.iconDefault + 2,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _centerOnUser();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapFab({
    required Widget child,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 2),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 2),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.sm + 2),
            child: child,
          ),
        ),
      ),
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
                child: Tooltip(
                  message: 'Pusat Zona',
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusXs,
                      ),
                    ),
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
                      'assets/images/map_normal.png',
                      AppIcons.mapTrifoldFill,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildLayerOption(
                      ctx,
                      'Satelit',
                      MapTileMode.satellite,
                      'assets/images/map_satellite.png',
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
    String imageFallback,
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
                fontSize: AppDimensions.fontDefault,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? _primaryNavy : Colors.blueGrey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: AppDimensions.md),
              Text(
                'Mendeteksi lokasi GPS...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: AppDimensions.fontDefault,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:sespimma/features/attendance/presentation/widgets/korsis_zone_form_sheet.dart';

class KorsisZoneMarkingScreen extends StatefulWidget {
  const KorsisZoneMarkingScreen({super.key});

  @override
  State<KorsisZoneMarkingScreen> createState() =>
      _KorsisZoneMarkingScreenState();
}

class _KorsisZoneMarkingScreenState extends State<KorsisZoneMarkingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _radiusController = TextEditingController(text: '100');
  final List<LatLng> _points = [];
  double _radius = 100.0;
  MapTileMode _tileMode = MapTileMode.satellite;
  LatLng? _userLocation;
  bool _isRefreshing = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initLocation();

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
    _pulseController.dispose();
    _mapController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      if (pos.latitude.isNaN || pos.longitude.isNaN) {
        setState(() => _userLocation = const LatLng(-6.967639, 107.659083));
      } else {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      }
      _mapController.move(_userLocation!, 18.0);
    } catch (_) {}
  }

  void _handleTap(TapPosition _, LatLng point) {
    HapticFeedback.lightImpact();
    setState(() => _points.add(point));
  }

  void _undo() {
    if (_points.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _points.removeLast());
  }

  void _clear() {
    if (_points.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _points.clear();
      _radius = 100.0;
      _radiusController.text = '100';
    });
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    await _initLocation();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _centerOnUser() {
    HapticFeedback.lightImpact();
    if (_userLocation != null) _mapController.move(_userLocation!, 18.0);
  }

  void _showTileSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TileLayerSheet(
        current: _tileMode,
        onSelected: (mode) {
          setState(() => _tileMode = mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    HapticFeedback.mediumImpact();

    final isPolygon = _points.length >= 3;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => KorsisZoneFormSheet(
        centerPoint: isPolygon ? null : _points.first,
        radius: isPolygon ? null : _radius,
        polygonPoints: isPolygon ? List.of(_points) : null,
      ),
    );

    if (result == true && mounted) Navigator.pop(context, true);
  }

  bool get _canConfirm => _points.length == 1 || _points.length >= 3;

  void _onRadiusInput(String val) {
    final parsed = int.tryParse(val);
    if (parsed != null && parsed >= 1 && parsed <= 5000) {
      setState(() => _radius = parsed.toDouble());
    }
  }

  _MarkingStatus get _status {
    if (_points.isEmpty) {
      return const _MarkingStatus(
        label: 'Belum Ada Titik',
        sub: 'Tap peta untuk mulai menandai zona',
        icon: AppIcons.mapPinLine,
        color: AppColors.primaryNavy,
      );
    } else if (_points.length == 1) {
      return _MarkingStatus(
        label: 'Mode Radius · ${_radius.toInt()} m',
        sub: 'Tap lagi (≥3 total) untuk beralih ke Polygon',
        icon: AppIcons.circle,
        color: AppColors.primaryNavy,
      );
    } else if (_points.length == 2) {
      return const _MarkingStatus(
        label: '2 Titik — Tambah 1 Lagi',
        sub: 'Minimal 3 titik untuk membentuk polygon area',
        icon: AppIcons.warningCircle,
        color: Color(0xFFE65100),
      );
    } else {
      return _MarkingStatus(
        label: 'Polygon ${_points.length} Titik — Siap',
        sub: 'Tekan konfirmasi untuk melanjutkan',
        icon: AppIcons.checkCircleFill,
        color: const Color(0xFF2E7D32),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Marking Zona',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildMap(),

          Positioned(
            top: mq.padding.top + kToolbarHeight + 12,
            left: 16,
            right: 16,
            child: _buildStatusCard(),
          ),

          if (_points.length == 1)
            Positioned(
              left: 16,
              bottom: mq.padding.bottom + 16,
              child: _buildRadiusInput(),
            ),

          Positioned(
            right: 16,
            bottom: mq.padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _MapFab(
                  icon: _isRefreshing
                      ? Icons.more_horiz
                      : AppIcons.arrowsClockwiseBold,
                  tooltip: 'Refresh Lokasi',
                  onTap: _refreshLocation,
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: AppIcons.stackBold,
                  tooltip: 'Jenis Peta',
                  onTap: _showTileSheet,
                ),
                const SizedBox(height: 8),
                _MapFab(
                  icon: AppIcons.crosshairBold,
                  tooltip: 'Ke Lokasiku',
                  onTap: _centerOnUser,
                ),
                const SizedBox(height: 12),

                Container(width: 42, height: 1, color: Colors.grey.shade300),
                const SizedBox(height: 12),

                _MapFab(
                  icon: Icons.check_rounded,
                  tooltip: 'Konfirmasi Zona',
                  iconColor: _canConfirm
                      ? AppColors.primaryNavy
                      : AppColors.primaryNavy.withValues(alpha: 0.3),
                  onTap: _canConfirm ? _confirm : null,
                ),
                const SizedBox(height: 8),

                _MapFab(
                  icon: AppIcons.trash,
                  tooltip: 'Hapus Semua',
                  iconColor: _points.isNotEmpty
                      ? AppColors.dangerRed
                      : AppColors.dangerRed.withValues(alpha: 0.3),
                  onTap: _points.isNotEmpty ? _clear : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final existingZones = AttendanceZones.activeZones;
    final polygonZones = existingZones
        .where((z) => z.polygonPoints != null && z.polygonPoints!.isNotEmpty)
        .toList();
    final radiusZones = existingZones
        .where((z) => z.polygonPoints == null || z.polygonPoints!.isEmpty)
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userLocation ?? const LatLng(-6.824003, 107.640779),
        initialZoom: 17.0,
        minZoom: 10,
        maxZoom: 22,
        onTap: _handleTap,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileMode.tileUrl,
          subdomains: _tileMode.subdomains,
          userAgentPackageName: 'com.sespimma.mobile',
          maxNativeZoom: 19,
          maxZoom: 22,
        ),
        if (polygonZones.isNotEmpty)
          PolygonLayer(
            polygons: polygonZones
                .map(
                  (z) => Polygon(
                    points: z.polygonPoints!,
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    borderColor: AppColors.primaryNavy,
                    borderStrokeWidth: 2.0,
                  ),
                )
                .toList(),
          ),
        if (radiusZones.isNotEmpty)
          CircleLayer(
            circles: radiusZones.map((z) {
              bool isInside = false;
              if (_userLocation != null) {
                final distance = Geolocator.distanceBetween(
                  z.latitude,
                  z.longitude,
                  _userLocation!.latitude,
                  _userLocation!.longitude,
                );
                isInside = distance <= z.radiusMeters;
              }
              final Color ringColor = isInside
                  ? AppColors.successGreen
                  : AppColors.dangerRed;

              return CircleMarker(
                point: LatLng(z.latitude, z.longitude),
                radius: z.radiusMeters,
                useRadiusInMeter: true,
                color: ringColor.withValues(alpha: 0.15),
                borderColor: ringColor,
                borderStrokeWidth: 2.0,
              );
            }).toList(),
          ),

        if (_points.length >= 3)
          PolygonLayer(
            polygons: [
              Polygon(
                points: _points.toList(),
                color: AppColors.primaryNavy.withValues(alpha: 0.18),
                borderColor: AppColors.primaryNavy,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),

        if (_points.length == 1)
          CircleLayer(
            circles: [
              (() {
                bool isInside = false;
                if (_userLocation != null) {
                  final distance = Geolocator.distanceBetween(
                    _points.first.latitude,
                    _points.first.longitude,
                    _userLocation!.latitude,
                    _userLocation!.longitude,
                  );
                  isInside = distance <= _radius;
                }
                final Color activeRingColor = isInside
                    ? AppColors.successGreen
                    : AppColors.dangerRed;

                return CircleMarker(
                  point: _points.first,
                  radius: _radius,
                  useRadiusInMeter: true,
                  color: activeRingColor.withValues(alpha: 0.15),
                  borderColor: activeRingColor,
                  borderStrokeWidth: 2.5,
                );
              })(),
            ],
          ),
        MarkerLayer(
          markers: [
            ...existingZones.map(
              (zone) => Marker(
                point: LatLng(zone.latitude, zone.longitude),
                width: 44,
                height: 44,
                child: const Tooltip(
                  message: 'Zona',
                  child: Icon(
                    AppIcons.buildingsFill,
                    color: AppColors.successGreen,
                    size: AppDimensions.iconXxl,
                  ),
                ),
              ),
            ),
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 44,
                height: 44,
                child: _buildUserLocationMarker(),
              ),
          ],
        ),
        if (_points.isNotEmpty)
          DragMarkers(
            markers: _points.indexed
                .map(
                  (entry) => DragMarker(
                    key: ValueKey('drag_${entry.$1}'),
                    point: entry.$2,
                    useLongPress: true,
                    size: const Size(48, 48),
                    builder: (_, _, isDragging) {
                      return Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isDragging ? 24 : 16,
                          height: isDragging ? 24 : 16,
                          decoration: BoxDecoration(
                            color: entry.$1 == 0
                                ? AppColors.primaryNavy
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryNavy,
                              width: isDragging ? 3.5 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDragging ? 0.4 : 0.2,
                                ),
                                blurRadius: isDragging ? 8 : 4,
                                spreadRadius: isDragging ? 2 : 0,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    onDragUpdate: (details, latLng) {
                      setState(() => _points[entry.$1] = latLng);
                    },
                    onLongDragUpdate: (details, latLng) {
                      setState(() => _points[entry.$1] = latLng);
                    },
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildStatusCard() {
    final s = _status;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: s.color.withValues(alpha: 0.22), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: s.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(s.icon, color: s.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w800,
                      color: s.color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    s.sub,
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      color: Colors.blueGrey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_points.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _undo,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.undo_rounded,
                    size: 16,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserLocationMarker() {
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
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dangerRed.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.dangerRed,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dangerRed.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRadiusInput() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Radius Zona',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      border: InputBorder.none,
                      hintText: '100',
                    ),
                    inputFormatters: [_DigitsOnlyFormatter(maxLen: 4)],
                    onChanged: _onRadiusInput,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'meter',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '1 – 5000 m',
              style: TextStyle(fontSize: 9, color: Colors.blueGrey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitsOnlyFormatter extends TextInputFormatter {
  final int maxLen;
  const _DigitsOnlyFormatter({required this.maxLen});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
    final digits = newVal.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > maxLen) return old;
    return newVal.copyWith(text: digits);
  }
}

class _MarkingStatus {
  final String label;
  final String sub;
  final IconData icon;
  final Color color;

  const _MarkingStatus({
    required this.label,
    required this.sub,
    required this.icon,
    required this.color,
  });
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primaryNavy;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 2),
        elevation: onTap != null ? 4 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg + 2),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              color: color,
              size: AppDimensions.iconDefault + 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TileLayerSheet extends StatelessWidget {
  final MapTileMode current;
  final ValueChanged<MapTileMode> onSelected;

  const _TileLayerSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const Text(
            'Jenis Peta',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: _TileOption(
                  title: 'Normal',
                  icon: AppIcons.mapTrifoldFill,
                  isActive: current == MapTileMode.normal,
                  onTap: () => onSelected(MapTileMode.normal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TileOption(
                  title: 'Satelit',
                  icon: AppIcons.globeHemisphereWestFill,
                  isActive: current == MapTileMode.satellite,
                  onTap: () => onSelected(MapTileMode.satellite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TileOption({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryNavy.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isActive ? AppColors.primaryNavy : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 34,
              color: isActive ? AppColors.primaryNavy : Colors.blueGrey,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? AppColors.primaryNavy
                    : Colors.blueGrey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:latlong2/latlong.dart';

enum MapTileMode {
  normal,
  satellite,
  terrain;

  String get label {
    switch (this) {
      case MapTileMode.normal:
        return 'Normal';
      case MapTileMode.satellite:
        return 'Satelit';
      case MapTileMode.terrain:
        return 'Terrain';
    }
  }

  String get emoji {
    switch (this) {
      case MapTileMode.normal:
        return '🗺';
      case MapTileMode.satellite:
        return '🛰';
      case MapTileMode.terrain:
        return '🏔';
    }
  }

  String get tileUrl {
    switch (this) {
      case MapTileMode.normal:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case MapTileMode.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapTileMode.terrain:
        return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    }
  }

  List<String> get subdomains {
    switch (this) {
      case MapTileMode.normal:
      case MapTileMode.terrain:
        return ['a', 'b', 'c', 'd'];
      case MapTileMode.satellite:
        return [];
    }
  }

  String get attribution {
    switch (this) {
      case MapTileMode.normal:
        return '© OpenStreetMap contributors';
      case MapTileMode.satellite:
        return '© Esri, Maxar, Earthstar Geographics';
      case MapTileMode.terrain:
        return '© OpenStreetMap contributors, SRTM | Map style: © OpenTopoMap';
    }
  }
}

class AttendanceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final List<LatLng>? polygonPoints;
  final String activityName;
  final String creator;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime deadline;
  final DateTime cutoffTime;
  final DateTime createdAt;
  final bool isRoutine;
  final bool isTraining;
  final DateTime? routineStartDate;
  final DateTime? routineEndDate;

  const AttendanceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.polygonPoints,
    required this.activityName,
    required this.creator,
    required this.startTime,
    required this.endTime,
    required this.deadline,
    required this.cutoffTime,
    required this.createdAt,
    this.isRoutine = false,
    this.isTraining = false,
    this.routineStartDate,
    this.routineEndDate,
  });

  String get timeString {
    final startStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr WIB';
  }
}

class AttendanceZones {
  AttendanceZones._();

  static bool isMakerindoEnabled = false;

  static final List<AttendanceZone> _dynamicZones = [];

  static List<AttendanceZone> get activeZones {
    final List<AttendanceZone> zones = [];

    if (isMakerindoEnabled) {
      final now = DateTime.now();
      zones.add(
        AttendanceZone(
          id: 'zone_apel_makerindo',
          name: 'PT. Makerindo Prima Solusi',
          latitude: -6.967639,
          longitude: 107.659083,
          radiusMeters: 50.0,
          activityName: 'Apel Pagi',
          creator: 'Korsis',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 4)),
          deadline: now.add(const Duration(hours: 3, minutes: 30)),
          cutoffTime: now.add(const Duration(hours: 3, minutes: 45)),
          createdAt: now.subtract(const Duration(hours: 2)),
          isRoutine: true,
          routineStartDate: now.subtract(const Duration(days: 1)),
          routineEndDate: now.add(const Duration(days: 5)),
        ),
      );
    }

    zones.addAll(_dynamicZones);

    return zones;
  }

  static void addZone(AttendanceZone zone) {
    _dynamicZones.add(zone);
  }

  static void removeZone(String id) {
    _dynamicZones.removeWhere((z) => z.id == id);
  }

  static void updateZone(AttendanceZone updatedZone) {
    final index = _dynamicZones.indexWhere((z) => z.id == updatedZone.id);
    if (index != -1) {
      _dynamicZones[index] = updatedZone;
    }
  }

  static void clearAllZones() {
    _dynamicZones.clear();
  }

  /// Replaces all dynamic zones with zones fetched from the backend API.
  static void setZonesFromApi(List<AttendanceZone> zones) {
    _dynamicZones.clear();
    _dynamicZones.addAll(zones);
  }

  static AttendanceZone get apelHarian => activeZones.first;
}

import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '../../domain/models/map_tile_mode.dart';
import '../../../notification/data/datasources/notification_mock_data.dart';

class LocationSyncService {
  static final LocationSyncService _instance = LocationSyncService._internal();
  factory LocationSyncService() => _instance;
  LocationSyncService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _syncTimer;

  Position? _lastPosition;
  bool _isSyncing = false;
  DateTime _lastGeofenceCheck = DateTime.now();
  static final Map<String, bool> _hasEnteredZone = {};

  static const Duration syncInterval = Duration(seconds: 10);

  void startSyncing(String serdikNrp) {
    if (_isSyncing) return;
    _isSyncing = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            if (position.latitude.isFinite && position.longitude.isFinite) {
              _lastPosition = position;
            }
          },
          onError: (dynamic error) {
            developer.log(
              'Location stream error: $error',
              name: 'LocationSync',
            );
          },
        );

    _syncTimer = Timer.periodic(syncInterval, (timer) {
      if (_lastPosition != null) {
        _sendToBackendAPI(serdikNrp, _lastPosition!);

        final now = DateTime.now();
        if (now.difference(_lastGeofenceCheck).inSeconds >= 60) {
          _lastGeofenceCheck = now;
          _checkGeofenceAlerts();
        }
      }
    });

    developer.log(
      'LocationSyncService STARTED for NRP: $serdikNrp',
      name: 'LocationSync',
    );
  }

  void stopSyncing() {
    _positionSubscription?.cancel();
    _syncTimer?.cancel();
    _isSyncing = false;
    developer.log('LocationSyncService STOPPED', name: 'LocationSync');
  }

  Future<void> _sendToBackendAPI(String nrp, Position pos) async {
    MockBackendDatabase.serdikLocations[nrp] = {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'timestamp': DateTime.now(),
    };

    developer.log(
      'MENGIRIM LOKASI REALTIME KE BACKEND -> NRP: $nrp | Lat: ${pos.latitude}, Lng: ${pos.longitude}',
      name: 'LocationSyncAPI',
    );
  }

  void _checkGeofenceAlerts() {
    if (_lastPosition == null) return;

    final activeZones = AttendanceZones.activeZones;
    for (var zone in activeZones) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        zone.latitude,
        zone.longitude,
      );

      final bool isInside = distance <= zone.radiusMeters;
      final bool hasEntered = _hasEnteredZone[zone.id] ?? false;

      if (isInside) {
        if (!hasEntered) {
          _hasEnteredZone[zone.id] = true;
          _pushLocalNotification(
            id: 'geofence_in_${zone.id}',
            title: 'Zona Terdeteksi',
            message:
                'Anda berada di dalam zona. Silahkan lakukan presensi apabila belum',
            type: 'zone',
          );
          NotificationMockData.items.removeWhere(
            (i) => i['id'] == 'geofence_out_${zone.id}',
          );
        }
      } else {
        if (hasEntered) {
          NotificationMockData.items.removeWhere(
            (i) => i['id'] == 'geofence_out_${zone.id}',
          );
          _pushLocalNotification(
            id: 'geofence_out_${zone.id}',
            title: 'Zona Tidak terdeteksi',
            message: 'Bahaya! kamu berada di luar zona, segera kembali ke zona',
            type: 'punishment',
          );
        }
      }
    }
  }

  void _pushLocalNotification({
    required String id,
    required String title,
    required String message,
    required String type,
  }) {
    NotificationMockData.items.removeWhere((item) => item['id'] == id);
    NotificationMockData.items.insert(0, {
      'id': id,
      'title': title,
      'message': message,
      'dateTime': DateTime.now(),
      'isRead': false,
      'type': type,
      'person': 'Sistem Geofence',
    });
    NotificationMockData.unreadCountNotifier.value++;
  }
}

class MockBackendDatabase {
  static final Map<String, Map<String, dynamic>> serdikLocations = {};
}

import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import '../../domain/models/map_tile_mode.dart';
import '../../../notification/data/datasources/notification_mock_data.dart';

/// Local, in-app geofence-enter/exit notification watcher.
///
/// IMPORTANT — this class does NOT send anything over the network anymore.
/// It used to also POST realtime location pings to `/mobile/location` on a
/// 10s timer, but that duplicated `BackgroundLocationService`
/// (core/services/background_location_service.dart), which runs
/// independently of any screen's lifecycle via flutter_background_service.
/// Running both meant two independent senders firing the same ping every
/// 10s. `BackgroundLocationService` is now the single source of location
/// pings; this class is left purely as a foreground-only helper that pushes
/// local notifications (via [NotificationMockData]) when the student enters
/// or exits an active zone while a screen has it running — it has no
/// business being backgrounded and does not need to be, since it has no
/// network/session identity of its own.
class LocationSyncService {
  static final LocationSyncService _instance = LocationSyncService._internal();
  factory LocationSyncService() => _instance;
  LocationSyncService._internal();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _geofenceCheckTimer;

  Position? _lastPosition;
  bool _isSyncing = false;
  DateTime _lastGeofenceCheck = DateTime.now();
  static final Map<String, bool> _hasEnteredZone = {};

  // Position stream is high-frequency (distanceFilter: 2m); geofence
  // alerts are throttled to once per minute so entering/leaving a zone
  // doesn't spam notification-list churn. Matches the original combined
  // ping+alert timer's cadence for this half of its behavior.
  static const Duration _pollInterval = Duration(seconds: 10);
  static const Duration _geofenceCheckThrottle = Duration(seconds: 60);

  void startSyncing() {
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

    _geofenceCheckTimer = Timer.periodic(_pollInterval, (timer) {
      if (_lastPosition == null) return;
      final now = DateTime.now();
      if (now.difference(_lastGeofenceCheck) >= _geofenceCheckThrottle) {
        _lastGeofenceCheck = now;
        _checkGeofenceAlerts();
      }
    });

    developer.log('LocationSyncService (local geofence alerts) STARTED', name: 'LocationSync');
  }

  void stopSyncing() {
    _positionSubscription?.cancel();
    _geofenceCheckTimer?.cancel();
    _isSyncing = false;
    developer.log('LocationSyncService STOPPED', name: 'LocationSync');
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

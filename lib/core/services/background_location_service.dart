import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/auth/data/datasources/auth_local_data_source.dart' show kAuthAccessTokenStorageKey;
import '../local_database_helper.dart';

/// Owns the ONE sender of realtime location pings to `POST /mobile/location`.
///
/// This runs via `flutter_background_service`, which on Android executes
/// [_onStart] in a completely separate Flutter engine/isolate — it does
/// NOT share memory with the app's main isolate. That means no `sl<Dio>()`,
/// no `GetIt`, no `dotenv.env` already loaded: everything this isolate
/// needs (Dio client, .env, auth token) is (re)built from scratch inside
/// [_onStart]. `LocalDatabaseHelper` is safe to reuse as-is because it opens
/// its own connection to the same on-disk SQLCipher file per isolate.
///
/// Lifecycle: [start] is called once the student's session begins
/// (see AuthBloc, on both fresh login and auto-login), [stop] on logout.
/// [AttendanceScreen] (and any other zone-aware screen) may call
/// [updateActivityLocation] to tell the running service which
/// `activity_location_id` to attach to pings, and listens to
/// [onFakeGpsDetected] to surface a warning when the OS reports a mocked
/// location.
///
/// Consolidation note: this is now the ONLY code path in the app that
/// POSTs to `/mobile/location`. `LocationSyncService`
/// (features/attendance/data/services/location_sync_service.dart) used to
/// duplicate this (a second independent 10s timer + its own position
/// stream), which meant two senders firing pings in parallel. It has been
/// stripped down to local-only geofence-enter/exit notifications and no
/// longer touches the network — see that file for details.
class BackgroundLocationService {
  BackgroundLocationService._();

  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static bool _configured = false;

  /// Persisted alongside the auth token so a freshly-started background
  /// isolate can read the current studentId directly on boot instead of
  /// relying solely on the `setStudent` invoke() message — `invoke()` is
  /// sent right after `startService()` returns, but that Future resolves
  /// once the OS accepts the start request, not once the new engine has
  /// finished booting and subscribed its listeners. Without this, a
  /// `setStudent` sent too early can be dropped (broadcast streams don't
  /// replay events to late subscribers), leaving the service running with
  /// no studentId to tag pings with.
  static const String _studentIdStorageKey = 'BG_LOCATION_STUDENT_ID';

  /// Registers the service handler. Safe to call multiple times; only
  /// configures once. Does NOT start the service — call [start] for that.
  /// Recommended to call once at app startup (see main.dart) so the plugin
  /// is ready regardless of whether a session is already active.
  static Future<void> initialize() async {
    if (_configured) return;
    _configured = true;

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'SESPIMMA Aktif',
        initialNotificationContent: 'Melacak lokasi untuk keperluan presensi...',
        // Matches android/app/src/main/AndroidManifest.xml's
        // foregroundServiceType="location" on the BackgroundService entry
        // (required by Android 14/API 34+ to call startForeground() with a
        // matching type flag).
        foregroundServiceTypes: [AndroidForegroundType.location],
        // Deliberately NOT setting notificationChannelId: the app manifest
        // declares no custom notification channel for this service (only
        // the <service> element itself), so there is nothing to "match".
        // The plugin auto-creates its own default channel
        // ("FOREGROUND_DEFAULT" / "Background Service") only when
        // notificationChannelId is left null; passing a custom id here
        // without separately creating that channel (e.g. via
        // flutter_local_notifications, which isn't a dependency of this
        // app) risks the foreground notification silently failing to post
        // on Android 8+.
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Starts the background tracking service for [studentId] (the serdik
  /// numeric id — `UserEntity.serdikId`). No-ops if already running; in
  /// that case just re-sends the studentId (covers the case where a
  /// different serdik logs in on the same device without a full app
  /// restart in between).
  static Future<void> start({required String studentId}) async {
    await initialize();
    try {
      await _storage.write(key: _studentIdStorageKey, value: studentId);
    } catch (e) {
      developer.log('BackgroundLocationService.start() storage write failed: $e', name: 'BackgroundLocation');
    }
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.startService();
    }
    // Live update in case the service was already running for a previous
    // session on this device (see _studentIdStorageKey doc for why this
    // alone isn't relied on for the initial/cold-start value).
    _service.invoke('setStudent', {'studentId': studentId});
  }

  /// Tells the running service which activity/kegiatan zone the student is
  /// currently inside (or null when outside every zone / unknown). This is
  /// best-effort context attached to pings; the ping loop itself keeps
  /// running independently of any screen being open.
  static void updateActivityLocation(String? activityLocationId) {
    _service.invoke('setActivityLocation', {
      'activityLocationId': activityLocationId,
    });
  }

  /// Stops tracking. Call on logout.
  static Future<void> stop() async {
    try {
      await _storage.delete(key: _studentIdStorageKey);
    } catch (_) {}
    try {
      final isRunning = await _service.isRunning();
      if (isRunning) {
        _service.invoke('stopService');
      }
    } catch (e) {
      developer.log('BackgroundLocationService.stop() error: $e', name: 'BackgroundLocation');
    }
  }

  /// Fires whenever a live GPS reading used for a ping is flagged as
  /// mocked (Android `Position.isMocked`; always false on iOS — the
  /// platform doesn't expose real mock detection). The ping is still sent
  /// so the backend can log/reject it, but the UI should surface this to
  /// the user. Only observable while some screen is actively listening
  /// (e.g. AttendanceScreen) — there is no in-app UI to show this from a
  /// fully backgrounded/killed app, only the persistent foreground
  /// notification.
  static Stream<Map<String, dynamic>?> get onFakeGpsDetected => _service.on('fakeGpsDetected');

  /// Fires when the background isolate's ping (or outbox flush) gets a 401
  /// from `/mobile/location` — i.e. the server has revoked this device's
  /// session (most commonly: the same account logged in elsewhere, which
  /// invalidates `users.current_token` server-side — see
  /// `backend/middleware/auth.go`'s single-active-session enforcement).
  /// Unlike a plain network failure, retrying will never succeed, so the
  /// background isolate stops itself and fires this event instead of
  /// queueing. The main isolate should treat this as "forced logout":
  /// clear local session state and navigate to the login screen. See
  /// `AuthBloc`'s `ForceLogoutRequested` event, which both this stream and
  /// the main-isolate Dio interceptor's refresh-failure path funnel into.
  static Stream<Map<String, dynamic>?> get onSessionExpired => _service.on('sessionExpired');
}

const Duration _pingInterval = Duration(seconds: 10);
const Duration _flushMinInterval = Duration(seconds: 5);
const String _locationEndpoint = '/mobile/location';

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  // iOS background-fetch style callbacks (BGTaskScheduler, which is what
  // flutter_background_service's IosConfiguration.onBackground wraps) are
  // limited to ~15-30s and do not support a long-running position stream
  // the way the Android foreground service does — it was never going to be
  // the right tool for continuous tracking. Real iOS background location
  // instead comes from `_onStart` (wired as `onForeground`, which on iOS
  // is already the code path that runs whenever the app process is alive,
  // backgrounded or not) combined with CLLocationManager background
  // delivery: "Always" location authorization + `UIBackgroundModes:
  // location` in Info.plist + `AppleSettings(allowBackgroundLocationUpdates:
  // true, ...)` on the position stream below. When those are in place, iOS
  // itself keeps the process alive and keeps delivering position callbacks
  // to `_onStart` while backgrounded — no separate background isolate is
  // needed on iOS the way Android requires one, so this stub is left as a
  // harmless no-op satisfying the plugin's required callback contract.
  //
  // One thing genuinely cannot be fixed from app code: if the user
  // force-quits the app (swipe-kill) on iOS, ALL background execution —
  // including CLLocationManager background delivery — stops immediately
  // and unconditionally. This is deliberate iOS OS-level behavior (by
  // design, so users can be certain a swiped-away app is truly not
  // running), not a bug or a gap in this implementation, and no app-level
  // technique (background modes, significant-location-change, etc.)
  // bypasses it. Only re-opening the app resumes tracking.
  return true;
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    developer.log('BackgroundLocation: dotenv.load failed: $e', name: 'BackgroundLocation');
  }

  const secureStorage = FlutterSecureStorage();
  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  );



  final dbHelper = LocalDatabaseHelper.instance;

  String? studentId;
  String? activityLocationId;
  Position? lastPosition;
  DateTime? lastFlushAttempt;
  bool sessionExpiredHandled = false;

  // Declared here (assigned further down, once the position stream and
  // timers actually start) so that `stopTracking`/`handleSessionExpired`
  // below — which are themselves defined before `sendPing`/`flushOutbox`
  // need them — can close over them. Dart requires a variable to be
  // lexically declared before any reference to it, even inside a closure
  // that only runs later, so these `late final`s stand in as forward
  // declarations.
  late final StreamSubscription<Position> positionSub;
  late final Timer pingTimer;
  late final Timer flushTimer;

  /// Shared teardown: cancels the position stream and both timers, then
  /// stops the service. Reused by both a normal `stopService` invoke
  /// (from the main isolate, on manual logout) and [handleSessionExpired]
  /// (401 from the server, detected in this isolate) so there is exactly
  /// one place that knows how to shut this isolate down cleanly.
  Future<void> stopTracking() async {
    await positionSub.cancel();
    pingTimer.cancel();
    flushTimer.cancel();
    await service.stopSelf();
  }

  /// Called when a ping or outbox flush gets a 401 back from
  /// `/mobile/location` — the server has revoked this device's session
  /// (see [BackgroundLocationService.onSessionExpired] doc). Idempotent:
  /// safe to call from both `sendPing` and `flushOutbox` even if a 401
  /// races in from both at nearly the same time.
  Future<void> handleSessionExpired() async {
    if (sessionExpiredHandled) return;
    sessionExpiredHandled = true;
    developer.log(
      'BackgroundLocation: 401 received, session expired — stopping tracking',
      name: 'BackgroundLocation',
    );
    service.invoke('sessionExpired', {});
    await stopTracking();
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await secureStorage.read(key: kAuthAccessTokenStorageKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
            handler.next(options);
          } else {
            developer.log('BackgroundLocation: No token, stopping silently', name: 'BackgroundLocation');
            stopTracking();
            handler.reject(DioException(requestOptions: options, error: 'No token'));
          }
        } catch (e) {
          developer.log('BackgroundLocation: token read failed: $e', name: 'BackgroundLocation');
          handler.next(options);
        }
      },
    ),
  );

  // Read the last-known studentId directly from storage rather than
  // waiting on the setStudent invoke() message — see
  // BackgroundLocationService._studentIdStorageKey doc for why the message
  // alone is not reliable for the cold-start value (it can be sent before
  // this isolate has finished booting and subscribed its listeners, and a
  // broadcast stream does not replay missed events to late subscribers).
  try {
    studentId = await secureStorage.read(key: BackgroundLocationService._studentIdStorageKey);
  } catch (e) {
    developer.log('BackgroundLocation: initial studentId read failed: $e', name: 'BackgroundLocation');
  }

  service.on('setStudent').listen((event) {
    studentId = event?['studentId'] as String?;
  });
  service.on('setActivityLocation').listen((event) {
    activityLocationId = event?['activityLocationId'] as String?;
  });

  Map<String, dynamic> buildPayload(Position pos, {required int studentIdInt}) {
    return {
      'student_id': studentIdInt,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'activity_location_id': activityLocationId,
      'is_mocked': pos.isMocked,
      'accuracy': pos.accuracy,
      'speed': pos.speed,
      'client_timestamp': (pos.timestamp.toIso8601String()),
    };
  }

  Future<void> flushOutbox() async {
    final now = DateTime.now();
    if (lastFlushAttempt != null && now.difference(lastFlushAttempt!) < _flushMinInterval) {
      return;
    }
    lastFlushAttempt = now;

    try {
      final pending = await dbHelper.getPendingLocationPings(limit: 20);
      for (final row in pending) {
        try {
          await dio.post(_locationEndpoint, data: {
            'student_id': row['student_id'],
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'activity_location_id': row['activity_location_id'],
            'is_mocked': row['is_mocked'] == 1,
            'accuracy': row['accuracy'],
            'speed': row['speed'],
            'client_timestamp': row['client_timestamp'],
          });
          await dbHelper.deleteLocationPing(row['id'] as int);
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 401) {
            // Session revoked — the rest of the outbox will never succeed
            // either under this dead token, so stop draining entirely
            // rather than just breaking this cycle. Row stays queued
            // un-deleted, but that no longer matters once the isolate
            // stops (see handleSessionExpired doc).
            await handleSessionExpired();
            return;
          }
          developer.log('BackgroundLocation: flush failed, stopping for now: $e', name: 'BackgroundLocation');
          break; // still offline / still failing — stop for this cycle
        }
      }
    } catch (e) {
      developer.log('BackgroundLocation: flushOutbox error: $e', name: 'BackgroundLocation');
    }
  }

  Future<void> sendPing(Position pos) async {
    final sId = int.tryParse(studentId ?? '');
    if (sId == null) return;

    if (pos.isMocked) {
      service.invoke('fakeGpsDetected', {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'timestamp': pos.timestamp.toIso8601String(),
      });
    }

    final payload = buildPayload(pos, studentIdInt: sId);

    try {
      await dio.post(_locationEndpoint, data: payload);
      developer.log(
        'Ping sent -> student:$sId lat:${pos.latitude} lng:${pos.longitude} mocked:${pos.isMocked}',
        name: 'BackgroundLocation',
      );
      // Opportunistic: a successful send means we're online, so drain
      // anything queued while we were offline.
      await flushOutbox();
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        // Session revoked server-side (e.g. the same account logged in
        // elsewhere, invalidating this device's token) — distinct from a
        // plain network failure/timeout, which keeps queueing as normal.
        // Retrying can never succeed under a dead session, so this
        // payload is deliberately dropped rather than enqueued (it would
        // just sit in the outbox forever) and tracking stops.
        await handleSessionExpired();
        return;
      }
      developer.log('BackgroundLocation: ping failed, queueing: $e', name: 'BackgroundLocation');
      try {
        await dbHelper.enqueueLocationPing(payload);
      } catch (dbErr) {
        developer.log('BackgroundLocation: enqueue failed: $dbErr', name: 'BackgroundLocation');
      }
    }
  }

  // On Android, the real foreground service (isForegroundMode: true, see
  // initialize()) is what keeps this isolate alive, so the generic
  // LocationSettings below is enough. On iOS there is no separate
  // background isolate — `_onStart` runs as `onForeground` and is already
  // the code path alive whenever the process is alive (see _onIosBackground
  // doc) — so AppleSettings' background-delivery flags are what keep iOS
  // actually *delivering* position callbacks here while the app is
  // backgrounded. `allowBackgroundLocationUpdates`/`showBackgroundLocationIndicator`
  // only take effect once "Always" authorization is granted (see the
  // permission flow in geofence_map_widget.dart) and Info.plist declares
  // `UIBackgroundModes: location` — without both, iOS simply pauses
  // delivery once backgrounded regardless of these settings.
  final locationSettings = Platform.isIOS
      ? AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        )
      : const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        );

  positionSub = Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).listen(
    (Position position) {
      if (position.latitude.isFinite && position.longitude.isFinite) {
        lastPosition = position;
      }
    },
    onError: (dynamic error) {
      developer.log('BackgroundLocation: position stream error: $error', name: 'BackgroundLocation');
    },
    cancelOnError: false,
  );

  pingTimer = Timer.periodic(_pingInterval, (timer) {
    final pos = lastPosition;
    if (pos != null) {
      sendPing(pos);
    }
  });

  flushTimer = Timer.periodic(_flushMinInterval, (timer) {
    flushOutbox();
  });

  service.on('stopService').listen((event) async {
    await stopTracking();
  });
}

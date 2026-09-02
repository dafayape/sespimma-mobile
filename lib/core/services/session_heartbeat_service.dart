import 'dart:async';
import 'dart:developer' as developer;
import 'package:get_it/get_it.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

/// Realtime session revocation detector.
///
/// Runs a periodic 2-second heartbeat check to `/profile` whenever a user
/// session is active. If the server responds with HTTP 401 (e.g. session ended
/// by Administrator on the web dashboard), it immediately dispatches
/// [ForceLogoutRequested] to trigger the 3-second cooldown dialog & redirect.
class SessionHeartbeatService {
  SessionHeartbeatService._();

  static Timer? _heartbeatTimer;
  static bool _isChecking = false;

  static void start() {
    stop();
    developer.log('SessionHeartbeatService: started (5s interval)', name: 'Heartbeat');
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkSession();
    });
  }

  static void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isChecking = false;
    developer.log('SessionHeartbeatService: stopped', name: 'Heartbeat');
  }

  static Future<void> _checkSession() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      GetIt.instance<AuthBloc>().add(const RefreshProfileRequested());
    } catch (e) {
      developer.log('Heartbeat check error: $e', name: 'Heartbeat');
    } finally {
      _isChecking = false;
    }
  }
}

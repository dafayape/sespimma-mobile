import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Local Notification clicked: ${response.payload}');
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sespimma_notifications',
      'Pemberitahuan SESPIMMA',
      description: 'Notifikasi resmi lembaga SESPIMMA',
      importance: Importance.max,
      playSound: true,
    );

    const AndroidNotificationChannel silentChannel = AndroidNotificationChannel(
      'sespimma_location_silent',
      'Layanan Lokasi (Sistem)',
      description: 'Melacak lokasi untuk keperluan presensi',
      importance: Importance.min,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.createNotificationChannel(silentChannel);

    _isInitialized = true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'sespimma_notifications',
      'Pemberitahuan SESPIMMA',
      channelDescription: 'Notifikasi resmi lembaga SESPIMMA',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
}

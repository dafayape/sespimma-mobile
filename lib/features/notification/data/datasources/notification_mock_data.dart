import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../assessment/data/models/korsis_inbox_mock_data.dart';
import '../../../attendance/domain/models/map_tile_mode.dart';
import '../../../auth/data/datasources/gadik_real_data.dart';
import '../../../auth/data/datasources/korsis_real_data.dart';
import '../../../auth/data/datasources/patun_real_data.dart';
import '../../../auth/data/datasources/operator_real_data.dart';
import '../../../leadership_report/domain/services/score_calculator_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class NotificationMockData {
  NotificationMockData._();

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final List<Map<String, dynamic>> items = [];
  static final Set<String> _shownNotificationIds = {};
  static bool _isFirstFetch = true;
  static Timer? _syncTimer;

  static void startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      fetchApiNotifications();
    });
  }

  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static String _getFullName(String name) {
    String lower = name.toLowerCase();

    if (lower == 'korsis' || lower.contains('korsis')) {
      for (var k in KorsisRealData.records) {
        if (k['nama'].toString().toLowerCase().contains(lower) ||
            lower == 'korsis') {
          return k['nama'] as String;
        }
      }
      return KorsisRealData.records.first['nama'] as String;
    }

    for (var g in GadikRealData.records) {
      if (g['nama'].toString().toLowerCase().contains(lower) ||
          g['nrp_nip'] == name) {
        return g['nama'] as String;
      }
    }

    for (var p in PatunRealData.records) {
      if (p['nama'].toString().toLowerCase().contains(lower)) {
        return p['nama'] as String;
      }
    }

    for (var o in OperatorRealData.records) {
      if (o['nama'].toString().toLowerCase().contains(lower)) {
        return o['nama'] as String;
      }
    }

    return name;
  }

  static void initialize(UserEntity user) {
    final oldStatus = <String, bool>{};
    for (var item in items) {
      oldStatus[item['id']] = item['isRead'] as bool;
    }

    items.clear();
    int unread = 0;

    for (var item in KorsisInboxMockData.items) {
      bool isTargetSerdik =
          user.roleId.toLowerCase() != 'siswa' || item.nosis == user.noSerdik;

      final bool isDirectOrApproved =
          item.status == 'approved' ||
          item.status == 'disetujui' ||
          item.senderName.toLowerCase().contains('korsis') ||
          item.senderName.toLowerCase().contains('sistem');

      if (isDirectOrApproved && isTargetSerdik) {
        final id = 'inbox_${item.id}';
        final isRead = oldStatus[id] ?? false;
        final senderFull = _getFullName(item.senderName);
        items.add({
          'id': id,
          'title': item.rewardPunishmentName,
          'message': 'Diberikan oleh $senderFull',
          'dateTime': item.timestamp,
          'isRead': isRead,
          'type': item.isReward ? 'reward' : 'punishment',
          'person': senderFull,
        });
        if (!isRead) unread++;
      }
    }

    if (user.roleId.toLowerCase() == 'siswa') {
      final raw = ScoreCalculatorService.generateSimulatedScores(user.noSerdik);
      final double sosiometriScore = (raw['NS'] as num?)?.toDouble() ?? 0.0;

      if (sosiometriScore > 0) {
        final id = 'soc_keluar_dinamis';
        final isRead = oldStatus[id] ?? false;
        items.add({
          'id': id,
          'title': 'Nilai Sosiometri Telah Keluar',
          'message':
              'Sosiometri berhasil dinilai silahkan cek laporan nilai untuk melihat hasilnya',
          'dateTime': DateTime.now().subtract(const Duration(minutes: 5)),
          'isRead': isRead,
          'type': 'sosiometri_done',
          'person': 'Sistem',
        });
        if (!isRead) unread++;
      }
    }

    final activeZones = AttendanceZones.activeZones;
    for (var zone in activeZones) {
      final id = 'zone_${zone.id}';
      final isRead = oldStatus[id] ?? false;
      final creatorFull = _getFullName(zone.creator);
      final createdAt = zone.createdAt;

      items.add({
        'id': id,
        'title': zone.name,
        'message':
            'Lokasi kegiatan telah dibuat oleh $creatorFull. Segera melakukan presensi.',
        'dateTime': createdAt,
        'isRead': isRead,
        'type': 'zone',
        'person': creatorFull,
      });
      if (!isRead) unread++;
    }

    items.sort(
      (a, b) =>
          (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime),
    );
    unreadCountNotifier.value = unread;
    fetchApiNotifications();
  }

  static Future<void> fetchApiNotifications({bool triggerBanner = false}) async {
    try {
      if (GetIt.instance.isRegistered<AuthBloc>()) {
        final authBloc = GetIt.instance<AuthBloc>();
        if (authBloc.state is! AuthSuccess) return;
      }
      final dio = GetIt.instance<Dio>();
      final response = await dio.get('/notifications?limit=50');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        final List rawItems = data['data']['items'] ?? [];

        final apiItems = <Map<String, dynamic>>[];
        for (var item in rawItems) {
          final DateTime dt = item['created_at'] != null
              ? DateTime.parse(item['created_at'].toString())
              : DateTime.now();
          final String notifId = item['id'].toString();
          final bool isRead = item['is_read'] == true;
          final String title = item['title'] ?? 'Pemberitahuan';
          final String message = item['body'] ?? '-';

          apiItems.add({
            'id': notifId,
            'title': title,
            'message': message,
            'dateTime': dt,
            'isRead': isRead,
            'type': (item['modul'] ?? 'info').toString().toLowerCase(),
            'person': item['action_label'] ?? 'Operator',
          });

          if (triggerBanner) {
            if (_isFirstFetch) {
              _shownNotificationIds.add(notifId);
            } else {
              if (!isRead && !_shownNotificationIds.contains(notifId)) {
                _shownNotificationIds.add(notifId);
                final isRecent = DateTime.now().difference(dt).inMinutes < 5;
                if (isRecent) {
                  final int numericId = int.tryParse(notifId) ?? DateTime.now().millisecondsSinceEpoch % 100000;
                  LocalNotificationService.showNotification(
                    id: numericId,
                    title: title,
                    body: message,
                  );
                }
              }
            }
          } else {
            _shownNotificationIds.add(notifId);
          }
        }

        _isFirstFetch = false;

        if (apiItems.isNotEmpty) {
          final existingIds = apiItems.map((i) => i['id']).toSet();
          items.removeWhere((i) => existingIds.contains(i['id']));
          items.insertAll(0, apiItems);

          items.sort(
            (a, b) =>
                (b['dateTime'] as DateTime).compareTo(a['dateTime'] as DateTime),
          );
          unreadCountNotifier.value = items.where((i) => !i['isRead']).length;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications API: $e');
    }
  }

  static void markAsRead(String id) {
    final index = items.indexWhere((i) => i['id'] == id);
    if (index != -1 && items[index]['isRead'] == false) {
      items[index]['isRead'] = true;
      unreadCountNotifier.value = (unreadCountNotifier.value - 1).clamp(0, 999);

      if (int.tryParse(id) != null) {
        try {
          final dio = GetIt.instance<Dio>();
          dio.put('/notifications/$id/read');
        } catch (_) {}
      }
    }
  }

  static void markAllAsRead() {
    for (var item in items) {
      item['isRead'] = true;
    }
    unreadCountNotifier.value = 0;
    try {
      final dio = GetIt.instance<Dio>();
      dio.put('/notifications/read-all');
    } catch (_) {}
  }
}

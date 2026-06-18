import 'dart:collection';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/notification_mock_data.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isDataPopulated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  void _populateNotifications(UserEntity user) {
    if (!_isDataPopulated) {
      setState(() {
        NotificationMockData.initialize(user);
      });
      _isDataPopulated = true;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _selectedDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryNavy,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess && !_isDataPopulated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDataPopulated) {
              _populateNotifications(state.user);
            }
          });
        }

        final filteredNotifs = _selectedDateRange == null
            ? NotificationMockData.items
            : NotificationMockData.items.where((notif) {
                final dt = notif['dateTime'] as DateTime;
                final start = DateTime(
                  _selectedDateRange!.start.year,
                  _selectedDateRange!.start.month,
                  _selectedDateRange!.start.day,
                );
                final end = DateTime(
                  _selectedDateRange!.end.year,
                  _selectedDateRange!.end.month,
                  _selectedDateRange!.end.day,
                  23,
                  59,
                  59,
                );
                return dt.isAfter(start.subtract(const Duration(seconds: 1))) &&
                    dt.isBefore(end.add(const Duration(seconds: 1)));
              }).toList();

        final LinkedHashMap<String, List<Map<String, dynamic>>> groupedNotifs =
            LinkedHashMap();
        for (var notif in filteredNotifs) {
          final dt = notif['dateTime'] as DateTime;
          final months = [
            'Januari',
            'Februari',
            'Maret',
            'April',
            'Mei',
            'Juni',
            'Juli',
            'Agustus',
            'September',
            'Oktober',
            'November',
            'Desember',
          ];
          final date =
              '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';

          if (!groupedNotifs.containsKey(date)) {
            groupedNotifs[date] = [];
          }
          groupedNotifs[date]!.add(notif);
        }

        final sortedDates = groupedNotifs.keys.toList();

        if (state is AuthInitial ||
            (state is AuthSuccess && !_isDataPopulated)) {
          return const Scaffold(
            backgroundColor: _lightGrey,
            body: Center(child: CircularProgressIndicator(color: _primaryNavy)),
          );
        }

        return Scaffold(
          backgroundColor: _lightGrey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Notifikasi',
              style: TextStyle(
                color: _primaryNavy,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontXl,
              ),
            ),
            leading: IconButton(
              icon: const Icon(AppIcons.caretLeft, color: _primaryNavy),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _selectedDateRange != null
                      ? AppIcons.calendarFill
                      : AppIcons.calendarBlank,
                  color: _selectedDateRange != null
                      ? Colors.teal.shade600
                      : _primaryNavy,
                  size: AppDimensions.iconDefault + 2,
                ),
                tooltip: 'Filter Tanggal',
                onPressed: _pickDateRange,
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  AppIcons.dotsThreeVertical,
                  color: _primaryNavy,
                ),
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                onSelected: (value) {
                  if (value == 'refresh') {
                    setState(() {
                      _animController.reset();
                      _animController.forward();
                    });
                  } else if (value == 'read_all') {
                    setState(() {
                      NotificationMockData.markAllAsRead();
                    });
                  } else if (value == 'clear_filter') {
                    setState(() {
                      _selectedDateRange = null;
                    });
                    _animController.reset();
                    _animController.forward();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'refresh',
                    child: Text(
                      'Refresh',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'read_all',
                    child: Text(
                      'Tandai sudah dibaca',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_selectedDateRange != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'clear_filter',
                      child: Text(
                        'Bersihkan Filter',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: AppDimensions.sm),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Expanded(
                    child: NotificationMockData.items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            itemCount: sortedDates.length,
                            itemBuilder: (context, index) {
                              final dateKey = sortedDates[index];
                              final items = groupedNotifs[dateKey]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: 12,
                                      top: index == 0 ? 0 : 16,
                                    ),
                                    child: Text(
                                      dateKey,
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontLg,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ),
                                  ...items.map((notif) {
                                    return Dismissible(
                                      key: ValueKey(notif['id']),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 20.0,
                                        ),
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD32F2F),
                                          borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusLg,
                                          ),
                                        ),
                                        child: const Icon(
                                          AppIcons.trashFill,
                                          color: Colors.white,
                                          size: AppDimensions.iconDefault + 2,
                                        ),
                                      ),
                                      onDismissed: (direction) {
                                        HapticFeedback.mediumImpact();
                                        final String deletedId =
                                            notif['id'] as String;
                                        setState(() {
                                          NotificationMockData.items
                                              .removeWhere(
                                                (item) =>
                                                    item['id'] == deletedId,
                                              );
                                          NotificationMockData
                                              .unreadCountNotifier
                                              .value = NotificationMockData
                                              .items
                                              .where((i) => !i['isRead'])
                                              .length;
                                        });
                                        AppNotifier.showSuccess(
                                          context,
                                          'Notifikasi berhasil dihapus',
                                        );
                                      },
                                      child: _AnimatedNotificationTile(
                                        notification: notif,
                                        animation: const AlwaysStoppedAnimation(
                                          1.0,
                                        ),
                                        onTap: () {
                                          final String currentId =
                                              notif['id'] as String;
                                          setState(() {
                                            NotificationMockData.markAsRead(
                                              currentId,
                                            );
                                          });
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _animController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.bellSlash,
                size: AppDimensions.iconDisplay,
                color: Colors.blueGrey.shade300,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Belum ada aktivitas atau pemberitahuan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.blueGrey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _AnimatedNotificationTile({
    required this.notification,
    required this.animation,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification['type']) {
      case 'reward':
        return AppIcons.thumbUp;
      case 'punishment':
        return AppIcons.thumbDown;
      case 'task':
        return AppIcons.clipboardTextFill;
      case 'task_dikirim':
        return AppIcons.paperPlaneTiltFill;
      case 'task_dinilai':
        return AppIcons.checkCircleFill;
      case 'task_remedial':
        return AppIcons.warningOctagonFill;
      case 'zone':
        return AppIcons.mapPinFill;
      case 'sosiometri_start':
        return AppIcons.usersThreeFill;
      case 'sosiometri_reminder':
        return AppIcons.usersThreeFill;
      case 'sosiometri_done':
        return AppIcons.checkCircleFill;
      default:
        return AppIcons.infoFill;
    }
  }

  Color _getColor() {
    switch (notification['type']) {
      case 'reward':
        return const Color(0xFF2E7D32);
      case 'punishment':
        return const Color(0xFFD32F2F);
      case 'task':
        return Colors.blue.shade600;
      case 'task_dikirim':
        return Colors.indigo.shade600;
      case 'task_dinilai':
        return const Color(0xFF2E7D32);
      case 'task_remedial':
        return const Color(0xFFFBC02D);
      case 'zone':
        return const Color(0xFFF57C00);
      case 'sosiometri_start':
        return const Color(0xFF4F46E5);
      case 'sosiometri_reminder':
        return const Color(0xFFF57C00);
      case 'sosiometri_done':
        return const Color(0xFF2E7D32);
      default:
        return Colors.blueGrey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['isRead'];
    final iconColor = _getColor();

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: isRead
                  ? Colors.grey.shade300
                  : iconColor.withValues(alpha: 0.3),
              width: isRead ? 1 : 1.5,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.sm + 2),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.grey.shade100
                            : iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(),
                        color: isRead ? Colors.grey.shade500 : iconColor,
                        size: AppDimensions.iconLg,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification['title'],
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontLg,
                                    fontWeight: isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: const Color(0xFF001C40),
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD32F2F),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.radiusSm),
                          Text(
                            notification['message'] ?? '-',
                            style: TextStyle(
                              fontSize: AppDimensions.fontDefault,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Row(
                            children: [
                              Icon(
                                AppIcons.clockFill,
                                size: AppDimensions.fontSm + 1,
                                color: Colors.blueGrey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(notification['dateTime'] as DateTime).toLocal().hour.toString().padLeft(2, '0')}.${(notification['dateTime'] as DateTime).toLocal().minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontSm + 1,
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

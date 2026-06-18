import 'dart:collection';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/shared/widgets/evidence_bottom_sheet.dart';
import 'package:sespimma/core/theme/app_colors.dart';

import 'package:sespimma/injection_container.dart';
import 'package:sespimma/features/assessment/data/datasources/inbox_remote_data_source.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../assessment/data/models/sociometry_period_config.dart';
import '../../../attendance/domain/models/map_tile_mode.dart';
import '../../../assessment/data/models/korsis_inbox_mock_data.dart';
import '../../../gadik_assignment/data/datasources/gadik_assignment_mock_data.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final String initialFilter;

  const ActivityHistoryScreen({super.key, this.initialFilter = 'Semua'});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<Map<String, dynamic>> _mockActivities = [];
  bool _isDataPopulated = false;

  String _getDynamicDateStr(DateTime target) {
    const months = [
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
    final monthName = months[target.month - 1];
    final dayStr = target.day.toString().padLeft(2, '0');
    return '$dayStr $monthName ${target.year}';
  }

  String _formatDynamicTime(DateTime target) {
    final localTarget = target.toLocal();
    final hourStr = localTarget.hour.toString().padLeft(2, '0');
    final minStr = localTarget.minute.toString().padLeft(2, '0');
    return '$hourStr.$minStr';
  }

  String _getGadikFullName(String sender) {
    if (sender == 'Gadik A') return 'Kombes Pol. Anton Suratto';
    if (sender == 'Gadik B') return 'Kombes Pol. Budi Santoso';
    if (sender == 'Gadik C') return 'Kombes Pol. Candra Muka';
    if (sender == 'Korsis A') return 'Kombes Pol. Ahmad Setiawan';
    if (sender == 'Patun A') return 'Kombes Pol. Bambang Sugeng';
    return sender;
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  Future<void> _populateActivities(UserEntity user) async {
    final today = DateTime.now();
    final role = user.roleId.toLowerCase();

    final List<Map<String, dynamic>> list = [];

    List<InboxItem> realInboxItems = [];
    if (role == 'siswa') {
      try {
        final inboxSource = sl<InboxRemoteDataSource>();
        realInboxItems = await inboxSource.getInbox(status: 'all');
        debugPrint("DEBUG ACTIVITY: fetched ${realInboxItems.length} items from remote source");
      } catch (e, stack) {
        debugPrint("DEBUG ACTIVITY ERROR: failed to fetch inbox: $e");
        debugPrint("$stack");
      }
    }

    if (role == 'siswa') {
      if (SociometryPeriodConfig.isAnyActive()) {
        final filledCount = SociometryPeriodConfig.getFilledCount();
        if (filledCount > 0) {
          final totalCount = SociometryPeriodConfig.getTotalCount();
          final phase = SociometryPeriodConfig.isAkhirActive()
              ? 'Akhir'
              : 'Awal';
          final phaseStart = SociometryPeriodConfig.isAkhirActive()
              ? SociometryPeriodConfig.akhirStartDate
              : SociometryPeriodConfig.awalStartDate;
          final fillDate = phaseStart.add(
            const Duration(days: 1, hours: 14, minutes: 30),
          );
          list.add({
            'id': 'act_dyn_sosiometri',
            'title': 'Pengisian Sosiometri $phase',
            'subtitle':
                'Telah berhasil mengisi partisipasi evaluasi sosiometri untuk $filledCount / $totalCount rekan peleton.',
            'timeRaw': _formatDynamicTime(fillDate),
            'date': _getDynamicDateStr(fillDate),
            'dateTime': fillDate,
            'points': '',
            'type': 'task',
          });
        }
      }

      for (var inbox in realInboxItems) {
        final bool isDirectOrApproved =
            inbox.status == 'approved' ||
            inbox.status == 'disetujui' ||
            inbox.senderName.toLowerCase().contains('korsis') ||
            inbox.senderName.toLowerCase().contains('sistem');

        if (isDirectOrApproved && inbox.nosis == user.noSerdik) {
          final isReward = inbox.isReward;
          final typeStr = isReward ? 'reward' : 'punishment';
          final pointStr = isReward
              ? '+${inbox.points.toStringAsFixed(2)}'
              : inbox.points.toStringAsFixed(2);
          list.add({
            'id': inbox.id,
            'title': inbox.rewardPunishmentName,
            'subtitle': 'Diberikan oleh ${_getGadikFullName(inbox.senderName)}',
            'timeRaw': _formatDynamicTime(inbox.timestamp),
            'date': _getDynamicDateStr(inbox.timestamp),
            'dateTime': inbox.timestamp,
            'points': pointStr,
            'type': typeStr,
            'photoPath': inbox.photoPath,
          });
        }
      }

      for (var zone in AttendanceZones.activeZones) {
        list.add({
          'id': 'zone_${zone.id}',
          'title': zone.activityName,
          'subtitle':
              '${zone.name} telah dibuat oleh ${_getGadikFullName(zone.creator)}. Segera melakukan presensi.',
          'timeRaw': _formatDynamicTime(zone.createdAt),
          'date': _getDynamicDateStr(zone.createdAt),
          'dateTime': zone.createdAt,
          'points': '',
          'type': 'zone',
        });
      }

      for (var task in GadikAssignmentMockData.assignments) {
        if (task.status == 'Belum Mulai' || task.status == 'Sedang Berjalan') {
          list.add({
            'id': 'task_${task.id}',
            'title': task.judul,
            'subtitle':
                'Segera kumpulkan tugas sebelum tenggat waktu ${_getDynamicDateStr(task.deadline)}, ${_formatDynamicTime(task.deadline)}.',
            'timeRaw': _formatDynamicTime(task.createdAt),
            'date': _getDynamicDateStr(task.createdAt),
            'dateTime': task.createdAt,
            'points': '',
            'type': 'task',
          });
        } else if (task.status == 'Selesai') {
          list.add({
            'id': 'task_${task.id}',
            'title': task.judul,
            'subtitle':
                'Selamat tugas kamu sudah dikirim ke ${_getGadikFullName(task.createdBy)}. Terus pantau riwayat tugas untuk melihat nilai',
            'timeRaw': _formatDynamicTime(task.createdAt),
            'date': _getDynamicDateStr(task.createdAt),
            'dateTime': task.createdAt,
            'points': '',
            'type': 'task_dikirim',
          });
        } else if (task.status == 'Dinilai') {
          list.add({
            'id': 'task_${task.id}',
            'title': task.judul,
            'subtitle':
                'Selamat tugas kamu sudah dinilai oleh ${_getGadikFullName(task.createdBy)}. Silahkan cek nilaimu segera',
            'timeRaw': _formatDynamicTime(task.createdAt),
            'date': _getDynamicDateStr(task.createdAt),
            'dateTime': task.createdAt,
            'points': '',
            'type': 'task_dinilai',
          });
        } else if (task.status == 'Remedial') {
          list.add({
            'id': 'task_${task.id}',
            'title': task.judul,
            'subtitle':
                'Remedial untuk kamu, segera cek tugas aktif. Kumpulkan sebelum tenggat waktu (${_getDynamicDateStr(task.deadline)}, ${_formatDynamicTime(task.deadline)})',
            'timeRaw': _formatDynamicTime(task.createdAt),
            'date': _getDynamicDateStr(task.createdAt),
            'dateTime': task.createdAt,
            'points': '',
            'type': 'task_remedial',
          });
        }
      }
    } else if (role == 'gadik' || role == 'patun' || role == 'instruktur') {
      if (SociometryPeriodConfig.isAnyActive()) {
        list.add({
          'id': 'act_gadik_dyn_sosiometri',
          'title': 'Memonitor Progres Sosiometri',
          'subtitle':
              'Mengakses panel rekapitulasi pengisian evaluasi sosiometri peleton yang sedang berlangsung.',
          'timeRaw': _formatDynamicTime(
            today.subtract(const Duration(hours: 1)),
          ),
          'date': _getDynamicDateStr(today),
          'dateTime': today,
          'points': '',
          'type': 'task',
        });
      }
    }

    list.sort((a, b) {
      final dtA = a['dateTime'] as DateTime;
      final dtB = b['dateTime'] as DateTime;
      return dtB.compareTo(dtA);
    });

    if (mounted) {
      setState(() {
        _mockActivities = list;
        _isDataPopulated = true;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = AppColors.background;

  late String _selectedFilter;
  final List<String> _filters = [
    'Semua',
    'Reward',
    'Punishment',
    'Tugas',
    'Zona',
  ];
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
      _animController.forward(from: 0.0);
    }
  }

  Widget _buildActiveFiltersBar() {
    final bool hasStatusFilter = _selectedFilter != 'Semua';
    final bool hasDateFilter = _selectedDateRange != null;
    if (!hasStatusFilter && !hasDateFilter) return const SizedBox.shrink();

    Color filterColor = _primaryNavy;
    if (_selectedFilter == 'Reward') {
      filterColor = const Color(0xFF2E7D32);
    } else if (_selectedFilter == 'Punishment') {
      filterColor = const Color(0xFFD32F2F);
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (hasStatusFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(
                  'Kategori: $_selectedFilter',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: filterColor,
                  ),
                ),
                backgroundColor: filterColor.withValues(alpha: 0.06),
                deleteIcon: Icon(
                  AppIcons.xCircle,
                  size: AppDimensions.iconSm,
                  color: filterColor,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedFilter = 'Semua';
                  });
                  _animController.forward(from: 0.0);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(color: filterColor.withValues(alpha: 0.12)),
                ),
              ),
            ),
          if (hasDateFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: const Text(
                  'Tanggal Aktif',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal,
                  ),
                ),
                backgroundColor: Colors.teal.shade50,
                deleteIcon: Icon(
                  AppIcons.xCircle,
                  size: AppDimensions.iconSm,
                  color: Colors.teal.shade800,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedDateRange = null;
                  });
                  _animController.forward(from: 0.0);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(color: Colors.teal.shade100),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthSuccess) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _primaryNavy)),
          );
        }

        final user = state.user;
        if (!_isDataPopulated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _populateActivities(user);
          });
        }

        final dateFiltered = _selectedDateRange == null
            ? _mockActivities
            : _mockActivities.where((a) {
                final dt = a['dateTime'] as DateTime;
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

        final filteredActivities = _selectedFilter == 'Semua'
            ? dateFiltered
            : dateFiltered.where((a) {
                if (_selectedFilter == 'Reward') return a['type'] == 'reward';
                if (_selectedFilter == 'Punishment') {
                  return a['type'] == 'punishment';
                }
                if (_selectedFilter == 'Tugas') {
                  return a['type'] == 'task' ||
                      a['type'] == 'task_dikirim' ||
                      a['type'] == 'task_dinilai' ||
                      a['type'] == 'task_remedial';
                }
                if (_selectedFilter == 'Zona') return a['type'] == 'zone';
                return true;
              }).toList();

        final LinkedHashMap<String, List<Map<String, dynamic>>>
        groupedActivities = LinkedHashMap();
        for (var activity in filteredActivities) {
          final date = activity['date'] as String;
          if (!groupedActivities.containsKey(date)) {
            groupedActivities[date] = [];
          }
          groupedActivities[date]!.add(activity);
        }

        return Scaffold(
          backgroundColor: _lightGrey,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Riwayat Aktivitas',
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
                  AppIcons.funnel,
                  color: _primaryNavy,
                  size: AppDimensions.iconDefault + 2,
                ),
                tooltip: 'Kategori',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                position: PopupMenuPosition.under,
                onSelected: (String filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _animController.forward(from: 0.0);
                },
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    ..._filters.map((String filter) {
                      final isSelected = _selectedFilter == filter;
                      return PopupMenuItem<String>(
                        value: filter,
                        child: Row(
                          children: [
                            Text(
                              filter,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? _primaryNavy
                                    : Colors.black87,
                                fontSize: AppDimensions.fontLg,
                              ),
                            ),
                            if (isSelected) ...[
                              const Spacer(),
                              const Icon(
                                AppIcons.checkCircleFill,
                                size: AppDimensions.iconMd,
                                color: _primaryNavy,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ];
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  AppIcons.dotsThreeVerticalBold,
                  color: _primaryNavy,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                onSelected: (value) {
                  if (value == 'refresh') {
                    _populateActivities(user);
                    _animController.forward(from: 0.0);
                    AppNotifier.showSuccess(
                      context,
                      'Data berhasil diperbarui',
                    );
                  } else if (value == 'clear_filter') {
                    setState(() {
                      _selectedFilter = 'Semua';
                      _selectedDateRange = null;
                    });
                    _animController.forward(from: 0.0);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Text(
                      'Refresh',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_selectedDateRange != null ||
                      _selectedFilter != 'Semua') ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'clear_filter',
                      child: Text(
                        'Bersihkan Semua Filter',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  _buildActiveFiltersBar(),
                  Expanded(
                    child: filteredActivities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    AppDimensions.lg,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    AppIcons.archive,
                                    size: AppDimensions.iconDisplay,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.lg),
                                const Text(
                                  'Tidak Ada Riwayat',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXxl,
                                    fontWeight: FontWeight.w800,
                                    color: _primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.sm),
                                Text(
                                  'Belum ada aktivitas yang tercatat.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontLg,
                                    color: Colors.blueGrey.shade400,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            itemCount: groupedActivities.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedActivities.keys.elementAt(
                                index,
                              );
                              final items = groupedActivities[dateKey]!;

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
                                  ...items.map((item) {
                                    final itemIndex = filteredActivities
                                        .indexOf(item);
                                    final animation = CurvedAnimation(
                                      parent: _animController,
                                      curve: Interval(
                                        (itemIndex / filteredActivities.length)
                                            .clamp(0.0, 1.0),
                                        1.0,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );
                                    return _AnimatedActivityTile(
                                      key: ValueKey(item['id']),
                                      title: item['title'],
                                      subtitle: item['subtitle'],
                                      time: item['timeRaw'],
                                      points: item['points'],
                                      type: item['type'],
                                      photoPath: item['photoPath'],
                                      animation: animation,
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
}

class _AnimatedActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String points;
  final String type;
  final String? photoPath;
  final Animation<double> animation;

  const _AnimatedActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.points,
    required this.type,
    this.photoPath,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case 'task':
      case 'task_dikirim':
      case 'task_dinilai':
      case 'task_remedial':
        iconColor = Colors.blue.shade600;
        iconData = AppIcons.clipboardTextFill;
        break;
      case 'reward':
        iconColor = const Color(0xFF2E7D32);
        iconData = AppIcons.thumbUp;
        break;
      case 'punishment':
        iconColor = const Color(0xFFD32F2F);
        iconData = AppIcons.thumbDown;
        break;
      case 'zone':
        iconColor = Colors.teal.shade600;
        iconData = AppIcons.mapPinLineFill;
        break;
      case 'info':
      default:
        iconColor = Colors.amber.shade700;
        iconData = AppIcons.infoFill;
        break;
    }

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              onTap: (type == 'reward' || type == 'punishment')
                  ? () {
                      EvidenceBottomSheet.show(
                        context,
                        title: title,
                        description: title,
                        evaluatorName: subtitle,
                        timeText: time,
                        points: points,
                        type: type,
                        photoPath: photoPath,
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: iconColor,
                        size: AppDimensions.iconLg,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontLg,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: AppDimensions.fontMd,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xs / 2),
                          Row(
                            children: [
                              Icon(
                                AppIcons.clock,
                                size: AppDimensions.fontSm,
                                color: Colors.blueGrey.shade300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (points.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          points,
                          style: TextStyle(
                            fontSize: AppDimensions.fontLg + 1,
                            fontWeight: FontWeight.w800,
                            color: iconColor,
                          ),
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

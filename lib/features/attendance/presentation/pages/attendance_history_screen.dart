import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/injection_container.dart';
import '../../data/datasources/absensi_remote_data_source.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _appInfo = 'Loading...';

  List<Map<String, dynamic>> _attendances = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();

    _loadHistory();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      deviceInfo.androidInfo.then((info) {
        if (mounted) {
          setState(() {
            _appInfo = '${info.manufacturer} ${info.model}';
          });
        }
      });
    } else if (Platform.isIOS) {
      deviceInfo.iosInfo.then((info) {
        if (mounted) {
          setState(() {
            _appInfo = info.name;
          });
        }
      });
    } else {
      setState(() {
        _appInfo = 'Unknown Device';
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final source = sl<AbsensiRemoteDataSource>();
      final data = await source.getHistory();
      if (mounted) {
        setState(() {
          _attendances = data.map((e) => {
            'id': e['id'],
            'title': e['title'],
            'date': _formatDate(DateTime.parse(e['dateTime'])),
            'time': _formatTime(DateTime.parse(e['dateTime'])),
            'dateTime': DateTime.parse(e['dateTime']),
            'status': e['status'],
            'type': e['type'],
            'location': e['location'] ?? '-',
            'method': e['method'] ?? '-',
            'attachment': e['attachment'],
            'waktuPelaksanaan': e['waktuPelaksanaan'] ?? '-',
            'waktuBatasAbsen': e['waktuBatasAbsen'] ?? '-',
            'pembuatZona': e['pembuatZona'] ?? '-',
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  String _formatDate(DateTime target) {
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
    return '${target.day.toString().padLeft(2, '0')} $monthName ${target.year}';
  }

  String _formatTime(DateTime target) {
    final localTarget = target.toLocal();
    return '${localTarget.hour.toString().padLeft(2, '0')}.${localTarget.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getAttendances() {
    return _attendances;
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Hadir',
    'Telat',
    'Izin',
    'Tanpa Keterangan',
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
              primary: AppColors.primaryNavy,
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
                  'Status: $_selectedFilter',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryNavy,
                  ),
                ),
                backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.06),
                deleteIcon: const Icon(
                  AppIcons.xCircle,
                  size: AppDimensions.iconSm,
                  color: AppColors.primaryNavy,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedFilter = 'Semua';
                  });
                  _animController.forward(from: 0.0);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(
                    color: AppColors.primaryNavy.withValues(alpha: 0.12),
                  ),
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Riwayat Kehadiran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.primaryNavy,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)),
      );
    }

    final currentAttendances = _getAttendances();

    final filteredByStatus = _selectedFilter == 'Semua'
        ? currentAttendances
        : currentAttendances.where((a) {
            if (_selectedFilter == 'Hadir') return a['type'] == 'hadir';
            if (_selectedFilter == 'Telat') return a['type'] == 'telat';
            if (_selectedFilter == 'Izin') return a['type'] == 'izin';
            if (_selectedFilter == 'Tanpa Keterangan') {
              return a['type'] == 'alpha';
            }
            return true;
          }).toList();

    final filteredActivities = _selectedDateRange == null
        ? filteredByStatus
        : filteredByStatus.where((item) {
            final dt = item['dateTime'] as DateTime;
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

    final Map<String, List<Map<String, dynamic>>> groupedActivities = {};
    for (var act in filteredActivities) {
      final dateKey = act['date'] as String;
      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }
      groupedActivities[dateKey]!.add(act);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXl,
          ),
        ),
        leading: IconButton(
          icon: const Icon(AppIcons.caretLeft, color: AppColors.primaryNavy),
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
                  : AppColors.primaryNavy,
              size: AppDimensions.iconDefault + 2,
            ),
            tooltip: 'Filter Kalender',
            onPressed: _pickDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              AppIcons.funnel,
              color: AppColors.primaryNavy,
              size: AppDimensions.iconDefault + 2,
            ),
            tooltip: 'Filter Status',
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
                                ? AppColors.primaryNavy
                                : Colors.black87,
                            fontSize: AppDimensions.fontLg,
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(
                            AppIcons.checkCircleFill,
                            size: AppDimensions.iconMd,
                            color: AppColors.primaryNavy,
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
              color: AppColors.primaryNavy,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            onSelected: (value) {
              if (value == 'refresh') {
                setState(() {});
                _animController.forward(from: 0.0);
                AppNotifier.showSuccess(context, 'Data berhasil diperbarui');
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
              if (_selectedDateRange != null || _selectedFilter != 'Semua') ...[
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
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthSuccess ? state.user : null;
          return Center(
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
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.sm),
                                Text(
                                  'Belum ada kehadiran yang tercatat untuk filter ini.',
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
                                    return _AnimatedAttendanceTile(
                                      key: ValueKey(item['id']),
                                      title: item['title'],
                                      time: item['time'],
                                      status: item['status'],
                                      type: item['type'],
                                      location: item['location'],
                                      animation: animation,
                                      onTap: () => _showAttendanceDetails(
                                        context,
                                        item,
                                        user,
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
          );
        },
      ),
    );
  }

  void _showAttendanceDetails(
    BuildContext context,
    Map<String, dynamic> item,
    UserEntity? user,
  ) {
    final type = item['type'] as String;
    final bool isHadir = type == 'hadir';
    final bool isTelat = type == 'telat';
    final bool isIzin = type == 'izin';
    final bool isAlpha = type == 'alpha';

    final Color iconColor = isHadir
        ? AppColors.successGreen
        : isTelat
        ? const Color(0xFFFBC02D)
        : (isIzin ? AppColors.warningOrange : AppColors.dangerRed);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd + 2,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.lg),
              const Text(
                'Bukti Presensi Digital',
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              if (user != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: AvatarHelper.getAvatar(user.profilePhoto),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
              ],
              Text(
                item['title'],
                style: const TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Text(
                  item['status'].toUpperCase(),
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: iconColor,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xxl + 4),
              _buildDetailRow(
                AppIcons.mapPinLineFill,
                'Lokasi Kegiatan',
                item['location'] ?? '-',
              ),
              const SizedBox(height: AppDimensions.md),
              _buildDetailRow(
                AppIcons.clockFill,
                'Waktu Pelaksanaan',
                item['waktuPelaksanaan'] ?? '00.00 - 00.00',
              ),
              const SizedBox(height: AppDimensions.md),
              if (!isIzin && !isAlpha)
                _buildDetailRow(
                  AppIcons.timerFill,
                  'Waktu Batas Absen',
                  item['waktuBatasAbsen'] ?? '00.00',
                ),
              if (!isIzin && !isAlpha) const SizedBox(height: AppDimensions.md),
              _buildDetailRow(
                AppIcons.userFocusFill,
                'Pembuat Zona',
                item['pembuatZona'] ?? '-',
              ),
              const SizedBox(height: AppDimensions.md),
              if (isIzin) ...[
                _buildDownloadRow(
                  context,
                  AppIcons.fileTextFill,
                  'Lampiran Dokumen',
                  'Unduh Dokumen Izin',
                ),
                const SizedBox(height: AppDimensions.md),
              ],
              if (!isAlpha && !isIzin)
                _buildDetailRow(
                  AppIcons.fingerprintFill,
                  'Metode Presensi',
                  item['method'] ?? 'Geofencing',
                ),
              if (!isAlpha) ...[
                const SizedBox(height: AppDimensions.md),
                _buildDetailRow(
                  AppIcons.deviceMobileSpeakerFill,
                  'Informasi Perangkat',
                  _appInfo,
                ),
              ],
              const SizedBox(height: AppDimensions.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'TUTUP DETAIL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: AppDimensions.fontLg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd + 2),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconMd,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(width: AppDimensions.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm + 1,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppDimensions.xs - 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  color: valueColor ?? AppColors.primaryNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadRow(
    BuildContext context,
    IconData icon,
    String label,
    String buttonText,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd + 2),
          ),
          child: Icon(
            icon,
            size: AppDimensions.iconMd,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(width: AppDimensions.md + 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm + 1,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppDimensions.xs - 1),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh dokumen izin...')),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontDefault,
                        color: Colors.blue,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedAttendanceTile extends StatelessWidget {
  final String title;
  final String time;
  final String status;
  final String type;
  final String location;
  final Animation<double> animation;
  final VoidCallback onTap;

  const _AnimatedAttendanceTile({
    super.key,
    required this.title,
    required this.time,
    required this.status,
    required this.type,
    required this.location,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHadir = type == 'hadir';
    final bool isTelat = type == 'telat';
    final bool isIzin = type == 'izin';

    final Color iconColor = isHadir
        ? AppColors.successGreen
        : isTelat
        ? const Color(0xFFFBC02D)
        : (isIzin ? AppColors.warningOrange : AppColors.dangerRed);

    final IconData iconData = isHadir
        ? AppIcons.checkCircleFill
        : isTelat
        ? AppIcons.clockFill
        : (isIzin ? AppIcons.fileTextFill : AppIcons.xCircleFill);

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
              onTap: onTap,
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
                          if (location != '-') ...[
                            Text(
                              location,
                              style: TextStyle(
                                fontSize: AppDimensions.fontMd,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.xs),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.login,
                                size: AppDimensions.fontMd + 2,
                                color: Colors.blueGrey.shade400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontMd,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXl,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w800,
                            color: iconColor,
                          ),
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

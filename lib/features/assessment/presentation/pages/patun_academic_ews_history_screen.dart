import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class PatunAcademicEwsHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialActivities;

  const PatunAcademicEwsHistoryScreen({
    super.key,
    required this.initialActivities,
  });

  @override
  State<PatunAcademicEwsHistoryScreen> createState() =>
      _PatunAcademicEwsHistoryScreenState();
}

class _PatunAcademicEwsHistoryScreenState
    extends State<PatunAcademicEwsHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = AppColors.background;

  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Kritis', 'Perhatian'];
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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

  String _formatDateRange(DateTimeRange range) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final start = range.start;
    final end = range.end;
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.day} ${months[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
    }
    return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
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
                  'Tingkat: $_selectedFilter',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: _primaryNavy,
                  ),
                ),
                backgroundColor: _primaryNavy.withValues(alpha: 0.06),
                deleteIcon: const Icon(
                  AppIcons.xCircle,
                  size: AppDimensions.iconSm,
                  color: _primaryNavy,
                ),
                onDeleted: () {
                  setState(() => _selectedFilter = 'Semua');
                  _animController.forward(from: 0.0);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  side: BorderSide(color: _primaryNavy.withValues(alpha: 0.12)),
                ),
              ),
            ),
          if (hasDateFilter)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(
                  _formatDateRange(_selectedDateRange!),
                  style: const TextStyle(
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
                  setState(() => _selectedDateRange = null);
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
    final dateFiltered = _selectedDateRange == null
        ? widget.initialActivities
        : widget.initialActivities.where((a) {
            if (!a.containsKey('dateTime')) return true;
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
            final isCritical = (a['isCritical'] as bool?) ?? false;
            if (_selectedFilter == 'Kritis') return isCritical;
            if (_selectedFilter == 'Perhatian') return !isCritical;
            return true;
          }).toList();

    final Map<String, List<Map<String, dynamic>>> groupedActivities = {};
    for (var activity in filteredActivities) {
      String dateKey = 'Hari Ini';
      if (activity.containsKey('dateStr')) {
        dateKey = activity['dateStr'];
      }
      if (!groupedActivities.containsKey(dateKey)) {
        groupedActivities[dateKey] = [];
      }
      groupedActivities[dateKey]!.add(activity);
    }

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Early Warning System',
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
              setState(() => _selectedFilter = filter);
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
                            color: isSelected ? _primaryNavy : Colors.black87,
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
              const PopupMenuItem<String>(
                value: 'refresh',
                child: Text(
                  'Refresh Data',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (_selectedDateRange != null || _selectedFilter != 'Semua')
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
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
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
                                padding: const EdgeInsets.all(AppDimensions.lg),
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
                                  final itemIndex = filteredActivities.indexOf(
                                    item,
                                  );
                                  final animation = CurvedAnimation(
                                    parent: _animController,
                                    curve: Interval(
                                      (itemIndex / filteredActivities.length)
                                          .clamp(0.0, 1.0),
                                      1.0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return _AnimatedEwsActivityTile(
                                    title:
                                        (item['title'] as String?) ??
                                        'Early Warning System',
                                    desc: (item['desc'] as String?) ?? '-',
                                    sender: (item['sender'] as String?) ?? '-',
                                    time: (item['time'] as String?) ?? '-',
                                    isCritical:
                                        (item['isCritical'] as bool?) ?? false,
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
      ),
    );
  }
}

class _AnimatedEwsActivityTile extends StatelessWidget {
  final String title;
  final String desc;
  final String sender;
  final String time;
  final bool isCritical;
  final Animation<double> animation;

  const _AnimatedEwsActivityTile({
    required this.title,
    required this.desc,
    required this.sender,
    required this.time,
    required this.isCritical,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isCritical
        ? const Color(0xFFD32F2F)
        : const Color(0xFFF57C00);
    final bgColor = isCritical
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFFFF3E0);

    final iconData = isCritical
        ? AppIcons.warningCircleFill
        : AppIcons.warningCircle;
    final subtitle = '$desc - $sender';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: bgColor,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontLg,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              isCritical ? 'Kritis' : 'Perhatian',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
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
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

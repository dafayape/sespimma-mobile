import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class PatunPhysicalMedicalHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialRecords;

  const PatunPhysicalMedicalHistoryScreen({
    super.key,
    required this.initialRecords,
  });

  @override
  State<PatunPhysicalMedicalHistoryScreen> createState() =>
      _PatunPhysicalMedicalHistoryScreenState();
}

class _PatunPhysicalMedicalHistoryScreenState
    extends State<PatunPhysicalMedicalHistoryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = AppColors.background;

  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Poliklinik',
    'Rawat Inap',
    'Tes Medis',
  ];
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
                  'Jenis: $_selectedFilter',
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
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade700,
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
    final filteredByCategory = _selectedFilter == 'Semua'
        ? widget.initialRecords
        : widget.initialRecords
              .where((r) => r['category'] == _selectedFilter)
              .toList();

    final filtered = _selectedDateRange == null
        ? filteredByCategory
        : filteredByCategory.where((r) {
            final date = r['date'] as DateTime?;
            if (date == null) return false;
            final start = _selectedDateRange!.start;
            final end = _selectedDateRange!.end.add(const Duration(days: 1));
            return date.isAfter(
                  start.subtract(const Duration(milliseconds: 1)),
                ) &&
                date.isBefore(end);
          }).toList();

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final record in filtered) {
      final dateKey = (record['dateStr'] as String?) ?? 'Hari Ini';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Catatan Medis',
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
                  child: filtered.isEmpty
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
                                'Tidak Ada Catatan Medis',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontXxl,
                                  fontWeight: FontWeight.w800,
                                  color: _primaryNavy,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.sm),
                              Text(
                                'Belum ada catatan medis yang tercatat.',
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
                          itemCount: grouped.length,
                          itemBuilder: (context, index) {
                            final dateKey = grouped.keys.elementAt(index);
                            final items = grouped[dateKey]!;

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
                                  final itemIndex = filtered.indexOf(item);
                                  final animation = CurvedAnimation(
                                    parent: _animController,
                                    curve: Interval(
                                      (itemIndex / filtered.length).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      1.0,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );

                                  return _AnimatedMedicalRecordTile(
                                    title:
                                        (item['title'] as String?) ??
                                        'Catatan Medis',
                                    desc: (item['desc'] as String?) ?? '-',
                                    sender: (item['sender'] as String?) ?? '-',
                                    time: (item['time'] as String?) ?? '-',
                                    category:
                                        (item['category'] as String?) ??
                                        'Poliklinik',
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

class _AnimatedMedicalRecordTile extends StatelessWidget {
  final String title;
  final String desc;
  final String sender;
  final String time;
  final String category;
  final Animation<double> animation;

  const _AnimatedMedicalRecordTile({
    required this.title,
    required this.desc,
    required this.sender,
    required this.time,
    required this.category,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor;
    final Color bgColor;
    final IconData iconData;

    switch (category) {
      case 'Rawat Inap':
        iconColor = const Color(0xFFD32F2F);
        bgColor = const Color(0xFFFFEBEE);
        iconData = Icons.local_hospital_rounded;
      case 'Tes Medis':
        iconColor = const Color(0xFF1565C0);
        bgColor = const Color(0xFFE3F2FD);
        iconData = Icons.verified_rounded;
      default:
        iconColor = const Color(0xFFF57C00);
        bgColor = const Color(0xFFFFF3E0);
        iconData = Icons.medical_services_rounded;
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
                              category,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w700,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: AppDimensions.fontMd,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              sender,
                              style: TextStyle(
                                fontSize: AppDimensions.fontMd,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import '../../data/models/korsis_inbox_mock_data.dart';

import 'package:file_picker/file_picker.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class KorsisInboxScreen extends StatefulWidget {
  const KorsisInboxScreen({super.key});

  @override
  State<KorsisInboxScreen> createState() => _KorsisInboxScreenState();
}

class _KorsisInboxScreenState extends State<KorsisInboxScreen> {
  List<InboxItem> _allItems = [];
  List<InboxItem> _filteredItems = [];

  String _searchQuery = '';
  String _selectedPokjar = 'Semua Pokjar';
  String _selectedStatus = 'Semua Status';
  DateTimeRange? _selectedDateRange;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _pokjarOptions = [
    'Semua Pokjar',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  final List<String> _statusOptions = [
    'Semua Status',
    'Reward',
    'Punishment',
    'Izin',
  ];

  @override
  void initState() {
    super.initState();
    _allItems = KorsisInboxMockData.generateMockData();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    _allItems = KorsisInboxMockData.generateMockData();
    _applyFilters();
  }

  String _mapRomanToArabic(String roman) {
    switch (roman) {
      case 'POKJAR I':
        return 'POKJAR I';
      case 'POKJAR II':
        return 'POKJAR II';
      case 'POKJAR III':
        return 'POKJAR III';
      case 'POKJAR IV':
        return 'POKJAR IV';
      case 'POKJAR V':
        return 'POKJAR V';
      default:
        return roman;
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (item.status != 'pending') return false;

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.serdikName.toLowerCase().contains(query) &&
              !item.nosis.toLowerCase().contains(query)) {
            return false;
          }
        }

        if (_selectedPokjar != 'Semua Pokjar') {
          if (item.pokjar != _mapRomanToArabic(_selectedPokjar)) return false;
        }

        if (_selectedStatus != 'Semua Status') {
          if (_selectedStatus == 'Reward' && (!item.isReward || item.isIzin)) {
            return false;
          }
          if (_selectedStatus == 'Punishment' &&
              (item.isReward || item.isIzin)) {
            return false;
          }
          if (_selectedStatus == 'Izin' && !item.isIzin) {
            return false;
          }
        }

        if (_selectedDateRange != null) {
          final dt = item.timestamp;
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
          if (dt.isBefore(start) || dt.isAfter(end)) return false;
        }

        return true;
      }).toList();

      _filteredItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      initialDateRange:
          _selectedDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: DateTime(now.year, now.month, now.day),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryNavy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _applyFilters();
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
      _applyFilters();
    });
  }

  void _updateMockDatabase(String nosis, double points) {
    final reportIndex = PimpinanMockData.sharedReportData.indexWhere(
      (r) => r.nosis == nosis,
    );
    if (reportIndex != -1) {
      final current = PimpinanMockData.sharedReportData[reportIndex];

      double newScore = current.mentalScore + points;
      if (newScore > 100) newScore = 100;
      if (newScore < 0) newScore = 0;

      PimpinanMockData.sharedReportData[reportIndex] = current.copyWith(
        mentalScore: newScore,
      );
    }
  }

  void _approveAll() {
    setState(() {
      int count = 0;
      for (var item in _filteredItems) {
        if (item.status == 'pending') {
          item.status = 'approved';
          _updateMockDatabase(item.nosis, item.points);
          count++;
        }
      }
      if (count > 0) {
        AppNotifier.showSuccess(
          context,
          '$count pencatatan berhasil disetujui',
        );
      } else {
        AppNotifier.showInfo(context, 'Tidak ada pencatatan tertunda');
      }
      _applyFilters();
    });
  }

  void _rejectAll() {
    setState(() {
      int count = 0;
      for (var item in _filteredItems) {
        if (item.status == 'pending') {
          item.status = 'rejected';
          count++;
        }
      }
      if (count > 0) {
        AppNotifier.showSuccess(context, '$count pencatatan berhasil ditolak');
      } else {
        AppNotifier.showInfo(context, 'Tidak ada pencatatan tertunda');
      }
      _applyFilters();
    });
  }

  void _approveItem(String id) {
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == id);
      if (index != -1) {
        final item = _allItems[index];
        item.status = 'approved';
        _updateMockDatabase(item.nosis, item.points);
      }
      _applyFilters();
    });
  }

  void _rejectItem(String id) {
    setState(() {
      final index = _allItems.indexWhere((i) => i.id == id);
      if (index != -1) _allItems[index].status = 'rejected';
      _applyFilters();
    });
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    Color? iconColor,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.primaryNavy),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return options.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Row(
              children: [
                Icon(
                  value == choice
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: value == choice ? AppColors.primaryNavy : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  choice,
                  style: TextStyle(
                    fontWeight: value == choice
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: value == choice
                        ? AppColors.primaryNavy
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFiltersBlock() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AssessmentSearchBarWidget(
                controller: _searchController,
                searchQuery: _searchQuery,
                hintText: 'Cari nama atau nomor serdik...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
                onClear: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _applyFilters();
                  });
                },
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            _buildFilterDropdown(
              icon: AppIcons.usersFill,
              value: _selectedPokjar,
              options: _pokjarOptions,
              onChanged: (val) {
                setState(() {
                  _selectedPokjar = val;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: AppDimensions.sm),
            _buildFilterDropdown(
              icon: AppIcons.funnelFill,
              value: _selectedStatus,
              options: _statusOptions,
              iconColor: _selectedStatus == 'Reward'
                  ? Colors.green
                  : (_selectedStatus == 'Punishment'
                        ? Colors.red
                        : (_selectedStatus == 'Izin'
                              ? Colors.blue
                              : AppColors.primaryNavy)),
              onChanged: (val) {
                setState(() {
                  _selectedStatus = val;
                  _applyFilters();
                });
              },
            ),
            const SizedBox(width: AppDimensions.sm),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'approve') {
                  _approveAll();
                } else if (value == 'reject') {
                  _rejectAll();
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabled: _filteredItems.any((i) => i.status == 'pending'),
              offset: const Offset(0, 45),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.checkCircleFill,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Setujui Semua',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.xCircleFill,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tolak Semua',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: _filteredItems.any((i) => i.status == 'pending')
                      ? AppColors.primaryNavy
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(
                  AppIcons.dotsThreeVerticalBold,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDateFilter() {
    if (_selectedDateRange == null) return const SizedBox.shrink();

    final startStr = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(_selectedDateRange!.start);
    final endStr = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(_selectedDateRange!.end);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: AppDimensions.xl,
        right: AppDimensions.xl,
        bottom: AppDimensions.md,
      ),
      child: Row(
        children: [
          InputChip(
            label: Text(
              'Tanggal: $startStr - $endStr',
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
            onDeleted: _clearDateFilter,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              side: BorderSide(color: Colors.teal.shade100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    final totalSerdik = _filteredItems.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xl,
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.sm,
      ),
      child: Row(
        children: [
          const Text(
            'DAFTAR SERDIK',
            style: TextStyle(
              color: AppColors.primaryNavy,
              fontWeight: FontWeight.w800,
              fontSize: AppDimensions.fontLg,
              letterSpacing: 0.5,
            ),
          ),
          if (_selectedPokjar != 'Semua Pokjar') ...[
            const SizedBox(width: AppDimensions.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                _selectedPokjar,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.fontSm,
                ),
              ),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$totalSerdik Serdik',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.fontSm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Pencatatan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateRange != null
                  ? AppIcons.calendarFill
                  : AppIcons.calendarBlank,
              color: _selectedDateRange != null
                  ? Colors.tealAccent
                  : Colors.white,
            ),
            onPressed: _selectDateRange,
            tooltip: 'Filter Tanggal',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFiltersBlock(),
          _buildActiveDateFilter(),
          Divider(
            height: AppDimensions.dividerHeight,
            color: Colors.grey.shade200,
            thickness: AppDimensions.dividerHeight,
          ),
          _buildListHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _allItems = KorsisInboxMockData.generateMockData();
                  _applyFilters();
                });
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.primaryNavy,
              child: _filteredItems.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.xl),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppIcons.fileText,
                                size: 48,
                                color: Colors.blueGrey.shade300,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.lg),
                            Text(
                              'Tidak ada pencatatan ditemukan',
                              style: TextStyle(
                                fontSize: AppDimensions.fontLg,
                                fontWeight: FontWeight.w700,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            Text(
                              'Belum ada data pencatatan baru yang masuk',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                color: Colors.blueGrey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildGroupedList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    Map<String, List<InboxItem>> grouped = {};
    for (var item in _filteredItems) {
      String dateStr = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(item.timestamp);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(item);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.sm,
      ),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        String dateStr = grouped.keys.elementAt(index);
        List<InboxItem> items = grouped[dateStr]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.md,
                horizontal: 4,
              ),
              child: Text(
                dateStr,
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.map((item) => _buildListItem(item)),
          ],
        );
      },
    );
  }

  Widget _buildListItem(InboxItem item) {
    final isIzin = item.isIzin;
    final isReward = item.isReward;
    final statusColor = isIzin
        ? Colors.orange.shade700
        : (isReward ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F));
    final statusIcon = isIzin
        ? AppIcons.envelopeSimpleBold
        : (isReward ? AppIcons.thumbUp : AppIcons.thumbDown);
    final statusText = isIzin
        ? 'SURAT IZIN'
        : (isReward ? 'REWARD' : 'PUNISHMENT');

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
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
          onTap: isIzin ? null : () => _showItemDetail(item),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.serdikName,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.pangkat} · ${item.nosis}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 10, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXs,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isIzin &&
                              item.izinStartTime != null &&
                              item.izinEndTime != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    AppIcons.clockBold,
                                    size: 10,
                                    color: Colors.blue.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${DateFormat('HH.mm').format(item.izinStartTime!)} - ${DateFormat('HH.mm').format(item.izinEndTime!)}',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isIzin && item.attachmentPath != null)
                            InkWell(
                              onTap: () async {
                                String? outputFile = await FilePicker.saveFile(
                                  dialogTitle: 'Simpan Dokumen Lampiran',
                                  fileName:
                                      item.attachmentPath ?? 'lampiran.pdf',
                                );

                                if (outputFile != null && mounted) {
                                  AppNotifier.showSuccess(
                                    context,
                                    'Berhasil disimpan ke $outputFile',
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      AppIcons.paperclip,
                                      size: 10,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Lampiran',
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontXs,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!isIzin)
                            Text(
                              item.senderName,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            AppIcons.clockFill,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('HH:mm').format(item.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                _buildActionArea(item, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionArea(InboxItem item, Color statusColor) {
    if (item.status != 'pending') {
      return Column(
        children: [
          if (!item.isIzin)
            Text(
              item.points > 0 ? '+${item.points}' : '${item.points}',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontLg + 1,
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.status == 'approved'
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.status == 'approved' ? 'DISETUJUI' : 'DITOLAK',
              style: TextStyle(
                color: item.status == 'approved'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!item.isIzin)
          Text(
            item.points > 0 ? '+${item.points}' : '${item.points}',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: AppDimensions.fontLg + 1,
            ),
          ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _approveItem(item.id);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.checkCircleFill,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _rejectItem(item.id);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.xCircleFill,
                  color: Colors.red.shade600,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AvatarHelper.getAvatar(null),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
    );
  }

  void _showItemDetail(InboxItem item) {
    final bool isReward = item.isReward;
    final String detailTitle = isReward
        ? "Bukti Penghargaan"
        : "Bukti Pelanggaran";
    final Color mainColor = isReward
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);

    Widget buildEvidenceImage() {
      if (item.photoPath != null && item.photoPath!.isNotEmpty) {
        return Image.file(
          File(item.photoPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, err, stack) {
            return _buildImageErrorPlaceholder();
          },
        );
      }

      return _buildImageErrorPlaceholder();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: mainColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isReward ? AppIcons.thumbUp : AppIcons.thumbDown,
                    color: mainColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detailTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: mainColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.rewardPunishmentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF001C40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildPopupInfoRow(
              "Waktu",
              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(item.timestamp),
            ),
            const SizedBox(height: 12),
            _buildPopupInfoRow("Oleh", item.senderName),
            const SizedBox(height: 12),
            _buildPopupInfoRow(
              "Dampak Skor",
              item.points > 0 ? '+${item.points}' : '${item.points}',
              valueColor: mainColor,
              isBold: true,
            ),
            const SizedBox(height: 16),
            const Text(
              "Keterangan Justifikasi",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF001C40),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Bukti Gambar",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF001C40),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: buildEvidenceImage(),
              ),
            ),
            const SizedBox(height: 24),
            if (item.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _rejectItem(item.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'TOLAK',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _approveItem(item.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'SETUJUI',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001C40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "TUTUP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageErrorPlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.image, color: Colors.blueGrey.shade300, size: 32),
            const SizedBox(height: 8),
            Text(
              "Gagal memuat gambar bukti",
              style: TextStyle(
                fontSize: 11,
                color: Colors.blueGrey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ),
        const Text(" :   ", style: TextStyle(color: Colors.blueGrey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? const Color(0xFF001C40),
            ),
          ),
        ),
      ],
    );
  }
}

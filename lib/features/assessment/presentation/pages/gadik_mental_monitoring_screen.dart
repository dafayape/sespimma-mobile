import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import '../../data/models/korsis_inbox_mock_data.dart';
import 'gadik_mental_form_screen.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class GadikMentalMonitoringScreen extends StatefulWidget {
  const GadikMentalMonitoringScreen({super.key});

  @override
  State<GadikMentalMonitoringScreen> createState() =>
      _GadikMentalMonitoringScreenState();
}

class _GadikMentalMonitoringScreenState
    extends State<GadikMentalMonitoringScreen> {
  static const Color _primaryNavy = AppColors.primaryNavy;

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

  final List<String> _statusOptions = ['Semua Status', 'Reward', 'Punishment'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    _loadData();
  }

  void _loadData() {
    _allItems = KorsisInboxMockData.items;
    _applyFilters();
  }

  String _mapRomanToArabic(String roman) {
    const mapping = {
      'POKJAR I': 'POKJAR I',
      'POKJAR II': 'POKJAR II',
      'POKJAR III': 'POKJAR III',
      'POKJAR IV': 'POKJAR IV',
      'POKJAR V': 'POKJAR V',
    };
    return mapping[roman] ?? roman;
  }

  void _applyFilters() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.serdikName.toLowerCase().contains(query) &&
              !item.nosis.toLowerCase().contains(query)) {
            return false;
          }
        }

        if (_selectedPokjar != 'Semua Pokjar') {
          if (item.pokjar != _mapRomanToArabic(_selectedPokjar)) {
            return false;
          }
        }

        if (_selectedStatus != 'Semua Status') {
          if (_selectedStatus == 'Reward' && !item.isReward) {
            return false;
          }
          if (_selectedStatus == 'Punishment' && item.isReward) {
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
          if (dt.isBefore(start) || dt.isAfter(end)) {
            return false;
          }
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
              primary: _primaryNavy,
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

  void _openFormScreen(bool isReward) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GadikMentalFormScreen(isReward: isReward),
      ),
    ).then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Penilaian',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_month_rounded,
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
          _buildListHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _loadData();
                await Future.delayed(const Duration(milliseconds: 400));
              },
              color: _primaryNavy,
              child: _filteredItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 200),
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                AppIcons.clipboardText,
                                size: 48,
                                color: Colors.blueGrey.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada riwayat penilaian',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontDefault,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildGroupedList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  void _showInputBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InputBottomSheet(
        onReward: () {
          Navigator.pop(context);
          _openFormScreen(true);
        },
        onPunishment: () {
          Navigator.pop(context);
          _openFormScreen(false);
        },
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: () => _showInputBottomSheet(context),
      backgroundColor: _primaryNavy,
      elevation: 6,
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
      label: const Text(
        'Input Nilai',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: AppDimensions.fontMd,
        ),
      ),
    );
  }

  Widget _buildFiltersBlock() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      child: Row(
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
                : (_selectedStatus == 'Punishment' ? Colors.red : _primaryNavy),
            onChanged: (val) {
              setState(() {
                _selectedStatus = val;
                _applyFilters();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
    Color? iconColor,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? _primaryNavy),
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
                  color: value == choice ? _primaryNavy : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  choice,
                  style: TextStyle(
                    fontWeight: value == choice
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: value == choice ? _primaryNavy : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildActiveDateFilter() {
    if (_selectedDateRange == null) {
      return const SizedBox.shrink();
    }

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: AppDimensions.dividerHeight,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xl,
        0,
        AppDimensions.xl,
        AppDimensions.md,
      ),
      child: Row(
        children: [
          const Text(
            'RIWAYAT PENILAIAN MENTAL',
            style: TextStyle(
              color: _primaryNavy,
              fontWeight: FontWeight.w800,
              fontSize: AppDimensions.fontDefault,
              letterSpacing: 0.5,
            ),
          ),
          if (_selectedPokjar != 'Semua Pokjar') ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _primaryNavy,
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
              color: _primaryNavy,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_alt, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_filteredItems.length} Serdik',
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

  Widget _buildGroupedList() {
    final Map<String, List<InboxItem>> grouped = {};
    for (final item in _filteredItems) {
      final dateStr = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(item.timestamp);
      grouped.putIfAbsent(dateStr, () => []).add(item);
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.sm,
      ),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final dateStr = grouped.keys.elementAt(index);
        final items = grouped[dateStr]!;

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
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...items.map(_buildListItem),
          ],
        );
      },
    );
  }

  Widget _buildListItem(InboxItem item) {
    final isReward = item.isReward;
    final statusColor = isReward
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);
    final statusIcon = isReward ? AppIcons.thumbUp : AppIcons.thumbDown;

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
          onTap: () => _showItemDetail(item),
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
                          color: _primaryNavy,
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
                      Row(
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
                                  isReward ? 'REWARD' : 'PUNISHMENT',
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.senderName,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                _buildScoreBadge(item, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(InboxItem item, Color statusColor) {
    final pointStr = item.isReward
        ? '+${item.points.toStringAsFixed(2)}'
        : '-${item.points.abs().toStringAsFixed(2)}';

    IconData statusIconData = item.status == 'approved'
        ? Icons.check_circle_rounded
        : (item.status == 'rejected'
              ? Icons.cancel_rounded
              : Icons.access_time_filled_rounded);

    Color badgeColor = item.status == 'approved'
        ? Colors.green.shade50
        : (item.status == 'rejected'
              ? Colors.red.shade50
              : Colors.amber.shade50);

    Color iconColor = item.status == 'approved'
        ? Colors.green.shade700
        : (item.status == 'rejected'
              ? Colors.red.shade700
              : Colors.amber.shade800);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          pointStr,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w900,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(statusIconData, size: 14, color: iconColor),
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
        ? 'Bukti Penghargaan'
        : 'Bukti Pelanggaran';
    final Color mainColor = isReward
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);

    Widget buildEvidenceImage() {
      if (item.photoPath != null && item.photoPath!.isNotEmpty) {
        return Image.file(
          File(item.photoPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        );
      }

      return _buildImagePlaceholder();
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
                          color: _primaryNavy,
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

            _buildPopupInfoRow('Serdik', item.serdikName),
            const SizedBox(height: 12),
            _buildPopupInfoRow(
              'Waktu',
              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(item.timestamp),
            ),
            const SizedBox(height: 12),
            _buildPopupInfoRow('Oleh', item.senderName),
            const SizedBox(height: 12),
            _buildPopupInfoRow(
              'Dampak Skor',
              item.points > 0 ? '+${item.points}' : '${item.points}',
              valueColor: mainColor,
              isBold: true,
            ),
            const SizedBox(height: 16),

            const Text(
              'Keterangan Justifikasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
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
              'Bukti Gambar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
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

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'TUTUP',
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.image, color: Colors.blueGrey.shade300, size: 32),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat gambar bukti',
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
        const Text(' :   ', style: TextStyle(color: Colors.blueGrey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor ?? _primaryNavy,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBottomSheet extends StatelessWidget {
  final VoidCallback onReward;
  final VoidCallback onPunishment;

  const _InputBottomSheet({required this.onReward, required this.onPunishment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.handleWidth,
                  height: AppDimensions.bottomSheetHandle,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Input Nilai Mental',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000B1D),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Pilih jenis penilaian yang akan diinput',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
              Row(
                children: [
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Reward',
                      subtitle: 'Penilaian Positif',
                      icon: Icons.thumb_up_rounded,
                      color: const Color(0xFF1B5E20),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: onReward,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.lg),
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Punishment',
                      subtitle: 'Penilaian Negatif',
                      icon: Icons.thumb_down_rounded,
                      color: const Color(0xFFC62828),
                      bgColor: const Color(0xFFFFEBEE),
                      onTap: onPunishment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SheetOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.xl,
            horizontal: AppDimensions.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconXl),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

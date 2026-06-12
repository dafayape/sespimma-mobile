import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';

import '../../data/models/gadik_assignment_model.dart';
import '../../data/datasources/gadik_assignment_mock_data.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'gadik_assignment_detail_screen.dart';
import 'gadik_create_assignment_screen.dart';

class GadikAssignmentMonitoringScreen extends StatefulWidget {
  const GadikAssignmentMonitoringScreen({super.key});

  @override
  State<GadikAssignmentMonitoringScreen> createState() =>
      _GadikAssignmentMonitoringScreenState();
}

class _GadikAssignmentMonitoringScreenState
    extends State<GadikAssignmentMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  String _searchQuery = '';
  String _selectedCategory = 'Semua Jenis Tugas';
  bool _sortAscending = false;
  DateTimeRange? _selectedDateRange;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _categoryOptions = [
    'Semua Jenis Tugas',
    'Ujian Mata Pelajaran atau Esai (NUMP)',
    'Naskah Kuliah Kerja Profesi (NKKP)',
    'Naskah Praktek Kerja Profesi (NPKP)',
    'Naskah Karya Perseorangan (NKP)',
    'Simulasi Kepemimpinan Kontemporer (NSK)',
    'Naskah Program Transformasi Teknis (NPTT)',
  ];

  String _getDynamicCategoryName(String rawCategory) {
    if (rawCategory.contains('NKKP')) return 'NKKP';
    if (rawCategory.contains('NPKP')) return 'NPKP';
    if (rawCategory.contains('NPTT')) return 'NPTT';
    if (rawCategory.contains('NKP')) return 'NKP';
    if (rawCategory.contains('NSK')) return 'NSK';
    if (rawCategory.contains('Ujian')) return 'NUMP';
    return rawCategory;
  }

  String _getDisplayPokjar(String target) {
    final t = target.toLowerCase();
    if (t.contains('semua')) return 'SELURUH POKJAR';
    if (t.contains('1') || t.contains('i')) return 'POKJAR I';
    if (t.contains('2') || t.contains('ii')) return 'POKJAR II';
    if (t.contains('3') || t.contains('iii')) return 'POKJAR III';
    if (t.contains('4') || t.contains('iv')) return 'POKJAR IV';
    if (t.contains('5') || t.contains('v')) return 'POKJAR V';
    return target.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getTotalSerdik(String targetPokjar) {
    if (targetPokjar.toLowerCase() == 'semua pokjar') return 125;
    return 25;
  }

  int _getSubmittedCount(String assignmentId) {
    return GadikAssignmentMockData.submissions
        .where((s) => s.assignmentId == assignmentId)
        .length;
  }

  int _getGradedCount(String assignmentId) {
    return GadikAssignmentMockData.submissions
        .where((s) => s.assignmentId == assignmentId && s.isGraded)
        .length;
  }

  Future<void> _pickDate() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryNavy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = GadikAssignmentMockData.assignments.where((task) {
      final title = task.judul.toLowerCase();
      final query = _searchQuery.toLowerCase();
      if (!title.contains(query)) return false;

      if (_selectedCategory != 'Semua Jenis Tugas') {
        final catFilter = _getDynamicCategoryName(_selectedCategory);
        final catTask = _getDynamicCategoryName(task.jenisTugas);
        if (catFilter != catTask) return false;
      }

      if (_selectedDateRange != null) {
        final date = task.createdAt;
        final taskDate = DateTime(date.year, date.month, date.day);
        final start = _selectedDateRange!.start;
        final end = _selectedDateRange!.end;
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(end.year, end.month, end.day);
        if (taskDate.isBefore(startDate) || taskDate.isAfter(endDate)) {
          return false;
        }
      }

      return true;
    }).toList();

    filteredList.sort((a, b) {
      final submissionsA = _getSubmittedCount(a.id);
      final submissionsB = _getSubmittedCount(b.id);
      if (_sortAscending) {
        if (submissionsA == submissionsB) {
          return a.createdAt.compareTo(b.createdAt);
        }
        return submissionsA.compareTo(submissionsB);
      } else {
        if (submissionsA == submissionsB) {
          return b.createdAt.compareTo(a.createdAt);
        }
        return submissionsB.compareTo(submissionsA);
      }
    });

    final totalTasks = filteredList.length;

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Tugas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: _pickDate,
            tooltip: 'Filter Tanggal',
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBlock(totalTasks),
          Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: _primaryNavy,
              child: filteredList.isEmpty
                  ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(),
                        ),
                      ],
                    )
                  : _buildTaskList(filteredList),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GadikCreateAssignmentScreen(),
            ),
          );
          if (result == true) {
            if (!context.mounted) return;
            setState(() {});
            AppNotifier.showSuccess(
              context,
              'Tugas berhasil dibuat dan didistribusikan.',
            );
          }
        },
        backgroundColor: _primaryNavy,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Buat Tugas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBlock(int totalTasks) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: AssessmentSearchBarWidget(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  hintText: 'Cari judul tugas...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              PopupMenuButton<String>(
                onSelected: (String value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                itemBuilder: (context) {
                  return _categoryOptions.map((subject) {
                    final bool isSelected = subject == _selectedCategory;
                    return PopupMenuItem<String>(
                      value: subject,
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isSelected
                                ? _primaryNavy
                                : Colors.blueGrey.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subject,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? _primaryNavy
                                    : Colors.blueGrey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedCategory != 'Semua Jenis Tugas'
                        ? _primaryNavy.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                      color: _selectedCategory != 'Semua Jenis Tugas'
                          ? _primaryNavy
                          : Colors.grey.shade200,
                      width: _selectedCategory != 'Semua Jenis Tugas'
                          ? 1.5
                          : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategory != 'Semua Jenis Tugas'
                            ? Icons.filter_alt_rounded
                            : Icons.filter_alt_outlined,
                        color: _selectedCategory != 'Semua Jenis Tugas'
                            ? _primaryNavy
                            : Colors.blueGrey.shade500,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _selectedCategory != 'Semua Jenis Tugas'
                            ? _primaryNavy
                            : Colors.blueGrey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'DAFTAR TUGAS',
                style: TextStyle(
                  color: _primaryNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.fontLg,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$totalTasks',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontSm,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                      color: Colors.grey.shade50,
                    ),
                    child: AnimatedRotation(
                      turns: _sortAscending ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: _primaryNavy,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    final isFiltered =
        _selectedCategory != 'Semua Jenis Tugas' || _selectedDateRange != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _primaryNavy.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSearching
                        ? Icons.search_off_rounded
                        : Icons.assignment_outlined,
                    size: 32,
                    color: _primaryNavy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
            Text(
              isSearching ? 'Tidak Ditemukan' : 'Belum Ada Tugas',
              style: const TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              isSearching
                  ? 'Tidak ada tugas yang cocok dengan kata kunci "$_searchQuery".'
                  : isFiltered
                  ? 'Tidak ada tugas yang sesuai dengan filter.'
                  : 'Mulai dengan menekan tombol "Buat Tugas" di bawah.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            if (isSearching || isFiltered) ...[
              const SizedBox(height: AppDimensions.xl),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedCategory = 'Semua Jenis Tugas';
                    _selectedDateRange = null;
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<GadikAssignmentModel> tasks) {
    final Map<String, List<GadikAssignmentModel>> groupedTasks = {};
    for (var task in tasks) {
      final dateStr = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(task.createdAt);
      if (!groupedTasks.containsKey(dateStr)) {
        groupedTasks[dateStr] = [];
      }
      groupedTasks[dateStr]!.add(task);
    }

    final sortedDates = groupedTasks.keys.toList();
    sortedDates.sort((a, b) {
      final dateA = DateFormat('dd MMMM yyyy', 'id_ID').parse(a);
      final dateB = DateFormat('dd MMMM yyyy', 'id_ID').parse(b);
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            100,
          ),
          itemCount: sortedDates.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDates[index];
            final dailyTasks = groupedTasks[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index > 0) const SizedBox(height: AppDimensions.xl),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: Text(
                    dateKey,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                    ),
                  ),
                ),
                ...dailyTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.lg),
                    child: _buildTaskCard(task),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(GadikAssignmentModel task) {
    final int totalTarget = _getTotalSerdik(task.targetPokjar);
    final int submitted = _getSubmittedCount(task.id);
    final int graded = _getGradedCount(task.id);

    final bool allGraded = submitted > 0 && graded == submitted;
    final bool hasSubmissions = submitted > 0;

    Color statusColor = Colors.grey.shade400;
    Color statusBgColor = Colors.grey.shade100;
    IconData statusIcon = Icons.assignment_outlined;

    if (allGraded) {
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
      statusIcon = Icons.check_circle_rounded;
    } else if (hasSubmissions) {
      statusColor = const Color(0xFFF59E0B);
      statusBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
      statusIcon = Icons.pending_actions_rounded;
    }

    String shortCat = _getDynamicCategoryName(task.jenisTugas);
    final progressPct = totalTarget > 0 ? (submitted / totalTarget) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GadikAssignmentDetailScreen(assignment: task),
              ),
            );
            if (!mounted) return;
            if (result == 'deleted') {
              setState(() {
                GadikAssignmentMockData.assignments.removeWhere(
                  (a) => a.id == task.id,
                );
              });
              AppNotifier.showSuccess(context, 'Tugas berhasil dihapus.');
            } else {
              setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: AppDimensions.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _lightGrey,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  shortCat,
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXs,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blueGrey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Text(
                            task.judul,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontLg,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat(
                              'dd MMMM yyyy, HH:mm',
                              'id_ID',
                            ).format(task.deadline),
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.track_changes_outlined,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getDisplayPokjar(task.targetPokjar),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: AppDimensions.fontXs + 1,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$submitted / $totalTarget',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 100,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progressPct,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                statusColor,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

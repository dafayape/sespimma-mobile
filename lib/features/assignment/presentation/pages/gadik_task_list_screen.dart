import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/features/assignment/data/models/tugas_model.dart';
import 'package:sespimma/features/assignment/data/datasources/assignment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class GadikTaskListScreen extends StatefulWidget {
  const GadikTaskListScreen({super.key});

  @override
  State<GadikTaskListScreen> createState() => _GadikTaskListScreenState();
}

class _GadikTaskListScreenState extends State<GadikTaskListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  List<TugasModel> _assignments = [];
  bool _isLoading = false;

  Future<void> _fetchAssignments() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await sl<AssignmentRemoteDataSource>().getGadikAssignments();
      if (mounted) {
        setState(() {
          _assignments = data.map((a) => TugasModel(
            id: a.id,
            judul: a.judul,
            deskripsi: a.deskripsi ?? '',
            mapel: a.mapel,
            deadline: a.deadline,
            status: a.status,
            createdBy: '',
            createdByName: a.pengajar,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(context, 'Gagal memuat tugas: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
    _fetchAssignments();
  }

  @override
  void reassemble() {
    super.reassemble();
    _fetchAssignments();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _lightGrey = Color(0xFFF8FAFC);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _surfaceColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    final tasks = _assignments.where((task) {
      final matchesSearch =
          task.judul.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.mapel.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == 'Semua' ||
          (_selectedFilter == 'Sedang Berjalan' &&
              task.status.toLowerCase() == 'aktif') ||
          (_selectedFilter == 'Ditutup' &&
              task.status.toLowerCase() == 'selesai');
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Manajemen Tugas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchAssignments,
                color: _primaryNavy,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _primaryNavy,
                        ),
                      )
                    : tasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final animation = CurvedAnimation(
                            parent: _animController,
                            curve: Interval(
                              (index / tasks.length).clamp(0.0, 1.0),
                              1.0,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: _buildTaskItem(context, tasks[index]),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          Navigator.pushNamed(context, '/buat-tugas').then((_) {
            if (mounted) _fetchAssignments();
          });
        },
        backgroundColor: _primaryNavy,
        elevation: 6,
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
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

  Widget _buildSearchAndFilter() {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari tugas atau mapel...',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey.shade300,
                        fontSize: AppDimensions.fontDefault,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.blueGrey.shade400,
                        size: AppDimensions.iconLg,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w600,
                      color: _primaryNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              PopupMenuButton<String>(
                initialValue: _selectedFilter,
                onSelected: (val) {
                  setState(() {
                    _selectedFilter = val;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                color: Colors.white,
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.1),
                offset: const Offset(0, 56),
                itemBuilder: (ctx) => [
                  _buildPopupMenuItem('Semua', 'Semua Status'),
                  _buildPopupMenuItem('Sedang Berjalan', 'Sedang Berjalan'),
                  _buildPopupMenuItem('Ditutup', 'Ditutup'),
                ],
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedFilter != 'Semua'
                        ? _primaryNavy
                        : _lightGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: _selectedFilter != 'Semua'
                          ? _primaryNavy
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Icon(
                    Icons.filter_list_rounded,
                    color: _selectedFilter != 'Semua'
                        ? Colors.white
                        : Colors.blueGrey.shade600,
                    size: AppDimensions.iconLg,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimensions.fontDefault,
          fontWeight: _selectedFilter == value
              ? FontWeight.w700
              : FontWeight.w500,
          color: _selectedFilter == value
              ? _primaryNavy
              : Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_add,
              size: 64,
              color: Colors.blueGrey.shade200,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const Text(
            'Belum ada tugas',
            style: TextStyle(
              fontSize: AppDimensions.fontXxl,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Tekan tombol "Buat Tugas" di bawah\nuntuk mempublikasikan tugas baru.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, TugasModel task) {
    final bool isAktif = task.status.toLowerCase() == 'aktif';
    final String displayStatus = isAktif ? 'SEDANG BERJALAN' : 'DITUTUP';
    final Color statusColor = isAktif
        ? _successGreen
        : Colors.blueGrey.shade500;
    final IconData statusIcon = isAktif
        ? Icons.run_circle_rounded
        : Icons.lock_clock_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isAktif
              ? statusColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/monitoring-tugas',
              arguments: task,
            ).then((val) {
              if (mounted) {
                _fetchAssignments();
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusIcon,
                                  size: AppDimensions.fontLg,
                                  color: statusColor,
                                ),
                                const SizedBox(width: AppDimensions.xs),
                                Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSm,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppDimensions.lg),
                          Text(
                            task.judul,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontXl,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xs),
                          Text(
                            task.mapel,
                            style: TextStyle(
                              fontSize: AppDimensions.fontMd,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: AppDimensions.iconSm,
                                  color: Colors.blueGrey.shade600,
                                ),
                                const SizedBox(width: AppDimensions.xs),
                                Text(
                                  'Dibuat Oleh: ${task.createdByName}',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSm,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      decoration: BoxDecoration(
                        color: _primaryNavy.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _primaryNavy,
                        size: AppDimensions.iconSm,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: AppDimensions.md),
                Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: AppDimensions.iconSm,
                      color: Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: AppDimensions.sm),
                    Text(
                      'Deadline: ${task.deadline.day}/${task.deadline.month}/${task.deadline.year} - ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')} WIB',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade500,
                      ),
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

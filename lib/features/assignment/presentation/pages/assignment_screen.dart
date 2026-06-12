import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import '../../data/models/assignment_model.dart';
import 'package:sespimma/features/gadik_assignment/data/datasources/gadik_assignment_mock_data.dart';
import 'package:sespimma/features/gadik_assignment/data/models/gadik_submission_model.dart';
import 'package:sespimma/features/auth/data/datasources/gadik_real_data.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import '../widgets/task_card.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = AppColors.background;

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSubject = 'Semua Jenis Tugas';

  final List<String> _categoryOptions = [
    'Semua Jenis Tugas',
    'Ujian Mata Pelajaran atau Esai (NUMP)',
    'Naskah Kuliah Kerja Profesi (NKKP)',
    'Naskah Praktek Kerja Profesi (NPKP)',
    'Naskah Karya Perseorangan (NKP)',
    'Simulasi Kepemimpinan Kontemporer (NSK)',
    'Naskah Program Transformasi Teknis (NPTT)',
  ];

  List<AssignmentModel> get _mockAssignments {
    final activeUserNrp = SerdikRealData.records.first['nrp'];

    final List<AssignmentModel> dynamicTasks = GadikAssignmentMockData
        .assignments
        .map((t) {
          final submission = GadikAssignmentMockData.submissions.firstWhere(
            (s) => s.assignmentId == t.id && s.serdikNrp == activeUserNrp,
            orElse: () => GadikSubmissionModel(
              id: '',
              assignmentId: '',
              serdikName: '',
              serdikNrp: '',
            ),
          );

          String status = 'aktif';
          if (submission.id.isNotEmpty) {
            if (submission.isGraded) {
              status = 'selesai';
            } else {
              status = 'diperiksa';
            }
          }

          String gadikName = t.createdBy;
          String? gadikFoto;
          final gadikMatch = GadikRealData.records.firstWhere(
            (g) =>
                g['nama'].toString().toLowerCase().contains(
                  t.createdBy.toLowerCase(),
                ) ||
                g['nrp_nip'] == t.createdBy,
            orElse: () => <String, dynamic>{},
          );
          if (gadikMatch.isNotEmpty) {
            gadikName = gadikMatch['nama'];
            gadikFoto = gadikMatch['foto'];
          } else {
            if (t.createdBy.toLowerCase().contains('gadik')) {
              gadikName = GadikRealData.records.first['nama'];
              gadikFoto = GadikRealData.records.first['foto'];
            }
          }

          return AssignmentModel(
            id: t.id,
            judul: t.judul,
            mapel: t.jenisTugas,
            pengajar: gadikName,
            pengajarFoto: gadikFoto,
            deadline: t.deadline,
            status: status,
            deskripsi: t.instruksi,
            nilai: submission.nilaiAkhir,
            catatan: submission.catatanPengajar,
            submissionFileName: submission.fileName,
            attachmentName: t.fileName,
            attachmentUrl: t.fileUrl,
          );
        })
        .toList();

    return dynamicTasks;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _allSubjects {
    return _categoryOptions;
  }

  Widget _buildFilterDropdown() {
    final bool isFiltered = _selectedSubject != 'Semua Jenis Tugas';
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedSubject = value;
        });
      },
      offset: const Offset(0, 56),
      constraints: const BoxConstraints(maxHeight: 280),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      itemBuilder: (context) {
        return _allSubjects.map((subject) {
          final bool isSelected = subject == _selectedSubject;
          return PopupMenuItem<String>(
            value: subject,
            child: Row(
              children: [
                Icon(
                  isSelected ? AppIcons.checkCircleFill : AppIcons.circle,
                  color: isSelected ? _primaryNavy : Colors.blueGrey.shade300,
                  size: AppDimensions.iconDefault,
                ),
                const SizedBox(width: AppDimensions.md - 4),
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
                      fontSize: AppDimensions.fontDefault,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isFiltered
              ? _primaryNavy.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isFiltered ? _primaryNavy : Colors.grey.shade200,
            width: isFiltered ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? AppIcons.funnelFill : AppIcons.funnel,
              color: isFiltered ? _primaryNavy : Colors.blueGrey.shade500,
              size: AppDimensions.iconDefault,
            ),
            if (isFiltered) ...[
              const SizedBox(width: AppDimensions.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 80),
                child: Text(
                  _selectedSubject,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: _primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: AppDimensions.xs),
            Icon(
              AppIcons.caretDown,
              color: isFiltered ? _primaryNavy : Colors.blueGrey.shade400,
              size: AppDimensions.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final List<AssignmentModel> searchedAssignments = _mockAssignments.where((
      t,
    ) {
      if (_selectedSubject != 'Semua Jenis Tugas' &&
          t.mapel != _selectedSubject) {
        return false;
      }
      if (query.isEmpty) return true;
      return t.judul.toLowerCase().contains(query) ||
          t.mapel.toLowerCase().contains(query) ||
          t.pengajar.toLowerCase().contains(query);
    }).toList();

    final activeTasks = searchedAssignments
        .where((t) => t.status == 'aktif')
        .toList();
    final historyTasks = searchedAssignments
        .where((t) => t.status != 'aktif')
        .toList();

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Manajemen Tugas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari judul tugas atau mata pelajaran...',
                      hintStyle: TextStyle(
                        color: Colors.blueGrey.shade300,
                        fontSize: AppDimensions.fontSm,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        AppIcons.magnifyingGlass,
                        color: Colors.blueGrey.shade400,
                        size: AppDimensions.iconDefault,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                AppIcons.xCircleFill,
                                color: Colors.blueGrey.shade300,
                                size: AppDimensions.iconMd,
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: _primaryNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      color: _primaryNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.md - 4),
                _buildFilterDropdown(),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _primaryNavy,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd + 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryNavy.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey.shade400,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontLg,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: AppDimensions.fontLg,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(AppDimensions.xs),
                tabs: const [
                  Tab(text: 'Tugas Aktif'),
                  Tab(text: 'Riwayat Tugas'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(
                  activeTasks,
                  'Tidak Ada Tugas Aktif',
                  'Anda sudah menyelesaikan semua kewajiban tugas saat ini.',
                  AppIcons.clipboardText,
                ),
                _buildTaskList(
                  historyTasks,
                  'Belum Ada Riwayat',
                  'Belum ada tugas yang diselesaikan atau kadaluarsa.',
                  AppIcons.archive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    List<AssignmentModel> tasks,
    String emptyTitle,
    String emptyMessage,
    IconData iconData,
  ) {
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: _primaryNavy,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.8, end: 1.0),
                      curve: Curves.easeOutBack,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(AppDimensions.lg),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              iconData,
                              size: AppDimensions.iconDisplay,
                              color: Colors.blueGrey.shade300,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Text(
                      emptyTitle,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontXxl,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      emptyMessage,
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
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: _primaryNavy,
      child: ListView.builder(
        key: ValueKey('list_$_searchQuery'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TweenAnimationBuilder<double>(
            key: ValueKey(task.id),
            duration: Duration(milliseconds: 400 + (index * 100)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: TaskCard(
              assignment: task,
              onRefresh: () {
                setState(() {});
              },
            ),
          );
        },
      ),
    );
  }
}

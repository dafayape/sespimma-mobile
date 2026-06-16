import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/assessment/presentation/widgets/medis_health_grading_sheet.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class MedisHealthMonitoringScreen extends StatefulWidget {
  const MedisHealthMonitoringScreen({super.key});

  @override
  State<MedisHealthMonitoringScreen> createState() =>
      _MedisHealthMonitoringScreenState();
}

class _MedisHealthMonitoringScreenState
    extends State<MedisHealthMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  final List<Map<String, dynamic>> _students = [];
  final Map<String, Map<String, dynamic>> _healthDataMap = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final studentList = await dataSource.getStudents();
      final Map<String, Map<String, dynamic>> tempHealthMap = {};

      await Future.wait(studentList.map((student) async {
        final noSerdik = (student['nip'] ?? student['nrp'] ?? student['no_serdik'] ?? '').toString();
        if (noSerdik.isNotEmpty) {
          final health = await dataSource.getHealth(noSerdik);
          tempHealthMap[noSerdik] = health;
        }
      }));

      if (mounted) {
        setState(() {
          _students.clear();
          _students.addAll(studentList);
          _healthDataMap.clear();
          _healthDataMap.addAll(tempHealthMap);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(context, 'Gagal memuat data kesehatan: $e');
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getScoreColor(double score) {
    if (score == 0) return _primaryNavy;
    if (score >= 85.01) return Colors.green.shade700;
    if (score >= 80.01) return Colors.lightGreen.shade700;
    if (score >= 75.01) return Colors.orange.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  bool get _isAllHealthScoresFilled {
    if (_students.isEmpty) return false;
    for (var student in _students) {
      final noSerdik = (student['nip'] ?? student['nrp'] ?? student['no_serdik'] ?? '').toString();
      final health = _healthDataMap[noSerdik];
      if (health == null) return false;
      final nilaiA = health['nilai_a'];
      final nilaiB = health['nilai_b'];
      if (nilaiA == null || nilaiB == null) {
        return false;
      }
    }
    return true;
  }

  void _showLockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Kunci Data?'),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengunci data kesehatan seluruh Serdik? Data yang sudah dikunci akan digunakan untuk kalkulasi Nilai Akhir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              AppNotifier.showSuccess(context, 'Data berhasil dikunci.');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Kunci Data',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Kesehatan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXl,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isAllHealthScoresFilled) {
            _showLockDialog();
          } else {
            AppNotifier.showError(
              context,
              'Belum semua Serdik dinilai A dan B.',
            );
          }
        },
        backgroundColor: _isAllHealthScoresFilled
            ? AppColors.primaryNavy
            : Colors.grey,
        child: const Icon(Icons.lock_outline, color: Colors.white),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (_isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryNavy),
            );
          }
          if (state is AuthSuccess) {
            final baseList = _students;

            var filteredList = baseList.where((serdik) {
              final name = (serdik['name'] ?? serdik['nama_lengkap'] ?? '')
                  .toString()
                  .toLowerCase();
              final noSerdik = (serdik['nip'] ?? serdik['nrp'] ?? serdik['no_serdik'] ?? '')
                  .toString()
                  .toLowerCase();
              final query = _searchQuery.toLowerCase();
              return name.contains(query) || noSerdik.contains(query);
            }).toList();

            if (_selectedFilter != 'Semua') {
              final targetPokjar = _selectedFilter;
              filteredList = filteredList
                  .where((serdik) {
                    final pokjar = (serdik['group_name'] ?? serdik['kelompok_kelas'] ?? '').toString();
                    return pokjar == targetPokjar;
                  })
                  .toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBlock(filteredList.length),
                Divider(
                  height: AppDimensions.dividerHeight,
                  color: Colors.grey.shade200,
                  thickness: AppDimensions.dividerHeight,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchData();
                    },
                    color: _primaryNavy,
                    child: filteredList.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(child: _buildEmptyState()),
                            ],
                          )
                        : _buildSerdikList(filteredList),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: _primaryNavy),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBlock(int totalSerdik) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AssessmentSearchBarWidget(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  hintText: 'Cari nama atau nomor serdik....',
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
              StatusFilterButtonWidget(
                selectedStatus: _selectedFilter,
                statuses: _filterOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAFTAR SERDIK',
                  style: TextStyle(
                    color: _primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontLg,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
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
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.person_search_rounded,
                size: AppDimensions.iconDisplay,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Text(
              isSearching ? 'Tidak Ditemukan' : 'Tidak Ada Serdik',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              isSearching
                  ? 'Tidak ada Serdik yang cocok dengan kata kunci "$_searchQuery".'
                  : 'Belum ada data Serdik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: AppDimensions.xl),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedFilter = 'Semua';
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryNavy,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSerdikList(List<Map<String, dynamic>> serdikList) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.xl),
      itemCount: serdikList.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.md),
      itemBuilder: (context, index) {
        final serdik = serdikList[index];
        return _buildSerdikCard(serdik);
      },
    );
  }

  Widget _buildSerdikCard(Map<String, dynamic> student) {
    final noSerdik = (student['nip'] ?? student['nrp'] ?? student['no_serdik'] ?? '').toString();
    final name = (student['name'] ?? student['nama_lengkap'] ?? '-').toString();
    final pangkat = (student['pangkat'] ?? '-').toString();

    final String rawPokjar = (student['group_name'] ?? student['kelompok_kelas'] ?? '-')
        .toString()
        .toUpperCase();
    final Map<String, String> pokjarMap = {
      'POKJAR I': 'POKJAR I',
      'POKJAR II': 'POKJAR II',
      'POKJAR III': 'POKJAR III',
      'POKJAR IV': 'POKJAR IV',
      'POKJAR V': 'POKJAR V',
    };
    final String displayPokjar = pokjarMap[rawPokjar] ?? rawPokjar;

    final health = _healthDataMap[noSerdik] ?? {};
    final double? nilaiA = (health['nilai_a'] as num?)?.toDouble();
    final double? nilaiB = (health['nilai_b'] as num?)?.toDouble();
    final List<dynamic> records = health['records'] ?? [];

    final bool isGraded = nilaiA != null && nilaiB != null;
    final double finalScore = (health['current_nilai_c'] as num?)?.toDouble() ?? 0.0;
    final Color scoreColor = isGraded
        ? _getScoreColor(finalScore)
        : Colors.grey;

    final normalizedSerdik = {
      'id': student['id']?.toString() ?? '',
      'no_serdik': noSerdik,
      'nama_lengkap': name,
      'pangkat': pangkat,
      'kelompok_kelas': displayPokjar,
      'jenis_kelamin': student['gender'] ?? student['jenis_kelamin'] ?? 'Laki-laki',
      'profile_photo': student['profile_photo'] ?? student['profilePhoto'],
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(normalizedSerdik),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      '$pangkat · $noSerdik',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xs,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      child: Text(
                        displayPokjar,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (nilaiA != null)
                          _buildStatusBadge('A', Colors.green),
                        if (nilaiB != null)
                          _buildStatusBadge('B', Colors.green),
                        if (records.isNotEmpty)
                          _buildStatusNote(records.length),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGraded
                          ? scoreColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isGraded ? 'NILAI' : 'BELUM DINILAI',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w800,
                            color: isGraded ? scoreColor : Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          isGraded ? finalScore.toStringAsFixed(2) : '-',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXl,
                            fontWeight: FontWeight.w900,
                            color: isGraded ? scoreColor : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      MedisHealthGradingSheet.show(
                        context,
                        normalizedSerdik,
                        health,
                        _fetchData,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'Nilai',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontSm,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusNote(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note, size: 14, color: Colors.amber.shade800),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppDimensions.fontXs,
              fontWeight: FontWeight.w800,
              color: Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: _lightGrey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 2),
        image: DecorationImage(
          image: (profilePhoto != null && profilePhoto.isNotEmpty)
              ? FileImage(File(profilePhoto)) as ImageProvider
              : AvatarHelper.getAvatar(null),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

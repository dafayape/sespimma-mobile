import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/assessment/data/models/jasmani_grading_data.dart';
import 'package:sespimma/features/assessment/data/datasources/jasmani_lookup_tables.dart';
import 'package:sespimma/features/assessment/presentation/widgets/jasmani_grading_bottom_sheet.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

import 'package:sespimma/core/utils/avatar_helper.dart';

class OperatorJasmaniScreen extends StatefulWidget {
  const OperatorJasmaniScreen({super.key});

  @override
  State<OperatorJasmaniScreen> createState() => _OperatorJasmaniScreenState();
}

class _OperatorJasmaniScreenState extends State<OperatorJasmaniScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  List<Map<String, dynamic>> _students = [];
  Map<String, Map<String, dynamic>> _physicalDataMap = {};
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  String _selectedGolongan = 'Semua';
  String _selectedGender = 'Semua';
  String _selectedStatusPenilaian = 'Semua';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  final List<String> _golonganOptions = [
    'Semua',
    'GOL I',
    'GOL II',
    'GOL III',
    'GOL IV',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final studentList = await dataSource.getStudents();
      final Map<String, Map<String, dynamic>> tempPhysicalMap = {};

      await Future.wait(studentList.map((student) async {
        final noSerdik = (student['nip'] ?? student['nrp'] ?? student['no_serdik'] ?? '').toString();
        if (noSerdik.isNotEmpty) {
          try {
            final physical = await dataSource.getPhysical(noSerdik);
            tempPhysicalMap[noSerdik] = physical;
          } catch (_) {
            tempPhysicalMap[noSerdik] = {};
          }
        }
      }));

      if (mounted) {
        setState(() {
          _students = studentList;
          _physicalDataMap = tempPhysicalMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(context, 'Gagal memuat data jasmani: $e');
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score == 0) return _primaryNavy;
    if (score >= 90.0) return Colors.green.shade900;
    if (score >= 85.01) return Colors.green.shade700;
    if (score >= 80.01) return Colors.lightGreen.shade700;
    if (score >= 75.01) return Colors.orange.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
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
          'Monitoring Jasmani',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryNavy),
            )
          : BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
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
                    if (!(name.contains(query) || noSerdik.contains(query))) {
                      return false;
                    }

                    if (_selectedFilter != 'Semua') {
                      final pokjar = (serdik['group_name'] ?? serdik['kelompok_kelas'] ?? '').toString().toUpperCase();
                      if (pokjar != _selectedFilter) {
                        return false;
                      }
                    }

                    final tanggalLahir = (serdik['tanggal_lahir'] ?? '-').toString();
                    final golongan = JasmaniLookupTables.getGolongan(tanggalLahir);

                    if (_selectedGolongan != 'Semua') {
                      if (golongan != _selectedGolongan) return false;
                    }

                    if (_selectedGender != 'Semua') {
                      final gender = (serdik['gender'] ?? serdik['jenis_kelamin'] ?? 'Pria').toString();
                      final isPria =
                          gender.toLowerCase() == 'laki-laki' ||
                          gender.toLowerCase() == 'pria';
                      if (_selectedGender == 'Pria' && !isPria) return false;
                      if (_selectedGender == 'Wanita' && isPria) return false;
                    }

                    if (_selectedStatusPenilaian != 'Semua') {
                      final phys = _physicalDataMap[noSerdik] ?? {};
                      final data = JasmaniGradingData(
                        noSerdik: noSerdik,
                        nilaiA: (phys['nga'] as num?)?.toDouble(),
                        nilaiB1: (phys['pullup'] as num?)?.toDouble(),
                        nilaiB2: (phys['situp'] as num?)?.toDouble(),
                        nilaiB3: (phys['pushup'] as num?)?.toDouble(),
                        nilaiB4: (phys['shuttle'] as num?)?.toDouble(),
                      );

                      final bool isSamaptaA = data.nilaiA != null;
                      final bool isSamaptaB = data.isSamaptaBComplete;
                      final bool isFullyGraded =
                          isSamaptaA && (golongan == 'GOL IV' ? true : isSamaptaB);

                      if (_selectedStatusPenilaian == 'Sudah Dinilai' &&
                          !isFullyGraded) {
                        return false;
                      }
                      if (_selectedStatusPenilaian == 'Belum Dinilai' &&
                          isFullyGraded) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

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
                          onRefresh: _fetchData,
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
                  hintText: 'Cari nama atau nomor serdik..',
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
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedFilter,
                statuses: _filterOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
                defaultStatus: 'Semua',
                icon: Icons.groups_rounded,
                tooltip: 'Filter Pokjar',
              ),
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedGolongan,
                statuses: _golonganOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedGolongan = value;
                  });
                },
                defaultStatus: 'Semua',
                icon: Icons.military_tech_rounded,
                tooltip: 'Filter Golongan',
              ),
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedGender,
                statuses: const ['Semua', 'Pria', 'Wanita'],
                onSelected: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                defaultStatus: 'Semua',
                icon: Icons.wc_rounded,
                tooltip: 'Filter Jenis Kelamin',
              ),
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedStatusPenilaian,
                statuses: const ['Semua', 'Sudah Dinilai', 'Belum Dinilai'],
                onSelected: (value) {
                  setState(() {
                    _selectedStatusPenilaian = value;
                  });
                },
                defaultStatus: 'Semua',
                icon: Icons.fact_check_rounded,
                tooltip: 'Filter Status Penilaian',
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
                    _selectedGolongan = 'Semua';
                    _selectedGender = 'Semua';
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
        return _buildSerdikCard(serdikList[index]);
      },
    );
  }

  Widget _buildSerdikCard(Map<String, dynamic> serdik) {
    final name = (serdik['name'] ?? serdik['nama_lengkap'] ?? '-').toString();
    final noSerdik = (serdik['nip'] ?? serdik['nrp'] ?? serdik['no_serdik'] ?? '').toString();
    final pangkat = (serdik['pangkat'] ?? '-').toString();
    final gender = (serdik['gender'] ?? serdik['jenis_kelamin'] ?? 'Pria').toString();
    final tanggalLahir = (serdik['tanggal_lahir'] ?? '-').toString();

    final String? senatRole = serdik['jabatan_senat'] as String?;

    final golongan = JasmaniLookupTables.getGolongan(tanggalLahir);
    
    final phys = _physicalDataMap[noSerdik] ?? {};
    final data = JasmaniGradingData(
      noSerdik: noSerdik,
      nilaiA: (phys['nga'] as num?)?.toDouble(),
      nilaiB1: (phys['pullup'] as num?)?.toDouble(),
      nilaiB2: (phys['situp'] as num?)?.toDouble(),
      nilaiB3: (phys['pushup'] as num?)?.toDouble(),
      nilaiB4: (phys['shuttle'] as num?)?.toDouble(),
    );

    final bool isSamaptaA = data.nilaiA != null;
    final bool isSamaptaB = data.isSamaptaBComplete;
    final bool isFullyGraded =
        isSamaptaA && (golongan == 'GOL IV' ? true : isSamaptaB);
    final bool isPartiallyGraded = isSamaptaA || isSamaptaB;

    final double finalScore = isPartiallyGraded
        ? data.getNilaiJasmani(golongan)
        : 0;
    final Color scoreColor = isPartiallyGraded
        ? _getScoreColor(finalScore)
        : Colors.grey;

    final normalizedSerdik = {
      'id': serdik['id']?.toString() ?? '',
      'no_serdik': noSerdik,
      'nama_lengkap': name,
      'pangkat': pangkat,
      'kelompok_kelas': (serdik['group_name'] ?? serdik['kelompok_kelas'] ?? '-').toString(),
      'jenis_kelamin': gender,
      'profile_photo': serdik['profile_photo'] ?? serdik['profilePhoto'],
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
              _buildAvatar(serdik),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (gender.toLowerCase() == 'pria' ||
                                        gender.toLowerCase() == 'laki-laki')
                                    ? Colors.blue.shade100
                                    : Colors.pink.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (gender.toLowerCase() == 'pria' ||
                                        gender.toLowerCase() == 'laki-laki')
                                    ? 'P'
                                    : 'W',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color:
                                      (gender.toLowerCase() == 'pria' ||
                                          gender.toLowerCase() == 'laki-laki')
                                      ? Colors.blue.shade900
                                      : Colors.pink.shade900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                golongan,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                    if (senatRole != null && senatRole.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1A237E,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFF1A237E,
                                  ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 10,
                                  color: Color(0xFF1A237E),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  senatRole,
                                  style: const TextStyle(
                                    fontSize: AppDimensions.fontXs,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A237E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDimensions.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (isSamaptaA)
                          _buildStatusBadge('SAMAPTA A', Colors.green),
                        if (isSamaptaB)
                          _buildStatusBadge('SAMAPTA B', Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPartiallyGraded
                          ? scoreColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPartiallyGraded
                            ? scoreColor.withValues(alpha: 0.2)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      isPartiallyGraded
                          ? 'N.JAS: ${finalScore.toStringAsFixed(2)}'
                          : 'BELUM DINILAI',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXs,
                        fontWeight: FontWeight.w800,
                        color: isPartiallyGraded
                            ? scoreColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  ElevatedButton(
                    onPressed: () {
                      _showGradingOptions(
                        context,
                        normalizedSerdik,
                        data,
                        golongan,
                        gender,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFullyGraded
                          ? Colors.white
                          : AppColors.primaryNavy,
                      foregroundColor: isFullyGraded
                          ? AppColors.primaryNavy
                          : Colors.white,
                      side: isFullyGraded
                          ? const BorderSide(color: AppColors.primaryNavy)
                          : null,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                    ),
                    child: const Text(
                      'NILAI',
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

  void _showGradingOptions(
    BuildContext context,
    Map<String, dynamic> serdik,
    JasmaniGradingData data,
    String golongan,
    String gender,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => JasmaniGradingBottomSheet(
        serdik: serdik,
        gradingData: data,
        golongan: golongan,
        gender: gender,
        onGradingComplete: _fetchData,
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto = serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: (profilePhoto != null && profilePhoto.isNotEmpty)
              ? FileImage(File(profilePhoto)) as ImageProvider
              : AvatarHelper.getAvatar(null),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color.shade700,
        ),
      ),
    );
  }
}

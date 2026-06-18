import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/assessment/presentation/pages/patun_mental_form_screen.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_action_sheet.dart';
import 'package:sespimma/features/assessment/presentation/widgets/numeric_input_dialog_sheet.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class PatunMentalMonitoringScreen extends StatefulWidget {
  const PatunMentalMonitoringScreen({super.key});

  @override
  State<PatunMentalMonitoringScreen> createState() =>
      _PatunMentalMonitoringScreenState();
}

class _PatunMentalMonitoringScreenState
    extends State<PatunMentalMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Aman', 'Warning', 'Kritis'];

  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

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
    setState(() => _isLoading = true);
    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final list = await dataSource.getStudents();
      if (mounted) {
        setState(() {
          _students = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _normalizePokjar(String pokjar) {
    final clean = pokjar.toUpperCase().replaceAll(' ', '');
    if (clean.contains('III') || clean.contains('3')) return 'POKJAR III';
    if (clean.contains('II') || clean.contains('2')) return 'POKJAR II';
    if (clean.contains('IV') || clean.contains('4')) return 'POKJAR IV';
    if (clean.contains('V') || clean.contains('5')) return 'POKJAR V';
    if (clean.contains('I') || clean.contains('1')) return 'POKJAR I';
    return pokjar;
  }

  Future<void> _onSaveScore(
    double averageScore,
    String localCategory,
    Map<String, String> serdik,
    List<Map<String, dynamic>> subCategories,
    TextEditingController justificationController,
    List<TextEditingController> inputControllers,
  ) async {
    if (averageScore > 90.00 && justificationController.text.trim().isEmpty) {
      _showSnackbar(
        'Justifikasi Gagal! Wajib mengisi Berita Acara khusus untuk nilai > 90,00.',
        Colors.red.shade700,
      );
      return;
    }

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final String noSerdik = serdik['nrp'] ?? serdik['nosis'] ?? '';
      
      final Map<String, dynamic> body = {};
      if (justificationController.text.isNotEmpty) {
        body['catatan'] = justificationController.text;
      }

      final keysMap = {
        'Akademik': {
          0: 'nump',
          1: 'nkkp',
          2: 'npkp',
          3: 'nkp',
          4: 'nsk_keaktifan',
          5: 'nsk_produk',
          6: 'nsk_tata_ruang',
          7: 'nt_materi',
          8: 'nt_penulisan',
          9: 'nt_paparan',
        },
        'Mental Kepribadian': {
          0: 'moral',
          1: 'disiplin',
          2: 'kepemimpinan',
          3: 'pengendalian_diri',
          4: 'penampilan',
          5: 'sosiometri_awal',
          6: 'sosiometri_akhir',
        },
        'Jasmani': {
          0: 'tes_awal',
          1: 'tes_akhir',
          2: 'status_kesehatan',
          3: 'nga',
          4: 'pullup',
          5: 'situp',
          6: 'pushup',
          7: 'shuttle',
        }
      };

      final subKeys = keysMap[localCategory];
      if (subKeys != null) {
        for (final entry in subKeys.entries) {
          final idx = entry.key;
          final key = entry.value;
          final String txt = inputControllers[idx].text;
          if (txt.isNotEmpty) {
            final double? val = double.tryParse(txt);
            if (val != null) {
              body[key] = val;
            }
          }
        }
      }

      if (localCategory == 'Akademik') {
        await dataSource.updateAcademic(noSerdik, body);
      } else if (localCategory == 'Mental Kepribadian') {
        await dataSource.updateMental(noSerdik, body);
      } else {
        await dataSource.updatePhysical(noSerdik, body);
      }

      await _fetchData();
      if (!mounted) return;
      Navigator.pop(context);
      _showResultSnackbar(averageScore);
    } catch (e) {
      _showSnackbar('Gagal menyimpan nilai: $e', Colors.red);
    }
  }

  void _showResultSnackbar(double averageScore) {
    if (averageScore > 90.01) {
      _showSnackbar(
        'Skor ${averageScore.toStringAsFixed(2)} (>90.01) memerlukan Berita Acara khusus sebagai bentuk verifikasi.',
        Colors.amber.shade800,
      );
    } else if (averageScore <= 70.0) {
      _showSnackbar(
        'PERINGATAN: Skor ${averageScore.toStringAsFixed(2)} di bawah passing grade! Serdik dinyatakan Tidak Lulus.',
        Colors.red.shade800,
      );
    } else {
      _showSnackbar(
        'Nilai rata-rata ${averageScore.toStringAsFixed(2)} berhasil disimpan.',
        const Color(0xFF2E7D32),
      );
    }
  }

  void _showSnackbar(String msg, Color bgColor) {
    AppNotifier.showInfo(context, msg);
  }

  void _showAssessmentActionSheet(
    BuildContext parentContext,
    Map<String, String> serdik,
  ) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (modalContext) => AssessmentActionSheet(
        serdik: serdik,
        currentRole: 'Patun',
        onInputNilai: () {
          Navigator.pop(modalContext);
          _showNumericInputDialog(parentContext, serdik);
        },
        onInputMedis: () {},
        onReward: () {
          Navigator.pop(modalContext);
          final dynamicStudent = _students.firstWhere(
            (s) => (s['no_serdik'] ?? s['nip'] ?? '') == serdik['nosis'],
            orElse: () => {},
          );
          Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => PatunMentalFormScreen(
                isReward: true,
                initialSerdik: dynamicStudent,
              ),
            ),
          ).then((_) => _fetchData());
        },
        onPunishment: () {
          Navigator.pop(modalContext);
          final dynamicStudent = _students.firstWhere(
            (s) => (s['no_serdik'] ?? s['nip'] ?? '') == serdik['nosis'],
            orElse: () => {},
          );
          Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => PatunMentalFormScreen(
                isReward: false,
                initialSerdik: dynamicStudent,
              ),
            ),
          ).then((_) => _fetchData());
        },
        onViewReport: null,
      ),
    );
  }

  void _showNumericInputDialog(
    BuildContext context,
    Map<String, String> serdik,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NumericInputDialogSheet(
        serdik: serdik,
        currentRole: 'Patun',
        category: 'Mental Kepribadian',
        onSaveScore: _onSaveScore,
      ),
    );
  }

  void _showStudentLookupBottomSheet(BuildContext parentContext, String userPokjar) {
    String localSearchQuery = '';
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setModalState) {
            final baseList = _students
                .where((r) =>
                    _normalizePokjar(r['group_name'] ?? r['kelompok_kelas'] ?? '') ==
                    _normalizePokjar(userPokjar))
                .toList();

            final filteredList = baseList.where((student) {
              final name = (student['nama_lengkap'] ?? student['name'] ?? '').toString().toLowerCase();
              final noSerdik = (student['no_serdik'] ?? student['nip'] ?? '').toString().toLowerCase();
              final query = localSearchQuery.toLowerCase();
              return name.contains(query) || noSerdik.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.xl,
                      vertical: AppDimensions.lg,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cari Serdik',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXl,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(stateContext),
                          color: Colors.grey.shade600,
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    child: TextField(
                      onChanged: (val) => setModalState(() => localSearchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau nomor serdik...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: _lightGrey,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                            child: Text(
                              'Serdik tidak ditemukan',
                              style: TextStyle(
                                fontSize: AppDimensions.fontLg,
                                color: Colors.blueGrey.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredList.length,
                            itemBuilder: (listContext, index) {
                              final student = filteredList[index];
                              final String name = (student['nama_lengkap'] ?? student['name'] ?? '-').toString();
                              final String noSerdik = (student['no_serdik'] ?? student['nip'] ?? '-').toString();
                              final String pangkat = (student['pangkat'] ?? '-').toString();

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.xl,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blueGrey.shade50,
                                  child: Icon(Icons.person_rounded, color: Colors.blueGrey.shade300),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _primaryNavy,
                                  ),
                                ),
                                subtitle: Text(
                                  '$pangkat • $noSerdik',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(stateContext); // Close lookup sheet

                                  final raw = ScoreCalculatorService.generateSimulatedScores(noSerdik);
                                  final finalRecap = ScoreCalculatorService.calculateFinalRecap(student, raw);
                                  final double score = finalRecap.mentalScore;
                                  final String status = score >= 80.0 ? 'Aman' : (score >= 70.0 ? 'Warning' : 'Kritis');

                                  final Map<String, String> serdikMap = {
                                    'id': (student['id'] ?? '').toString(),
                                    'name': name,
                                    'nrp': noSerdik,
                                    'nosis': noSerdik,
                                    'pokjar': (student['group_name'] ?? student['pokjar'] ?? student['kelompok_kelas'] ?? '').toString().toUpperCase(),
                                    'status': status,
                                    'jenisKelamin': (student['jenis_kelamin'] ?? 'Laki-laki').toString(),
                                    'tanggalLahir': (student['tanggal_lahir'] ?? '').toString(),
                                    'sosiometriAwal': (student['sosiometri_awal'] ?? '0.00').toString(),
                                    'sosiometriAkhir': (student['sosiometri_akhir'] ?? '0.00').toString(),
                                  };

                                  _showAssessmentActionSheet(parentContext, serdikMap);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          final user = state.user;
          final userPokjar = user.pokjar;

          if (_isLoading) {
            return Scaffold(
              backgroundColor: _lightGrey,
              appBar: AppBar(
                backgroundColor: _primaryNavy,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                title: const Text(
                  'Monitoring Mental',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.fontXxl,
                  ),
                ),
              ),
              body: const Center(
                child: CircularProgressIndicator(color: _primaryNavy),
              ),
            );
          }

          final baseList = _students
              .where((r) =>
                  _normalizePokjar(r['group_name'] ?? r['kelompok_kelas'] ?? '') ==
                  _normalizePokjar(userPokjar))
              .toList();

          final listWithScores = baseList.map((entry) {
            final serdik = Map<String, dynamic>.from(entry);
            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? '').toString();

            final raw = ScoreCalculatorService.generateSimulatedScores(noSerdik);
            final finalRecap = ScoreCalculatorService.calculateFinalRecap(serdik, raw);
            final score = finalRecap.mentalScore;

            final String status;
            if (score >= 80.0) {
              status = 'Aman';
            } else if (score >= 70.0) {
              status = 'Warning';
            } else {
              status = 'Kritis';
            }

            serdik['_mock_score'] = score;
            serdik['_mock_status'] = status;
            final jSenat = (serdik['jabatan_senat'] ?? '').toString();
            serdik['_senat_role'] = jSenat.isNotEmpty ? jSenat : null;
            return serdik;
          }).toList();

          var filteredList = listWithScores.where((serdik) {
            final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '')
                .toString()
                .toLowerCase();
            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? '')
                .toString()
                .toLowerCase();
            final status = (serdik['_mock_status'] as String?) ?? 'Aman';
            final query = _searchQuery.toLowerCase();

            final matchesSearch =
                name.contains(query) || noSerdik.contains(query);
            final matchesFilter =
                _selectedFilter == 'Semua' || status == _selectedFilter;

            return matchesSearch && matchesFilter;
          }).toList();

          filteredList.sort((a, b) {
            final nameA = (a['name'] ?? a['nama_lengkap'] ?? '').toString().toUpperCase();
            final nameB = (b['name'] ?? b['nama_lengkap'] ?? '').toString().toUpperCase();
            return nameA.compareTo(nameB);
          });

          return Scaffold(
            backgroundColor: _lightGrey,
            appBar: AppBar(
              backgroundColor: _primaryNavy,
              elevation: 0,
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: const Text(
                'Monitoring Mental',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontXxl,
                ),
              ),
              actions: [const SizedBox(width: AppDimensions.sm)],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'input_nilai_fab',
              onPressed: () => _showStudentLookupBottomSheet(context, userPokjar),
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
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBlock(userPokjar, baseList.length),
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
            ),
          );
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: _primaryNavy),
          ),
        );
      },
    );
  }

  Widget _buildHeaderBlock(String pokjar, int totalSerdik) {
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
                  hintText: 'Cari nama atau nomor serdik...',
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
              const Text(
                'DAFTAR SERDIK',
                style: TextStyle(
                  color: _primaryNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.fontLg,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Text(
                  pokjar.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.fontSm,
                  ),
                ),
              ),
              const Spacer(),
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
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
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
    final isFiltered = _selectedFilter != 'Semua';
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
                  : isFiltered
                  ? 'Tidak ada Serdik dengan status "$_selectedFilter" di Pokjar Anda.'
                  : 'Belum ada data Serdik untuk Pokjar Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
            if (isSearching || isFiltered) ...[
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.xl,
            AppDimensions.xl,
            AppDimensions.huge + AppDimensions.xxxl,
          ),
          itemCount: serdikList.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            final serdik = serdikList[index];
            final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '-').toString();
            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? serdik['nrp'] ?? '-').toString();
            final pangkat = (serdik['pangkat'] ?? '-').toString();
            final double score =
                (serdik['_mock_score'] as num?)?.toDouble() ?? 0.0;
            final String status = (serdik['_mock_status'] as String?) ?? 'Aman';

            return _buildSerdikCard(
              serdik,
              name,
              noSerdik,
              pangkat,
              score,
              status,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSerdikCard(
    Map<String, dynamic> serdik,
    String name,
    String noSerdik,
    String pangkat,
    double score,
    String status,
  ) {
    final Color statusColor;
    final IconData statusIcon;
    final String? senatRole = serdik['_senat_role'] as String?;
    if (status == 'Aman') {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Warning') {
      statusColor = const Color(0xFFF57C00);
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = const Color(0xFFD32F2F);
      statusIcon = Icons.error_rounded;
    }

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
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: () {
            HapticFeedback.selectionClick();
            final Map<String, String> serdikMap = {
              'id': (serdik['id'] ?? '').toString(),
              'name': name,
              'nrp': noSerdik,
              'nosis': noSerdik,
              'pokjar': (serdik['group_name'] ?? serdik['pokjar'] ?? serdik['kelompok_kelas'] ?? '').toString().toUpperCase(),
              'status': status,
              'jenisKelamin': (serdik['jenis_kelamin'] ?? 'Laki-laki').toString(),
              'tanggalLahir': (serdik['tanggal_lahir'] ?? '').toString(),
              'sosiometriAwal': (serdik['sosiometri_awal'] ?? '0.00').toString(),
              'sosiometriAkhir': (serdik['sosiometri_akhir'] ?? '0.00').toString(),
            };
            _showAssessmentActionSheet(context, serdikMap);
          },
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
                      const SizedBox(height: AppDimensions.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusColor),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXs,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (senatRole != null && senatRole.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color: const Color(0xFF1A237E).withValues(alpha: 0.2),
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
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NILAI',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        score.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
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

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(AppDimensions.xs / 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blueGrey.shade100,
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blueGrey.shade50,
        backgroundImage: (profilePhoto != null && profilePhoto.isNotEmpty)
            ? FileImage(File(profilePhoto)) as ImageProvider
            : null,
        child: (profilePhoto == null || profilePhoto.isEmpty)
            ? Icon(
                Icons.person_rounded,
                color: Colors.blueGrey.shade300,
                size: 28,
              )
            : null,
      ),
    );
  }
}

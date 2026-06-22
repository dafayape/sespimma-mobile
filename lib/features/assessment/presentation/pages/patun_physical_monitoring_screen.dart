import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/features/report/presentation/pages/report_screen.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';

class PatunPhysicalMonitoringScreen extends StatefulWidget {
  const PatunPhysicalMonitoringScreen({super.key});

  @override
  State<PatunPhysicalMonitoringScreen> createState() =>
      _PatunPhysicalMonitoringScreenState();
}

class _PatunPhysicalMonitoringScreenState
    extends State<PatunPhysicalMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _students = [];

  final List<String> _filterOptions = ['Semua', 'Aman', 'Warning', 'Kritis'];

  @override
  void initState() {
    super.initState();
    _fetchData();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          'Monitoring Penilaian',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: _primaryNavy,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess) {
              if (_isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: _primaryNavy),
                );
              }
              final user = state.user;
              final userPokjar = user.pokjar;
              final userRole = user.roleId.toLowerCase();

              final List<Map<String, dynamic>> baseList;
              if (userRole == 'korsis' || userRole == 'pimpinan' || userRole == 'admin' || userRole == 'superadmin') {
                baseList = _students;
              } else {
                baseList = _students
                    .where((r) =>
                        _normalizePokjar(r['group_name'] ?? r['kelompok_kelas'] ?? '') ==
                        _normalizePokjar(userPokjar))
                    .toList();
              }

              final listWithEWS = baseList.map((student) {
                final serdik = Map<String, dynamic>.from(student);
                final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? '').toString();

                final raw = ScoreCalculatorService.generateSimulatedScores(noSerdik);
                final finalRecap = ScoreCalculatorService.calculateFinalRecap(serdik, raw);
                final double score = finalRecap.physicalScore;

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

              var filteredList = listWithEWS.where((serdik) {
                final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '')
                    .toString()
                    .toLowerCase();
                final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? '')
                    .toString()
                    .toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || noSerdik.contains(query);
              }).toList();

              if (_selectedFilter != 'Semua') {
                filteredList = filteredList
                    .where((serdik) => serdik['_mock_status'] == _selectedFilter)
                    .toList();
              }

              filteredList.sort((a, b) {
                final nameA = (a['name'] ?? a['nama_lengkap'] ?? '').toString().toUpperCase();
                final nameB = (b['name'] ?? b['nama_lengkap'] ?? '').toString().toUpperCase();
                return nameA.compareTo(nameB);
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBlock(userRole, userPokjar, baseList.length),
                  Divider(
                    height: AppDimensions.dividerHeight,
                    color: Colors.grey.shade200,
                    thickness: AppDimensions.dividerHeight,
                  ),
                  Expanded(
                    child: filteredList.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: _buildEmptyState(userRole, userPokjar),
                              ),
                            ],
                          )
                        : _buildSerdikList(filteredList),
                  ),
                ],
              );
            }
            return const Center(
              child: CircularProgressIndicator(color: _primaryNavy),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderBlock(String role, String pokjar, int totalSerdik) {
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
                  (role == 'korsis' || role == 'pimpinan' || role == 'admin' || role == 'superadmin')
                      ? 'SEMUA POKJAR'
                      : pokjar.toUpperCase(),
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

  Widget _buildEmptyState(String role, String pokjar) {
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
                  ? 'Tidak ada Serdik dengan status "$_selectedFilter".'
                  : 'Belum ada data Serdik.',
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.xl),
          itemCount: serdikList.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            final serdik = serdikList[index];
            final name = (serdik['name'] ?? serdik['nama_lengkap'] ?? '-').toString();
            final noSerdik = (serdik['nip'] ?? serdik['nosis'] ?? serdik['no_serdik'] ?? '-').toString();
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportScreen(
                  targetUser: UserEntity(
                    userId: (serdik['id'] ?? '').toString(),
                    name: name,
                    roleId: 'serdik',
                    pokjar: (serdik['group_name'] ?? serdik['pokjar'] ?? serdik['kelompok_kelas'] ?? '').toString(),
                    nrp: noSerdik,
                    nosis: noSerdik,
                    pangkat: pangkat,
                    angkatan: (serdik['angkatan'] ?? '').toString(),
                    agama: (serdik['agama'] ?? '').toString(),
                    jenisKelamin: (serdik['jenis_kelamin'] ?? serdik['jenisKelamin'] ?? 'Laki-laki').toString(),
                    jabatan: (serdik['jabatan'] ?? '').toString(),
                    noSerdik: noSerdik,
                    nik: (serdik['nik'] ?? '').toString(),
                    jabatanSenat: (serdik['jabatan_senat'] ?? '').toString(),
                    tempatLahir: (serdik['tempat_lahir'] ?? '').toString(),
                    noHandphone: (serdik['no_handphone'] ?? '').toString(),
                    pendidikanTerakhir: (serdik['pendidikan_terakhir'] ?? '').toString(),
                    alamatLengkap: (serdik['alamat_lengkap'] ?? '').toString(),
                    email: (serdik['email'] ?? '').toString(),
                    noTelepon: (serdik['no_telepon'] ?? '').toString(),
                    kelompok: (serdik['kelompok'] ?? '').toString(),
                    diktukAwal: (serdik['diktuk_awal'] ?? '').toString(),
                    tahunDiktuk: (serdik['tahun_diktuk'] ?? '').toString(),
                    personel: (serdik['personel'] ?? '').toString(),
                    satker: (serdik['satker'] ?? '').toString(),
                    eselon: (serdik['eselon'] ?? '').toString(),
                    golongan: (serdik['golongan'] ?? '').toString(),
                    nilaiAkademik: 0.0,
                    nilaiMental: 0.0,
                    nilaiJasmani: 0.0,
                    serdikId: (serdik['id'] ?? '').toString(),
                  ),
                ),
              ),
            );
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
                          if (senatRole != null && senatRole.toString().isNotEmpty) ...[
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
        child: Icon(
          Icons.person_rounded,
          color: Colors.blueGrey.shade300,
          size: 28,
        ),
      ),
    );
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
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_action_sheet.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_empty_state_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/pokjar_dropdown_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/serdik_card_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/medical_deduction_dialog.dart';
import 'package:sespimma/features/assessment/presentation/widgets/numeric_input_dialog_sheet.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/features/report/presentation/pages/report_screen.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/assessment/presentation/pages/patun_mental_form_screen.dart';

class GadikAssessmentScreen extends StatefulWidget {
  final String? categoryOverride;
  const GadikAssessmentScreen({super.key, this.categoryOverride});

  @override
  State<GadikAssessmentScreen> createState() => _GadikAssessmentScreenState();
}

class _GadikAssessmentScreenState extends State<GadikAssessmentScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPokjar = 'Semua Pokjar';
  String _selectedStatus = 'Semua Status';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, String>> _serdikList = [];

  final List<String> _statuses = [
    'Semua Status',
    'Sudah Dinilai',
    'Belum Dinilai',
  ];
  final List<String> _pokjars = [
    'Semua Pokjar',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AuthBloc>().state;
      if (state is AuthSuccess) {
        final roleId = state.user.roleId.toLowerCase();
        if (roleId.contains('patun')) {
          final uPokjar = state.user.pokjar;
          if (uPokjar.isNotEmpty && uPokjar != '-') {
            setState(() {
              _selectedPokjar = _normalizePokjarToRoman(uPokjar);
            });
          }
        }
      }
      _fetchData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final role = _getCurrentRole(context);
      String category = widget.categoryOverride ?? 'Akademik';
      if (widget.categoryOverride == null) {
        if (role == 'Patun' || role == 'Gadik') {
          category = 'Mental Kepribadian';
        } else if (role == 'Tim Medis' || role == 'Korsis') {
          category = 'Jasmani';
        }
      }

      final dataSource = sl<AssessmentRemoteDataSource>();
      final students = await dataSource.getStudents();
      final gradedIds = await dataSource.getGradedStatus(category);
      final gradedSet = gradedIds.toSet();

      final List<Map<String, String>> list = [];
      for (final student in students) {
        final int id = student['id'] ?? 0;
        final bool sudahDinilai = gradedSet.contains(id);
        final String nosisVal = (student['nip'] ?? student['no_serdik'] ?? student['nosis'] ?? '').toString();

        list.add({
          'id': id.toString(),
          'user_id': (student['user_id'] ?? '').toString(),
          'name': (student['name'] ?? student['nama_lengkap'] ?? '').toString(),
          'nrp': (student['nrp'] ?? '').toString(),
          'nosis': nosisVal,
          'pokjar': (student['group_name'] ?? student['pokjar'] ?? student['kelompok_kelas'] ?? '').toString().toUpperCase(),
          'status': sudahDinilai ? 'Sudah Dinilai' : 'Belum Dinilai',
          'jenisKelamin': (student['jenis_kelamin'] ?? student['gender'] ?? 'Laki-laki').toString(),
          'tanggalLahir': (student['tanggal_lahir'] ?? student['birth_date'] ?? '').toString(),
          'profile_photo': (student['profile_photo'] ?? '').toString(),
          'sanksiKesehatan': '0',
          'sosiometri': '0.00',
        });
      }

      if (mounted) {
        setState(() {
          _serdikList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackbar('Gagal memuat data serdik: $e', Colors.red);
      }
    }
  }

  String _getCurrentRole(BuildContext context) {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess) {
      final roleId = state.user.roleId.toLowerCase();
      if (roleId.contains('patun')) return 'Patun';
      if (roleId.contains('medis')) return 'Tim Medis';
      if (roleId.contains('korsis')) return 'Korsis';
      if (roleId.contains('pimpinan') || roleId.contains('admin')) {
        return 'Admin';
      }
    }
    return 'Gadik';
  }

  void _showAssessmentActionSheet(
    BuildContext context,
    Map<String, String> serdik,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusRound),
        ),
      ),
      builder: (_) => AssessmentActionSheet(
        serdik: serdik,
        currentRole: _getCurrentRole(context),
        onInputNilai: () {
          Navigator.pop(context);
          _showNumericInputDialog(context, serdik);
        },
        onInputMedis: () {
          Navigator.pop(context);
          _showMedicalDeductionDialog(context, serdik);
        },
        onReward: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatunMentalFormScreen(
                isReward: true,
                initialSerdik: {
                  'id': int.tryParse(serdik['id'] ?? '0'),
                  'user_id': int.tryParse(serdik['user_id'] ?? '0'),
                  'no_serdik': serdik['nosis'] ?? '',
                  'nip': serdik['nosis'] ?? '',
                  'nrp': serdik['nrp'] ?? '',
                  'nama_lengkap': serdik['name'] ?? '',
                  'name': serdik['name'] ?? '',
                  'pangkat': serdik['pangkat'] ?? '',
                  'kelompok_kelas': serdik['pokjar'] ?? '',
                  'pokjar': serdik['pokjar'] ?? '',
                  'jenis_kelamin': serdik['jenisKelamin'] ?? '',
                  'profile_photo': serdik['profile_photo'] ?? '',
                },
              ),
            ),
          ).then((_) => _fetchData());
        },
        onPunishment: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PatunMentalFormScreen(
                isReward: false,
                initialSerdik: {
                  'id': int.tryParse(serdik['id'] ?? '0'),
                  'user_id': int.tryParse(serdik['user_id'] ?? '0'),
                  'no_serdik': serdik['nosis'] ?? '',
                  'nip': serdik['nosis'] ?? '',
                  'nrp': serdik['nrp'] ?? '',
                  'nama_lengkap': serdik['name'] ?? '',
                  'name': serdik['name'] ?? '',
                  'pangkat': serdik['pangkat'] ?? '',
                  'kelompok_kelas': serdik['pokjar'] ?? '',
                  'pokjar': serdik['pokjar'] ?? '',
                  'jenis_kelamin': serdik['jenisKelamin'] ?? '',
                  'profile_photo': serdik['profile_photo'] ?? '',
                },
              ),
            ),
          ).then((_) => _fetchData());
        },
        onViewReport: _getCurrentRole(context) == 'Patun'
            ? null
            : () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportScreen(
                      targetUser: UserEntity(
                        userId: serdik['id'] ?? '',
                        name: serdik['name'] ?? '',
                        roleId: 'serdik',
                        pokjar: serdik['pokjar'] ?? '',
                        nrp: serdik['nrp'] ?? serdik['nosis'] ?? '',
                        nosis: serdik['nosis'] ?? '',
                        pangkat: '',
                        angkatan: '',
                        agama: '',
                        jenisKelamin: serdik['jenisKelamin'] ?? 'Laki-laki',
                        jabatan: '',
                        noSerdik: serdik['nosis'] ?? '',
                        nik: '',
                        jabatanSenat: '',
                        tempatLahir: '',
                        noHandphone: '',
                        pendidikanTerakhir: '',
                        alamatLengkap: '',
                        email: '',
                        noTelepon: '',
                        kelompok: '',
                        diktukAwal: '',
                        tahunDiktuk: '',
                        personel: '',
                        satker: '',
                        eselon: '',
                        golongan: '',
                        nilaiAkademik: 0.0,
                        nilaiMental: 0.0,
                        nilaiJasmani: 0.0,
                        serdikId: serdik['id'],
                      ),
                    ),
                  ),
                );
              },
      ),
    );
  }

  void _showMedicalDeductionDialog(
    BuildContext context,
    Map<String, String> serdik,
  ) {
    showDialog(
      context: context,
      builder: (_) => MedicalDeductionDialog(
        serdik: serdik,
        onSaved: () => _fetchData(),
      ),
    );
  }

  void _showNumericInputDialog(
    BuildContext context,
    Map<String, String> serdik,
  ) {
    final role = _getCurrentRole(context);
    String category = widget.categoryOverride ?? 'Akademik';
    if (widget.categoryOverride == null) {
      if (role == 'Patun') {
        category = 'Mental Kepribadian';
      } else if (role == 'Tim Medis' || role == 'Korsis') {
        category = 'Jasmani';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NumericInputDialogSheet(
        serdik: serdik,
        currentRole: role,
        category: category,
        onSaveScore: _onSaveScore,
      ),
    );
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
          5: 'sosiometri',
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
        AppColors.successGreen,
      );
    }
  }

  void _showSnackbar(String msg, Color bgColor) {
    AppNotifier.showInfo(context, msg);
  }

  String _normalizePokjarToRoman(String pokjar) {
    final clean = pokjar.toUpperCase().replaceAll(' ', '');
    if (clean.contains('III') || clean.contains('3')) return 'POKJAR III';
    if (clean.contains('II') || clean.contains('2')) return 'POKJAR II';
    if (clean.contains('IV') || clean.contains('4')) return 'POKJAR IV';
    if (clean.contains('V') || clean.contains('5')) return 'POKJAR V';
    if (clean.contains('I') || clean.contains('1')) return 'POKJAR I';
    return pokjar;
  }

  String _normalizePokjarToArabic(String pokjar) {
    final clean = pokjar.toUpperCase().replaceAll(' ', '');
    if (clean.contains('III') || clean.contains('3')) return 'POKJAR 3';
    if (clean.contains('II') || clean.contains('2')) return 'POKJAR 2';
    if (clean.contains('IV') || clean.contains('4')) return 'POKJAR 4';
    if (clean.contains('V') || clean.contains('5')) return 'POKJAR 5';
    if (clean.contains('I') || clean.contains('1')) return 'POKJAR 1';
    return pokjar;
  }

  void _showStudentLookupBottomSheet(BuildContext parentContext) {
    String localSearchQuery = '';
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (stateContext, setModalState) {
            final filteredList = _serdikList.where((student) {
              final name = (student['name'] ?? '').toLowerCase();
              final noSerdik = (student['nrp'] ?? student['nosis'] ?? '').toLowerCase();
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
                            color: AppColors.primaryNavy,
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
                        fillColor: const Color(0xFFF8F9FA),
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
                              final String name = student['name'] ?? '-';
                              final String noSerdik = student['nrp'] ?? student['nosis'] ?? '-';
                              final String pokjar = student['pokjar'] ?? '-';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.xl,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blueGrey.shade50,
                                  backgroundImage: (student['profile_photo'] != null && student['profile_photo']!.isNotEmpty)
                                      ? FileImage(File(student['profile_photo']!)) as ImageProvider
                                      : null,
                                  child: (student['profile_photo'] == null || student['profile_photo']!.isEmpty)
                                      ? Icon(Icons.person_rounded, color: Colors.blueGrey.shade300)
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                subtitle: Text(
                                  '$pokjar • $noSerdik',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(stateContext); // Close lookup sheet
                                  _showAssessmentActionSheet(parentContext, student);
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
    final role = _getCurrentRole(context);

    final filteredList = _serdikList.where((serdik) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          serdik['name']!.toLowerCase().contains(q) ||
          serdik['nrp']!.toLowerCase().contains(q);
      final matchPokjar =
          _selectedPokjar == 'Semua Pokjar' ||
          _normalizePokjarToArabic(serdik['pokjar'] ?? '') ==
              _normalizePokjarToArabic(_selectedPokjar);
      final matchStatus =
          _selectedStatus == 'Semua Status' ||
          serdik['status'] == _selectedStatus;
      return matchSearch && matchPokjar && matchStatus;
    }).toList();

    filteredList.sort((a, b) {
      final nameA = (a['name'] ?? '').toUpperCase();
      final nameB = (b['name'] ?? '').toUpperCase();
      return nameA.compareTo(nameB);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        centerTitle: true,
        automaticallyImplyLeading: Navigator.canPop(context),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          role == 'Gadik'
              ? 'Penilaian Serdik'
              : widget.categoryOverride == 'Mental Kepribadian'
                  ? 'Penilaian Mental'
                  : widget.categoryOverride == 'Jasmani'
                      ? 'Penilaian Jasmani'
                      : 'Penilaian Akademik',
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      floatingActionButton: role == 'Gadik'
          ? FloatingActionButton.extended(
              heroTag: 'gadik_input_nilai_fab',
              onPressed: () => _showStudentLookupBottomSheet(context),
              backgroundColor: AppColors.primaryNavy,
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
            )
          : null,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xl,
              vertical: AppDimensions.lg,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AssessmentSearchBarWidget(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    onChanged: (val) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 300),
                        () => setState(() => _searchQuery = val),
                      );
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                if (_getCurrentRole(context) != 'Patun') ...[
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: PokjarDropdownWidget(
                      selectedPokjar: _selectedPokjar,
                      pokjars: _pokjars,
                      onChanged: (val) {
                        setState(() => _selectedPokjar = val);
                        _animController.forward(from: 0.0);
                      },
                    ),
                  ),
                ],
                const SizedBox(width: AppDimensions.sm),
                StatusFilterButtonWidget(
                  selectedStatus: _selectedStatus,
                  statuses: _statuses,
                  onSelected: (val) {
                    setState(() => _selectedStatus = val);
                    _animController.forward(from: 0.0);
                  },
                ),
              ],
            ),
          ),
          Divider(
            height: AppDimensions.dividerHeight,
            color: Colors.grey.shade200,
            thickness: AppDimensions.dividerHeight,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryNavy,
                    ),
                  )
                : filteredList.isEmpty
                    ? const AssessmentEmptyStateWidget()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.xl,
                          vertical: AppDimensions.lg,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) => SerdikCardWidget(
                          serdik: filteredList[index],
                          onTap: () => _showAssessmentActionSheet(
                            context,
                            filteredList[index],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

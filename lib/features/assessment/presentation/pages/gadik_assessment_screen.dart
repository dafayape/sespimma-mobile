import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
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
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';

class GadikAssessmentScreen extends StatefulWidget {
  const GadikAssessmentScreen({super.key});

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
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _mockSerdikList {
    return PimpinanMockData.sharedReportData.map((report) {
      final bool sudahDinilai = PimpinanMockData.ratedSerdikForAssessment
          .contains(report.nrp);
      return {
        'name': report.name,
        'nrp': report.nrp,
        'nosis': report.nosis,
        'pokjar': report.pokjar.toUpperCase(),
        'status': sudahDinilai ? 'Sudah Dinilai' : 'Belum Dinilai',
        if (sudahDinilai) 'lookupPoints': '+0.50',
        'tanggalLahir': report.tanggalLahir,
        'jenisKelamin': report.jenisKelamin,
        'sanksiKesehatan': report.sanksiKesehatan.toString(),
        'sosiometriAwal': (report.mentalScore * 1.05).toStringAsFixed(2),
        'sosiometriAkhir': (report.mentalScore * 1.02).toStringAsFixed(2),
      };
    }).toList();
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
          Navigator.pushNamed(
            context,
            '/lookup-selection',
            arguments: {'type': 'reward', 'serdik': serdik},
          );
        },
        onPunishment: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            '/lookup-selection',
            arguments: {'type': 'punishment', 'serdik': serdik},
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
        onSaved: () => setState(() {}),
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
        currentRole: _getCurrentRole(context),
        onSaveScore: _onSaveScore,
      ),
    );
  }

  void _onSaveScore(
    double averageScore,
    String localCategory,
    Map<String, String> serdik,
    List<Map<String, dynamic>> subCategories,
    TextEditingController justificationController,
  ) {
    if (averageScore > 90.00 && justificationController.text.trim().isEmpty) {
      _showSnackbar(
        'Justifikasi Gagal! Wajib mengisi Berita Acara khusus untuk nilai > 90,00.',
        Colors.red.shade700,
      );
      return;
    }
    setState(() {
      PimpinanMockData.ratedSerdikForAssessment.add(serdik['nrp']!);
      serdik['status'] = 'Sudah Dinilai';
      _updateMockData(localCategory, averageScore, serdik, subCategories);
    });
    Navigator.pop(context);
    _showResultSnackbar(averageScore);
  }

  void _updateMockData(
    String localCategory,
    double averageScore,
    Map<String, String> serdik,
    List<Map<String, dynamic>> subCategories,
  ) {
    final index = PimpinanMockData.sharedReportData.indexWhere(
      (r) => r.nrp == serdik['nrp'],
    );
    if (index == -1) return;

    final current = PimpinanMockData.sharedReportData[index];
    double newPhysicalScore = current.physicalScore;
    double newMentalScore = current.mentalScore;
    double newAcademicScore = current.academicScore;

    if (localCategory == 'Mental Kepribadian') {
      newMentalScore = averageScore;
    } else if (localCategory == 'Akademik') {
      newAcademicScore = averageScore;
    } else {
      newPhysicalScore = averageScore;
    }

    PimpinanMockData.sharedReportData[index] = current.copyWith(
      physicalScore: newPhysicalScore,
      mentalScore: newMentalScore,
      academicScore: newAcademicScore,
    );
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

  @override
  Widget build(BuildContext context) {
    final filteredList = _mockSerdikList.where((serdik) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          serdik['name']!.toLowerCase().contains(q) ||
          serdik['nrp']!.toLowerCase().contains(q);
      final matchPokjar =
          _selectedPokjar == 'Semua Pokjar' ||
          serdik['pokjar'] == _mapRomanToArabic(_selectedPokjar);
      final matchStatus =
          _selectedStatus == 'Semua Status' ||
          serdik['status'] == _selectedStatus;
      return matchSearch && matchPokjar && matchStatus;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        centerTitle: true,
        title: const Text(
          'Input Penilaian Serdik',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
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
            child: filteredList.isEmpty
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

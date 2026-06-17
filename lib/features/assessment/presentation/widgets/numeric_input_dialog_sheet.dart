import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/assessment/domain/services/assessment_sub_categories.dart';
import 'package:sespimma/features/assessment/domain/services/samapta_scoring_service.dart';
import 'package:sespimma/features/assessment/presentation/widgets/samapta_calculator_dialog.dart';
import 'package:sespimma/features/assessment/presentation/widgets/score_summary_widget.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';

class NumericInputDialogSheet extends StatefulWidget {
  final Map<String, String> serdik;
  final String currentRole;
  final String? category;
  final Function(
    double,
    String,
    Map<String, String>,
    List<Map<String, dynamic>>,
    TextEditingController,
    List<TextEditingController>,
  )
  onSaveScore;

  const NumericInputDialogSheet({
    super.key,
    required this.serdik,
    required this.currentRole,
    this.category,
    required this.onSaveScore,
  });

  @override
  State<NumericInputDialogSheet> createState() =>
      _NumericInputDialogSheetState();
}

class _NumericInputDialogSheetState extends State<NumericInputDialogSheet> {
  late String localCategory;
  late String localTahap;
  List<Map<String, dynamic>> subCategories = [];
  double averageScore = 0.0;
  bool _isLoading = false;
  final TextEditingController justificationController = TextEditingController();
  final List<TextEditingController> _inputControllers = List.generate(
    10,
    (index) => TextEditingController(),
  );

  @override
  void initState() {
    super.initState();
    localCategory = widget.category ?? 'Akademik';
    if (widget.category == null) {
      if (widget.currentRole == 'Patun') localCategory = 'Mental Kepribadian';
      if (widget.currentRole == 'Tim Medis' || widget.currentRole == 'Korsis') {
        localCategory = 'Jasmani';
      }
    }
    _setupCategory(localCategory);
    _loadActualScores();
  }

  Future<void> _loadActualScores() async {
    setState(() => _isLoading = true);
    try {
      final dataSource = GetIt.instance<AssessmentRemoteDataSource>();
      final String noSerdik = widget.serdik['nrp'] ?? widget.serdik['nosis'] ?? '';
      Map<String, dynamic> data = {};

      if (localCategory == 'Akademik') {
        data = await dataSource.getAcademic(noSerdik);
      } else if (localCategory == 'Mental Kepribadian') {
        data = await dataSource.getMental(noSerdik);
      } else {
        data = await dataSource.getPhysical(noSerdik);
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
          final val = data[key];
          if (val != null) {
            final double dVal = double.tryParse(val.toString()) ?? 0.0;
            if (dVal > 0) {
              _inputControllers[idx].text = dVal.toStringAsFixed(2);
            } else {
              _inputControllers[idx].text = '';
            }
          }
        }
      }

      _calculateAverage();
    } catch (e) {
      // ignore
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    justificationController.dispose();
    for (var c in _inputControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _setupCategory(String cat) {
    localCategory = cat;
    localTahap = widget.currentRole == 'Korsis' ? 'Samapta' : 'Semua';
    for (final c in _inputControllers) {
      c.text = '';
    }
    final bool isWanita =
        (widget.serdik['jenisKelamin'] ?? 'Laki-laki') == 'Perempuan';

    if (cat == 'Akademik') {
      subCategories = AssessmentSubCategories.getAkademik();
    } else if (cat == 'Mental Kepribadian') {
      subCategories = AssessmentSubCategories.getMentalKepribadian();
    } else {
      subCategories = AssessmentSubCategories.getJasmani(
        isWanita: isWanita,
        currentRole: widget.currentRole,
      );
    }

    _prefillControllers(cat, widget.serdik, subCategories, widget.currentRole);
    averageScore = 0.0;
  }

  void _prefillControllers(
    String cat,
    Map<String, String> serdik,
    List<Map<String, dynamic>> subCategories,
    String currentRole,
  ) {
    for (int i = 0; i < subCategories.length; i++) {
      final int ctrlIndex = subCategories[i]['index'] as int;
      if (cat == 'Mental Kepribadian') {
        if (ctrlIndex == 5) {
          _inputControllers[ctrlIndex].text = serdik['sosiometriAwal'] ?? '0.0';
        } else if (ctrlIndex == 6) {
          _inputControllers[ctrlIndex].text =
              serdik['sosiometriAkhir'] ?? '0.0';
        } else {
          _inputControllers[ctrlIndex].text = _getDefaultValue(
            cat,
            ctrlIndex,
            serdik,
            currentRole,
          );
        }
      } else {
        _inputControllers[ctrlIndex].text = _getDefaultValue(
          cat,
          ctrlIndex,
          serdik,
          currentRole,
        );
      }
    }
  }

  String _getDefaultValue(
    String cat,
    int ctrlIndex,
    Map<String, String> serdik,
    String currentRole,
  ) {
    if (serdik['status'] != 'Sudah Dinilai') return '';
    final matchReport = PimpinanMockData.sharedReportData
        .where((r) => r.nrp == serdik['nrp'])
        .toList();
    if (matchReport.isEmpty) return '85.0';
    final r = matchReport.first;
    if (r.rawScores.containsKey('${cat}_$ctrlIndex')) {
      return r.rawScores['${cat}_$ctrlIndex']!.toStringAsFixed(2);
    }
    if (cat == 'Jasmani') return r.physicalScore.toStringAsFixed(2);
    if (cat == 'Mental Kepribadian') return r.mentalScore.toStringAsFixed(2);
    return r.academicScore.toStringAsFixed(2);
  }

  void _calculateAverage() {
    double getVal(int idx) =>
        double.tryParse(_inputControllers[idx].text) ?? 0.0;

    double result = 0.0;
    if (localCategory == 'Akademik') {
      result = SamaptaScoringService.calculateAkademikScore(getVal);
    } else if (localCategory == 'Mental Kepribadian') {
      final lp = widget.serdik['lookupPoints'] != null
          ? double.parse(widget.serdik['lookupPoints']!)
          : 0.0;
      result = SamaptaScoringService.calculateMentalScore(getVal, lp);
    } else {
      result = SamaptaScoringService.calculateJasmaniScore(
        getVal,
        widget.currentRole,
      );
    }
    setState(() => averageScore = result);
  }

  bool _isCategoryAllowed(String cat, String role) {
    if (role == 'Gadik' && cat != 'Akademik') return false;
    if (role == 'Patun' && cat != 'Mental Kepribadian') return false;
    if (role == 'Tim Medis' && cat != 'Jasmani') return false;
    if (role == 'Korsis' && cat != 'Jasmani') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (averageScore == 0.0 && widget.serdik['status'] == 'Sudah Dinilai') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateAverage();
      });
    }

    final filteredSubCategories = subCategories
        .where((s) => localTahap == 'Semua' || s['tahap'] == localTahap)
        .toList();

    final tahapOptions = AssessmentSubCategories.getTahapOptions(
      localCategory,
      widget.currentRole,
    );

    final availableCategories = [
      'Akademik',
      'Mental Kepribadian',
      'Jasmani',
    ].where((cat) => _isCategoryAllowed(cat, widget.currentRole)).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusXxl),
                  topRight: Radius.circular(AppDimensions.radiusXxl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.lg),
                  _buildSheetHandle(),
                  const SizedBox(height: AppDimensions.xxl),
                  _buildSheetHeader(widget.serdik),
                  const SizedBox(height: AppDimensions.lg),
                  _buildCategoryDropdown(localCategory, availableCategories, (
                    val,
                  ) {
                    setState(() {
                      _setupCategory(val);
                      _calculateAverage();
                    });
                  }),
                  _buildTahapDropdown(
                    localTahap,
                    tahapOptions,
                    (val) => setState(() => localTahap = val),
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  const Divider(
                    thickness: AppDimensions.dividerHeight,
                    height: AppDimensions.dividerHeight,
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryNavy,
                            ),
                          )
                        : _buildInputList(
                            filteredSubCategories,
                            scrollController,
                          ),
                  ),
                  if (averageScore > 90.0) _buildJustificationSection(),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: AppDimensions.handleWidth,
        height: AppDimensions.bottomSheetHandle,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
    );
  }

  Widget _buildSheetHeader(Map<String, String> serdik) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input Nilai Rutin',
            style: TextStyle(
              fontSize: AppDimensions.fontHuge,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.xs),
          Text(
            '${serdik['name']} • ${serdik['nrp']}',
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.xxl),
      height: AppDimensions.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryNavy,
            size: AppDimensions.iconMd,
          ),
          isExpanded: true,
          style: const TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
          items: items
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
          onChanged: (val) {
            if (val != null && val != value) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildTahapDropdown(
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppDimensions.xxl,
        right: AppDimensions.xxl,
        top: AppDimensions.md,
      ),
      height: AppDimensions.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.filter_list_rounded,
            color: AppColors.primaryNavy,
            size: AppDimensions.iconMd,
          ),
          isExpanded: true,
          style: const TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryNavy,
          ),
          items: items
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text('Tahap Penilaian: $t'),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null && val != value) onChanged(val);
          },
        ),
      ),
    );
  }

  Widget _buildInputList(
    List<Map<String, dynamic>> items,
    ScrollController scrollController,
  ) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xxl,
        vertical: AppDimensions.lg,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.lg),
      itemBuilder: (context, index) {
        final sub = items[index];
        final ctrlIndex = sub['index'] as int;
        final bool isSociometri = sub['tahap'].toString().contains(
          'Sosiometri',
        );
        final bool isSamapta = sub['tahap'] == 'Samapta';
        final bool isReadOnly = isSociometri || isSamapta;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sub['icon'],
                  size: AppDimensions.iconMd,
                  color: AppColors.primaryNavy,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    sub['name'],
                    style: const TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _buildScoreTextField(
                    ctrlIndex,
                    isReadOnly,
                    isSociometri,
                    isSamapta,
                  ),
                ),
                if (isSamapta) ...[
                  const SizedBox(width: AppDimensions.md),
                  _buildCalcButton(ctrlIndex, sub['name']),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreTextField(
    int ctrlIndex,
    bool isReadOnly,
    bool isSociometri,
    bool isSamapta,
  ) {
    String hintText = '0.00 - 100.00';
    if (isSociometri) hintText = 'Otomatis dari Sosiometri Peleton';
    if (isSamapta) hintText = 'Gunakan Kalkulator IDMS →';

    return TextField(
      controller: _inputControllers[ctrlIndex],
      readOnly: isReadOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      onChanged: (value) {
        if (value.isNotEmpty) {
          final double? val = double.tryParse(value);
          if (val != null && val > 100) {
            _inputControllers[ctrlIndex].text = '100';
            _inputControllers[ctrlIndex].selection = TextSelection.fromPosition(
              TextPosition(offset: _inputControllers[ctrlIndex].text.length),
            );
          }
        }
        _calculateAverage();
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isReadOnly
              ? Colors.teal.shade700.withValues(alpha: 0.8)
              : Colors.grey.shade400,
          fontSize: isReadOnly ? AppDimensions.fontMd : AppDimensions.fontLg,
          fontStyle: isReadOnly ? FontStyle.italic : FontStyle.normal,
        ),
        suffixIcon: isReadOnly
            ? Container(
                margin: const EdgeInsets.only(right: AppDimensions.sm),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.teal.shade600,
                  size: AppDimensions.iconSm,
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.teal.shade200 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.teal.shade300 : Colors.grey.shade300,
            width: isReadOnly
                ? AppDimensions.borderWidthThick
                : AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          borderSide: BorderSide(
            color: isReadOnly ? Colors.teal.shade600 : AppColors.primaryNavy,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        filled: true,
        fillColor: isReadOnly
            ? Colors.teal.shade50.withValues(alpha: 0.4)
            : AppColors.background,
      ),
    );
  }

  Widget _buildCalcButton(int ctrlIndex, String exerciseName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: IconButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => SamaptaCalculatorDialog(
              exerciseName: exerciseName,
              birthDateStr: widget.serdik['tanggalLahir'] ?? '',
              gender: widget.serdik['jenisKelamin'] ?? 'Laki-laki',
              onApply: (score) {
                _inputControllers[ctrlIndex].text = score.toStringAsFixed(2);
                _calculateAverage();
              },
            ),
          );
        },
        icon: const Icon(Icons.calculate_rounded, color: AppColors.primaryNavy),
        tooltip: 'Kalkulator Konversi',
      ),
    );
  }

  Widget _buildJustificationSection() {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.xxl,
        right: AppDimensions.xxl,
        bottom: AppDimensions.lg,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.indigo.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          border: Border.all(
            color: Colors.deepPurple.shade200.withValues(alpha: 0.7),
            width: AppDimensions.borderWidthThick,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.xs + 2),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.textOnPrimary,
                          size: AppDimensions.fontLg,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        'Berita Acara Khusus',
                        style: TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple.shade900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: AppDimensions.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'WAJIB DIISI',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXs + 1,
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md - 2),
              Text(
                'Nilai istimewa (>90.00) mewajibkan penilai melampirkan rincian bukti objektif sebagai dasar verifikasi Sidang Wanodik.',
                style: TextStyle(
                  fontSize: AppDimensions.fontSm + 1,
                  color: Colors.blueGrey.shade700,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              TextField(
                controller: justificationController,
                maxLines: 3,
                maxLength: 250,
                style: const TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Tulis bukti prestasi menonjol / justifikasi konkret di sini...',
                  hintStyle: TextStyle(
                    color: Colors.blueGrey.shade300,
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.fontLg,
                  ),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    borderSide: BorderSide(
                      color: Colors.deepPurple.shade100,
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    borderSide: BorderSide(
                      color: Colors.deepPurple.shade600,
                      width: AppDimensions.borderWidthFocus,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: AppDimensions.md - 2,
            offset: const Offset(0, -AppDimensions.xs),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ScoreSummaryWidget(
              averageScore: averageScore,
              category: localCategory,
              currentRole: widget.currentRole,
              lookupPoints: widget.serdik['lookupPoints'],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onSaveScore(
              averageScore,
              localCategory,
              widget.serdik,
              subCategories,
              justificationController,
              _inputControllers,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.xxl,
                vertical: AppDimensions.fontLg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: const Text(
              'SIMPAN NILAI',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

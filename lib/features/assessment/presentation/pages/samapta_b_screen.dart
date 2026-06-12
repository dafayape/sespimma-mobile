import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/models/jasmani_grading_data.dart';
import 'package:sespimma/features/assessment/data/datasources/jasmani_lookup_tables.dart';
import 'package:sespimma/features/assessment/presentation/widgets/serdik_info_header_widget.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class SamaptaBScreen extends StatefulWidget {
  final Map<String, dynamic> serdik;
  final JasmaniGradingData gradingData;
  final String golongan;
  final String gender;

  const SamaptaBScreen({
    super.key,
    required this.serdik,
    required this.gradingData,
    required this.golongan,
    required this.gender,
  });

  @override
  State<SamaptaBScreen> createState() => _SamaptaBScreenState();
}

class _SamaptaBScreenState extends State<SamaptaBScreen> {
  final TextEditingController _pullUpController = TextEditingController();
  final TextEditingController _sitUpController = TextEditingController();
  final TextEditingController _pushUpController = TextEditingController();
  final TextEditingController _shuttleRunController = TextEditingController();

  double _ngb1 = 0.0;
  double _ngb2 = 0.0;
  double _ngb3 = 0.0;
  double _ngb4 = 0.0;

  @override
  void initState() {
    super.initState();
    _ngb1 = widget.gradingData.nilaiB1 ?? 0.0;
    _ngb2 = widget.gradingData.nilaiB2 ?? 0.0;
    _ngb3 = widget.gradingData.nilaiB3 ?? 0.0;
    _ngb4 = widget.gradingData.nilaiB4 ?? 0.0;
  }

  @override
  void dispose() {
    _pullUpController.dispose();
    _sitUpController.dispose();
    _pushUpController.dispose();
    _shuttleRunController.dispose();
    super.dispose();
  }

  double get _ngbTotal => (_ngb1 + _ngb2 + _ngb3 + _ngb4) / 4;

  void _calculatePullUp(String value) {
    if (value.isEmpty) {
      setState(() => _ngb1 = 0.0);
      return;
    }
    final count = int.tryParse(value);
    if (count != null) {
      setState(
        () => _ngb1 = JasmaniLookupTables.getNilaiPullUp(
          count,
          widget.gender,
          widget.golongan,
        ),
      );
    }
  }

  void _calculateSitUp(String value) {
    if (value.isEmpty) {
      setState(() => _ngb2 = 0.0);
      return;
    }
    final count = int.tryParse(value);
    if (count != null) {
      setState(
        () => _ngb2 = JasmaniLookupTables.getNilaiSitUp(
          count,
          widget.gender,
          widget.golongan,
        ),
      );
    }
  }

  void _calculatePushUp(String value) {
    if (value.isEmpty) {
      setState(() => _ngb3 = 0.0);
      return;
    }
    final count = int.tryParse(value);
    if (count != null) {
      setState(
        () => _ngb3 = JasmaniLookupTables.getNilaiPushUp(
          count,
          widget.gender,
          widget.golongan,
        ),
      );
    }
  }

  void _calculateShuttleRun(String value) {
    if (value.isEmpty) {
      setState(() => _ngb4 = 0.0);
      return;
    }
    final seconds = double.tryParse(value.replaceAll(',', '.'));
    if (seconds != null) {
      setState(
        () => _ngb4 = JasmaniLookupTables.getNilaiShuttleRun(
          seconds,
          widget.gender,
          widget.golongan,
        ),
      );
    }
  }

  void _saveData() {
    if (_ngb1 == 0 || _ngb2 == 0 || _ngb3 == 0 || _ngb4 == 0) {
      AppNotifier.showError(context, 'Harap isi semua nilai Samapta B');
      return;
    }

    widget.gradingData.nilaiB1 = _ngb1;
    widget.gradingData.nilaiB2 = _ngb2;
    widget.gradingData.nilaiB3 = _ngb3;
    widget.gradingData.nilaiB4 = _ngb4;
    JasmaniGradingData.saveJasmaniData(widget.gradingData);

    AppNotifier.showSuccess(context, 'Nilai Samapta B berhasil disimpan');

    Navigator.pop(context);
  }

  bool get _isPria =>
      widget.gender.toLowerCase() == 'laki-laki' ||
      widget.gender.toLowerCase() == 'pria';

  Color _getScoreBgColor(double score) {
    if (score == 0) return Colors.blueGrey.shade50;
    if (score > 85.00) return Colors.green.shade50;
    if (score > 80.00) return Colors.lightGreen.shade50;
    if (score > 75.00) return Colors.orange.shade50;
    if (score >= 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color _getScoreTextColor(double score) {
    if (score == 0) return const Color(0xFF001C40);
    if (score > 85.00) return Colors.green.shade800;
    if (score > 80.00) return Colors.lightGreen.shade800;
    if (score > 75.00) return Colors.orange.shade800;
    if (score >= 70.00) return Colors.amber.shade900;
    return Colors.red.shade800;
  }

  Color _getScoreBorderColor(double score) {
    if (score == 0) return Colors.grey.shade200;
    if (score > 85.00) return Colors.green.shade200;
    if (score > 80.00) return Colors.lightGreen.shade200;
    if (score > 75.00) return Colors.orange.shade200;
    if (score >= 70.00) return Colors.amber.shade200;
    return Colors.red.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Samapta B',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SerdikInfoHeaderWidget(
              serdik: widget.serdik,
              golongan: widget.golongan,
              gender: widget.gender,
            ),
            const SizedBox(height: AppDimensions.xl),

            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: _getScoreBgColor(_ngbTotal),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: _getScoreBorderColor(_ngbTotal),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total NGB:',
                    style: TextStyle(
                      color: _getScoreTextColor(
                        _ngbTotal,
                      ).withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                      fontSize: AppDimensions.fontLg,
                    ),
                  ),
                  Text(
                    _ngbTotal.toStringAsFixed(2),
                    style: TextStyle(
                      color: _getScoreTextColor(_ngbTotal),
                      fontWeight: FontWeight.w900,
                      fontSize: AppDimensions.fontXxl,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),

            _buildSection(
              title: 'Pull Up (1 Menit)',
              unit: 'kali',
              insight:
                  'Posisi awal tangan lurus menggantung. Mengangkat badan dengan DAGU melewati batas tiang.',
              controller: _pullUpController,
              currentScore: _ngb1,
              onChanged: _calculatePullUp,
              isDecimal: false,
            ),
            const SizedBox(height: AppDimensions.lg),

            _buildSection(
              title: 'Sit Up (1 Menit)',
              unit: 'kali',
              insight: _isPria
                  ? 'Tangan DI BELAKANG KEPALA. Mengangkat badan menyentuh kaki, SIKUT MENYILANG MASUK.'
                  : 'Tangan LURUS atau DISILANG DI DEPAN DADA. Mengangkat badan sampai menyentuh LUTUT.',
              controller: _sitUpController,
              currentScore: _ngb2,
              onChanged: _calculateSitUp,
              isDecimal: false,
            ),
            const SizedBox(height: AppDimensions.lg),

            _buildSection(
              title: 'Push Up (1 Menit)',
              unit: 'kali',
              insight: _isPria
                  ? 'Tangan selebar bahu, UJUNG JARI KAKI menghadap tanah. Angkat sampai lurus.'
                  : 'TUMPUAN LUTUT KAKI. Angkat sampai tangan lurus, sejajar dengan PAHA.',
              controller: _pushUpController,
              currentScore: _ngb3,
              onChanged: _calculatePushUp,
              isDecimal: false,
            ),
            const SizedBox(height: AppDimensions.lg),

            _buildSection(
              title: 'Shuttle Run 6x10 Meter',
              unit: 'detik',
              insight:
                  'Lari membentuk ANGKA 8 (delapan). TIGA KALI PUTARAN (6x10 meter).',
              controller: _shuttleRunController,
              currentScore: _ngb4,
              onChanged: _calculateShuttleRun,
              isDecimal: true,
            ),
            const SizedBox(height: AppDimensions.xxxl),

            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: const Text(
                'SIMPAN NILAI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String unit,
    required String insight,
    required TextEditingController controller,
    required double currentScore,
    required Function(String) onChanged,
    required bool isDecimal,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_gymnastics,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  fontSize: AppDimensions.fontLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            insight,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: isDecimal,
                  ),
                  inputFormatters: isDecimal
                      ? [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d*'),
                          ),
                        ]
                      : [FilteringTextInputFormatter.digitsOnly],
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: isDecimal ? 'Misal: 18.5' : 'Misal: 25',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        unit,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              Container(
                width: 70,
                height: 48,
                decoration: BoxDecoration(
                  color: currentScore >= 70
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: currentScore >= 70
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Center(
                  child: Text(
                    currentScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: currentScore >= 70
                          ? Colors.green.shade700
                          : Colors.red.shade700,
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
}

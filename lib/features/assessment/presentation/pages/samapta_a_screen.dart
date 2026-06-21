import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/models/jasmani_grading_data.dart';
import 'package:sespimma/features/assessment/data/datasources/jasmani_lookup_tables.dart';
import 'package:sespimma/features/assessment/presentation/widgets/serdik_info_header_widget.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class SamaptaAScreen extends StatefulWidget {
  final Map<String, dynamic> serdik;
  final JasmaniGradingData gradingData;
  final String golongan;
  final String gender;

  const SamaptaAScreen({
    super.key,
    required this.serdik,
    required this.gradingData,
    required this.golongan,
    required this.gender,
  });

  @override
  State<SamaptaAScreen> createState() => _SamaptaAScreenState();
}

class _SamaptaAScreenState extends State<SamaptaAScreen> {
  final TextEditingController _distanceController = TextEditingController();
  double _ngaScore = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.gradingData.nilaiA != null) {
      _ngaScore = widget.gradingData.nilaiA!;
    }
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  void _calculateScore(String value) {
    if (value.isEmpty) {
      setState(() => _ngaScore = 0.0);
      return;
    }

    final int? meters = int.tryParse(value);
    if (meters != null) {
      final double score = JasmaniLookupTables.getNilaiLari(
        meters,
        widget.gender,
        widget.golongan,
      );
      setState(() {
        _ngaScore = score;
      });
    }
  }

  void _saveData() async {
    FocusScope.of(context).unfocus();
    if (_ngaScore == 0) {
      AppNotifier.showError(context, 'Jarak belum diisi atau tidak valid');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final String noSerdik = (widget.serdik['nip'] ?? widget.serdik['nrp'] ?? widget.serdik['no_serdik'] ?? '').toString();
      await dataSource.updatePhysical(noSerdik, {'nga': _ngaScore});

      widget.gradingData.nilaiA = _ngaScore;
      JasmaniGradingData.saveJasmaniData(widget.gradingData);

      if (mounted) {
        AppNotifier.showSuccess(context, 'Nilai Samapta A berhasil disimpan');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifier.showError(context, 'Gagal menyimpan nilai Samapta A: $e');
      }
    }
  }

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
    final isGol4 = widget.golongan == 'GOL IV';

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
        title: Text(
          isGol4 ? 'Jalan selama 12 menit' : 'Lari selama 12 menit',
          style: const TextStyle(
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
            _buildInsightInfo(isGol4),
            const SizedBox(height: AppDimensions.xl),

            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input Jarak (Meter)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _distanceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: _calculateScore,
                          decoration: InputDecoration(
                            hintText: 'Misal: 2500',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                              borderSide: const BorderSide(
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            suffixIcon: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'm',
                                style: TextStyle(
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
                        width: 80,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _getScoreBgColor(_ngaScore),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: _getScoreBorderColor(_ngaScore),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _ngaScore.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: AppDimensions.fontLg,
                              fontWeight: FontWeight.w800,
                              color: _getScoreTextColor(_ngaScore),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.xxxl),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
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

  Widget _buildInsightInfo(bool isGol4) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Insight Information',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'APA ITU:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isGol4
                ? 'Tes jalan selama 12 menit untuk mengukur daya tahan kardiovaskuler serdik khusus Golongan IV.'
                : 'Tes lari selama 12 menit untuk mengukur daya tahan kardiovaskuler serdik.',
            style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'TEKNIS PELAKSANAAN:',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.blue.shade900,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isGol4
                ? '• Serdik berjalan kaki\n• Durasi: 12 MENIT\n• Yang diukur: JARAK yang ditempuh (dalam meter)'
                : '• Serdik berlari\n• Durasi: 12 MENIT\n• Yang diukur: JARAK yang ditempuh (dalam meter)',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

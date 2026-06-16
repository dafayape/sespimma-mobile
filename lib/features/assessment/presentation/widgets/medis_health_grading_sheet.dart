import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/features/assessment/presentation/pages/medis_health_record_screen.dart';

class MedisHealthGradingSheet extends StatefulWidget {
  final Map<String, dynamic> serdik;
  final Map<String, dynamic> health;
  final VoidCallback onDataChanged;

  const MedisHealthGradingSheet({
    super.key,
    required this.serdik,
    required this.health,
    required this.onDataChanged,
  });

  static void show(
    BuildContext context,
    Map<String, dynamic> serdik,
    Map<String, dynamic> health,
    VoidCallback onDataChanged,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) =>
          MedisHealthGradingSheet(serdik: serdik, health: health, onDataChanged: onDataChanged),
    );
  }

  @override
  State<MedisHealthGradingSheet> createState() =>
      _MedisHealthGradingSheetState();
}

class _MedisHealthGradingSheetState extends State<MedisHealthGradingSheet> {
  static const Color _primaryNavy = Color(0xFF000B1D);

  Color _getScoreColor(double score) {
    if (score == 0) return Colors.grey.shade400;
    if (score >= 85.01) return Colors.green.shade700;
    if (score >= 80.01) return Colors.lightGreen.shade700;
    if (score >= 75.01) return Colors.orange.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  String _getScoreCategory(double score) {
    if (score == 0) return '-';
    if (score >= 85.01) return 'Sangat Memuaskan (SM)';
    if (score >= 80.01) return 'Memuaskan (M)';
    if (score >= 75.01) return 'Baik (B)';
    if (score >= 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  void _showInputDialog(String type) {
    Navigator.pop(context);

    final TextEditingController controller = TextEditingController();
    final noSerdik = widget.serdik['no_serdik'].toString();
    
    final double? existingScore = type == 'A'
        ? (widget.health['nilai_a'] as num?)?.toDouble()
        : (widget.health['nilai_b'] as num?)?.toDouble();

    if (existingScore != null) {
      controller.text = existingScore.toString();
    }

    bool dialogSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx2, setStateDialog) {
            final double currentScore = double.tryParse(controller.text) ?? 0.0;
            final Color scoreColor = _getScoreColor(currentScore);
            final String scoreCategory = _getScoreCategory(currentScore);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              title: Text(
                type == 'A' ? 'Tes Kesehatan Awal' : 'Tes Kesehatan Akhir',
                style: const TextStyle(
                  color: _primaryNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !dialogSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nilai (0-100)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: _primaryNavy,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      if (parsed > 100) {
                        controller.text = '100';
                        controller.selection = TextSelection.fromPosition(
                          const TextPosition(offset: 3),
                        );
                      }
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: currentScore > 0
                          ? scoreColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: currentScore > 0
                            ? scoreColor.withValues(alpha: 0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PREDIKAT',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreCategory,
                          style: TextStyle(
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w800,
                            color: currentScore > 0
                                ? scoreColor
                                : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogSaving ? null : () => Navigator.pop(dialogCtx2),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                  ),
                  onPressed: dialogSaving
                      ? null
                      : () async {
                          final val = double.tryParse(controller.text);
                          if (val != null) {
                            setStateDialog(() {
                              dialogSaving = true;
                            });
                            try {
                              final dataSource = sl<AssessmentRemoteDataSource>();
                              if (type == 'A') {
                                await dataSource.updateHealthScoreA(noSerdik, val);
                              } else {
                                await dataSource.updateHealthScoreB(noSerdik, val);
                              }
                              widget.onDataChanged();
                              if (dialogCtx2.mounted) {
                                Navigator.pop(dialogCtx2);
                                AppNotifier.showSuccess(
                                  dialogCtx2,
                                  'Nilai berhasil disimpan',
                                );
                              }
                            } catch (e) {
                              setStateDialog(() {
                                dialogSaving = false;
                              });
                              if (dialogCtx2.mounted) {
                                AppNotifier.showError(
                                  dialogCtx2,
                                  'Gagal menyimpan nilai: $e',
                                );
                              }
                            }
                          }
                        },
                  child: dialogSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToRecordScreen() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedisHealthRecordScreen(
          serdik: widget.serdik,
          initialHealth: widget.health,
          onRecordAdded: widget.onDataChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.xl,
        right: AppDimensions.xl,
        top: AppDimensions.md,
        bottom: MediaQuery.of(context).padding.bottom + AppDimensions.xl,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXxl),
          topRight: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const Text(
            'Pilih Jenis Penilaian',
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.xl),
          _buildActionCard(
            'Tes Kesehatan Awal',
            'Pemeriksaan Intensif II Plus',
            Icons.medical_information,
            () => _showInputDialog('A'),
          ),
          const SizedBox(height: AppDimensions.md),
          _buildActionCard(
            'Tes Kesehatan Akhir',
            'Pemeriksaan akhir dalam periode pendidikan',
            Icons.fact_check,
            () => _showInputDialog('B'),
          ),
          const SizedBox(height: AppDimensions.md),
          _buildActionCard(
            'Status Kesehatan Pendidikan',
            'Catat rawat inap kunjungan ke poliklinik, dirawat inap TPS, atau dirawat inap RS',
            Icons.local_hospital,
            _navigateToRecordScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _primaryNavy),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontMd,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';

class MedicalDeductionDialog extends StatefulWidget {
  final Map<String, String> serdik;
  final VoidCallback onSaved;

  const MedicalDeductionDialog({
    super.key,
    required this.serdik,
    required this.onSaved,
  });

  @override
  State<MedicalDeductionDialog> createState() => _MedicalDeductionDialogState();
}

class _MedicalDeductionDialogState extends State<MedicalDeductionDialog> {
  String statusCatatan = 'Rawat Inap RS (Akibat Kelalaian)';
  final TextEditingController hariController = TextEditingController(text: '1');
  int pengurangan = 2;

  void _recalculate() {
    if (statusCatatan.contains('Poliklinik')) {
      pengurangan = 0;
    } else {
      final int h = int.tryParse(hariController.text) ?? 0;
      pengurangan = h * 2;
    }
  }

  @override
  void dispose() {
    hariController.dispose();
    super.dispose();
  }

  Widget _buildMedicalResultBanner() {
    final bool hasSanksi = pengurangan > 0;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: hasSanksi ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: hasSanksi ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSanksi
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: hasSanksi ? Colors.red.shade700 : Colors.green.shade700,
                size: AppDimensions.iconMd,
              ),
              const SizedBox(width: AppDimensions.sm),
              Text(
                hasSanksi ? 'Sanksi Pengurangan Nilai' : 'Kondisi Aman',
                style: TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.bold,
                  color: hasSanksi
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs + 2),
          Text(
            hasSanksi
                ? 'Akan mengurangi Nilai Kesehatan (Status C) sebesar -$pengurangan poin dari baseline (2 poin / hari).'
                : 'Berobat poliklinik biasa tidak dikenakan pemotongan poin status kesehatan.',
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              color: hasSanksi ? Colors.red.shade900 : Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      final String noSerdik = widget.serdik['nrp'] ?? widget.serdik['nosis'] ?? '';
      final int duration = int.tryParse(hariController.text) ?? 1;

      final Map<String, dynamic> body = {
        'type': statusCatatan.contains('Poliklinik') ? 'Poliklinik' : 'Rawat Inap',
        'description': statusCatatan,
        'medis_name': 'Tim Medis',
        'minus_points': statusCatatan.contains('Poliklinik') ? 0 : duration * 2,
      };

      final dataSource = GetIt.instance<AssessmentRemoteDataSource>();
      await dataSource.createHealthRecord(noSerdik, body);

      if (!mounted) return;
      Navigator.pop(context);
      final msg = pengurangan > 0
          ? 'Berhasil mencatat rawat inap ${hariController.text} hari. Sanksi -$pengurangan poin diterapkan.'
          : 'Berhasil mencatat riwayat kunjungan poliklinik.';
      AppNotifier.showInfo(context, msg);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      AppNotifier.showInfo(context, 'Gagal mencatat medis: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
      ),
      title: Row(
        children: [
          Icon(Icons.local_hospital_rounded, color: Colors.orange.shade700),
          const SizedBox(width: AppDimensions.md - 2),
          const Text(
            'Pencatatan Medis (Status C)',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Serdik: ${widget.serdik['name']}',
              style: const TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Status Catatan',
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: AppDimensions.xs + 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: statusCatatan,
                  isExpanded: true,
                  items:
                      [
                            'Rawat Inap RS (Akibat Kelalaian)',
                            'Berobat Poliklinik (Biasa)',
                          ]
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(
                                v,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontLg,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        statusCatatan = val;
                        _recalculate();
                      });
                    }
                  },
                ),
              ),
            ),
            if (statusCatatan.contains('Rawat Inap')) ...[
              const SizedBox(height: AppDimensions.lg),
              const Text(
                'Lama Rawat Inap (Hari)',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: AppDimensions.xs + 2),
              TextField(
                controller: hariController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: AppDimensions.md,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  hintText: 'Masukkan jumlah hari',
                ),
                onChanged: (val) {
                  setState(() => _recalculate());
                },
              ),
            ],
            const SizedBox(height: AppDimensions.xl),
            _buildMedicalResultBanner(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Batal',
            style: TextStyle(color: Colors.blueGrey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade900,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
          ),
          child: const Text('Simpan Catatan'),
        ),
      ],
    );
  }
}

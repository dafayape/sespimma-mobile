import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/presentation/widgets/action_tile_widget.dart';

class AssessmentActionSheet extends StatelessWidget {
  final Map<String, String> serdik;
  final String currentRole;
  final VoidCallback onInputNilai;
  final VoidCallback onInputMedis;
  final VoidCallback onReward;
  final VoidCallback onPunishment;

  const AssessmentActionSheet({
    super.key,
    required this.serdik,
    required this.currentRole,
    required this.onInputNilai,
    required this.onInputMedis,
    required this.onReward,
    required this.onPunishment,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.xl,
          horizontal: AppDimensions.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHandle(),
            const SizedBox(height: AppDimensions.xxl),
            _buildTitle(),
            if (serdik['status'] == 'Sudah Dinilai') _buildWarningBanner(),
            const SizedBox(height: AppDimensions.xxl),
            _buildInputAction(),
            const SizedBox(height: AppDimensions.md),
            ..._buildRoleActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
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

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tindakan Penilaian',
          style: TextStyle(
            fontSize: AppDimensions.fontXxl,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade900,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          '${serdik['name']} • ${serdik['nrp']}',
          style: TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.md),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.amber.shade700,
              size: AppDimensions.iconDefault,
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Text(
                'Serdik ini sudah dinilai sebelumnya. Input baru akan menimpa data lama (Audit Trail akan mencatat perubahan).',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputAction() {
    final String title = currentRole == 'Tim Medis'
        ? 'Input Hasil Rikes (Awal & Akhir)'
        : 'Input Nilai Rutin (Angka)';
    final String subtitle = currentRole == 'Tim Medis'
        ? 'Masukkan skor murni (0-100) hasil rikes riil'
        : 'Masukkan skor murni (0-100) untuk evaluasi';

    return ActionTileWidget(
      icon: Icons.edit_note_rounded,
      title: title,
      subtitle: subtitle,
      color: AppColors.academicBlue,
      onTap: onInputNilai,
    );
  }

  List<Widget> _buildRoleActions(BuildContext context) {
    if (currentRole == 'Tim Medis') {
      return [
        ActionTileWidget(
          icon: Icons.local_hospital_rounded,
          title: 'Catat Rawat Inap & Sanksi',
          subtitle: 'Pencatatan status C: sanksi 2 poin per hari rawat inap',
          color: Colors.orange.shade700,
          onTap: onInputMedis,
        ),
      ];
    }
    return [
      ActionTileWidget(
        icon: Icons.stars_rounded,
        title: 'Beri Pujian (Reward)',
        subtitle: 'Pilih indikator positif dari Lookup Table',
        color: AppColors.successGreen,
        onTap: onReward,
      ),
      const SizedBox(height: AppDimensions.md),
      ActionTileWidget(
        icon: Icons.warning_rounded,
        title: 'Beri Teguran (Punishment)',
        subtitle: 'Pilih indikator pelanggaran dari Lookup Table',
        color: AppColors.dangerRed,
        onTap: onPunishment,
      ),
    ];
  }
}

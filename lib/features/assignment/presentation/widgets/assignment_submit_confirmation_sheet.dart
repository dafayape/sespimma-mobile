import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AssignmentSubmitConfirmationSheet extends StatelessWidget {
  final bool isExpired;
  final String fileName;
  final VoidCallback onConfirm;

  const AssignmentSubmitConfirmationSheet({
    super.key,
    required this.isExpired,
    required this.fileName,
    required this.onConfirm,
  });

  Color get _btnColor =>
      isExpired ? AppColors.dangerRed : AppColors.primaryNavy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusRound + 8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: AppDimensions.xxl),
          _buildIcon(),
          const SizedBox(height: AppDimensions.xl),
          _buildTitle(),
          const SizedBox(height: AppDimensions.sm),
          _buildDescription(),
          const SizedBox(height: AppDimensions.xl),
          _buildFileInfo(),
          const SizedBox(height: AppDimensions.xxxl),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      height: AppDimensions.xs,
      width: AppDimensions.huge - 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: _btnColor.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isExpired ? AppIcons.warningCircleFill : AppIcons.cloudArrowUpFill,
        color: _btnColor,
        size: AppDimensions.huge - 8,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      isExpired ? 'Kirim Secara Terlambat?' : 'Konfirmasi Pengumpulan',
      style: TextStyle(
        fontSize: AppDimensions.fontXxl,
        fontWeight: FontWeight.w800,
        color: _btnColor,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      isExpired
          ? 'Tenggat waktu tugas ini telah berakhir. '
                'Jika dilanjutkan, tugas akan ditandai TELAT '
                'pada audit trail IDMS & dikenakan pemotongan '
                '-0.50 Poin Kepribadian (Disiplin).'
          : 'Apakah Anda yakin berkas yang dilampirkan '
                'sudah sesuai? Tindakan pengumpulan tugas '
                'bersifat final.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: AppDimensions.fontDefault,
        fontWeight: isExpired ? FontWeight.w600 : FontWeight.w500,
        color: isExpired ? Colors.red.shade900 : Colors.blueGrey.shade600,
        height: 1.5,
      ),
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(AppIcons.fileTextFill, color: _btnColor),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              fileName,
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w700,
                color: _btnColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
            ),
            child: Text(
              'Periksa Lagi',
              style: TextStyle(
                color: Colors.blueGrey.shade700,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _btnColor,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
            ),
            child: Text(
              isExpired ? 'Kirim Telat' : 'Kirim Tugas',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

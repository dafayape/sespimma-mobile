import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AssignmentUploadSectionWidget extends StatelessWidget {
  final bool isFileAttached;
  final String fileName;
  final bool isExpired;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;

  const AssignmentUploadSectionWidget({
    super.key,
    required this.isFileAttached,
    required this.fileName,
    required this.isExpired,
    required this.onPickFile,
    required this.onRemoveFile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isExpired) _buildExpiredBanner(),
        const Text(
          'Bukti Pengerjaan',
          style: TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !isFileAttached
              ? _buildUploadButton()
              : _buildFileAttachedCard(),
        ),
      ],
    );
  }

  Widget _buildExpiredBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      margin: const EdgeInsets.only(bottom: AppDimensions.xxl),
      decoration: BoxDecoration(
        color: AppColors.dangerRed.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.warningCircleFill,
            color: AppColors.dangerRed,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batas Waktu Terlampaui',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dangerRed,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm - 2),
                Text(
                  'Sistem IDMS memberikan keringanan untuk tetap mengumpulkan tugas susulan. Harap dicatat bahwa keterlambatan ini akan terekam otomatis dan dapat berakibat pada pengurangan Nilai Kepribadian (Disiplin) sebesar -0.50 Poin.',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return InkWell(
      key: const ValueKey('upload_btn'),
      onTap: onPickFile,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.huge - 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(
            color: Colors.blueGrey.shade200,
            width: AppDimensions.borderWidthThick,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.cloudArrowUp,
                size: AppDimensions.iconXxl,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Tekan untuk memilih file atau ambil foto',
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.sm - 2),
            Text(
              'Maksimal ukuran file: 10 MB',
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachedCard() {
    return Container(
      key: const ValueKey('file_attached'),
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.05),
            blurRadius: AppDimensions.md - 2,
            offset: const Offset(0, AppDimensions.xs),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: const Icon(
              AppIcons.fileTextFill,
              color: AppColors.successGreen,
              size: AppDimensions.iconXl,
            ),
          ),
          const SizedBox(width: AppDimensions.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXl - 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
                const Text(
                  'Siap dikirim',
                  style: TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemoveFile,
            icon: Container(
              padding: const EdgeInsets.all(AppDimensions.sm - 2),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.trash,
                color: AppColors.dangerRed,
                size: AppDimensions.iconDefault,
              ),
            ),
            tooltip: 'Hapus File',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assignment/data/models/assignment_model.dart';

class AssignmentSubmittedSectionWidget extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onDownload;

  const AssignmentSubmittedSectionWidget({
    super.key,
    required this.assignment,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDiperiksa = assignment.status == 'diperiksa';
    final statusColor = isDiperiksa
        ? AppColors.warningOrange
        : AppColors.successGreen;
    final fileName = assignment.submissionFileName ?? 'Berkas Terlampir';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bukti Pengerjaan',
          style: TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.lg),
        _buildFileCard(fileName, statusColor, isDiperiksa),
        if (isDiperiksa) _buildPendingInfo(),
        if (assignment.status == 'selesai') _buildGradeSection(),
      ],
    );
  }

  Widget _buildFileCard(String fileName, Color color, bool isDiperiksa) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Icon(
              AppIcons.fileTextFill,
              color: color,
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
                Text(
                  isDiperiksa ? 'Sedang Dinilai' : 'Telah Dinilai',
                  style: TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(
              AppIcons.downloadSimple,
              color: AppColors.primaryNavy,
            ),
            style: IconButton.styleFrom(backgroundColor: AppColors.background),
            tooltip: 'Unduh Berkas',
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.lg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.warningOrange.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: AppColors.warningOrange.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              AppIcons.info,
              color: AppColors.warningOrange,
              size: AppDimensions.iconDefault,
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Text(
                'Tugas Anda telah aman dikirimkan. Mohon tunggu hingga pengajar melakukan verifikasi dan penilaian terhadap dokumen ini.',
                style: TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange.shade900,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSection() {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Penilaian',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.xxl),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.successGreen.withValues(alpha: 0.06),
                  AppColors.successGreen.withValues(alpha: 0.01),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGradeHeader(),
                const SizedBox(height: AppDimensions.xl),
                Divider(
                  color: Colors.blueGrey.shade100,
                  thickness: AppDimensions.dividerHeight,
                  height: AppDimensions.dividerHeight,
                ),
                const SizedBox(height: AppDimensions.xl),
                _buildTeacherNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nilai Akhir',
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.xs),
            Text(
              'Skala Penilaian 100',
              style: TextStyle(
                fontSize: AppDimensions.fontSm + 1,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.lg,
            vertical: AppDimensions.md - 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Text(
            assignment.nilai?.toString() ?? '-',
            style: const TextStyle(
              fontSize: AppDimensions.fontDisplayLg - 2,
              fontWeight: FontWeight.w900,
              color: AppColors.successGreen,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherNote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              AppIcons.chatCenteredDotsFill,
              color: Colors.blueGrey.shade500,
              size: AppDimensions.iconMd,
            ),
            const SizedBox(width: AppDimensions.sm),
            Text(
              'Catatan Pengajar',
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md - 2),
        Text(
          assignment.catatan ?? 'Tidak ada catatan tambahan dari pengajar.',
          style: const TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryNavy,
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

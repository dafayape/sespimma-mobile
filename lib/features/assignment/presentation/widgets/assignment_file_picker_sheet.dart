import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AssignmentFilePickerSheet extends StatelessWidget {
  final VoidCallback onPickImage;
  final VoidCallback onPickDocument;

  const AssignmentFilePickerSheet({
    super.key,
    required this.onPickImage,
    required this.onPickDocument,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.xxl,
          horizontal: AppDimensions.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppDimensions.handleWidth,
              height: AppDimensions.bottomSheetHandle,
              margin: const EdgeInsets.only(bottom: AppDimensions.xxl),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            const Text(
              'Unggah Bukti Tugas',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
            _ModalOption(
              icon: AppIcons.camera,
              title: 'Ambil Foto',
              subtitle: 'Gunakan kamera untuk bukti langsung',
              onTap: onPickImage,
            ),
            const SizedBox(height: AppDimensions.md),
            _ModalOption(
              icon: AppIcons.file,
              title: 'Pilih Dokumen',
              subtitle: 'Dukung format PDF, DOCX, PNG, JPG',
              onTap: onPickDocument,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModalOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primaryNavy,
                size: AppDimensions.iconLg,
              ),
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
                      fontSize: AppDimensions.fontXl - 1,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: AppDimensions.xs / 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: AppDimensions.fontDefault,
                      color: Colors.blueGrey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.caretRight, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

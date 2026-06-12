import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AssignmentAttachmentSection extends StatelessWidget {
  final String attachmentName;
  final VoidCallback onDownload;

  const AssignmentAttachmentSection({
    super.key,
    required this.attachmentName,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lampiran Tugas',
          style: TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: AppDimensions.sm,
                offset: const Offset(0, AppDimensions.xs),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md - 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.filePdfFill,
                  color: Colors.red.shade400,
                  size: AppDimensions.iconLg,
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachmentName,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNavy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Dokumen Pendukung',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDownload,
                icon: const Icon(
                  AppIcons.downloadSimple,
                  color: AppColors.primaryNavy,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

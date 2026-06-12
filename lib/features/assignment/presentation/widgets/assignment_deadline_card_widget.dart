import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assignment/data/models/assignment_model.dart';

class AssignmentDeadlineCardWidget extends StatelessWidget {
  final AssignmentModel assignment;
  final bool isAktif;
  final bool isExpired;

  const AssignmentDeadlineCardWidget({
    super.key,
    required this.assignment,
    required this.isAktif,
    required this.isExpired,
  });

  static String _formatIndoDate(DateTime dt) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final difference = assignment.deadline.difference(DateTime.now());
    final bool isCritical = isAktif && difference.inHours < 3;

    Color cardColor;
    String statusLabel;
    String statusValue;
    IconData statusIcon;

    if (isAktif) {
      statusLabel = 'Tenggat Waktu';
      if (isExpired) {
        cardColor = AppColors.dangerRed;
        statusValue = 'Waktu Pengumpulan Habis';
        statusIcon = AppIcons.warningCircleFill;
      } else {
        cardColor = isCritical ? AppColors.dangerRed : AppColors.primaryNavy;
        statusValue =
            '${_formatIndoDate(assignment.deadline)}, ${assignment.deadline.hour.toString().padLeft(2, '0')}.${assignment.deadline.minute.toString().padLeft(2, '0')}';
        statusIcon = AppIcons.timerFill;
      }
    } else {
      statusLabel = 'Status Tugas';
      if (assignment.status == 'diperiksa') {
        cardColor = AppColors.warningOrange;
        statusValue = 'Sedang Dinilai';
        statusIcon = AppIcons.hourglassHighFill;
      } else {
        cardColor = AppColors.successGreen;
        statusValue = 'Telah Dinilai';
        statusIcon = AppIcons.checkCircleFill;
      }
    }

    return Hero(
      tag: 'deadline-${assignment.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(color: cardColor.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md - 2),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  statusIcon,
                  color: cardColor,
                  size: AppDimensions.iconLg,
                ),
              ),
              const SizedBox(width: AppDimensions.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      statusValue,
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        color: cardColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

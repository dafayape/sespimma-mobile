import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assignment/data/models/assignment_model.dart';

class AssignmentHeaderWidget extends StatelessWidget {
  final AssignmentModel assignment;

  const AssignmentHeaderWidget({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.fontLg,
                vertical: AppDimensions.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                assignment.mapel.toUpperCase(),
                style: const TextStyle(
                  fontSize: AppDimensions.fontSm + 1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Hero(
              tag: 'icon-${assignment.id}',
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.md - 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.clipboardTextFill,
                  color: AppColors.primaryNavy,
                  size: AppDimensions.iconDefault,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.xl),
        Hero(
          tag: 'title-${assignment.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              assignment.judul,
              style: const TextStyle(
                fontSize: AppDimensions.fontDisplay,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
                height: 1.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.xl),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueGrey.shade100,
              backgroundImage: assignment.pengajarFoto != null
                  ? AssetImage(assignment.pengajarFoto!)
                  : null,
              child: assignment.pengajarFoto == null
                  ? const Icon(AppIcons.userFill, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppDimensions.md),
            Text(
              assignment.pengajar,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

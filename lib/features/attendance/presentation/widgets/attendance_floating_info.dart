import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';

class AttendanceFloatingInfo extends StatelessWidget {
  final AttendanceZone activeZone;
  final bool isInRadius;
  final VoidCallback onTapInfo;

  const AttendanceFloatingInfo({
    super.key,
    required this.activeZone,
    required this.isInRadius,
    required this.onTapInfo,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isInRadius
        ? AppColors.successGreen
        : AppColors.dangerRed;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTapInfo();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.mapPinFill,
                color: statusColor,
                size: AppDimensions.iconSm,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activeZone.activityName,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeZone.name,
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.xs / 2),
                  Text(
                    isInRadius
                        ? 'Berada di Radius Absensi'
                        : 'Di Luar Radius Absensi',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs - 1,
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

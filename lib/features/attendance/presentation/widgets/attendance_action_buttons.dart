import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';

class AttendanceActionButtons extends StatelessWidget {
  final bool isAttended;
  final bool isInRadius;
  final bool isSubmitting;
  final AttendanceZone? activeZone;
  final VoidCallback onOpenQr;
  final VoidCallback onSubmit;

  const AttendanceActionButtons({
    super.key,
    required this.isAttended,
    required this.isInRadius,
    required this.isSubmitting,
    required this.activeZone,
    required this.onOpenQr,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlpha =
        activeZone != null && DateTime.now().isAfter(activeZone!.cutoffTime);
    final bool isNotStarted =
        activeZone != null && DateTime.now().isBefore(activeZone!.startTime);

    final bool isGreyedOut =
        isAttended || isAlpha || isNotStarted || !isInRadius;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionBtn(
          icon: AppIcons.qrCodeBold,
          color: isAttended ? Colors.grey.shade300 : Colors.white,
          iconColor: isAttended ? Colors.grey.shade500 : AppColors.primaryNavy,
          onTap: isAttended ? null : onOpenQr,
        ),
        const SizedBox(height: AppDimensions.lg),
        _ActionBtn(
          icon: AppIcons.checkSquareOffsetBold,
          color: isGreyedOut ? Colors.grey.shade400 : AppColors.primaryNavy,
          iconColor: Colors.white,
          onTap: () {
            HapticFeedback.mediumImpact();
            onSubmit();
          },
          isLoading: isSubmitting,
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: isLoading
              ? SizedBox(
                  width: AppDimensions.lg + 8,
                  height: AppDimensions.lg + 8,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: iconColor,
                  ),
                )
              : Icon(icon, color: iconColor, size: AppDimensions.iconMd + 2),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class AssignmentBottomActionButton extends StatelessWidget {
  final bool isExpired;
  final bool isFileAttached;
  final VoidCallback onPressed;

  const AssignmentBottomActionButton({
    super.key,
    required this.isExpired,
    required this.isFileAttached,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isExpired
        ? AppColors.dangerRed
        : AppColors.primaryNavy;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: AppDimensions.xl,
            offset: const Offset(0, -AppDimensions.bottomSheetHandle),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: AppDimensions.appBarHeight,
          child: ElevatedButton(
            onPressed: isFileAttached ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              elevation: isFileAttached ? AppDimensions.elevationMd : 0,
            ),
            child: Text(
              isExpired ? 'KIRIM TERLAMBAT' : 'SELESAIKAN TUGAS',
              style: const TextStyle(
                fontSize: AppDimensions.fontXl - 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

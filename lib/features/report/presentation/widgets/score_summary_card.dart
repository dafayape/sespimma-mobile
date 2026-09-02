import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class ScoreSummaryCard extends StatelessWidget {
  final String label;
  final double score;
  final String weight;
  final bool isSelected;
  final VoidCallback onTap;

  const ScoreSummaryCard({
    super.key,
    required this.label,
    required this.score,
    required this.weight,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBgColor;
    Color borderColor;
    Color badgeBgColor;
    Color badgeTextColor;
    Color scoreColor;
    Color labelColor = const Color(0xFF001C40);

    if (score == 0) {
      cardBgColor = Colors.white;
      borderColor = isSelected ? AppColors.primaryNavy : Colors.grey.shade200;
      badgeBgColor = Colors.blueGrey.shade50;
      badgeTextColor = Colors.blueGrey.shade700;
      scoreColor = AppColors.primaryNavy;
    } else if (score >= 80.0) {
      cardBgColor = isSelected
          ? Colors.green.shade50.withValues(alpha: 0.9)
          : Colors.green.shade50;
      borderColor = isSelected ? Colors.green.shade700 : Colors.green.shade200;
      badgeBgColor = Colors.green.shade100;
      badgeTextColor = Colors.green.shade800;
      scoreColor = Colors.green.shade800;
    } else if (score >= 70.0) {
      cardBgColor = isSelected
          ? Colors.amber.shade50.withValues(alpha: 0.9)
          : Colors.amber.shade50;
      borderColor = isSelected ? Colors.amber.shade700 : Colors.amber.shade200;
      badgeBgColor = Colors.amber.shade100;
      badgeTextColor = Colors.amber.shade900;
      scoreColor = Colors.amber.shade900;
    } else {
      cardBgColor = isSelected
          ? Colors.red.shade50.withValues(alpha: 0.9)
          : Colors.red.shade50;
      borderColor = isSelected ? Colors.red.shade700 : Colors.red.shade200;
      badgeBgColor = Colors.red.shade100;
      badgeTextColor = Colors.red.shade800;
      scoreColor = Colors.red.shade800;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? scoreColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected
                ? AppDimensions.radiusXl
                : AppDimensions.radiusLg,
            offset: isSelected ? const Offset(0, 6) : const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.xl,
              horizontal: AppDimensions.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    weight,
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    score > 0 ? score.toStringAsFixed(2) : '-',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXxl + 4,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class SummaryStatsCards extends StatelessWidget {
  final int lulusCount;
  final int peringatanCount;

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _dangerRed = Color(0xFFD32F2F);

  const SummaryStatsCards({
    super.key,
    required this.lulusCount,
    required this.peringatanCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            'Lulus',
            lulusCount.toString(),
            _successGreen,
            AppIcons.checkCircleFill,
          ),
        ),
        const SizedBox(width: AppDimensions.md - 4),
        Expanded(
          child: _buildSummaryItem(
            'Tidak Lulus',
            peringatanCount.toString(),
            _dangerRed,
            AppIcons.warningCircleFill,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconDefault),
          ),
          const SizedBox(width: AppDimensions.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontHuge + 2,
                    fontWeight: FontWeight.w900,
                    color: _primaryNavy,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.blueGrey.shade400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

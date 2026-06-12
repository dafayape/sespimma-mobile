import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AiRecommendationCard extends StatelessWidget {
  final double academicScore;
  final double mentalScore;
  final double physicalScore;
  final String title;

  final bool showAcademic;

  const AiRecommendationCard({
    super.key,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
    this.title = 'Rekomendasi Sistem',
    this.showAcademic = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showAcademic) ...[
          _buildCategoryRec(
            context,
            'Akademik',
            academicScore,
            AppIcons.bookOpenFill,
            _getRecText('Akademik', academicScore),
          ),
          const SizedBox(height: AppDimensions.sm),
        ],
        _buildCategoryRec(
          context,
          'Mental Kepribadian',
          mentalScore,
          AppIcons.shieldCheckFill,
          _getRecText('Mental Kepribadian', mentalScore),
        ),
        const SizedBox(height: AppDimensions.sm),
        _buildCategoryRec(
          context,
          'Jasmani',
          physicalScore,
          AppIcons.barbellFill,
          _getRecText('Jasmani', physicalScore),
        ),
      ],
    );
  }

  String _getRecText(String category, double score) {
    if (score == 0) {
      return 'Data belum dinilai.';
    }

    if (score >= 80) {
      return 'Sangat memuaskan. Pertahankan performa $category saat ini.';
    }

    if (score >= 70) {
      return 'Cukup baik. Disarankan untuk lebih proaktif dalam meningkatkan komponen $category.';
    }

    return 'Kritis! Nilai $category di bawah standar lulus (< 70). Segera lakukan evaluasi dan perbaikan komprehensif.';
  }

  Color _getColor(double score) {
    if (score == 0) return Colors.blueGrey;
    if (score >= 80) return Colors.green.shade700;
    if (score >= 70) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Color _getBgColor(double score) {
    if (score == 0) return Colors.blueGrey.shade50;
    if (score >= 80) return Colors.green.shade50;
    if (score >= 70) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  Widget _buildCategoryRec(
    BuildContext context,
    String category,
    double score,
    IconData icon,
    String message,
  ) {
    final color = _getColor(score);
    final bgColor = _getBgColor(score);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconDefault),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rekomendasi $category',
                      style: TextStyle(
                        color: color,
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      score > 0 ? score.toStringAsFixed(2) : '-',
                      style: TextStyle(
                        color: color,
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.blueGrey.shade800,
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import '../../data/models/final_recap_model.dart';

class AverageStatsCard extends StatelessWidget {
  final List<FinalRecapModel> data;

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _dangerRed = Color(0xFFD32F2F);

  const AverageStatsCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double avgScore = 0;
    if (data.isNotEmpty) {
      avgScore =
          data.map((e) => e.average).reduce((a, b) => a + b) / data.length;
    }

    String getPredicateText(double score) {
      if (score == 0) return '-';
      if (score > 90.0) return 'Istimewa';
      if (score > 85.0) return 'Sangat Memuaskan';
      if (score > 80.0) return 'Memuaskan';
      if (score > 75.0) return 'Baik';
      if (score >= 70.0) return 'Cukup';
      return 'Kurang';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        AppIcons.chartLineUpFill,
                        size: AppDimensions.iconSm,
                        color: _primaryNavy,
                      ),
                      const SizedBox(width: AppDimensions.radiusSm),
                      Text(
                        'Rata-Rata Nilai',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm + 2),
                  Text(
                    avgScore > 0 ? avgScore.toStringAsFixed(2) : '-',
                    style: TextStyle(
                      fontSize: AppDimensions.fontDisplay,
                      fontWeight: FontWeight.w900,
                      color: _resolvePredicateColor(avgScore),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
              color: Colors.grey.shade200,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        AppIcons.medalFill,
                        size: AppDimensions.iconSm,
                        color: _primaryNavy,
                      ),
                      const SizedBox(width: AppDimensions.radiusSm),
                      Text(
                        'Predikat',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.sm + 2),
                  Text(
                    getPredicateText(avgScore),
                    style: TextStyle(
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w900,
                      color: _resolvePredicateColor(avgScore),
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

  Color _resolvePredicateColor(double avgScore) {
    if (avgScore > 85.0) return Colors.green.shade700;
    if (avgScore > 80.0) return Colors.lightGreen.shade600;
    if (avgScore > 75.0) return Colors.orange.shade700;
    if (avgScore >= 70.0) return Colors.amber.shade700;
    if (avgScore > 0) return _dangerRed;
    return Colors.blueGrey;
  }
}

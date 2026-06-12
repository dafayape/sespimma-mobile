import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/domain/services/samapta_scoring_service.dart';

class ScoreSummaryWidget extends StatelessWidget {
  final double averageScore;
  final String category;
  final String currentRole;
  final String? lookupPoints;

  const ScoreSummaryWidget({
    super.key,
    required this.averageScore,
    required this.category,
    required this.currentRole,
    this.lookupPoints,
  });

  String _resolveLabel() {
    if (category != 'Jasmani') return 'Rata-rata Nilai';
    if (currentRole == 'Tim Medis') return 'Rata-rata Kesehatan';
    if (currentRole == 'Korsis' || currentRole == 'Gadik') {
      return 'Rata-rata Samapta';
    }
    return 'Rata-rata Jasmani';
  }

  Color _resolvePredicateColor(String predicate) {
    if (predicate.contains('SM')) return Colors.teal.shade700;
    if (predicate.contains('(M)')) return Colors.indigo.shade700;
    if (predicate.contains('(B)')) return Colors.blue.shade700;
    if (predicate.contains('(C)')) return Colors.orange.shade800;
    return Colors.red.shade700;
  }

  Color _resolvePredicateBg(String predicate) {
    if (predicate.contains('SM')) return Colors.teal.shade50;
    if (predicate.contains('(M)')) return Colors.indigo.shade50;
    if (predicate.contains('(B)')) return Colors.blue.shade50;
    if (predicate.contains('(C)')) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  @override
  Widget build(BuildContext context) {
    final predicate = SamaptaScoringService.getScorePredicate(averageScore);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _resolveLabel(),
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade500,
          ),
        ),
        Text(
          averageScore.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: AppDimensions.fontDisplay,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        if (category == 'Mental Kepribadian' && lookupPoints != null)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.xs / 2),
            child: Text(
              'Agregasi Poin Dinamis: $lookupPoints',
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        const SizedBox(height: AppDimensions.xs),
        if (predicate != '-')
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color: _resolvePredicateBg(predicate),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: _resolvePredicateColor(predicate).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              predicate,
              style: TextStyle(
                fontSize: AppDimensions.fontSm + 1,
                fontWeight: FontWeight.w800,
                color: _resolvePredicateColor(predicate),
              ),
            ),
          ),
      ],
    );
  }
}

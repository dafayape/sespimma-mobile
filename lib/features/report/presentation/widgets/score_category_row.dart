import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/report/presentation/widgets/score_summary_card.dart';

class ScoreCategoryRow extends StatelessWidget {
  final double nilaiAkademik;
  final double nilaiMental;
  final double nilaiJasmani;
  final double nilaiKesehatan;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Map<String, dynamic>? bobot;

  const ScoreCategoryRow({
    super.key,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    required this.nilaiKesehatan,
    required this.selectedCategory,
    required this.onCategoryChanged,
    this.bobot,
  });

  @override
  Widget build(BuildContext context) {
    final double akBobot = (bobot?['akademik'] as num?)?.toDouble() ?? 40.0;
    final double menBobot = (bobot?['mental'] as num?)?.toDouble() ?? 40.0;
    final double kesjasBobot = (bobot?['kesjas'] as num?)?.toDouble() ?? 20.0;
    final double jasBobot = (kesjasBobot * 0.6).roundToDouble();
    final double kesBobot = kesjasBobot - jasBobot;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ScoreSummaryCard(
                label: 'Akademik',
                score: nilaiAkademik,
                weight: '${akBobot.toInt()}%',
                isSelected: selectedCategory == 'Akademik',
                onTap: () => onCategoryChanged('Akademik'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ScoreSummaryCard(
                label: 'Mental',
                score: nilaiMental,
                weight: '${menBobot.toInt()}%',
                isSelected: selectedCategory == 'Mental' || selectedCategory == 'Mental Kepribadian',
                onTap: () => onCategoryChanged('Mental'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Row(
          children: [
            Expanded(
              child: ScoreSummaryCard(
                label: 'Jasmani',
                score: nilaiJasmani,
                weight: '${jasBobot.toInt()}%',
                isSelected: selectedCategory == 'Jasmani',
                onTap: () => onCategoryChanged('Jasmani'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ScoreSummaryCard(
                label: 'Kesehatan',
                score: nilaiKesehatan,
                weight: '${kesBobot.toInt()}%',
                isSelected: selectedCategory == 'Kesehatan',
                onTap: () => onCategoryChanged('Kesehatan'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

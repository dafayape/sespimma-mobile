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

  const ScoreCategoryRow({
    super.key,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    required this.nilaiKesehatan,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ScoreSummaryCard(
                label: 'Akademik',
                score: nilaiAkademik,
                weight: '40%',
                isSelected: selectedCategory == 'Akademik',
                onTap: () => onCategoryChanged('Akademik'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ScoreSummaryCard(
                label: 'Mental Kepribadian',
                score: nilaiMental,
                weight: '40%',
                isSelected: selectedCategory == 'Mental Kepribadian',
                onTap: () => onCategoryChanged('Mental Kepribadian'),
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
                weight: '12%',
                isSelected: selectedCategory == 'Jasmani',
                onTap: () => onCategoryChanged('Jasmani'),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: ScoreSummaryCard(
                label: 'Kesehatan',
                score: nilaiKesehatan,
                weight: '8%',
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

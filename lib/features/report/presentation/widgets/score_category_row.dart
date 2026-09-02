import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/report/presentation/widgets/score_summary_card.dart';

class ScoreCategoryRow extends StatelessWidget {
  final double nilaiAkademik;
  final double nilaiMental;
  final double nilaiJasmani;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const ScoreCategoryRow({
    super.key,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: ScoreSummaryCard(
            label: 'Jasmani',
            score: nilaiJasmani,
            weight: '20%',
            isSelected: selectedCategory == 'Jasmani',
            onTap: () => onCategoryChanged('Jasmani'),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/report/presentation/widgets/detailed_competencies.dart';
import 'package:sespimma/features/report/presentation/widgets/nak_hero_card.dart';
import 'package:sespimma/features/report/presentation/widgets/personal_recommendations_card.dart';
import 'package:sespimma/features/report/presentation/widgets/score_category_row.dart';
import 'package:sespimma/features/report/presentation/widgets/report_section_header.dart';

class ReportContentBody extends StatelessWidget {
  final UserEntity user;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final Map<String, dynamic> reportData;
  final Future<void> Function() onRefresh;

  const ReportContentBody({
    super.key,
    required this.user,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.reportData,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> summary = reportData['summary'] is Map
        ? Map<String, dynamic>.from(reportData['summary'])
        : {};
    final double dynamicMentalScore = (summary['mental_score'] as num?)?.toDouble() ?? 0.0;
    final double dynamicJasmaniScore = (summary['jasmani_score'] as num?)?.toDouble() ?? (summary['physical_score'] as num?)?.toDouble() ?? 0.0;
    final double dynamicKesehatanScore = (summary['kesehatan_score'] as num?)?.toDouble() ?? (summary['physical_score'] as num?)?.toDouble() ?? 0.0;
    final double dynamicAcademicScore = (summary['academic_score'] as num?)?.toDouble() ?? 0.0;
    final double nakScore = (summary['nak'] as num?)?.toDouble() ??
        (dynamicAcademicScore * 0.4 + dynamicMentalScore * 0.4 + (dynamicJasmaniScore * 0.6 + dynamicKesehatanScore * 0.4) * 0.2);

    return RefreshIndicator(
      color: AppColors.primaryNavy,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await HapticFeedback.mediumImpact();
        await onRefresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NakHeroCard(
              nakScore: nakScore,
              academicScore: dynamicAcademicScore,
              mentalScore: dynamicMentalScore,
              physicalScore: dynamicJasmaniScore,
            ),
            const SizedBox(height: 16.0),
            ScoreCategoryRow(
              nilaiAkademik: dynamicAcademicScore,
              nilaiMental: dynamicMentalScore,
              nilaiJasmani: dynamicJasmaniScore,
              nilaiKesehatan: dynamicKesehatanScore,
              selectedCategory: selectedCategory,
              onCategoryChanged: onCategoryChanged,
              bobot: reportData['summary'] != null && reportData['summary']['bobot'] != null
                  ? Map<String, dynamic>.from(reportData['summary']['bobot'])
                  : null,
            ),
            const SizedBox(height: 28.0),
            const ReportSectionHeader(judul: 'Rincian Kompetensi'),
            const SizedBox(height: 12.0),
            _buildAnimatedChild(
              DetailedCompetencies(
                key: ValueKey<String>('details_$selectedCategory'),
                category: selectedCategory,
                user: user,
                rawScores: reportData['raw_scores'] != null ? Map<String, dynamic>.from(reportData['raw_scores']) : null,
              ),
            ),
            const SizedBox(height: 28.0),
            _buildAnimatedChild(
              PersonalRecommendationsCard(
                key: ValueKey<String>('recommendations_$selectedCategory'),
                category: selectedCategory,
                nakScore: nakScore,
                academicScore: dynamicAcademicScore,
                mentalScore: dynamicMentalScore,
                physicalScore: dynamicJasmaniScore,
                rawScores: reportData['raw_scores'] != null ? Map<String, dynamic>.from(reportData['raw_scores']) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedChild(Widget child) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/report/presentation/widgets/ai_insight_card.dart';
import 'package:sespimma/features/report/presentation/widgets/detailed_competencies.dart';
import 'package:sespimma/features/report/presentation/widgets/score_category_row.dart';
import 'package:sespimma/features/report/presentation/widgets/score_line_chart.dart';
import 'package:sespimma/features/report/presentation/widgets/report_section_header.dart';
import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';

class ReportContentBody extends StatelessWidget {
  final UserEntity user;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const ReportContentBody({
    super.key,
    required this.user,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final allRecaps = ScoreCalculatorService.generateRealReports();
    final finalRecap = allRecaps.firstWhere(
      (r) => r.id == user.noSerdik,
      orElse: () => allRecaps.first,
    );

    final double dynamicMentalScore = finalRecap.mentalScore;
    final double dynamicJasmaniScore = finalRecap.physicalScore;
    double currentScore = 0.0;
    if (selectedCategory == 'Mental Kepribadian') {
      currentScore = dynamicMentalScore;
    } else if (selectedCategory == 'Akademik') {
      currentScore = user.nilaiAkademik;
    } else {
      currentScore = dynamicJasmaniScore;
    }

    return RefreshIndicator(
      color: AppColors.primaryNavy,
      backgroundColor: Colors.white,
      onRefresh: () async {
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.xl,
          vertical: AppDimensions.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScoreCategoryRow(
              nilaiAkademik: user.nilaiAkademik,
              nilaiMental: dynamicMentalScore,
              nilaiJasmani: dynamicJasmaniScore,
              selectedCategory: selectedCategory,
              onCategoryChanged: onCategoryChanged,
            ),
            const SizedBox(height: AppDimensions.xxl + AppDimensions.md),
            const ReportSectionHeader(judul: 'Tren Perkembangan Terpadu'),
            const SizedBox(height: AppDimensions.md),
            ScoreLineChart(
              key: const ValueKey('integrated_trend_chart'),
              nilaiAkademik: user.nilaiAkademik,
              nilaiMental: dynamicMentalScore,
              nilaiJasmani: dynamicJasmaniScore,
              selectedCategory: selectedCategory,
              noSerdik: user.noSerdik,
            ),
            const SizedBox(height: AppDimensions.xxl + AppDimensions.md),
            const ReportSectionHeader(judul: 'Rincian Kompetensi'),
            const SizedBox(height: AppDimensions.md),
            _buildAnimatedChild(
              DetailedCompetencies(
                key: ValueKey<String>('details_$selectedCategory'),
                category: selectedCategory,
                user: user,
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
            _buildAnimatedChild(
              AiInsightCard(
                key: ValueKey<String>('insight_$selectedCategory'),
                category: selectedCategory,
                score: currentScore,
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

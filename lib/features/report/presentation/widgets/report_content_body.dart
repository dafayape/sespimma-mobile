import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/features/report/presentation/widgets/ai_insight_card.dart';
import 'package:sespimma/features/report/presentation/widgets/detailed_competencies.dart';
import 'package:sespimma/features/report/presentation/widgets/ews_warning_banner.dart';
import 'package:sespimma/features/report/presentation/widgets/nak_hero_card.dart';
import 'package:sespimma/features/report/presentation/widgets/score_category_row.dart';
import 'package:sespimma/features/report/presentation/widgets/score_line_chart.dart';
import 'package:sespimma/features/report/presentation/widgets/report_section_header.dart';
import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';

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
    final summary = reportData['summary'];
    double dynamicMentalScore;
    double dynamicJasmaniScore;
    double dynamicAcademicScore;
    double nakScore;

    if (summary != null && summary is Map) {
      dynamicMentalScore = (summary['mental_score'] as num?)?.toDouble() ?? 0.0;
      dynamicJasmaniScore = (summary['physical_score'] as num?)?.toDouble() ?? 0.0;
      dynamicAcademicScore = (summary['academic_score'] as num?)?.toDouble() ?? 0.0;
      nakScore = (summary['nak'] as num?)?.toDouble() ??
          (dynamicAcademicScore * 0.4 + dynamicMentalScore * 0.4 + dynamicJasmaniScore * 0.2);
    } else {
      final allRecaps = ScoreCalculatorService.generateRealReports();
      final finalRecap = allRecaps.firstWhere(
        (r) => r.id == user.noSerdik,
        orElse: () => allRecaps.first,
      );
      dynamicMentalScore = finalRecap.mentalScore;
      dynamicJasmaniScore = finalRecap.physicalScore;
      dynamicAcademicScore = user.nilaiAkademik;
      nakScore = dynamicAcademicScore * 0.4 + dynamicMentalScore * 0.4 + dynamicJasmaniScore * 0.2;
    }

    double currentScore = 0.0;
    if (selectedCategory == 'Mental Kepribadian') {
      currentScore = dynamicMentalScore;
    } else if (selectedCategory == 'Akademik') {
      currentScore = dynamicAcademicScore;
    } else {
      currentScore = dynamicJasmaniScore;
    }

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
          horizontal: AppDimensions.xl,
          vertical: AppDimensions.xxl,
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
            const SizedBox(height: AppDimensions.lg),
            EwsWarningBanner(
              academicScore: dynamicAcademicScore,
              mentalScore: dynamicMentalScore,
              physicalScore: dynamicJasmaniScore,
            ),
            ScoreCategoryRow(
              nilaiAkademik: dynamicAcademicScore,
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
              nilaiAkademik: dynamicAcademicScore,
              nilaiMental: dynamicMentalScore,
              nilaiJasmani: dynamicJasmaniScore,
              selectedCategory: selectedCategory,
              noSerdik: user.noSerdik,
              trendList: reportData['trend'] != null ? List<Map<String, dynamic>>.from(reportData['trend']) : null,
            ),
            const SizedBox(height: AppDimensions.xxl + AppDimensions.md),
            const ReportSectionHeader(judul: 'Rincian Kompetensi'),
            const SizedBox(height: AppDimensions.md),
            _buildAnimatedChild(
              DetailedCompetencies(
                key: ValueKey<String>('details_$selectedCategory'),
                category: selectedCategory,
                user: user,
                rawScores: reportData['raw_scores'] != null ? Map<String, dynamic>.from(reportData['raw_scores']) : null,
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

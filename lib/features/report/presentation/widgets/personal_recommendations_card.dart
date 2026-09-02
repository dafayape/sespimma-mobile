import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

class RecommendationItemData {
  final String title;
  final String text;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;

  RecommendationItemData({
    required this.title,
    required this.text,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
  });
}

class PersonalRecommendationsCard extends StatelessWidget {
  final double nakScore;
  final double academicScore;
  final double mentalScore;
  final double physicalScore;

  const PersonalRecommendationsCard({
    super.key,
    required this.nakScore,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
  });

  List<RecommendationItemData> _buildRecommendations() {
    final list = <RecommendationItemData>[];

    // 1. Rekomendasi NAK (Nilai Akhir Kumulatif)
    if (nakScore >= 80.0) {
      list.add(RecommendationItemData(
        title: 'Capaian Prestasi Sangat Baik',
        text: 'Nilai Akhir Kumulatif Anda (${nakScore.toStringAsFixed(2)}) berada di kategori Sangat Memuaskan. Pertahankan performa konsisten ini hingga akhir pendidikan.',
        icon: Icons.workspace_premium_rounded,
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        iconColor: const Color(0xFF16A34A),
        textColor: const Color(0xFF15803D),
      ));
    } else if (nakScore >= 70.0) {
      list.add(RecommendationItemData(
        title: 'Capaian Prestasi Memenuhi Syarat',
        text: 'Nilai Akhir Kumulatif Anda (${nakScore.toStringAsFixed(2)}) sudah memenuhi standar minimum. Tingkatkan aspek yang masih lemah untuk menaikkan peringkat.',
        icon: Icons.trending_up_rounded,
        bgColor: const Color(0xFFFEFCE8),
        borderColor: const Color(0xFFFEF08A),
        iconColor: const Color(0xFFCA8A04),
        textColor: const Color(0xFFA16207),
      ));
    } else if (nakScore > 0) {
      list.add(RecommendationItemData(
        title: 'Perlunya Akselerasi Nilai Akhir',
        text: 'Nilai Akhir Kumulatif Anda (${nakScore.toStringAsFixed(2)}) masih di bawah rata-rata kelulusan. Diperlukan konseling dan pembinaan intensif.',
        icon: Icons.gavel_rounded,
        bgColor: const Color(0xFFFEF2F2),
        borderColor: const Color(0xFFFECACA),
        iconColor: const Color(0xFFDC2626),
        textColor: const Color(0xFFB91C1C),
      ));
    }

    // 2. Rekomendasi Mental Kepribadian
    if (mentalScore >= 80.0) {
      list.add(RecommendationItemData(
        title: 'Disiplin & Mental Terjaga Baik',
        text: 'Nilai Mental Kepribadian (${mentalScore.toStringAsFixed(2)}) menunjukkan sikap integritas dan kepemimpinan yang tinggi.',
        icon: Icons.verified_user_rounded,
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        iconColor: const Color(0xFF16A34A),
        textColor: const Color(0xFF15803D),
      ));
    } else if (mentalScore > 0 && mentalScore < 75.0) {
      list.add(RecommendationItemData(
        title: 'Evaluasi Kedisiplinan & Poin Pelanggaran',
        text: 'Nilai Mental Kepribadian Anda (${mentalScore.toStringAsFixed(2)}) memerlukan perhatian. Hindari catatan pelanggaran disiplin dan tingkatkan giat positif.',
        icon: Icons.report_problem_rounded,
        bgColor: const Color(0xFFFEFCE8),
        borderColor: const Color(0xFFFEF08A),
        iconColor: const Color(0xFFCA8A04),
        textColor: const Color(0xFFA16207),
      ));
    }

    // 3. Rekomendasi Jasmani & Samapta
    if (physicalScore > 0 && physicalScore < 70.0) {
      list.add(RecommendationItemData(
        title: 'Pembinaan Kesamaptaan Jasmani',
        text: 'Nilai Jasmani Anda (${physicalScore.toStringAsFixed(2)}) masih kurang. Lakukan latihan mandiri Samapta A (Lari) dan Samapta B secara rutin.',
        icon: Icons.directions_run_rounded,
        bgColor: const Color(0xFFFEF2F2),
        borderColor: const Color(0xFFFECACA),
        iconColor: const Color(0xFFDC2626),
        textColor: const Color(0xFFB91C1C),
      ));
    } else if (physicalScore >= 80.0) {
      list.add(RecommendationItemData(
        title: 'Kebugaran Fisik Prima',
        text: 'Nilai Jasmani (${physicalScore.toStringAsFixed(2)}) sangat mendukung kesiapan fisik pendidikan.',
        icon: Icons.fitness_center_rounded,
        bgColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        iconColor: const Color(0xFF16A34A),
        textColor: const Color(0xFF15803D),
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildRecommendations();
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rekomendasi',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: Color(0xFF001C40),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        ...items.map((item) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppDimensions.md),
              padding: const EdgeInsets.all(AppDimensions.lg),
              decoration: BoxDecoration(
                color: item.bgColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: item.borderColor, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 20),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w700,
                            color: item.textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSm - 1,
                            fontWeight: FontWeight.w500,
                            color: item.textColor.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

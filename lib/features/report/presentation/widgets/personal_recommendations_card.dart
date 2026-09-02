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
  final String category;
  final double nakScore;
  final double academicScore;
  final double mentalScore;
  final double physicalScore;

  const PersonalRecommendationsCard({
    super.key,
    required this.category,
    required this.nakScore,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
  });

  List<RecommendationItemData> _buildRecommendations() {
    final list = <RecommendationItemData>[];

    if (category == 'Akademik') {
      if (academicScore >= 80.0) {
        list.add(RecommendationItemData(
          title: 'Penguasaan Materi Akademik Sangat Baik',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) berada dalam tingkat Sangat Memuaskan. Pertahankan kedalaman analisis pada NPTT/Taskap dan Simulasi Kepemimpinan.',
          icon: Icons.workspace_premium_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      } else if (academicScore >= 70.0) {
        list.add(RecommendationItemData(
          title: 'Peningkatan Hasil Belajar Akademik',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) telah memenuhi standar. Fokus tingkatkan pendalaman materi Ujian Mata Pelajaran dan Produk Perseorangan.',
          icon: Icons.trending_up_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      } else if (academicScore > 0) {
        list.add(RecommendationItemData(
          title: 'Pendalaman Ekstra Materi Akademik',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) memerlukan bimbingan ekstra. Disarankan mengikuti pendalaman materi bersama Mentor/Dosen Pengampu.',
          icon: Icons.gavel_rounded,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFFB91C1C),
        ));
      }
    } else if (category == 'Mental Kepribadian') {
      if (mentalScore >= 80.0) {
        list.add(RecommendationItemData(
          title: 'Integritas & Kepemimpinan Prima',
          text: 'Nilai Mental Kepribadian Anda (${mentalScore.toStringAsFixed(2)}) sangat tinggi. Pertahankan sikap keteladanan, moralitas, dan Sosiometri positif.',
          icon: Icons.verified_user_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      } else if (mentalScore > 0) {
        list.add(RecommendationItemData(
          title: 'Penguatan Kedisiplinan & Interaksi Rekan',
          text: 'Nilai Mental Kepribadian Anda (${mentalScore.toStringAsFixed(2)}) perlu ditingkatkan. Hindari pelanggaran tata tertib dan tingkatkan inisiatif sosial.',
          icon: Icons.report_problem_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }
    } else if (category == 'Jasmani') {
      if (physicalScore >= 80.0) {
        list.add(RecommendationItemData(
          title: 'Kebugaran Fisik & Samapta Prima',
          text: 'Nilai Kesamaptaan Jasmani Anda (${physicalScore.toStringAsFixed(2)}) sangat baik. Pertahankan porsi latihan Samapta A dan B secara konsisten.',
          icon: Icons.fitness_center_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      } else if (physicalScore > 0) {
        list.add(RecommendationItemData(
          title: 'Pembinaan Latihan Fisik Mandiri',
          text: 'Nilai Jasmani Anda (${physicalScore.toStringAsFixed(2)}) perlu peningkatan. Lakukan latihan lari 12 menit dan penguatan otot lengan/perut rutin sore hari.',
          icon: Icons.directions_run_rounded,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFFB91C1C),
        ));
      }
    } else if (category == 'Kesehatan') {
      list.add(RecommendationItemData(
        title: 'Pemeliharaan Kesehatan & Stamina',
        text: 'Jaga kebugaran tubuh, pola istirahat teratur, serta pantau hasil Tes Kesehatan (MCU) berkala untuk mendukung kelancaran seluruh kegiatan pendidikan.',
        icon: Icons.health_and_safety_rounded,
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

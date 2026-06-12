import 'package:flutter/material.dart';

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AiInsightCard extends StatelessWidget {
  final String category;
  final double score;

  const AiInsightCard({super.key, required this.category, required this.score});

  @override
  Widget build(BuildContext context) {
    bool isWarning = score > 0 && score < 70.0;
    bool isAverage = score >= 70.0 && score < 80.0;
    bool isExcellent = score >= 80.0;

    String insight = _getInsight(score, isWarning, isExcellent);

    Color bgColor;
    Color borderColor;
    Color iconBgColor;
    Color iconColor;
    Color titleColor;

    if (score == 0.0) {
      bgColor = Colors.blueGrey.shade50;
      borderColor = Colors.blueGrey.shade100;
      iconBgColor = Colors.blueGrey.shade100;
      iconColor = Colors.blueGrey.shade700;
      titleColor = Colors.blueGrey.shade900;
    } else if (isWarning) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade100;
      iconBgColor = Colors.red.shade100;
      iconColor = Colors.red.shade700;
      titleColor = Colors.red.shade900;
    } else if (isAverage) {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade100;
      iconBgColor = Colors.amber.shade100;
      iconColor = Colors.amber.shade700;
      titleColor = Colors.amber.shade900;
    } else {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade100;
      iconBgColor = Colors.green.shade100;
      iconColor = Colors.green.shade700;
      titleColor = Colors.green.shade900;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.sparkleFill,
              color: iconColor,
              size: AppDimensions.iconSm,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  insight,
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: AppDimensions.fontXs + 2,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInsight(double score, bool isWarning, bool isExcellent) {
    if (score == 0.0) {
      return 'Penilaian belum masuk masih diproses oleh bagian terkait.';
    }

    if (category == 'Akademik') {
      if (isWarning) {
        return 'Berdasarkan analisis tren Akademik Anda, terdapat penurunan performa pada pemahaman NPTT / Taskap. AI menyarankan Anda untuk mengikuti sesi pendalaman materi ekstra bersama Mentor / Pengasuh.';
      }
      if (isExcellent) {
        return 'Performa Akademik Anda sangat luar biasa! Anda menunjukkan pemahaman konseptual yang tajam. Pertahankan ritme belajar ini untuk bisa meraih predikat Lulusan Terbaik.';
      }
      return 'Nilai Akademik Anda berada pada kondisi stabil dan baik. Tetap jaga fokus belajar, terutama pada simulasi kepemimpinan kontemporer untuk mendongkrak nilai ke tingkat maksimal.';
    } else if (category == 'Mental Kepribadian') {
      if (isWarning) {
        return 'Sistem mendeteksi adanya indikator kedisiplinan dan pengendalian diri yang perlu diperhatikan. Mohon untuk segera berkonsultasi secara intensif dengan Pengasuh.';
      }
      if (isExcellent) {
        return 'Karakter dan kepemimpinan Anda dinilai sangat inspiratif oleh rekan. Anda adalah role model yang baik dalam aspek Mental Kepribadian.';
      }
      return 'Aspek Mental Kepribadian Anda masuk kategori baik. Terus tingkatkan inisiatif dan interaksi positif Anda dengan rekan sejawat agar penilaian karakter semakin optimal.';
    } else {
      if (isWarning) {
        return 'Evaluasi Jasmani Anda saat ini berada di bawah standar minimum kelulusan. Segera perbaiki pola latihan fisik harian dan perhatikan asupan gizi untuk menghindari risiko kesehatan.';
      }
      if (isExcellent) {
        return 'Kondisi fisik dan Kesamaptaan Anda sangat prima! Ketahanan lari 12 menit Anda berada jauh di atas rata-rata Serdik lain. Pertahankan rutinitas olahraga mandiri Anda.';
      }
      return 'Nilai Jasmani Anda mencukupi standar dan stabil. Tambahkan porsi latihan kardio secara bertahap setiap sore untuk meningkatkan poin secara progresif pada Kesamaptaan A.';
    }
  }
}

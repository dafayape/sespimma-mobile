import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

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

    Color borderColor;

    if (score == 0.0) {
      borderColor = Colors.blueGrey.shade100;
    } else if (isWarning) {
      borderColor = Colors.red.shade200;
    } else if (isAverage) {
      borderColor = Colors.amber.shade200;
    } else {
      borderColor = Colors.green.shade200;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: AppDimensions.radiusLg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekomendasi',
            style: TextStyle(
              color: Color(0xFF001C40),
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            insight,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w500,
              height: 1.4,
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
        return 'Berdasarkan analisis tren Akademik Anda, terdapat penurunan performa pada pemahaman NPTT / Taskap. Disarankan Anda untuk mengikuti sesi pendalaman materi ekstra bersama Mentor / Pengasuh.';
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

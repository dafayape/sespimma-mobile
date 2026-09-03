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
  final double kesehatanScore;
  final Map<String, dynamic>? rawScores;

  const PersonalRecommendationsCard({
    super.key,
    required this.category,
    required this.nakScore,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
    required this.kesehatanScore,
    this.rawScores,
  });

  double _getScore(String key) {
    if (rawScores == null) return 0.0;
    final val = rawScores![key] ?? rawScores![key.toLowerCase()] ?? rawScores![key.toUpperCase()];
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  double _getAnyScore(List<String> keys) {
    for (final key in keys) {
      final score = _getScore(key);
      if (score > 0) return score;
    }
    return 0.0;
  }

  double _getRawVal(List<String> keys) {
    for (final key in keys) {
      final rawKey = '${key}_raw';
      final val = rawScores?[rawKey] ?? rawScores?[rawKey.toLowerCase()] ?? rawScores?[rawKey.toUpperCase()];
      if (val != null) {
        if (val is num) return val.toDouble();
        if (val is String) return double.tryParse(val) ?? 0.0;
      }
    }
    return 0.0;
  }

  List<RecommendationItemData> _buildRecommendations() {
    final list = <RecommendationItemData>[];

    if (category == 'Akademik') {
      if (academicScore == 0) {
        list.add(RecommendationItemData(
          title: 'Belum Ada Penilaian Akademik',
          text: 'Data Nilai Akademik belum terisi. Nilai akan muncul setelah seluruh ujian/produk perorangan selesai dinilai pengampu.',
          icon: Icons.info_outline_rounded,
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          iconColor: const Color(0xFF64748B),
          textColor: const Color(0xFF334155),
        ));
      } else if (academicScore >= 80.0) {
        list.add(RecommendationItemData(
          title: 'Penguasaan Akademik Prima',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) dalam tingkat Memuaskan. Pertahankan sintesis dan kedalaman analisis pada tugas penulisan Taskap/NPTT.',
          icon: Icons.workspace_premium_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      } else if (academicScore >= 70.0) {
        list.add(RecommendationItemData(
          title: 'Peningkatan Hasil Belajar Akademik',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) telah memenuhi batas lulus (70.00). Fokus tingkatkan pendalaman materi ujian dan Produk Perseorangan.',
          icon: Icons.trending_up_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      } else {
        list.add(RecommendationItemData(
          title: 'Pendalaman Ekstra & Remedial Akademik',
          text: 'Nilai Akademik Anda (${academicScore.toStringAsFixed(2)}) berada di bawah batas lulus (70.00). Disarankan mengikuti bimbingan intensif dan jadwal remedial bersama pengampu.',
          icon: Icons.gavel_rounded,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFFB91C1C),
        ));
      }
    } else if (category == 'Mental' || category == 'Mental Kepribadian') {
      final moral = _getScore('moral');
      final disiplin = _getScore('disiplin');
      final kepemimpinan = _getScore('kepemimpinan');
      final pengendalian = _getScore('pengendalian_diri');
      final penampilan = _getScore('penampilan');
      final sosio = _getAnyScore(['SOSIOMETRI', 'NS', 'sosiometri']);

      if (disiplin > 0 && disiplin < 80.0) {
        list.add(RecommendationItemData(
          title: 'Penguatan Kedisiplinan & Kepatuhan',
          text: 'Nilai Disiplin Anda (${disiplin.toStringAsFixed(2)}) memerlukan peningkatan. Tingkatkan ketepatan waktu presensi dan kepatuhan penuh terhadap tata tertib lembaga.',
          icon: Icons.gavel_rounded,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFFB91C1C),
        ));
      }
      if (sosio > 0 && sosio < 80.0) {
        list.add(RecommendationItemData(
          title: 'Tingkatkan Interaksi Sosial & Sosiometri',
          text: 'Nilai Sosiometri Anda (${sosio.toStringAsFixed(2)}) memerlukan perhatian. Tingkatkan komunikasi efektif, kerja sama kelompok, dan solidaritas antar-peserta didik.',
          icon: Icons.groups_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }
      if (moral > 0 && moral < 80.0) {
        list.add(RecommendationItemData(
          title: 'Pemeliharaan Moralitas & Etika',
          text: 'Nilai Moral Anda (${moral.toStringAsFixed(2)}) perlu ditingkatkan. Selalu terapkan nilai-nilai integritas dan etika Bhayangkara dalam penugasan harian.',
          icon: Icons.verified_user_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }
      if (kepemimpinan > 0 && kepemimpinan < 80.0) {
        list.add(RecommendationItemData(
          title: 'Pengembangan Inisiatif Kepemimpinan',
          text: 'Nilai Kepemimpinan Anda (${kepemimpinan.toStringAsFixed(2)}) perlu diasah. Ambil peran aktif saat diskusi kelompok dan penugasan organisasi.',
          icon: Icons.psychology_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }
      if (pengendalian > 0 && pengendalian < 80.0) {
        list.add(RecommendationItemData(
          title: 'Pengendalian Diri & Kestabilan Emosi',
          text: 'Nilai Pengendalian Diri Anda (${pengendalian.toStringAsFixed(2)}) perlu ditingkatkan. Jaga kestabilan emosi dan ketenangan dalam penugasan di bawah tekanan.',
          icon: Icons.psychology_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }
      if (penampilan > 0 && penampilan < 80.0) {
        list.add(RecommendationItemData(
          title: 'Sikap Tampang & Kerapian Penampilan',
          text: 'Nilai Penampilan Anda (${penampilan.toStringAsFixed(2)}) perlu ditingkatkan. Jagalah kebersihan gampol, sikap tampang, dan kerapian sesuai standar.',
          icon: Icons.dry_cleaning_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }

      if (list.isEmpty) {
        list.add(RecommendationItemData(
          title: 'Integritas & Kepemimpinan Prima',
          text: 'Nilai Mental Kepribadian Anda (${mentalScore.toStringAsFixed(2)}) berada dalam kondisi Memuaskan. Pertahankan keteladanan, kedisiplinan, dan hubungan sosiometri yang harmonis.',
          icon: Icons.verified_user_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      }
    } else if (category == 'Jasmani') {
      final samaptaA = _getAnyScore(['SAMAPTA_A', 'LARI', 'NGA', 'P1', 'JALAN_KAKI']);
      final pullUp = _getAnyScore(['PULL_UP', 'CHINNING', 'NGB1', 'P21']);
      final sitUp = _getAnyScore(['SIT_UP', 'NGB2', 'P22']);
      final pushUp = _getAnyScore(['PUSH_UP', 'NGB3', 'P23']);
      final shuttleRun = _getAnyScore(['SHUTTLE_RUN', 'NGB4', 'P24']);
      final hasAnyJasmaniData = physicalScore > 0 || samaptaA > 0 || pullUp > 0 || sitUp > 0 || pushUp > 0 || shuttleRun > 0;

      if (!hasAnyJasmaniData) {
        list.add(RecommendationItemData(
          title: 'Belum Ada Penilaian Jasmani',
          text: 'Data Kesamaptaan Jasmani belum terisi. Rekomendasi fisik akan ditampilkan setelah tes Samapta A dan B dilaksanakan.',
          icon: Icons.info_outline_rounded,
          bgColor: const Color(0xFFF8FAFC),
          borderColor: const Color(0xFFE2E8F0),
          iconColor: const Color(0xFF64748B),
          textColor: const Color(0xFF334155),
        ));
      } else {
        final rawLari = _getRawVal(['SAMAPTA_A', 'P1']);
        final rawPullUp = _getRawVal(['PULL_UP', 'P21']);
        final rawPushUp = _getRawVal(['PUSH_UP', 'P23']);
        final rawSitUp = _getRawVal(['SIT_UP', 'P22']);

        if (samaptaA > 0 && samaptaA < 80.0) {
          list.add(RecommendationItemData(
            title: 'Latihan Aerobik & Lari (Samapta A)',
            text: 'Nilai Samapta A (Lari) Anda (${samaptaA.toStringAsFixed(2)}${rawLari > 0 ? ' • ${rawLari.toInt()}m' : ''}) memerlukan penguatan. Lakukan latihan lari 12 menit atau tempo run rutin sore hari.',
            icon: Icons.directions_run_rounded,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
            iconColor: const Color(0xFFCA8A04),
            textColor: const Color(0xFFA16207),
          ));
        }
        if (pullUp > 0 && pullUp < 80.0) {
          list.add(RecommendationItemData(
            title: 'Penguatan Otot Lengan (Pull Up)',
            text: 'Nilai Pull Up Anda (${pullUp.toStringAsFixed(2)}${rawPullUp > 0 ? ' • ${rawPullUp.toInt()} kali' : ''}) perlu ditingkatkan. Lakukan latihan chin-up dan penguatan triceps teratur.',
            icon: Icons.fitness_center_rounded,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
            iconColor: const Color(0xFFCA8A04),
            textColor: const Color(0xFFA16207),
          ));
        }
        if (pushUp > 0 && pushUp < 80.0) {
          list.add(RecommendationItemData(
            title: 'Penguatan Otot Dada (Push Up)',
            text: 'Nilai Push Up Anda (${pushUp.toStringAsFixed(2)}${rawPushUp > 0 ? ' • ${rawPushUp.toInt()} kali' : ''}) perlu ditingkatkan. Lakukan latihan rutin variasi set push-up pagi dan sore.',
            icon: Icons.fitness_center_rounded,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
            iconColor: const Color(0xFFCA8A04),
            textColor: const Color(0xFFA16207),
          ));
        }
        if (sitUp > 0 && sitUp < 80.0) {
          list.add(RecommendationItemData(
            title: 'Penguatan Otot Core & Perut (Sit Up)',
            text: 'Nilai Sit Up Anda (${sitUp.toStringAsFixed(2)}${rawSitUp > 0 ? ' • ${rawSitUp.toInt()} kali' : ''}) perlu ditingkatkan. Lakukan latihan core plank dan crunches harian.',
            icon: Icons.fitness_center_rounded,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
            iconColor: const Color(0xFFCA8A04),
            textColor: const Color(0xFFA16207),
          ));
        }
        if (shuttleRun > 0 && shuttleRun < 80.0) {
          list.add(RecommendationItemData(
            title: 'Kelincahan & Agility (Shuttle Run)',
            text: 'Nilai Shuttle Run Anda (${shuttleRun.toStringAsFixed(2)}) perlu ditingkatkan. Lakukan latihan kelincahan dan koordinasi gerak kaki (footwork) berkala.',
            icon: Icons.directions_run_rounded,
            bgColor: const Color(0xFFFEFCE8),
            borderColor: const Color(0xFFFEF08A),
            iconColor: const Color(0xFFCA8A04),
            textColor: const Color(0xFFA16207),
          ));
        }

        if (list.isEmpty) {
          list.add(RecommendationItemData(
            title: 'Kebugaran Fisik & Samapta Prima',
            text: 'Nilai Kesamaptaan Jasmani Anda (${physicalScore.toStringAsFixed(2)}) sangat baik. Pertahankan porsi latihan Samapta A dan B serta pemanasan teratur.',
            icon: Icons.fitness_center_rounded,
            bgColor: const Color(0xFFF0FDF4),
            borderColor: const Color(0xFFBBF7D0),
            iconColor: const Color(0xFF16A34A),
            textColor: const Color(0xFF15803D),
          ));
        }
      }
    } else if (category == 'Kesehatan') {
      final kesAwal = _getAnyScore(['TES_AWAL', 'nilai_awal']);
      final kesAkhir = _getAnyScore(['TES_AKHIR', 'nilai_akhir']);
      final kesStatus = _getAnyScore(['STATUS_KESEHATAN', 'nilai_status']);
      final effectiveKesScore = kesehatanScore > 0 ? kesehatanScore : (kesStatus > 0 ? kesStatus : 80.0);

      if (effectiveKesScore < 70.0) {
        list.add(RecommendationItemData(
          title: 'Pemeriksaan & Bimbingan Kesehatan Ekstra',
          text: 'Nilai Kesehatan Anda (${effectiveKesScore.toStringAsFixed(2)}) berada di bawah batas lulus (70.00). Segera konsultasi dengan tim medis Poliklinik dan ikuti pemeriksaan kesehatan (MCU) lanjutan.',
          icon: Icons.health_and_safety_rounded,
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFECACA),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFFB91C1C),
        ));
      } else if (effectiveKesScore < 80.0 || (kesStatus > 0 && kesStatus < 80.0)) {
        list.add(RecommendationItemData(
          title: 'Minimalkan Faktor Kunjungan Berobat',
          text: 'Nilai Kesehatan Anda (${effectiveKesScore.toStringAsFixed(2)}) memerlukan perhatian. Jaga kebersihan diri, tidur cukup, dan konsumsi suplemen.',
          icon: Icons.medical_services_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }

      if (kesAkhir > 0 && kesAwal > 0 && kesAkhir < kesAwal) {
        list.add(RecommendationItemData(
          title: 'Pemeriksaan Kesehatan Berkala',
          text: 'Nilai Tes Kesehatan Akhir (${kesAkhir.toStringAsFixed(2)}) mengalami penurunan dari Tes Awal (${kesAwal.toStringAsFixed(2)}). Segera konsultasi dengan tim medis poliklinik.',
          icon: Icons.health_and_safety_rounded,
          bgColor: const Color(0xFFFEFCE8),
          borderColor: const Color(0xFFFEF08A),
          iconColor: const Color(0xFFCA8A04),
          textColor: const Color(0xFFA16207),
        ));
      }

      if (list.isEmpty) {
        list.add(RecommendationItemData(
          title: 'Pemeliharaan Kesehatan & Stamina',
          text: 'Nilai Kesehatan Anda (${effectiveKesScore.toStringAsFixed(2)}) dalam kondisi prima. Jaga kebugaran tubuh, hidrasi cukup, dan pola istirahat teratur.',
          icon: Icons.health_and_safety_rounded,
          bgColor: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          iconColor: const Color(0xFF16A34A),
          textColor: const Color(0xFF15803D),
        ));
      }
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

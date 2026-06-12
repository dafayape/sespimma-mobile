import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

import 'package:sespimma/features/assessment/data/models/serdik_mental_scores.dart';
import '../../data/models/sociometry_period_config.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunSociometryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> serdikData;
  final bool isPhaseAwal;
  final int totalSerdik;

  const PatunSociometryDetailScreen({
    super.key,
    required this.serdikData,
    required this.isPhaseAwal,
    required this.totalSerdik,
  });

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  final List<Map<String, dynamic>> _indicators = const [
    {
      'key': 'moral',
      'pillar': 'Moral',
      'title': 'Etika dan Integritas',
      'desc':
          'Penerapan nilai-nilai etika, kejujuran, dan keluhuran budi pekerti dalam keseharian.',
    },
    {
      'key': 'kepemimpinan',
      'pillar': 'Kepemimpinan',
      'title': 'Kemampuan Memimpin',
      'desc':
          'Kapasitas dalam mengarahkan, mengambil keputusan, dan memberikan pengaruh positif bagi rekan.',
    },
    {
      'key': 'pengendalian_diri',
      'pillar': 'Pengendalian Diri',
      'title': 'Kematangan Emosional',
      'desc':
          'Kemampuan menjaga stabilitas emosi, ketenangan dalam tekanan, dan bersikap bijaksana.',
    },
    {
      'key': 'disiplin',
      'pillar': 'Disiplin',
      'title': 'Ketaatan Aturan',
      'desc':
          'Kepatuhan terhadap tata tertib, ketepatan waktu, dan konsistensi pelaksanaan tugas.',
    },
    {
      'key': 'penampilan',
      'pillar': 'Penampilan',
      'title': 'Sikap dan Kerapian',
      'desc':
          'Kerapian seragam, kebersihan diri, dan sikap jasmani yang mencerminkan kewibawaan.',
    },
  ];

  Map<String, dynamic> _getQualitativeRating(double value) {
    if (value >= 85.00) {
      return {
        'label': 'Sangat Memuaskan',
        'code': 'SM',
        'color': const Color(0xFF2E7D32),
      };
    } else if (value >= 80.00) {
      return {
        'label': 'Memuaskan',
        'code': 'M',
        'color': const Color(0xFF7CB342),
      };
    } else if (value >= 75.00) {
      return {'label': 'Baik', 'code': 'B', 'color': const Color(0xFFFBC02D)};
    } else if (value >= 70.00) {
      return {'label': 'Cukup', 'code': 'C', 'color': const Color(0xFFF57C00)};
    } else {
      return {'label': 'Kurang', 'code': 'K', 'color': const Color(0xFFD32F2F)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final nosis = serdikData['no_serdik'];

    final mentalData = SerdikMentalScores.getScores(nosis);

    final double defaultScore = 80.0;
    bool isPhaseActive = isPhaseAwal
        ? SociometryPeriodConfig.isAwalActive()
        : SociometryPeriodConfig.isAkhirActive();
    bool isPhaseClosed = isPhaseAwal
        ? SociometryPeriodConfig.isAwalClosed()
        : SociometryPeriodConfig.isAkhirClosed();

    int filled = 0;
    if (isPhaseActive || isPhaseClosed) {
      int hash = serdikData['nrp'].hashCode;
      if (!isPhaseAwal) hash += 1000;
      if (hash % 10 > 3) {
        filled = totalSerdik;
      } else {
        filled = hash % (totalSerdik + 1);
      }
    }

    final finalScoreStr = isPhaseAwal ? 'sosiometri_awal' : 'sosiometri_akhir';
    final double baseFinalScore = mentalData[finalScoreStr] ?? defaultScore;

    final double finalScore =
        (baseFinalScore * filled) / (totalSerdik > 0 ? totalSerdik : 1);

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _primaryNavy),
        title: const Text(
          'Detail Sosiometri',
          style: TextStyle(
            color: _primaryNavy,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.xl - 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileAndFinalScore(finalScore),
            const SizedBox(height: AppDimensions.lg),
            const Text(
              'Rincian Nilai',
              style: TextStyle(
                fontSize: AppDimensions.fontXl,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _indicators.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppDimensions.md),
              itemBuilder: (context, index) {
                final item = _indicators[index];
                final baseScore = mentalData[item['key']] ?? defaultScore;
                final double score =
                    ((baseScore as num).toDouble() * filled) /
                    (totalSerdik > 0 ? totalSerdik : 1);
                return _buildScoreCard(item, score, filled, totalSerdik);
              },
            ),
            const SizedBox(height: AppDimensions.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAndFinalScore(double finalScore) {
    final ratingMeta = _getQualitativeRating(finalScore);
    final Color badgeColor = ratingMeta['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _primaryIndigo.withValues(alpha: 0.1),
            backgroundImage:
                (serdikData['foto'] != null &&
                    serdikData['foto'].toString().isNotEmpty)
                ? NetworkImage(serdikData['foto']) as ImageProvider
                : AvatarHelper.getAvatar(null),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${serdikData['nama_lengkap']}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg + 1,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  '${serdikData['pangkat']} • ${serdikData['no_serdik']}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    '${ratingMeta['label']} (${ratingMeta['code']})',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'NILAI AKHIR',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXs,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  finalScore.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl + 4,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(
    Map<String, dynamic> item,
    double averageScore,
    int filled,
    int total,
  ) {
    final ratingMeta = _getQualitativeRating(averageScore);
    final Color statusColor = ratingMeta['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  item['pillar'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  averageScore.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            item['title'],
            style: const TextStyle(
              fontSize: AppDimensions.fontLg + 1,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Penilaian Masuk: $filled dari $total Serdik',
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade400,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: _primaryNavy.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              item['desc'],
              style: TextStyle(
                fontSize: AppDimensions.fontSm + 1,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/scoring_calculator.dart';

class DetailedCompetencies extends StatelessWidget {
  final String category;
  final UserEntity user;
  final Map<String, dynamic>? rawScores;

  const DetailedCompetencies({
    super.key,
    required this.category,
    required this.user,
    this.rawScores,
  });

  double _getScore(Map<String, dynamic> raw, String key) {
    final val = raw[key] ?? raw[key.toLowerCase()] ?? raw[key.toUpperCase()];
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  double _getAnyScore(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final val = _getScore(raw, key);
      if (val > 0) return val;
    }
    return 0.0;
  }

  String? _getRawText(Map<String, dynamic> raw, List<String> keys, String unit) {
    for (final key in keys) {
      final rawKey = '${key}_raw';
      final val = raw[rawKey] ?? raw[rawKey.toLowerCase()] ?? raw[rawKey.toUpperCase()];
      if (val != null) {
        final numVal = val is num ? val.toDouble() : (double.tryParse(val.toString()) ?? 0.0);
        if (numVal > 0) {
          if (unit == 'Detik') {
            return '${numVal.toStringAsFixed(1)} Detik';
          }
          return '${numVal.toInt()} $unit';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (category == 'Mental' || category == 'Mental Kepribadian') {
      final Map<String, dynamic> actualScores = rawScores ?? {};

      double moral = _getScore(actualScores, 'moral');
      double disiplin = _getScore(actualScores, 'disiplin');
      double kepemimpinan = _getScore(actualScores, 'kepemimpinan');
      double pengendalian = _getScore(actualScores, 'pengendalian_diri');
      double penampilan = _getScore(actualScores, 'penampilan');
      double ns = _getScore(actualScores, 'SOSIOMETRI') > 0
          ? _getScore(actualScores, 'SOSIOMETRI')
          : _getScore(actualScores, 'NS');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.sm),
          _CompetencyItem(title: 'Moral (20%)', score: moral),
          _CompetencyItem(title: 'Disiplin (15%)', score: disiplin),
          _CompetencyItem(title: 'Kepemimpinan (20%)', score: kepemimpinan),
          _CompetencyItem(
            title: 'Pengendalian Diri (15%)',
            score: pengendalian,
          ),
          _CompetencyItem(title: 'Penampilan (15%)', score: penampilan),
          _CompetencyItem(title: 'Sosiometri (15%)', score: ns),
        ],
      );
    } else if (category == 'Akademik') {
      final Map<String, dynamic> actualScores = rawScores ?? {};

      double ujianMp = _getScore(actualScores, 'NUMP') > 0 ? _getScore(actualScores, 'NUMP') : _getScore(actualScores, 'UJIAN_MAPEL');

      double nkkpMateri = _getScore(actualScores, 'NKKP_MATERI') > 0 ? _getScore(actualScores, 'NKKP_MATERI') : _getScore(actualScores, 'NMPN_NKKP');
      double nkkpPaparan = _getScore(actualScores, 'NKKP_PAPARAN') > 0 ? _getScore(actualScores, 'NKKP_PAPARAN') : _getScore(actualScores, 'NPA_NKKP');
      double nkkpKeaktifan = _getScore(actualScores, 'NKKP_KEAKTIFAN') > 0 ? _getScore(actualScores, 'NKKP_KEAKTIFAN') : _getScore(actualScores, 'NKA_NKKP');
      double nkkp = _getScore(actualScores, 'NKKP') > 0
          ? _getScore(actualScores, 'NKKP')
          : ScoringCalculator.hitungNKKPatauNPKP(nmpn: nkkpMateri, npa: nkkpPaparan, nka: nkkpKeaktifan);

      double npkpMateri = _getScore(actualScores, 'NPKP_MATERI') > 0 ? _getScore(actualScores, 'NPKP_MATERI') : _getScore(actualScores, 'NMPN_NPKP');
      double npkpPaparan = _getScore(actualScores, 'NPKP_PAPARAN') > 0 ? _getScore(actualScores, 'NPKP_PAPARAN') : _getScore(actualScores, 'NPA_NPKP');
      double npkpKeaktifan = _getScore(actualScores, 'NPKP_KEAKTIFAN') > 0 ? _getScore(actualScores, 'NPKP_KEAKTIFAN') : _getScore(actualScores, 'NKA_NPKP');
      double npkp = _getScore(actualScores, 'NPKP') > 0
          ? _getScore(actualScores, 'NPKP')
          : ScoringCalculator.hitungNKKPatauNPKP(nmpn: npkpMateri, npa: npkpPaparan, nka: npkpKeaktifan);

      double nkpMateri = _getScore(actualScores, 'NKP_MATERI') > 0 ? _getScore(actualScores, 'NKP_MATERI') : _getScore(actualScores, 'NMPN_NKP');
      double nkpPaparan = _getScore(actualScores, 'NKP_PAPARAN') > 0 ? _getScore(actualScores, 'NKP_PAPARAN') : _getScore(actualScores, 'NPA_NKP');
      double nkp = _getScore(actualScores, 'NKP') > 0
          ? _getScore(actualScores, 'NKP')
          : ScoringCalculator.hitungNKP(nmpn: nkpMateri, npa: nkpPaparan);

      double namp = _getScore(actualScores, 'NAMP') > 0
          ? _getScore(actualScores, 'NAMP')
          : ScoringCalculator.hitungNP(nump: ujianMp, nkkp: nkkp, npkp: npkp, nkp: nkp);

      double nskAktif = _getScore(actualScores, 'NKAP') > 0 ? _getScore(actualScores, 'NKAP') : _getScore(actualScores, 'KEAKTIFAN_PERSEORANGAN');
      double nskProduk = _getScore(actualScores, 'NPP') > 0 ? _getScore(actualScores, 'NPP') : _getScore(actualScores, 'PRODUK_PERSEORANGAN');
      double nskRuang = _getScore(actualScores, 'NTR') > 0 ? _getScore(actualScores, 'NTR') : _getScore(actualScores, 'TATA_RUANG_KELOMPOK');
      double nsk = _getScore(actualScores, 'NSK') > 0
          ? _getScore(actualScores, 'NSK')
          : ScoringCalculator.hitungNSK(keaktifan: nskAktif, produk: nskProduk, tataRuang: nskRuang);

      double ntMateri = _getScore(actualScores, 'NAM') > 0 ? _getScore(actualScores, 'NAM') : _getScore(actualScores, 'NPTT_MATERI');
      double ntPenulisan = _getScore(actualScores, 'NKM') > 0 ? _getScore(actualScores, 'NKM') : _getScore(actualScores, 'NPTT_PENULISAN');
      double ntPaparan = _getScore(actualScores, 'NKP_NPTT') > 0 ? _getScore(actualScores, 'NKP_NPTT') : _getScore(actualScores, 'NPTT_PAPARAN');
      double nt = _getScore(actualScores, 'NT') > 0
          ? _getScore(actualScores, 'NT')
          : ScoringCalculator.hitungNT(nam: ntMateri, nkm: ntPenulisan, nkp: ntPaparan);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.sm),
          _ExpandableCompetencyGroup(
            title: 'NAMP - Nilai Akhir Mata Pelajaran (60%)',
            score: namp,
            children: [
              _CompetencyItem(
                title: 'NUMP - Ujian Mata Pelajaran / Esai (30%)',
                score: ujianMp,
              ),
              const SizedBox(height: AppDimensions.sm),
              _ExpandableCompetencyGroup(
                title: 'NKKP - Naskah Kuliah Kerja Profesi (5%)',
                score: nkkp,
                children: [
                  _SubCompetencyItem(title: 'NMPN - Nilai Materi & Penulisan (35%)', score: nkkpMateri),
                  _SubCompetencyItem(title: 'NPa - Paparan (35%)', score: nkkpPaparan),
                  _SubCompetencyItem(title: 'NKa - Keaktifan (30%)', score: nkkpKeaktifan),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              _ExpandableCompetencyGroup(
                title: 'NPKP - Naskah Praktik Kerja Profesi (5%)',
                score: npkp,
                children: [
                  _SubCompetencyItem(title: 'NMPN - Nilai Materi & Penulisan (35%)', score: npkpMateri),
                  _SubCompetencyItem(title: 'NPa - Paparan (35%)', score: npkpPaparan),
                  _SubCompetencyItem(title: 'NKa - Keaktifan (30%)', score: npkpKeaktifan),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
              _ExpandableCompetencyGroup(
                title: 'NKP - Naskah Karya Perseorangan (60%)',
                score: nkp,
                children: [
                  _SubCompetencyItem(title: 'NMPN - Nilai Materi & Penulisan (50%)', score: nkpMateri),
                  _SubCompetencyItem(title: 'NPa - Paparan (50%)', score: nkpPaparan),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
          _ExpandableCompetencyGroup(
            title: 'NSK - Simulasi Kepemimpinan Kontemporer (10%)',
            score: nsk,
            children: [
              _SubCompetencyItem(title: 'NKaP - Keaktifan Perseorangan (60%)', score: nskAktif),
              _SubCompetencyItem(title: 'NPP - Produk Perseorangan (20%)', score: nskProduk),
              _SubCompetencyItem(title: 'NTR - Tata Ruang Kelompok (20%)', score: nskRuang),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
          _ExpandableCompetencyGroup(
            title: 'NT - Naskah Program Transformasi Teknis (Taskap) (30%)',
            score: nt,
            children: [
              _SubCompetencyItem(title: 'NAm - Materi NPTT/Taskap (40%)', score: ntMateri),
              _SubCompetencyItem(title: 'NKm - Penulisan NPTT/Taskap (30%)', score: ntPenulisan),
              _SubCompetencyItem(title: 'NKp - Paparan dan Diskusi (30%)', score: ntPaparan),
            ],
          ),
        ],
      );
    } else if (category == 'Kesehatan') {
      final Map<String, dynamic> actualScores = rawScores ?? {};
      double kesAwal = _getScore(actualScores, 'TES_AWAL') > 0 ? _getScore(actualScores, 'TES_AWAL') : _getScore(actualScores, 'nilai_awal');
      double kesAkhir = _getScore(actualScores, 'TES_AKHIR') > 0 ? _getScore(actualScores, 'TES_AKHIR') : _getScore(actualScores, 'nilai_akhir');
      double kesStatus = _getScore(actualScores, 'STATUS_KESEHATAN') > 0
          ? _getScore(actualScores, 'STATUS_KESEHATAN')
          : (_getScore(actualScores, 'nilai_status') > 0 ? _getScore(actualScores, 'nilai_status') : 80.00);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.sm),
          _CompetencyItem(title: 'Tes Kesehatan Awal (A)', score: kesAwal),
          _CompetencyItem(title: 'Tes Kesehatan Akhir (B)', score: kesAkhir),
          _CompetencyItem(title: 'Status Kesehatan Selama Pendidikan (C)', score: kesStatus),
        ],
      );
    } else {
      final Map<String, dynamic> actualScores = rawScores ?? {};

      double samaptaA = _getAnyScore(actualScores, ['SAMAPTA_A', 'LARI', 'NGA', 'P1', 'JALAN_KAKI']);
      double pullUp = _getAnyScore(actualScores, ['PULL_UP', 'CHINNING', 'NGB1', 'P21']);
      double sitUp = _getAnyScore(actualScores, ['SIT_UP', 'NGB2', 'P22']);
      double pushUp = _getAnyScore(actualScores, ['PUSH_UP', 'NGB3', 'P23']);
      double shuttleRun = _getAnyScore(actualScores, ['SHUTTLE_RUN', 'NGB4', 'P24']);

      String? textSamaptaA = _getRawText(actualScores, ['SAMAPTA_A', 'LARI', 'NGA', 'P1', 'JALAN_KAKI'], 'Meter');
      String? textPullUp = _getRawText(actualScores, ['PULL_UP', 'CHINNING', 'NGB1', 'P21'], 'Kali');
      String? textSitUp = _getRawText(actualScores, ['SIT_UP', 'NGB2', 'P22'], 'Kali');
      String? textPushUp = _getRawText(actualScores, ['PUSH_UP', 'NGB3', 'P23'], 'Kali');
      String? textShuttleRun = _getRawText(actualScores, ['SHUTTLE_RUN', 'NGB4', 'P24'], 'Detik');

      double samaptaB = _getAnyScore(actualScores, ['SAMAPTA_B', 'NGB']);
      if (samaptaB == 0) {
        samaptaB = ScoringCalculator.hitungNGB(ngb1: pullUp, ngb2: sitUp, ngb3: pushUp, ngb4: shuttleRun);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.sm),
          _CompetencyItem(
            title: 'Samapta A (Lari / Jalan 12 Menit)',
            score: samaptaA,
            rawText: textSamaptaA,
          ),
          _ExpandableCompetencyGroup(
            title: 'Samapta B',
            score: samaptaB,
            children: [
              _SubCompetencyItem(title: 'Pull Up (1 menit)', score: pullUp, rawText: textPullUp),
              _SubCompetencyItem(title: 'Sit Up (1 menit)', score: sitUp, rawText: textSitUp),
              _SubCompetencyItem(title: 'Push Up (1 menit)', score: pushUp, rawText: textPushUp),
              _SubCompetencyItem(
                title: 'Shuttle Run (6x10m)',
                score: shuttleRun,
                rawText: textShuttleRun,
              ),
            ],
          ),
        ],
      );
    }
  }
}

class _CompetencyItem extends StatelessWidget {
  final String title;
  final double score;
  final String? rawText;

  const _CompetencyItem({
    required this.title,
    required this.score,
    this.rawText,
  });

  String get _status {
    if (score == 0) return '';
    if (score >= 85.00) return 'Sangat Memuaskan (SM)';
    if (score >= 80.00) return 'Memuaskan (M)';
    if (score >= 75.00) return 'Baik (B)';
    if (score >= 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  Color get _borderColor {
    if (score == 0) return Colors.grey.shade100;
    if (score >= 85.00) return Colors.green.shade300;
    if (score >= 80.00) return Colors.lightGreen.shade300;
    if (score >= 75.00) return Colors.blue.shade200;
    if (score >= 70.00) return Colors.amber.shade200;
    return Colors.red.shade200;
  }

  Color get _iconBgColor {
    if (score == 0) return const Color(0xFFF0F4F8);
    if (score >= 85.00) return Colors.green.shade50;
    if (score >= 80.00) return Colors.lightGreen.shade50;
    if (score >= 75.00) return Colors.blue.shade50;
    if (score >= 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  Color get _statusColor {
    if (score == 0) return Colors.blueGrey.shade500;
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  Color get _scoreColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  IconData get _iconData {
    if (score == 0) return AppIcons.minusCircle;
    if (score > 70.00) return AppIcons.checkCircle;
    return AppIcons.warningCircle;
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = title;
    String? weight;
    if (title.contains('(') && title.contains(')')) {
      final start = title.lastIndexOf('(');
      final end = title.lastIndexOf(')');
      if (start < end && title.substring(start + 1, end).contains('%')) {
        weight = title.substring(start + 1, end);
        displayTitle = title.substring(0, start).trim();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: AppDimensions.radiusLg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl - 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: _iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconData,
                    color: _iconColor,
                    size: AppDimensions.iconMd,
                  ),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (weight != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF001C40,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Text(
                                weight,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontXs,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF001C40),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF001C40),
                                  height: 1.25,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF001C40),
                            height: 1.25,
                          ),
                          softWrap: true,
                        ),
                      if (_status.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          _status,
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs + 2,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score > 0 ? score.toStringAsFixed(2) : '-',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w800,
                        color: _scoreColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (rawText != null && rawText!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        rawText!,
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableCompetencyGroup extends StatelessWidget {
  final String title;
  final double score;
  final List<Widget> children;

  const _ExpandableCompetencyGroup({
    required this.title,
    required this.score,
    required this.children,
  });

  String get _status {
    if (score == 0) return '';
    if (score >= 85.00) return 'Sangat Memuaskan (SM)';
    if (score >= 80.00) return 'Memuaskan (M)';
    if (score >= 75.00) return 'Baik (B)';
    if (score >= 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  Color get _borderColor {
    if (score == 0) return Colors.grey.shade100;
    if (score >= 85.00) return Colors.green.shade300;
    if (score >= 80.00) return Colors.lightGreen.shade300;
    if (score >= 75.00) return Colors.blue.shade200;
    if (score >= 70.00) return Colors.amber.shade200;
    return Colors.red.shade200;
  }

  Color get _iconBgColor {
    if (score == 0) return const Color(0xFFF0F4F8);
    if (score >= 85.00) return Colors.green.shade50;
    if (score >= 80.00) return Colors.lightGreen.shade50;
    if (score >= 75.00) return Colors.blue.shade50;
    if (score >= 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  Color get _statusColor {
    if (score == 0) return Colors.blueGrey.shade500;
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  Color get _scoreColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score >= 85.00) return Colors.green.shade700;
    if (score >= 80.00) return Colors.lightGreen.shade700;
    if (score >= 75.00) return Colors.blue.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  IconData get _iconData {
    if (score == 0) return AppIcons.minusCircle;
    if (score > 70.00) return AppIcons.checkCircle;
    return AppIcons.warningCircle;
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = title;
    String? weight;
    if (title.contains('(') && title.contains(')')) {
      final start = title.lastIndexOf('(');
      final end = title.lastIndexOf(')');
      if (start < end && title.substring(start + 1, end).contains('%')) {
        weight = title.substring(start + 1, end);
        displayTitle = title.substring(0, start).trim();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: AppDimensions.radiusLg,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xl - 4,
              vertical: AppDimensions.sm,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppDimensions.xl - 4,
              0,
              AppDimensions.xl - 4,
              AppDimensions.md,
            ),
            iconColor: const Color(0xFF001C40),
            collapsedIconColor: Colors.blueGrey.shade400,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: _iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconData,
                    color: _iconColor,
                    size: AppDimensions.iconMd,
                  ),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (weight != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF001C40,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                              ),
                              child: Text(
                                weight,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontXs,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF001C40),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.sm),
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF001C40),
                                  height: 1.25,
                                ),
                                softWrap: true,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF001C40),
                            height: 1.25,
                          ),
                          softWrap: true,
                        ),
                      if (_status.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          _status,
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs + 2,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    score > 0 ? score.toStringAsFixed(2) : '-',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w800,
                      color: _scoreColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            children: [
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: AppDimensions.sm),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCompetencyItem extends StatelessWidget {
  final String title;
  final double score;
  final String? rawText;

  const _SubCompetencyItem({
    required this.title,
    required this.score,
    this.rawText,
  });

  Color get _scoreBgColor {
    if (score == 0) return Colors.blueGrey.shade50;
    if (score >= 85.00) return Colors.green.shade50;
    if (score >= 80.00) return Colors.lightGreen.shade50;
    if (score >= 75.00) return Colors.blue.shade50;
    if (score >= 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _scoreTextColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score >= 85.00) return Colors.green.shade800;
    if (score >= 80.00) return Colors.lightGreen.shade800;
    if (score >= 75.00) return Colors.blue.shade800;
    if (score >= 70.00) return Colors.amber.shade900;
    return Colors.red.shade800;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score >= 85.00) return Colors.green.shade400;
    if (score >= 80.00) return Colors.lightGreen.shade400;
    if (score >= 75.00) return Colors.blue.shade400;
    if (score >= 70.00) return Colors.amber.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    String displayTitle = title;
    String? weight;
    if (title.contains('(') && title.contains(')')) {
      final start = title.lastIndexOf('(');
      final end = title.lastIndexOf(')');
      if (start < end && title.substring(start + 1, end).contains('%')) {
        weight = title.substring(start + 1, end);
        displayTitle = title.substring(0, start).trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  AppIcons.circle,
                  size: AppDimensions.iconXs - 4,
                  color: _iconColor,
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Row(
                    children: [
                      if (weight != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF001C40,
                            ).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            weight,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontXs - 1,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF001C40),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTitle,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                            if (rawText != null && rawText!.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                rawText!,
                                style: TextStyle(
                                  fontSize: AppDimensions.fontXs - 1,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Container(
            width: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _scoreBgColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              score > 0 ? score.toStringAsFixed(2) : '-',
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w800,
                color: _scoreTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}



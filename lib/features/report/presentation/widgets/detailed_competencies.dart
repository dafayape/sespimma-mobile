import 'package:flutter/material.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assessment/data/models/health_record_mock_data.dart';
import 'package:sespimma/features/assessment/data/models/serdik_academic_scores.dart';
import 'package:sespimma/core/utils/scoring_calculator.dart';
import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';

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
    return (val as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (category == 'Mental Kepribadian') {
      final Map<String, dynamic> actualScores;
      if (rawScores != null && rawScores!.isNotEmpty) {
        actualScores = rawScores!;
      } else {
        final allRecaps = ScoreCalculatorService.generateRealReports();
        final recap = allRecaps.firstWhere(
          (r) => r.id == user.noSerdik,
          orElse: () => allRecaps.first,
        );
        actualScores = recap.rawScores;
      }

      double moral = _getScore(actualScores, 'moral');
      double disiplin = _getScore(actualScores, 'disiplin');
      double kepemimpinan = _getScore(actualScores, 'kepemimpinan');
      double pengendalian = _getScore(actualScores, 'pengendalian_diri');
      double penampilan = _getScore(actualScores, 'penampilan');
      double ns = _getScore(actualScores, 'SOSIOMETRI') > 0 ? _getScore(actualScores, 'SOSIOMETRI') : _getScore(actualScores, 'NS');

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
      final Map<String, dynamic> actualScores;
      if (rawScores != null && rawScores!.isNotEmpty) {
        actualScores = rawScores!;
      } else {
        actualScores = {};
      }

      double ujianMp = _getScore(actualScores, 'UJIAN_MAPEL');
      double nkkpMateri = _getScore(actualScores, 'NKKP_MATERI');
      double nkkpPaparan = _getScore(actualScores, 'NKKP_PAPARAN');
      double nkkpKeaktifan = _getScore(actualScores, 'NKKP_KEAKTIFAN');
      double nkkp = ScoringCalculator.hitungNKKPatauNPKP(nmpn: nkkpMateri, npa: nkkpPaparan, nka: nkkpKeaktifan);

      double npkpMateri = _getScore(actualScores, 'NPKP_MATERI');
      double npkpPaparan = _getScore(actualScores, 'NPKP_PAPARAN');
      double npkpKeaktifan = _getScore(actualScores, 'NPKP_KEAKTIFAN');
      double npkp = ScoringCalculator.hitungNKKPatauNPKP(nmpn: npkpMateri, npa: npkpPaparan, nka: npkpKeaktifan);

      double nkpMateri = _getScore(actualScores, 'NKP_MATERI');
      double nkpPaparan = _getScore(actualScores, 'NKP_PAPARAN');
      double nkp = ScoringCalculator.hitungNKP(nmpn: nkpMateri, npa: nkpPaparan);

      double np = ScoringCalculator.hitungNP(nump: ujianMp, nkkp: nkkp, npkp: npkp, nkp: nkp);

      double nskAktif = _getScore(actualScores, 'KEAKTIFAN_PERSEORANGAN');
      double nskProduk = _getScore(actualScores, 'PRODUK_PERSEORANGAN');
      double nskRuang = _getScore(actualScores, 'TATA_RUANG_KELOMPOK');
      double nsk = ScoringCalculator.hitungNSK(keaktifan: nskAktif, produk: nskProduk, tataRuang: nskRuang);

      double ntMateri = _getScore(actualScores, 'NPTT_MATERI');
      double ntPenulisan = _getScore(actualScores, 'NPTT_PENULISAN');
      double ntPaparan = _getScore(actualScores, 'NPTT_PAPARAN');
      double nt = ScoringCalculator.hitungNT(nam: ntMateri, nkm: ntPenulisan, nkp: ntPaparan);

      if (actualScores.isEmpty) {
        final mockScores = SerdikAcademicScores.getScores(user.noSerdik);
        ujianMp = (mockScores['nump'] as num?)?.toDouble() ?? 0.0;
        nkkp = (mockScores['nkkp'] as num?)?.toDouble() ?? 0.0;
        nkkpMateri = nkkp; nkkpPaparan = nkkp; nkkpKeaktifan = nkkp;
        npkp = (mockScores['npkp'] as num?)?.toDouble() ?? 0.0;
        npkpMateri = npkp; npkpPaparan = npkp; npkpKeaktifan = npkp;
        nkp = (mockScores['nkp'] as num?)?.toDouble() ?? 0.0;
        nkpMateri = nkp; nkpPaparan = nkp;
        np = (mockScores['np'] as num?)?.toDouble() ?? 0.0;
        nskAktif = (mockScores['nsk_keaktifan'] as num?)?.toDouble() ?? 0.0;
        nskProduk = (mockScores['nsk_produk'] as num?)?.toDouble() ?? 0.0;
        nskRuang = (mockScores['nsk_tata_ruang'] as num?)?.toDouble() ?? 0.0;
        nsk = (mockScores['nsk'] as num?)?.toDouble() ?? 0.0;
        ntMateri = (mockScores['nt_materi'] as num?)?.toDouble() ?? 0.0;
        ntPenulisan = (mockScores['nt_penulisan'] as num?)?.toDouble() ?? 0.0;
        ntPaparan = (mockScores['nt_paparan'] as num?)?.toDouble() ?? 0.0;
        nt = (mockScores['nt'] as num?)?.toDouble() ?? 0.0;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.sm),
          _SectionTitle(title: 'Nilai Pelajaran (60%)', score: np),
          _CompetencyItem(title: 'Ujian Mata Pelajaran atau Esai (30%)', score: ujianMp),
          _ExpandableCompetencyGroup(
            title: 'Naskah Kuliah Kerja Profesi (5%)',
            score: nkkp,
            children: [
              _SubCompetencyItem(title: 'Materi & Penulisan (35%)', score: nkkpMateri),
              _SubCompetencyItem(title: 'Paparan (35%)', score: nkkpPaparan),
              _SubCompetencyItem(title: 'Keaktifan (30%)', score: nkkpKeaktifan),
            ],
          ),
          _ExpandableCompetencyGroup(
            title: 'Naskah Praktek Kerja Profesi (5%)',
            score: npkp,
            children: [
              _SubCompetencyItem(title: 'Materi & Penulisan (35%)', score: npkpMateri),
              _SubCompetencyItem(title: 'Paparan (35%)', score: npkpPaparan),
              _SubCompetencyItem(title: 'Keaktifan (30%)', score: npkpKeaktifan),
            ],
          ),
          _ExpandableCompetencyGroup(
            title: 'Naskah Karya Perseorangan (60%)',
            score: nkp,
            children: [
              _SubCompetencyItem(title: 'Materi & Penulisan (50%)', score: nkpMateri),
              _SubCompetencyItem(title: 'Paparan (50%)', score: nkpPaparan),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
          _SectionTitle(title: 'Simulasi Kepemimpinan Kontemporer (10%)', score: nsk),
          _ExpandableCompetencyGroup(
            title: 'Simulasi Kepemimpinan',
            score: nsk,
            children: [
              _SubCompetencyItem(title: 'Keaktifan Perseorangan (60%)', score: nskAktif),
              _SubCompetencyItem(title: 'Produk Perseorangan (20%)', score: nskProduk),
              _SubCompetencyItem(title: 'Tata Ruang Kelompok (20%)', score: nskRuang),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
          _SectionTitle(title: 'Naskah Program Transformasi Teknis (30%)', score: nt),
          _ExpandableCompetencyGroup(
            title: 'Program Transformasi Teknis',
            score: nt,
            children: [
              _SubCompetencyItem(title: 'Materi (40%)', score: ntMateri),
              _SubCompetencyItem(title: 'Penulisan Efektif (30%)', score: ntPenulisan),
              _SubCompetencyItem(title: 'Paparan & Diskusi (30%)', score: ntPaparan),
            ],
          ),
        ],
      );
    } else {
      final Map<String, dynamic> actualScores;
      if (rawScores != null && rawScores!.isNotEmpty) {
        actualScores = rawScores!;
      } else {
        actualScores = {};
      }

      double kesAwal = _getScore(actualScores, 'TES_AWAL');
      double kesAkhir = _getScore(actualScores, 'TES_AKHIR');
      double kesStatus = _getScore(actualScores, 'STATUS_KESEHATAN');

      double samaptaA = _getScore(actualScores, 'SAMAPTA_A');
      double pullUp = _getScore(actualScores, 'PULL_UP');
      double sitUp = _getScore(actualScores, 'SIT_UP');
      double pushUp = _getScore(actualScores, 'PUSH_UP');
      double shuttleRun = _getScore(actualScores, 'SHUTTLE_RUN');

      if (actualScores.isEmpty) {
        kesAwal = 0.0;
        kesAkhir = 0.0;
        int poliVisits = 0;
        int tpsDays = 0;
        int rsDays = 0;
        for (var item in HealthRecordMockData.items) {
          if (item.nosis == user.noSerdik) {
            if (item.type == 'Poliklinik') {
              poliVisits += item.value;
            } else if (item.type == 'Rawat TPS') {
              tpsDays += item.value;
            } else if (item.type == 'Rawat RS') {
              rsDays += item.value;
            }
          }
        }
        double kesPengurangan = 0.0;
        if (poliVisits > 0) kesPengurangan += (poliVisits / 5).ceil();
        if (tpsDays > 0) kesPengurangan += (tpsDays / 2).ceil();
        if (rsDays > 0) kesPengurangan += (rsDays * 2);

        kesStatus = 80.0 - kesPengurangan;
        samaptaA = 0.0;
        pullUp = 0.0;
        sitUp = 0.0;
        pushUp = 0.0;
        shuttleRun = 0.0;
      }

      double kesehatan = ScoringCalculator.hitungNKes(tesAwal: kesAwal, tesAkhir: kesAkhir, statusKesehatan: kesStatus);
      double samaptaB = ScoringCalculator.hitungNGB(ngb1: pullUp, ngb2: sitUp, ngb3: pushUp, ngb4: shuttleRun);
      double jasmani = ScoringCalculator.hitungNJas(nga: samaptaA, ngb: samaptaB);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Kesehatan (40%)', score: kesehatan),
          _ExpandableCompetencyGroup(
            title: 'Pemeriksaan dan Riwayat',
            score: kesehatan,
            children: [
              _SubCompetencyItem(
                title: 'Tes Kesehatan Awal (A)',
                score: kesAwal,
              ),
              _SubCompetencyItem(
                title: 'Tes Kesehatan Akhir (B)',
                score: kesAkhir,
              ),
              _SubCompetencyItem(
                title: 'Status Kesehatan Selama Pendidikan (C)',
                score: kesStatus,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.lg),
          _SectionTitle(title: 'Jasmani (60%)', score: jasmani),
          _CompetencyItem(
            title: 'Samapta A (Lari atau Jalan 12 Menit)',
            score: samaptaA,
          ),
          _ExpandableCompetencyGroup(
            title: 'Samapta B',
            score: samaptaB,
            children: [
              _SubCompetencyItem(title: 'Pull Up (1 menit)', score: pullUp),
              _SubCompetencyItem(title: 'Sit Up (1 menit)', score: sitUp),
              _SubCompetencyItem(title: 'Push Up (1 menit)', score: pushUp),
              _SubCompetencyItem(
                title: 'Shuttle Run (6x10m)',
                score: shuttleRun,
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

  const _CompetencyItem({required this.title, required this.score});

  String get _status {
    if (score == 0) return 'Belum Nilai (BN)';
    if (score > 85.00) return 'Sangat Memuaskan (SM)';
    if (score > 80.00) return 'Memuaskan (M)';
    if (score > 75.00) return 'Baik (B)';
    if (score > 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  Color get _borderColor {
    if (score == 0) return Colors.grey.shade100;
    if (score > 85.00) return Colors.green.shade200;
    if (score > 80.00) return Colors.lightGreen.shade200;
    if (score > 75.00) return Colors.orange.shade200;
    if (score > 70.00) return Colors.amber.shade200;
    return Colors.red.shade200;
  }

  Color get _iconBgColor {
    if (score == 0) return const Color(0xFFF0F4F8);
    if (score > 85.00) return Colors.green.shade50;
    if (score > 80.00) return Colors.lightGreen.shade50;
    if (score > 75.00) return Colors.orange.shade50;
    if (score > 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score > 85.00) return Colors.green.shade700;
    if (score > 80.00) return Colors.lightGreen.shade700;
    if (score > 75.00) return Colors.orange.shade700;
    if (score > 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  Color get _statusColor {
    if (score == 0) return Colors.blueGrey.shade500;
    if (score > 85.00) return Colors.green.shade600;
    if (score > 80.00) return Colors.lightGreen.shade600;
    if (score > 75.00) return Colors.orange.shade600;
    if (score > 70.00) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  Color get _scoreColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score > 85.00) return Colors.green.shade700;
    if (score > 80.00) return Colors.lightGreen.shade700;
    if (score > 75.00) return Colors.orange.shade700;
    if (score > 70.00) return Colors.amber.shade700;
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
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                          ),
                        ),
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
    if (score == 0) return 'Belum Nilai (BN)';
    if (score > 85.00) return 'Sangat Memuaskan (SM)';
    if (score > 80.00) return 'Memuaskan (M)';
    if (score > 75.00) return 'Baik (B)';
    if (score > 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  Color get _borderColor {
    if (score == 0) return Colors.grey.shade100;
    if (score > 85.00) return Colors.green.shade200;
    if (score > 80.00) return Colors.lightGreen.shade200;
    if (score > 75.00) return Colors.orange.shade200;
    if (score > 70.00) return Colors.amber.shade200;
    return Colors.red.shade200;
  }

  Color get _iconBgColor {
    if (score == 0) return const Color(0xFFF0F4F8);
    if (score > 85.00) return Colors.green.shade50;
    if (score > 80.00) return Colors.lightGreen.shade50;
    if (score > 75.00) return Colors.orange.shade50;
    if (score > 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score > 85.00) return Colors.green.shade700;
    if (score > 80.00) return Colors.lightGreen.shade700;
    if (score > 75.00) return Colors.orange.shade700;
    if (score > 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  Color get _statusColor {
    if (score == 0) return Colors.blueGrey.shade500;
    if (score > 85.00) return Colors.green.shade600;
    if (score > 80.00) return Colors.lightGreen.shade600;
    if (score > 75.00) return Colors.orange.shade600;
    if (score > 70.00) return Colors.amber.shade700;
    return Colors.red.shade600;
  }

  Color get _scoreColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score > 85.00) return Colors.green.shade700;
    if (score > 80.00) return Colors.lightGreen.shade700;
    if (score > 75.00) return Colors.orange.shade700;
    if (score > 70.00) return Colors.amber.shade700;
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
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                          ),
                        ),
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

  const _SubCompetencyItem({required this.title, required this.score});

  Color get _scoreBgColor {
    if (score == 0) return Colors.blueGrey.shade50;
    if (score > 85.00) return Colors.green.shade50;
    if (score > 80.00) return Colors.lightGreen.shade50;
    if (score > 75.00) return Colors.orange.shade50;
    if (score > 70.00) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color get _scoreTextColor {
    if (score == 0) return const Color(0xFF001C40);
    if (score > 85.00) return Colors.green.shade800;
    if (score > 80.00) return Colors.lightGreen.shade800;
    if (score > 75.00) return Colors.orange.shade800;
    if (score > 70.00) return Colors.amber.shade900;
    return Colors.red.shade800;
  }

  Color get _iconColor {
    if (score == 0) return Colors.blueGrey.shade400;
    if (score > 85.00) return Colors.green.shade400;
    if (score > 80.00) return Colors.lightGreen.shade400;
    if (score > 75.00) return Colors.orange.shade400;
    if (score > 70.00) return Colors.amber.shade400;
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
                        child: Text(
                          displayTitle,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final double score;

  const _SectionTitle({required this.title, required this.score});

  MaterialColor get _color {
    if (score == 0) return Colors.blueGrey;
    if (score > 85.00) return Colors.green;
    if (score > 80.00) return Colors.lightGreen;
    if (score > 75.00) return Colors.orange;
    if (score > 70.00) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

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
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xs,
        AppDimensions.sm,
        AppDimensions.xs,
        AppDimensions.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (weight != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF001C40).withValues(alpha: 0.08),
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
                ],
                Expanded(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF001C40),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              score.toStringAsFixed(2),
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w800,
                color: score == 0 ? const Color(0xFF001C40) : color.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

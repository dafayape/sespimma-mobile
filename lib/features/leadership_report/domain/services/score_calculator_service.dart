import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/features/assessment/data/models/health_record_mock_data.dart';
import 'package:sespimma/features/assessment/data/models/jasmani_grading_data.dart';
import 'package:sespimma/features/assessment/data/datasources/jasmani_lookup_tables.dart';
import 'package:sespimma/features/leadership_report/data/models/final_recap_model.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:sespimma/core/utils/scoring_calculator.dart';
import 'package:sespimma/features/assessment/data/models/serdik_mental_scores.dart';

class ScoreCalculatorService {
  static List<FinalRecapModel> generateRealReports() {
    return SerdikRealData.records.map((serdik) {
      final String noSerdik = serdik['no_serdik'] ?? '';

      final raw = generateSimulatedScores(noSerdik);

      return calculateFinalRecap(serdik, raw);
    }).toList();
  }

  static FinalRecapModel calculateFinalRecap(
    Map<String, dynamic> serdikData,
    Map<String, dynamic> raw,
  ) {
    double nmpn = _getDouble(raw, 'NMPN');
    double npa = _getDouble(raw, 'NPa');
    double nka = _getDouble(raw, 'NKa');
    double nump = _getDouble(raw, 'NUMP');

    double nkkp = ScoringCalculator.hitungNKKPatauNPKP(
      nmpn: nmpn,
      npa: npa,
      nka: nka,
    );
    double npkp = ScoringCalculator.hitungNKKPatauNPKP(
      nmpn: nmpn,
      npa: npa,
      nka: nka,
    );

    List<double> nkpTasks =
        (raw['NKP_tasks'] as List<dynamic>?)
            ?.map((e) => e as double)
            .toList() ??
        [];
    double nkp = nkpTasks.isEmpty
        ? ScoringCalculator.hitungNKP(nmpn: nmpn, npa: npa)
        : nkpTasks.reduce((a, b) => a + b) / nkpTasks.length;

    double np = ScoringCalculator.hitungNP(
      nump: nump,
      nkkp: nkkp,
      npkp: npkp,
      nkp: nkp,
    );

    double keaktifan = _getDouble(raw, 'keaktifan_sk');
    double produk = _getDouble(raw, 'produk_sk');
    double tataRuang = _getDouble(raw, 'tataruang_sk');
    double nsk = ScoringCalculator.hitungNSK(
      keaktifan: keaktifan,
      produk: produk,
      tataRuang: tataRuang,
    );

    double nam = _getDouble(raw, 'NAm');
    double nkm = _getDouble(raw, 'NKm');
    double nkp2 = _getDouble(raw, 'NKp');
    double nt = ScoringCalculator.hitungNT(nam: nam, nkm: nkm, nkp: nkp2);

    double na = ScoringCalculator.hitungNA(np: np, nsk: nsk, nt: nt);

    double moral = _getDouble(raw, 'moral');
    double disiplin = _getDouble(raw, 'disiplin');
    double kepemimpinan = _getDouble(raw, 'kepemimpinan');
    double pengendalianDiri = _getDouble(raw, 'pengendalian_diri');
    double penampilan = _getDouble(raw, 'penampilan');

    double dynamicReward = 0.0;
    double dynamicPunishment = 0.0;

    for (var item in KorsisInboxMockData.items) {
      final bool isDirectOrApproved =
          item.status == 'approved' ||
          item.status == 'disetujui' ||
          item.senderName.toLowerCase().contains('korsis') ||
          item.senderName.toLowerCase().contains('sistem');

      if (item.nosis == serdikData['no_serdik'] &&
          isDirectOrApproved &&
          !item.isIzin) {
        bool appliedToAspect = false;

        if (item.rewardPunishmentId != null) {
          try {
            final rule = RewardPunishmentData.rules.firstWhere(
              (r) => r.id == item.rewardPunishmentId,
            );

            final double pointValue = item.isReward
                ? item.points
                : -item.points.abs();

            switch (rule.aspect.toUpperCase()) {
              case 'MORAL':
                moral += pointValue;
                appliedToAspect = true;
                break;
              case 'DISIPLIN':
                disiplin += pointValue;
                appliedToAspect = true;
                break;
              case 'KEPEMIMPINAN':
                kepemimpinan += pointValue;
                appliedToAspect = true;
                break;
              case 'PENGENDALIAN DIRI':
                pengendalianDiri += pointValue;
                appliedToAspect = true;
                break;
              case 'PENAMPILAN':
                penampilan += pointValue;
                appliedToAspect = true;
                break;
            }
          } catch (e) {
            appliedToAspect = false;
          }
        }

        if (!appliedToAspect) {
          if (item.isReward) {
            dynamicReward += item.points;
          } else {
            dynamicPunishment += item.points.abs();
          }
        }
      }
    }

    double reward = _getDouble(raw, 'reward_mental') + dynamicReward;
    double punishment =
        _getDouble(raw, 'punishment_mental') + dynamicPunishment;

    double nku = ScoringCalculator.hitungNKU(
      moral: moral,
      disiplin: disiplin,
      kepemimpinan: kepemimpinan,
      pengendalianDiri: pengendalianDiri,
      penampilan: penampilan,
    );

    double nilaiPengamatan = nku + reward - punishment;

    double ns = _getDouble(raw, 'NS');

    double nk = ScoringCalculator.hitungNK(
      moral: moral,
      disiplin: disiplin,
      kepemimpinan: kepemimpinan,
      pengendalianDiri: pengendalianDiri,
      penampilan: penampilan,
      sosiometri: ns,
    ) + reward - punishment;

    double kesA = _getDouble(raw, 'kes_awal');
    double kesB = _getDouble(raw, 'kes_akhir');

    int poliVisits = 0;
    int tpsDays = 0;
    int rsDays = 0;
    for (var item in HealthRecordMockData.items) {
      if (item.nosis == serdikData['no_serdik']) {
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

    double kesC = 80.0 - kesPengurangan;

    double nkes = ScoringCalculator.hitungNKes(
      tesAwal: kesA,
      tesAkhir: kesB,
      statusKesehatan: kesC,
    );

    final String noSerdik = serdikData['no_serdik'] ?? '';
    final String tanggalLahir = serdikData['tanggal_lahir'] ?? '';
    final String golongan = JasmaniLookupTables.getGolongan(tanggalLahir);
    final JasmaniGradingData jasmaniData = JasmaniGradingData.getJasmaniData(
      noSerdik,
    );

    double njas = 0.0;
    final bool isSamaptaA = jasmaniData.nilaiA != null;
    final bool isSamaptaB = jasmaniData.isSamaptaBComplete;
    final bool isPartiallyGraded = isSamaptaA || isSamaptaB;

    if (isPartiallyGraded) {
      njas = jasmaniData.getNilaiJasmani(golongan);
    }

    double nkj = ScoringCalculator.hitungNKJ(nKes: nkes, nJas: njas);

    return FinalRecapModel(
      id: serdikData['no_serdik'] ?? '',
      name: serdikData['nama_lengkap'] ?? '',
      nrp: serdikData['nrp'] ?? '',
      nosis: serdikData['no_serdik'] ?? '',
      pangkat: serdikData['pangkat'] ?? '',
      pokjar: _formatPokjar(serdikData['kelompok_kelas'] ?? ''),
      academicScore: na,
      mentalScore: nk,
      physicalScore: nkj,
      tanggalLahir: serdikData['tanggal_lahir'] ?? '1985-01-01',
      jenisKelamin: serdikData['jenis_kelamin'] ?? 'Pria',
      rawScores: {
        'NKKP': nkkp,
        'NPKP': npkp,
        'NKP': nkp,
        'NP': np,
        'NSK': nsk,
        'NT': nt,
        'NA': na,
        'NilaiPengamatan': nilaiPengamatan,
        'NS': ns,
        'NK': nk,
        'NKes': nkes,
        'NJas': njas,
        'NKJ': nkj,
        'moral': moral,
        'disiplin': disiplin,
        'kepemimpinan': kepemimpinan,
        'pengendalian_diri': pengendalianDiri,
        'penampilan': penampilan,
      },
    );
  }

  static double _getDouble(Map<String, dynamic> raw, String key) {
    if (!raw.containsKey(key)) return 0.0;
    return (raw[key] as num).toDouble();
  }

  static String _formatPokjar(String pokjar) {
    String p = pokjar.toUpperCase().trim();
    if (p.endsWith(' 1')) return 'POKJAR I';
    if (p.endsWith(' 2')) return 'POKJAR II';
    if (p.endsWith(' 3')) return 'POKJAR III';
    if (p.endsWith(' 4')) return 'POKJAR IV';
    if (p.endsWith(' 5')) return 'POKJAR V';
    return p;
  }

  static Map<String, dynamic> generateSimulatedScores(String noSerdik) {
    int hash = noSerdik.hashCode;

    double sim(double base, int varianceIndex) {
      double offset = ((hash >> varianceIndex) % 15) - 5;
      return base + offset;
    }

    return {
      'NMPN': sim(80, 0),
      'NPa': sim(80, 1),
      'NKa': sim(80, 2),
      'NUMP': sim(80, 3),

      'keaktifan_sk': sim(80, 4),
      'produk_sk': sim(80, 5),
      'tataruang_sk': sim(80, 6),

      'NAm': sim(82, 7),
      'NKm': sim(82, 8),
      'NKp': sim(82, 9),

      'reward_mental': 0.0,
      'punishment_mental': 0.0,
      'NS':
          ((SerdikMentalScores.getScores(noSerdik)['sosiometri_awal'] ?? 0.0) +
              (SerdikMentalScores.getScores(noSerdik)['sosiometri_akhir'] ??
                  0.0)) /
          2,

      'kes_awal': 0.0,
      'kes_akhir': 0.0,
      'kes_pengurangan': 0.0,

      'NGA': 0.0,
      'NGB1': 0.0,
      'NGB2': 0.0,
      'NGB3': 0.0,
      'NGB4': 0.0,

      'moral': SerdikMentalScores.getScores(noSerdik)['moral'] ?? 0.0,
      'disiplin': SerdikMentalScores.getScores(noSerdik)['disiplin'] ?? 0.0,
      'kepemimpinan':
          SerdikMentalScores.getScores(noSerdik)['kepemimpinan'] ?? 0.0,
      'pengendalian_diri':
          SerdikMentalScores.getScores(noSerdik)['pengendalian_diri'] ?? 0.0,
      'penampilan': SerdikMentalScores.getScores(noSerdik)['penampilan'] ?? 0.0,

      'NKP_tasks': List.generate(10, (i) => sim(80, (21 + i) % 31)),
    };
  }
}

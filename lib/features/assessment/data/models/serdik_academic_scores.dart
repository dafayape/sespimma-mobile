import 'package:sespimma/core/utils/scoring_calculator.dart';

class SerdikAcademicScores {
  static final Map<String, Map<String, dynamic>> _scores = {};

  static Map<String, dynamic> getScores(String noSerdik) {
    if (!_scores.containsKey(noSerdik)) {
      _scores[noSerdik] = {
        'nump': 85.0,
        'nkkp': 80.0,
        'npkp': 82.0,
        'nkp': 84.0,
        'nsk_keaktifan': 80.0,
        'nsk_produk': 85.0,
        'nsk_tata_ruang': 82.0,
        'nt_materi': 85.0,
        'nt_penulisan': 80.0,
        'nt_paparan': 82.0,
      };
    }

    final data = _scores[noSerdik]!;

    final np = ScoringCalculator.hitungNP(
      nump: data['nump'],
      nkkp: data['nkkp'],
      npkp: data['npkp'],
      nkp: data['nkp'],
    );

    final nsk = ScoringCalculator.hitungNSK(
      keaktifan: data['nsk_keaktifan'],
      produk: data['nsk_produk'],
      tataRuang: data['nsk_tata_ruang'],
    );

    final nt = ScoringCalculator.hitungNT(
      nam: data['nt_materi'],
      nkm: data['nt_penulisan'],
      nkp: data['nt_paparan'],
    );

    final na = ScoringCalculator.hitungNA(np: np, nsk: nsk, nt: nt);

    return {
      'nump': data['nump'],
      'nkkp': data['nkkp'],
      'npkp': data['npkp'],
      'nkp': data['nkp'],
      'np': np,
      'nsk_keaktifan': data['nsk_keaktifan'],
      'nsk_produk': data['nsk_produk'],
      'nsk_tata_ruang': data['nsk_tata_ruang'],
      'nsk': nsk,
      'nt_materi': data['nt_materi'],
      'nt_penulisan': data['nt_penulisan'],
      'nt_paparan': data['nt_paparan'],
      'nt': nt,
      'na': na,
    };
  }

  static void updateScore(String noSerdik, String category, double score) {
    if (!_scores.containsKey(noSerdik)) {
      getScores(noSerdik);
    }
    _scores[noSerdik]![category] = score;
  }
}

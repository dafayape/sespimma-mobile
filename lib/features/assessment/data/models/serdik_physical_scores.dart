import 'package:sespimma/core/utils/scoring_calculator.dart';

class SerdikPhysicalScores {
  static final Map<String, Map<String, dynamic>> _scores = {};

  static Map<String, dynamic> getScores(String noSerdik) {
    if (!_scores.containsKey(noSerdik)) {
      _scores[noSerdik] = {
        'tes_awal': 85.0,
        'tes_akhir': 85.0,
        'status_kesehatan': 85.0,
        'nga': 85.0,
        'ngb': 85.0,
      };
    }

    final data = _scores[noSerdik]!;

    final nKes = ScoringCalculator.hitungNKes(
      tesAwal: data['tes_awal'],
      tesAkhir: data['tes_akhir'],
      statusKesehatan: data['status_kesehatan'],
    );

    final nJas = ScoringCalculator.hitungNJas(
      nga: data['nga'],
      ngb: data['ngb'],
    );

    final nKj = ScoringCalculator.hitungNKJ(nKes: nKes, nJas: nJas);

    return {
      'tes_awal': data['tes_awal'],
      'tes_akhir': data['tes_akhir'],
      'status_kesehatan': data['status_kesehatan'],
      'nKes': nKes,
      'nga': data['nga'],
      'ngb': data['ngb'],
      'nJas': nJas,
      'nKj': nKj,
    };
  }

  static void updateScore(String noSerdik, String category, double score) {
    if (!_scores.containsKey(noSerdik)) {
      getScores(noSerdik);
    }
    _scores[noSerdik]![category] = score;
  }
}

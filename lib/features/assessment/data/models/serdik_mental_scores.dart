class SerdikMentalScores {
  static final Map<String, Map<String, dynamic>> _scores = {};

  static Map<String, dynamic> getScores(String noSerdik) {
    if (!_scores.containsKey(noSerdik)) {
      _scores[noSerdik] = {
        'moral': 80.0,
        'disiplin': 80.0,
        'kepemimpinan': 80.0,
        'pengendalian_diri': 80.0,
        'penampilan': 80.0,
        'sosiometri': 80.0,
        'nilai': 0.0,
      };
    }

    final data = _scores[noSerdik]!;

    double moral = data['moral'] ?? 80.0;
    double disiplin = data['disiplin'] ?? 80.0;
    double kepemimpinan = data['kepemimpinan'] ?? 80.0;
    double pengendalian = data['pengendalian_diri'] ?? 80.0;
    double penampilan = data['penampilan'] ?? 80.0;
    double sosiometri = data['sosiometri'] ?? 80.0;

    double nk = 0.0;
    if (moral > 0 ||
        disiplin > 0 ||
        kepemimpinan > 0 ||
        pengendalian > 0 ||
        penampilan > 0 ||
        sosiometri > 0) {
      nk = ((moral * 20) +
              (disiplin * 15) +
              (kepemimpinan * 20) +
              (pengendalian * 15) +
              (penampilan * 15) +
              (sosiometri * 15)) /
          100;
    }

    data['nilai'] = nk;
    return data;
  }

  static void updateScore(String noSerdik, String category, double score) {
    if (!_scores.containsKey(noSerdik)) {
      getScores(noSerdik);
    }
    _scores[noSerdik]![category] = score;

    getScores(noSerdik);
  }

  static double getNilai(String noSerdik, double fallback) {
    final scores = getScores(noSerdik);
    if (scores['nilai'] == 0.0) return fallback;
    return scores['nilai'] ?? fallback;
  }
}

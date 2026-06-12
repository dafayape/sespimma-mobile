abstract final class SamaptaScoringService {
  static double lookupScore(
    String exerciseName,
    String golongan,
    String gender,
    double rawValue,
  ) {
    if (rawValue <= 0) return 0.0;
    final bool isPria = gender != 'Perempuan';

    if (exerciseName.contains('Lari')) {
      return _scoreLari(golongan, isPria, rawValue);
    } else if (exerciseName.contains('Pull-up')) {
      return _scorePullUp(golongan, isPria, rawValue);
    } else if (exerciseName.contains('Sit-up')) {
      return _scoreSitUp(golongan, isPria, rawValue);
    } else if (exerciseName.contains('Push-up')) {
      return _scorePushUp(golongan, isPria, rawValue);
    } else if (exerciseName.contains('Shuttle Run')) {
      return _scoreShuttleRun(golongan, rawValue);
    }

    return 0.0;
  }

  static double _scoreLari(String golongan, bool isPria, double val) {
    List<Map<String, double>> table;
    if (isPria) {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 3444, 's': 100},
          {'v': 3338, 's': 95},
          {'v': 3232, 's': 90},
          {'v': 3126, 's': 85},
          {'v': 3021, 's': 80},
          {'v': 2914, 's': 75},
          {'v': 2809, 's': 70},
          {'v': 2597, 's': 60},
          {'v': 2386, 's': 50},
          {'v': 2301, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 3232, 's': 100},
          {'v': 3126, 's': 95},
          {'v': 3021, 's': 90},
          {'v': 2914, 's': 85},
          {'v': 2809, 's': 80},
          {'v': 2703, 's': 75},
          {'v': 2597, 's': 70},
          {'v': 2386, 's': 60},
          {'v': 2174, 's': 50},
          {'v': 2090, 's': 46},
        ];
      } else {
        table = [
          {'v': 2936, 's': 100},
          {'v': 2820, 's': 95},
          {'v': 2725, 's': 90},
          {'v': 2618, 's': 85},
          {'v': 2513, 's': 80},
          {'v': 2407, 's': 75},
          {'v': 2301, 's': 70},
          {'v': 2090, 's': 60},
          {'v': 1878, 's': 50},
          {'v': 1793, 's': 46},
        ];
      }
    } else {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 3095, 's': 100},
          {'v': 2999, 's': 95},
          {'v': 2893, 's': 90},
          {'v': 2788, 's': 85},
          {'v': 2682, 's': 80},
          {'v': 2576, 's': 75},
          {'v': 2470, 's': 70},
          {'v': 2259, 's': 60},
          {'v': 2048, 's': 50},
          {'v': 1962, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 2978, 's': 100},
          {'v': 2872, 's': 95},
          {'v': 2767, 's': 90},
          {'v': 2661, 's': 85},
          {'v': 2555, 's': 80},
          {'v': 2449, 's': 75},
          {'v': 2343, 's': 70},
          {'v': 2132, 's': 60},
          {'v': 1920, 's': 50},
          {'v': 1836, 's': 46},
        ];
      } else {
        table = [
          {'v': 2851, 's': 100},
          {'v': 2746, 's': 95},
          {'v': 2639, 's': 90},
          {'v': 2534, 's': 85},
          {'v': 2428, 's': 80},
          {'v': 2322, 's': 75},
          {'v': 2216, 's': 70},
          {'v': 2005, 's': 60},
          {'v': 1793, 's': 50},
          {'v': 1708, 's': 46},
        ];
      }
    }
    return _interpolate(val, table, false);
  }

  static double _scorePullUp(String golongan, bool isPria, double val) {
    List<Map<String, double>> table;
    if (isPria) {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 17, 's': 100},
          {'v': 14, 's': 82},
          {'v': 12, 's': 70},
          {'v': 8, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 15, 's': 100},
          {'v': 12, 's': 82},
          {'v': 10, 's': 70},
          {'v': 6, 's': 46},
        ];
      } else {
        table = [
          {'v': 12, 's': 100},
          {'v': 10, 's': 90},
          {'v': 4, 's': 60},
        ];
      }
    } else {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 72, 's': 100},
          {'v': 68, 's': 90},
          {'v': 65, 's': 82},
          {'v': 60, 's': 70},
          {'v': 56, 's': 60},
          {'v': 50, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 70, 's': 100},
          {'v': 66, 's': 90},
          {'v': 63, 's': 82},
          {'v': 58, 's': 70},
          {'v': 54, 's': 60},
          {'v': 48, 's': 46},
        ];
      } else {
        table = [
          {'v': 68, 's': 100},
          {'v': 64, 's': 90},
          {'v': 61, 's': 82},
          {'v': 56, 's': 70},
          {'v': 52, 's': 60},
          {'v': 46, 's': 46},
        ];
      }
    }
    return _interpolate(val, table, false);
  }

  static double _scoreSitUp(String golongan, bool isPria, double val) {
    List<Map<String, double>> table;
    if (isPria) {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 42, 's': 100},
          {'v': 37, 's': 85},
          {'v': 32, 's': 70},
          {'v': 23, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 36, 's': 100},
          {'v': 30, 's': 85},
          {'v': 25, 's': 70},
          {'v': 17, 's': 46},
        ];
      } else {
        table = [
          {'v': 30, 's': 100},
          {'v': 25, 's': 90},
          {'v': 23, 's': 85},
          {'v': 13, 's': 60},
        ];
      }
    } else {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 50, 's': 100},
          {'v': 37, 's': 60},
          {'v': 32, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 47, 's': 100},
          {'v': 45, 's': 90},
          {'v': 42, 's': 81},
          {'v': 38, 's': 70},
          {'v': 35, 's': 60},
          {'v': 30, 's': 46},
        ];
      } else {
        table = [
          {'v': 44, 's': 100},
          {'v': 31, 's': 60},
          {'v': 26, 's': 46},
        ];
      }
    }
    return _interpolate(val, table, false);
  }

  static double _scorePushUp(String golongan, bool isPria, double val) {
    List<Map<String, double>> table;
    if (isPria) {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 42, 's': 100},
          {'v': 37, 's': 85},
          {'v': 32, 's': 70},
          {'v': 23, 's': 46},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 36, 's': 100},
          {'v': 30, 's': 85},
          {'v': 25, 's': 70},
          {'v': 17, 's': 46},
        ];
      } else {
        table = [
          {'v': 30, 's': 100},
          {'v': 25, 's': 90},
          {'v': 23, 's': 85},
          {'v': 13, 's': 60},
        ];
      }
    } else {
      if (golongan == 'Golongan I') {
        table = [
          {'v': 37, 's': 100},
          {'v': 34, 's': 90},
        ];
      } else if (golongan == 'Golongan II') {
        table = [
          {'v': 35, 's': 100},
          {'v': 32, 's': 90},
        ];
      } else {
        table = [
          {'v': 33, 's': 100},
          {'v': 30, 's': 90},
        ];
      }
    }
    return _interpolate(val, table, false);
  }

  static double _scoreShuttleRun(String golongan, double val) {
    List<Map<String, double>> table;
    if (golongan == 'Golongan I') {
      table = [
        {'v': 16.2, 's': 100},
        {'v': 17.0, 's': 90},
        {'v': 17.5, 's': 80},
        {'v': 18.0, 's': 70},
        {'v': 18.5, 's': 60},
        {'v': 19.2, 's': 46},
      ];
    } else if (golongan == 'Golongan II') {
      table = [
        {'v': 17.0, 's': 100},
        {'v': 17.8, 's': 90},
        {'v': 18.5, 's': 80},
        {'v': 19.3, 's': 70},
        {'v': 20.0, 's': 60},
        {'v': 20.8, 's': 50},
        {'v': 21.0, 's': 46},
      ];
    } else {
      table = [
        {'v': 18.2, 's': 100},
        {'v': 19.1, 's': 90},
        {'v': 19.9, 's': 80},
        {'v': 21.0, 's': 70},
        {'v': 22.1, 's': 60},
        {'v': 23.2, 's': 50},
        {'v': 23.6, 's': 46},
      ];
    }
    return _interpolate(val, table, true);
  }

  static Map<String, dynamic> getAgeAndGolongan(String? birthDateStr) {
    if (birthDateStr == null) {
      return {
        'age': 25,
        'golongan': 'Golongan I',
        'label': 'Golongan I (17-30 Tahun)',
      };
    }
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      String golongan = 'Golongan I';
      String label = 'Golongan I (17-30 Tahun)';
      if (age >= 31 && age <= 40) {
        golongan = 'Golongan II';
        label = 'Golongan II (31-40 Tahun)';
      } else if (age >= 41 && age <= 50) {
        golongan = 'Golongan III';
        label = 'Golongan III (41-50 Tahun)';
      } else if (age > 50) {
        golongan = 'Golongan III';
        label = 'Golongan III (>40 Tahun)';
      }

      return {'age': age, 'golongan': golongan, 'label': label};
    } catch (e) {
      return {
        'age': 25,
        'golongan': 'Golongan I',
        'label': 'Golongan I (17-30 Tahun)',
      };
    }
  }

  static double calculateAkademikScore(double Function(int) getVal) {
    double np =
        getVal(0) * 0.30 +
        getVal(1) * 0.05 +
        getVal(2) * 0.05 +
        getVal(3) * 0.60;
    double nsk = getVal(4) * 0.60 + getVal(5) * 0.20 + getVal(6) * 0.20;
    double nt = getVal(7) * 0.40 + getVal(8) * 0.30 + getVal(9) * 0.30;
    return (np * 0.60) + (nsk * 0.10) + (nt * 0.30);
  }

  static double calculateMentalScore(
    double Function(int) getVal,
    double lookupPoints,
  ) {
    double avg5 =
        (getVal(0) * 20 +
            getVal(1) * 15 +
            getVal(2) * 20 +
            getVal(3) * 15 +
            getVal(4) * 15) /
        85;
    double sosiometriAvg = (getVal(5) + getVal(6)) / 2;
    return ((avg5 * 7 + sosiometriAvg * 3) / 10) + lookupPoints;
  }

  static double calculateJasmaniScore(
    double Function(int) getVal,
    String currentRole,
  ) {
    double nKes = (getVal(0) + getVal(1) + getVal(2)) / 3;
    double ngb = (getVal(4) + getVal(5) + getVal(6) + getVal(7)) / 4;
    double nJas = (getVal(3) + ngb) / 2;

    if (currentRole == 'Tim Medis') return nKes;
    if (currentRole == 'Korsis' || currentRole == 'Gadik') return nJas;
    return (nKes * 4 + nJas * 6) / 10;
  }

  static String getScorePredicate(double score) {
    if (score > 85.0) return 'Sangat Memuaskan (SM)';
    if (score > 80.0) return 'Memuaskan (M)';
    if (score > 75.0) return 'Baik (B)';
    if (score > 70.0) return 'Cukup (C)';
    if (score > 0) return 'Tidak Lulus (K)';
    return '-';
  }

  static double _interpolate(
    double val,
    List<Map<String, double>> table,
    bool lowerIsBetter,
  ) {
    if (table.isEmpty) return 0.0;

    if (lowerIsBetter) {
      if (val <= table.first['v']!) return 100.0;
      if (val >= table.last['v']!) {
        double lowestV = table.last['v']!;
        double lowestS = table.last['s']!;
        if (val > lowestV + 5.0) return 0.0;
        double s = lowestS - ((val - lowestV) / 5.0) * lowestS;
        return double.parse((s < 0 ? 0.0 : s).toStringAsFixed(2));
      }
      for (int i = 0; i < table.length - 1; i++) {
        if (val >= table[i]['v']! && val <= table[i + 1]['v']!) {
          double v1 = table[i]['v']!;
          double s1 = table[i]['s']!;
          double v2 = table[i + 1]['v']!;
          double s2 = table[i + 1]['s']!;
          double s = s1 + ((val - v1) / (v2 - v1)) * (s2 - s1);
          return double.parse(s.toStringAsFixed(2));
        }
      }
    } else {
      if (val >= table.first['v']!) return 100.0;
      if (val <= table.last['v']!) {
        double lowestV = table.last['v']!;
        double lowestS = table.last['s']!;
        double s = (val / lowestV) * lowestS;
        return double.parse((s < 0 ? 0.0 : s).toStringAsFixed(2));
      }
      for (int i = 0; i < table.length - 1; i++) {
        if (val <= table[i]['v']! && val >= table[i + 1]['v']!) {
          double v1 = table[i]['v']!;
          double s1 = table[i]['s']!;
          double v2 = table[i + 1]['v']!;
          double s2 = table[i + 1]['s']!;
          double s = s1 + ((val - v1) / (v2 - v1)) * (s2 - s1);
          return double.parse(s.toStringAsFixed(2));
        }
      }
    }
    return 0.0;
  }
}

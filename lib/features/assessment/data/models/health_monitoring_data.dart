class HealthRecord {
  final String id;
  final String type;
  final String description;
  final String? photoPath;
  final int minusPoints;
  final DateTime timestamp;
  final String medisName;

  HealthRecord({
    required this.id,
    required this.type,
    required this.description,
    this.photoPath,
    required this.minusPoints,
    required this.timestamp,
    required this.medisName,
  });
}

class SerdikHealthData {
  final String noSerdik;
  double? nilaiA;
  String? catatanDokterA;
  double? nilaiB;
  String? catatanDokterB;
  int baseNilaiC = 80;
  List<HealthRecord> records = [];

  SerdikHealthData({
    required this.noSerdik,
    this.nilaiA,
    this.catatanDokterA,
    this.nilaiB,
    this.catatanDokterB,
  });

  int get currentNilaiC {
    int totalMinus = 0;
    for (var r in records) {
      totalMinus += r.minusPoints;
    }
    return baseNilaiC - totalMinus;
  }

  double get nilaiAkhir {
    double a = nilaiA ?? 0.0;
    double b = nilaiB ?? 0.0;
    double c = currentNilaiC.toDouble();
    return (a + b + c) / 3;
  }
}

class HealthMonitoringData {
  static final Map<String, SerdikHealthData> _data = {};

  static SerdikHealthData getHealthData(String noSerdik) {
    if (!_data.containsKey(noSerdik)) {
      _data[noSerdik] = SerdikHealthData(noSerdik: noSerdik);
    }
    return _data[noSerdik]!;
  }

  static void updateNilaiA(String noSerdik, double score, {String? catatan}) {
    final data = getHealthData(noSerdik);
    data.nilaiA = score;
    if (catatan != null) data.catatanDokterA = catatan;
  }

  static void updateNilaiB(String noSerdik, double score, {String? catatan}) {
    final data = getHealthData(noSerdik);
    data.nilaiB = score;
    if (catatan != null) data.catatanDokterB = catatan;
  }

  static void addHealthRecord(
    String noSerdik,
    String type,
    String description,
    String medisName,
    int minusPoints, {
    String? photoPath,
  }) {
    final record = HealthRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      photoPath: photoPath,
      minusPoints: minusPoints,
      timestamp: DateTime.now(),
      medisName: medisName,
    );
    getHealthData(noSerdik).records.insert(0, record);
  }
}

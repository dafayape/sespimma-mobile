class JasmaniGradingData {
  final String noSerdik;
  double? nilaiA;
  double? nilaiB1;
  double? nilaiB2;
  double? nilaiB3;
  double? nilaiB4;

  JasmaniGradingData({
    required this.noSerdik,
    this.nilaiA,
    this.nilaiB1,
    this.nilaiB2,
    this.nilaiB3,
    this.nilaiB4,
  });

  bool get isSamaptaBComplete =>
      nilaiB1 != null && nilaiB2 != null && nilaiB3 != null && nilaiB4 != null;

  double get nilaiB {
    return ((nilaiB1 ?? 0) + (nilaiB2 ?? 0) + (nilaiB3 ?? 0) + (nilaiB4 ?? 0)) /
        4;
  }

  double getNilaiJasmani(String golongan) {
    if (nilaiA == null) return 0.0;
    if (golongan == 'GOL IV') {
      return nilaiA!;
    }
    return (nilaiA! + nilaiB) / 2;
  }

  static final Map<String, JasmaniGradingData> _records = {};

  static JasmaniGradingData getJasmaniData(String noSerdik) {
    if (!_records.containsKey(noSerdik)) {
      _records[noSerdik] = JasmaniGradingData(noSerdik: noSerdik);
    }
    return _records[noSerdik]!;
  }

  static void saveJasmaniData(JasmaniGradingData data) {
    _records[data.noSerdik] = data;
  }
}

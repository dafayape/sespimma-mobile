class HealthRecordItem {
  final String id;
  final String serdikName;
  final String nosis;
  final String type;
  final DateTime timestamp;
  final int value;

  HealthRecordItem({
    required this.id,
    required this.serdikName,
    required this.nosis,
    required this.type,
    required this.timestamp,
    this.value = 1,
  });
}

class HealthRecordMockData {
  HealthRecordMockData._();

  static List<HealthRecordItem>? _items;

  static List<HealthRecordItem> get items {
    _items ??= _generateInitialData();
    return _items!;
  }

  static void addRecord(HealthRecordItem item) {
    items.insert(0, item);
  }

  static void reset() {
    _items = null;
  }

  static List<HealthRecordItem> _generateInitialData() {
    return [];
  }
}

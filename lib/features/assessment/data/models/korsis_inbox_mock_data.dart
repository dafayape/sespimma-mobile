class InboxItem {
  final String id;
  final String serdikName;
  final String pangkat;
  final String nosis;
  final String pokjar;
  final bool isReward;
  final String senderName;
  final DateTime timestamp;
  final double points;
  final String description;
  final String rewardPunishmentName;
  String status;
  final String? photoPath;
  final String? rewardPunishmentId;
  final bool isIzin;
  final DateTime? izinStartTime;
  final DateTime? izinEndTime;
  final String? attachmentPath;

  InboxItem({
    required this.id,
    required this.serdikName,
    required this.pangkat,
    required this.nosis,
    required this.pokjar,
    required this.isReward,
    required this.senderName,
    required this.timestamp,
    required this.points,
    required this.description,
    required this.rewardPunishmentName,
    this.status = 'pending',
    this.photoPath,
    this.rewardPunishmentId,
    this.isIzin = false,
    this.izinStartTime,
    this.izinEndTime,
    this.attachmentPath,
  });
}

class KorsisInboxMockData {
  KorsisInboxMockData._();

  static List<InboxItem>? _items;

  static List<InboxItem> get items {
    _items ??= _generateInitialData();
    return _items!;
  }

  static List<InboxItem> generateMockData() => items;

  static void addRecord(InboxItem item) {
    items.insert(0, item);
  }

  static void reset() {
    _items = null;
  }

  static List<InboxItem> _generateInitialData() {
    return [];
  }
}

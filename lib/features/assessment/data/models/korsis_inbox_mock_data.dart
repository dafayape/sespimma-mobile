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

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    return InboxItem(
      id: json['id']?.toString() ?? '',
      serdikName: json['serdik_name'] ?? json['serdikName'] ?? '',
      pangkat: json['pangkat'] ?? '',
      nosis: json['nosis'] ?? '',
      pokjar: json['pokjar'] ?? '',
      isReward: json['is_reward'] ?? json['isReward'] ?? false,
      senderName: json['sender_name'] ?? json['senderName'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      points: (json['points'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      rewardPunishmentName: json['reward_punishment_name'] ?? json['rewardPunishmentName'] ?? '',
      status: json['status'] ?? 'pending',
      photoPath: json['photo_url'] ?? json['photoPath'],
      rewardPunishmentId: json['reward_punishment_id'] ?? json['rewardPunishmentId'],
      isIzin: json['is_izin'] ?? json['isIzin'] ?? false,
      izinStartTime: json['izin_start_time'] != null 
          ? DateTime.parse(json['izin_start_time']) 
          : (json['izinStartTime'] != null ? DateTime.parse(json['izinStartTime']) : null),
      izinEndTime: json['izin_end_time'] != null 
          ? DateTime.parse(json['izin_end_time']) 
          : (json['izinEndTime'] != null ? DateTime.parse(json['izinEndTime']) : null),
      attachmentPath: json['attachment_url'] ?? json['attachmentPath'],
    );
  }
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

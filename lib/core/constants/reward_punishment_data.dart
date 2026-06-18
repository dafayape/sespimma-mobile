class RewardPunishmentItem {
  final String id;
  final String type;
  final String aspect;
  final String description;
  final double point;
  final String? note;

  const RewardPunishmentItem({
    required this.id,
    required this.type,
    required this.aspect,
    required this.description,
    required this.point,
    this.note,
  });
}

class RewardPunishmentData {
  static List<RewardPunishmentItem> rules = [];
  static bool _isLoaded = false;

  static Future<void> loadFromApi(dynamic dataSource) async {
    if (_isLoaded) return;
    try {
      final prestasis = await dataSource.getPoints('prestasi');
      final pelanggarans = await dataSource.getPoints('pelanggaran');

      List<RewardPunishmentItem> newRules = [];

      String mapAspect(int? mentalComponentId) {
        switch (mentalComponentId) {
          case 1: return 'MORAL';
          case 2: return 'DISIPLIN';
          case 3: return 'KEPEMIMPINAN';
          case 4: return 'PENGENDALIAN DIRI';
          case 5: return 'PENAMPILAN';
          default: return 'UMUM';
        }
      }

      for (var p in prestasis) {
        newRules.add(RewardPunishmentItem(
          id: p['id'].toString(),
          type: 'REWARD',
          aspect: mapAspect(p['mentalComponentId']),
          description: p['description'] ?? '',
          point: (p['points'] as num).toDouble(),
        ));
      }

      for (var p in pelanggarans) {
        newRules.add(RewardPunishmentItem(
          id: p['id'].toString(),
          type: 'PUNISHMENT',
          aspect: mapAspect(p['mentalComponentId']),
          description: p['description'] ?? '',
          point: (p['points'] as num).toDouble(),
        ));
      }

      rules = newRules;
      _isLoaded = true;
    } catch (e) {
      print('Failed to load points from API: $e');
    }
  }
  static List<RewardPunishmentItem> get rewards =>
      rules.where((r) => r.type == 'REWARD').toList();

  static List<RewardPunishmentItem> get punishments =>
      rules.where((r) => r.type == 'PUNISHMENT').toList();

  static List<RewardPunishmentItem> getByAspect(String aspect) =>
      rules.where((r) => r.aspect == aspect).toList();
}

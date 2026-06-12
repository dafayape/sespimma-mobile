class SerdikSenatRoles {
  static const Map<String, String> roles = {
    '202602003001': 'Ketua Senat',
    '202602003097': 'Kasenat',
    '202602003038': 'Wakasenat',
    '202602003084': 'Sie Sosial Dan Kesehatan',
    '202602003028': 'Sekretaris',
    '202602003083': 'Bendahara Senat',
    '202602003074': 'Bendahara Senat',
    '202602003101': 'Sie Opsdik',
    '202602003106': 'Sie Sosial Dan Kesehatan',
    '202502003031': 'Sie Roh Islam',
    '202602003102': 'Sie Opsdik',
    '202602003091': 'Sie Sosial Dan Kesehatan',
    '202602003122': 'Sekretaris',
    '202602003015': 'Kapokjar II',
    '202602003034': 'Sie Opsdik',
    '202602003073': 'Demusdik',
    '202602003105': 'Polsis Pokjar I',
    '202602003012': 'Demusdik',
    '202502003051': 'Sie Humas/IT',
    '202602003117': 'Kapokjar V',
    '202502003006': 'Polsis Pokjar IV',
    '202602003022': 'Kapokjar I',
    '202602003076': 'Polsis Polwan',
    '202602003010': 'Polsis Pokjar III',
    '202602003049': 'Sie Or',
    '202602003056': 'Sie Roh Hindu',
    '202602003030': 'Demusdik',
    '202602003046': 'Sie Or',
    '202602003120': 'Polsis Pokjar II',
    '202602003018': 'Sie Humas/IT',
    '202602003054': 'Sie Roh Nasrani',
    '202602003085': 'Kapolsis',
    '202602003009': 'Kapokjar IV',
    '202602003024': 'Polsis Pokjar V',
  };

  static String? getRole(String noSerdik) => roles[noSerdik];

  static bool isSenatMember(String noSerdik) => roles.containsKey(noSerdik);

  static List<Map<String, dynamic>> filterSenatMembers(
    List<Map<String, dynamic>> pokjarMembers,
  ) {
    return pokjarMembers
        .where((m) => isSenatMember(m['no_serdik'] as String? ?? ''))
        .toList();
  }
}

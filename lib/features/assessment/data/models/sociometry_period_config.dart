import 'sociometry_peer_model.dart';

class SociometryPeriodConfig {
  static final DateTime educationStartDate = DateTime(2026, 5, 21);

  static DateTime _awalStartDate = DateTime(2026, 5, 21);
  static DateTime _awalEndDate = DateTime(
    2026,
    5,
    21,
  ).add(const Duration(days: 15));

  static DateTime _akhirStartDate = DateTime(
    2026,
    5,
    21,
  ).add(const Duration(days: 90));
  static DateTime _akhirEndDate = DateTime(
    2026,
    5,
    21,
  ).add(const Duration(days: 97));

  static DateTime get awalStartDate => _awalStartDate;
  static DateTime get awalEndDate => _awalEndDate;
  static DateTime get akhirStartDate => _akhirStartDate;
  static DateTime get akhirEndDate => _akhirEndDate;

  static void setAwalPeriod(DateTime start, DateTime end) {
    _awalStartDate = start;
    _awalEndDate = end;
  }

  static void setAkhirPeriod(DateTime start, DateTime end) {
    _akhirStartDate = start;
    _akhirEndDate = end;
  }

  static bool? isAwalUnlockedForce;
  static bool? isAkhirUnlockedForce;

  static bool get isAwalLocked => isAwalUnlockedForce == false;
  static bool get isAkhirLocked => isAkhirUnlockedForce == false;

  static void lockAwal() => isAwalUnlockedForce = false;
  static void lockAkhir() => isAkhirUnlockedForce = false;

  static bool isAwalActive() {
    if (isAwalUnlockedForce != null) return isAwalUnlockedForce!;
    final now = DateTime.now();
    return now.isAfter(awalStartDate) && now.isBefore(awalEndDate);
  }

  static bool isAwalClosed() {
    if (isAwalUnlockedForce != null) return !isAwalUnlockedForce!;
    final now = DateTime.now();
    return now.isAfter(awalEndDate);
  }

  static bool isAkhirActive() {
    if (isAkhirUnlockedForce != null) return isAkhirUnlockedForce!;
    final now = DateTime.now();
    return now.isAfter(akhirStartDate) && now.isBefore(akhirEndDate);
  }

  static bool isAkhirClosed() {
    if (isAkhirUnlockedForce != null) return !isAkhirUnlockedForce!;
    final now = DateTime.now();
    return now.isAfter(akhirEndDate);
  }

  static bool isAnyActive() {
    return isAwalActive() || isAkhirActive();
  }

  static final List<SociometryPeerModel> _peersAwal = [
    SociometryPeerModel(
      id: 'P001',
      name: 'Bagus Hermawan',
      nrp: '202602003110',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
      isEvaluated: true,
    ),
    SociometryPeerModel(
      id: 'P002',
      name: 'Dian Ayu Ningsih',
      nrp: '202602003124',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
      isEvaluated: true,
    ),
    SociometryPeerModel(
      id: 'P003',
      name: 'Ferry Kurniawan',
      nrp: '202602003145',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
      isEvaluated: true,
    ),
    SociometryPeerModel(
      id: 'P004',
      name: 'Reza Pahlevi',
      nrp: '202602003167',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P005',
      name: 'Siti Aisyah',
      nrp: '202602003188',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P006',
      name: 'Aditya Nugraha',
      nrp: '202602003201',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P007',
      name: 'Budi Santoso',
      nrp: '202602003212',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P008',
      name: 'Citra Lestari',
      nrp: '202602003225',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P009',
      name: 'Doni Setiawan',
      nrp: '202602003238',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P010',
      name: 'Eka Prasetya',
      nrp: '202602003249',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P011',
      name: 'Fitri Handayani',
      nrp: '202602003260',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P012',
      name: 'Guntur Wibowo',
      nrp: '202602003271',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P013',
      name: 'Hendra Wijaya',
      nrp: '202602003282',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P014',
      name: 'Indah Permata',
      nrp: '202602003293',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P015',
      name: 'Jaka Swara',
      nrp: '202602003304',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
  ];

  static final List<SociometryPeerModel> _peersAkhir = [
    SociometryPeerModel(
      id: 'P001',
      name: 'Bagus Hermawan',
      nrp: '202602003110',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P002',
      name: 'Dian Ayu Ningsih',
      nrp: '202602003124',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P003',
      name: 'Ferry Kurniawan',
      nrp: '202602003145',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P004',
      name: 'Reza Pahlevi',
      nrp: '202602003167',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P005',
      name: 'Siti Aisyah',
      nrp: '202602003188',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P006',
      name: 'Aditya Nugraha',
      nrp: '202602003201',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P007',
      name: 'Budi Santoso',
      nrp: '202602003212',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P008',
      name: 'Citra Lestari',
      nrp: '202602003225',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P009',
      name: 'Doni Setiawan',
      nrp: '202602003238',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P010',
      name: 'Eka Prasetya',
      nrp: '202602003249',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P011',
      name: 'Fitri Handayani',
      nrp: '202602003260',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P012',
      name: 'Guntur Wibowo',
      nrp: '202602003271',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P013',
      name: 'Hendra Wijaya',
      nrp: '202602003282',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P014',
      name: 'Indah Permata',
      nrp: '202602003293',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
    SociometryPeerModel(
      id: 'P015',
      name: 'Jaka Swara',
      nrp: '202602003304',
      rank: 'AKP',
      imageUrl: 'assets/images/default_avatar.png',
    ),
  ];

  static List<SociometryPeerModel> get peersAwal => _peersAwal;
  static List<SociometryPeerModel> get peersAkhir => _peersAkhir;

  static List<SociometryPeerModel> get peers =>
      isAkhirActive() ? _peersAkhir : _peersAwal;

  static int getFilledCount() {
    return peers.where((peer) => peer.isEvaluated).length;
  }

  static int getTotalCount() {
    return peers.length;
  }

  static bool isCurrentPhaseLocked(bool isAwal) {
    return isAwal ? !isAwalActive() : !isAkhirActive();
  }
}

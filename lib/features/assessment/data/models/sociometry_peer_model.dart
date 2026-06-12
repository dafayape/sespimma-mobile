class SociometryPeerModel {
  final String id;
  final String name;
  final String nrp;
  final String rank;
  final String imageUrl;
  bool isEvaluated;

  SociometryPeerModel({
    required this.id,
    required this.name,
    required this.nrp,
    required this.rank,
    required this.imageUrl,
    this.isEvaluated = false,
  });
}

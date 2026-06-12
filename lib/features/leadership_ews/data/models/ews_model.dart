class EwsModel {
  final String id;
  final String name;
  final String nrp;
  final String pokjar;
  final double averageScore;
  final int violationCount;

  const EwsModel({
    required this.id,
    required this.name,
    required this.nrp,
    required this.pokjar,
    required this.averageScore,
    required this.violationCount,
  });

  bool get isHighRisk => averageScore <= 70.0 || violationCount >= 5;

  bool get isMediumRisk =>
      averageScore > 70.0 && averageScore <= 75.0 && violationCount < 5;

  bool get isSafe => !isHighRisk && !isMediumRisk;

  factory EwsModel.fromJson(Map<String, dynamic> json) {
    return EwsModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nrp: json['nrp'] as String? ?? '',
      pokjar: json['pokjar'] as String? ?? '',
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.0,
      violationCount: json['violation_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nrp': nrp,
      'pokjar': pokjar,
      'average_score': averageScore,
      'violation_count': violationCount,
    };
  }

  EwsModel copyWith({
    String? id,
    String? name,
    String? nrp,
    String? pokjar,
    double? averageScore,
    int? violationCount,
  }) {
    return EwsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nrp: nrp ?? this.nrp,
      pokjar: pokjar ?? this.pokjar,
      averageScore: averageScore ?? this.averageScore,
      violationCount: violationCount ?? this.violationCount,
    );
  }
}

class ScoringModel {
  final String id;
  final String serdikId;
  final String category;
  final double score;
  final String type;
  final String note;
  final DateTime timestamp;

  const ScoringModel({
    required this.id,
    required this.serdikId,
    required this.category,
    required this.score,
    required this.type,
    required this.note,
    required this.timestamp,
  });

  factory ScoringModel.fromJson(Map<String, dynamic> json) {
    return ScoringModel(
      id: json['id'] as String? ?? '',
      serdikId: json['serdikId'] as String? ?? '',
      category: json['category'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'numeric',
      note: json['note'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serdikId': serdikId,
      'category': category,
      'score': score,
      'type': type,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  ScoringModel copyWith({
    String? id,
    String? serdikId,
    String? category,
    double? score,
    String? type,
    String? note,
    DateTime? timestamp,
  }) {
    return ScoringModel(
      id: id ?? this.id,
      serdikId: serdikId ?? this.serdikId,
      category: category ?? this.category,
      score: score ?? this.score,
      type: type ?? this.type,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class LookupModel {
  final String id;
  final String type;
  final String description;
  final double point;

  const LookupModel({
    required this.id,
    required this.type,
    required this.description,
    required this.point,
  });

  factory LookupModel.fromJson(Map<String, dynamic> json) {
    return LookupModel(
      id: json['id'] as String? ?? '',
      type: json['tipe'] as String? ?? '',
      description: json['deskripsi'] as String? ?? '',
      point: (json['poin'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'tipe': type, 'deskripsi': description, 'poin': point};
  }
}

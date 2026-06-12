class FinalRecapModel {
  final String id;
  final String name;
  final String nrp;
  final String nosis;
  final String pokjar;
  final double academicScore;
  final double mentalScore;
  final double physicalScore;
  final String tanggalLahir;
  final String jenisKelamin;
  final int sanksiKesehatan;
  final String pangkat;
  final Map<String, double> rawScores;

  FinalRecapModel({
    required this.id,
    required this.name,
    required this.nrp,
    required this.nosis,
    required this.pokjar,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
    this.tanggalLahir = '1985-01-01',
    this.jenisKelamin = 'Laki-laki',
    this.sanksiKesehatan = 0,
    this.pangkat = '',
    this.rawScores = const {},
  });

  double get nak {
    return (academicScore * 70 + mentalScore * 20 + physicalScore * 10) / 100;
  }

  double get average => nak;

  bool get isPassed {
    return academicScore >= 70.0 &&
        mentalScore >= 70.0 &&
        physicalScore >= 70.0;
  }

  String get predicate {
    final double score = average;
    if (score > 90.00) return 'Istimewa (BA)';
    if (score > 85.00) return 'Sangat Memuaskan (SM)';
    if (score > 80.00) return 'Memuaskan (M)';
    if (score > 75.00) return 'Baik (B)';
    if (score >= 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  factory FinalRecapModel.empty() {
    return FinalRecapModel(
      id: '',
      name: '',
      nrp: '',
      nosis: '',
      pokjar: '',
      academicScore: 0.0,
      mentalScore: 0.0,
      physicalScore: 0.0,
    );
  }

  factory FinalRecapModel.fromJson(Map<String, dynamic> json) {
    return FinalRecapModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nrp: json['nrp'] as String? ?? '',
      nosis: json['nosis'] as String? ?? '',
      pokjar: json['pokjar'] as String? ?? '',
      academicScore: (json['academic_score'] as num?)?.toDouble() ?? 0.0,
      mentalScore: (json['mental_score'] as num?)?.toDouble() ?? 0.0,
      physicalScore: (json['physical_score'] as num?)?.toDouble() ?? 0.0,
      tanggalLahir: json['tanggal_lahir'] as String? ?? '1985-01-01',
      jenisKelamin: json['jenis_kelamin'] as String? ?? 'Laki-laki',
      sanksiKesehatan: json['sanksi_kesehatan'] as int? ?? 0,
      pangkat: json['pangkat'] as String? ?? '',
      rawScores:
          (json['raw_scores'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nrp': nrp,
      'nosis': nosis,
      'pokjar': pokjar,
      'academic_score': academicScore,
      'mental_score': mentalScore,
      'physical_score': physicalScore,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'sanksi_kesehatan': sanksiKesehatan,
      'pangkat': pangkat,
      'raw_scores': rawScores,
    };
  }

  FinalRecapModel copyWith({
    String? id,
    String? name,
    String? nrp,
    String? nosis,
    String? pokjar,
    double? academicScore,
    double? mentalScore,
    double? physicalScore,
    String? tanggalLahir,
    String? jenisKelamin,
    int? sanksiKesehatan,
    String? pangkat,
    Map<String, double>? rawScores,
  }) {
    return FinalRecapModel(
      id: id ?? this.id,
      name: name ?? this.name,
      nrp: nrp ?? this.nrp,
      nosis: nosis ?? this.nosis,
      pokjar: pokjar ?? this.pokjar,
      academicScore: academicScore ?? this.academicScore,
      mentalScore: mentalScore ?? this.mentalScore,
      physicalScore: physicalScore ?? this.physicalScore,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      sanksiKesehatan: sanksiKesehatan ?? this.sanksiKesehatan,
      pangkat: pangkat ?? this.pangkat,
      rawScores: rawScores ?? this.rawScores,
    );
  }
}

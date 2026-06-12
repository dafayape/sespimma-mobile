class TugasModel {
  final String id;
  final String judul;
  final String deskripsi;
  final String mapel;
  final DateTime deadline;
  final String status;
  final String createdBy;
  final String createdByName;

  const TugasModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.mapel,
    required this.deadline,
    required this.status,
    required this.createdBy,
    required this.createdByName,
  });

  factory TugasModel.fromJson(Map<String, dynamic> json) {
    return TugasModel(
      id: json['id'] as String? ?? '',
      judul: json['judul'] as String? ?? '',
      deskripsi: json['deskripsi'] as String? ?? '',
      mapel: json['mapel'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      status: json['status'] as String? ?? 'Aktif',
      createdBy: json['createdBy'] as String? ?? '',
      createdByName: json['createdByName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'deskripsi': deskripsi,
      'mapel': mapel,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  TugasModel copyWith({
    String? id,
    String? judul,
    String? deskripsi,
    String? mapel,
    DateTime? deadline,
    String? status,
    String? createdBy,
    String? createdByName,
  }) {
    return TugasModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      deskripsi: deskripsi ?? this.deskripsi,
      mapel: mapel ?? this.mapel,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

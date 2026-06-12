class AssignmentModel {
  final String id;
  final String judul;
  final String mapel;
  final String pengajar;
  final String? pengajarFoto;
  final DateTime deadline;
  final String status;
  final String? deskripsi;
  final String? attachmentName;
  final String? attachmentUrl;
  final String? submissionFileName;
  final double? nilai;
  final String? catatan;

  const AssignmentModel({
    required this.id,
    required this.judul,
    required this.mapel,
    required this.pengajar,
    this.pengajarFoto,
    required this.deadline,
    required this.status,
    this.deskripsi,
    this.attachmentName,
    this.attachmentUrl,
    this.submissionFileName,
    this.nilai,
    this.catatan,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String? ?? '',
      judul: json['judul'] as String? ?? '',
      mapel: json['mapel'] as String? ?? '',
      pengajar: json['gadik'] as String? ?? '',
      pengajarFoto: json['pengajarFoto'] as String?,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'])
          : DateTime.now(),
      status: json['status'] as String? ?? 'aktif',
      deskripsi: json['deskripsi'] as String?,
      attachmentName: json['attachmentName'] as String?,
      attachmentUrl: json['attachmentUrl'] as String?,
      submissionFileName: json['submissionFileName'] as String?,
      nilai: json['nilai'] != null ? (json['nilai'] as num).toDouble() : null,
      catatan: json['catatan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'mapel': mapel,
      'gadik': pengajar,
      'pengajarFoto': pengajarFoto,
      'deadline': deadline.toIso8601String(),
      'status': status,
      'deskripsi': deskripsi,
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'submissionFileName': submissionFileName,
      'nilai': nilai,
      'catatan': catatan,
    };
  }

  AssignmentModel copyWith({
    String? id,
    String? judul,
    String? mapel,
    String? pengajar,
    DateTime? deadline,
    String? status,
    String? deskripsi,
    String? attachmentName,
    String? attachmentUrl,
    String? submissionFileName,
    double? nilai,
    String? catatan,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      mapel: mapel ?? this.mapel,
      pengajar: pengajar ?? this.pengajar,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      deskripsi: deskripsi ?? this.deskripsi,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      submissionFileName: submissionFileName ?? this.submissionFileName,
      nilai: nilai ?? this.nilai,
      catatan: catatan ?? this.catatan,
    );
  }
}

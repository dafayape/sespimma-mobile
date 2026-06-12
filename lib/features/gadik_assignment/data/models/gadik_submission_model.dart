class GadikSubmissionModel {
  final String id;
  final String assignmentId;
  final String serdikName;
  final String serdikNrp;
  final String? serdikPangkat;
  final String? serdikNosis;
  final DateTime? submittedAt;
  final String? fileUrl;
  final String? fileName;

  final bool isGraded;
  final bool? isRemedial;
  final double? nilaiAkhir;
  final String? catatanPengajar;

  final double? scoreMateri;
  final double? scorePenulisan;
  final double? scorePaparan;
  final double? scoreKeaktifan;

  final double? scoreUjian;

  final double? scoreKeaktifanPerseorangan;
  final double? scoreProdukPerseorangan;
  final double? scoreTataRuang;

  const GadikSubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.serdikName,
    required this.serdikNrp,
    this.serdikPangkat,
    this.serdikNosis,
    this.submittedAt,
    this.fileUrl,
    this.fileName,
    this.isGraded = false,
    this.isRemedial = false,
    this.nilaiAkhir,
    this.catatanPengajar,
    this.scoreMateri,
    this.scorePenulisan,
    this.scorePaparan,
    this.scoreKeaktifan,
    this.scoreUjian,
    this.scoreKeaktifanPerseorangan,
    this.scoreProdukPerseorangan,
    this.scoreTataRuang,
  });
}

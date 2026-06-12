import '../../domain/entities/attendance_report_entity.dart';

class SerdikAttendanceStatusModel extends SerdikAttendanceStatus {
  const SerdikAttendanceStatusModel({
    required super.id,
    required super.nama,
    required super.noSerdik,
    required super.status,
  });

  factory SerdikAttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    return SerdikAttendanceStatusModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      noSerdik: json['no_serdik'] ?? '',
      status: json['status'] ?? 'HADIR',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nama': nama, 'no_serdik': noSerdik, 'status': status};
  }
}

class AttendanceReportModel extends AttendanceReportEntity {
  const AttendanceReportModel({
    required super.id,
    required super.date,
    required super.pokjar,
    required super.total,
    required super.hadir,
    required super.telat,
    required super.izin,
    required super.sakit,
    required super.tk,
    required super.serdikList,
  });

  factory AttendanceReportModel.fromJson(Map<String, dynamic> json) {
    final serdikListJson = json['serdik_list'] as List<dynamic>? ?? [];
    final serdikList = serdikListJson
        .map(
          (e) =>
              SerdikAttendanceStatusModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();

    return AttendanceReportModel(
      id: json['id'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      pokjar: json['pokjar'] ?? '',
      total: json['total'] ?? 0,
      hadir: json['hadir'] ?? 0,
      telat: json['telat'] ?? 0,
      izin: json['izin'] ?? 0,
      sakit: json['sakit'] ?? 0,
      tk: json['tk'] ?? 0,
      serdikList: serdikList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'pokjar': pokjar,
      'total': total,
      'hadir': hadir,
      'telat': telat,
      'izin': izin,
      'sakit': sakit,
      'tk': tk,
      'serdik_list': serdikList
          .map((e) => (e as SerdikAttendanceStatusModel).toJson())
          .toList(),
    };
  }
}

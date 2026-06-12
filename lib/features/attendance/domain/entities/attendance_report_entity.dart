class SerdikAttendanceStatus {
  final String id;
  final String nama;
  final String noSerdik;
  final String status;

  const SerdikAttendanceStatus({
    required this.id,
    required this.nama,
    required this.noSerdik,
    required this.status,
  });
}

class AttendanceReportEntity {
  final String id;
  final DateTime date;
  final String pokjar;
  final int total;
  final int hadir;
  final int telat;
  final int izin;
  final int sakit;
  final int tk;
  final List<SerdikAttendanceStatus> serdikList;

  const AttendanceReportEntity({
    required this.id,
    required this.date,
    required this.pokjar,
    required this.total,
    required this.hadir,
    required this.telat,
    required this.izin,
    required this.sakit,
    required this.tk,
    required this.serdikList,
  });
}

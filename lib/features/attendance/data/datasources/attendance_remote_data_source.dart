import '../models/attendance_report_model.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'dart:math';

abstract interface class AttendanceRemoteDataSource {
  Future<List<AttendanceReportModel>> getReports(
    String pokjar, {
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<AttendanceReportModel> generateCurrentReport(String pokjar);
}

class AttendanceRemoteDataSourceMock implements AttendanceRemoteDataSource {
  static final List<AttendanceReportModel> _mockDatabase = [];

  @override
  Future<List<AttendanceReportModel>> getReports(
    String pokjar, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    var filtered = _mockDatabase
        .where((report) => report.pokjar == pokjar)
        .toList();

    if (startDate != null && endDate != null) {
      filtered = filtered.where((report) {
        final rDate = DateTime(
          report.date.year,
          report.date.month,
          report.date.day,
        );
        final sDate = DateTime(startDate.year, startDate.month, startDate.day);
        final eDate = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        return rDate.isAfter(sDate.subtract(const Duration(seconds: 1))) &&
            rDate.isBefore(eDate.add(const Duration(seconds: 1)));
      }).toList();
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  @override
  Future<AttendanceReportModel> generateCurrentReport(String pokjar) async {
    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final listSerdikData = SerdikRealData.records
        .where((s) => pokjar.isEmpty || s['kelompok_kelas'] == pokjar)
        .toList();

    listSerdikData.sort((a, b) => (a['nama'] ?? '').compareTo(b['nama'] ?? ''));

    int hadir = 0;
    int telat = 0;
    int izin = 0;
    int sakit = 0;
    int tk = 0;

    final List<SerdikAttendanceStatusModel> serdikList = [];
    final random = Random();

    for (var serdik in listSerdikData) {
      String noSerdik = serdik['no_serdik'] ?? serdik['nrp'] ?? '';
      String nama = serdik['nama_lengkap'] ?? serdik['nama'] ?? '';
      String id =
          serdik['id_peserta']?.toString() ?? random.nextInt(1000).toString();

      int rand = random.nextInt(100);
      String status = 'HADIR';

      if (rand < 2) {
        status = 'SAKIT';
        sakit++;
      } else if (rand < 4) {
        status = 'IZIN';
        izin++;
      } else if (rand < 5) {
        status = 'TK';
        tk++;
      } else if (rand < 8) {
        status = 'TELAT';
        telat++;
      } else {
        hadir++;
      }

      serdikList.add(
        SerdikAttendanceStatusModel(
          id: id,
          nama: nama,
          noSerdik: noSerdik,
          status: status,
        ),
      );
    }

    final newReport = AttendanceReportModel(
      id: 'REP-${now.millisecondsSinceEpoch}',
      date: now,
      pokjar: pokjar,
      total: listSerdikData.length,
      hadir: hadir,
      telat: telat,
      izin: izin,
      sakit: sakit,
      tk: tk,
      serdikList: serdikList,
    );

    bool isExist = _mockDatabase.any(
      (element) =>
          element.date.year == now.year &&
          element.date.month == now.month &&
          element.date.day == now.day &&
          element.pokjar == pokjar,
    );

    if (!isExist) {
      _mockDatabase.add(newReport);
    }

    return newReport;
  }
}

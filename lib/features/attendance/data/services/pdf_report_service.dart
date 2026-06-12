import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';

import 'package:intl/intl.dart';
import 'package:sespimma/features/attendance/domain/entities/attendance_report_entity.dart';

class PdfReportService {
  static Future<void> generateAndDownloadReport({
    required String pokjar,
    required DateTime date,
    required AttendanceReportEntity reportEntity,
  }) async {
    final pdf = pw.Document();

    final fontRegularData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Regular.ttf',
    );
    final fontRegular = pw.Font.ttf(fontRegularData);
    final fontBoldData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Bold.ttf',
    );
    final fontBold = pw.Font.ttf(fontBoldData);

    final listSerdik = reportEntity.serdikList;

    final DateFormat formatHariTanggal = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    );
    final String hariTanggalStr = formatHariTanggal.format(date);

    final String tglLembangStr = DateFormat(
      'dd MMMM',
      'id_ID',
    ).format(date).toUpperCase();
    final String tahunStr = DateFormat('yyyy').format(date);

    int total = reportEntity.total;
    int hadir = reportEntity.hadir;
    int ijin = reportEntity.izin;
    int sakit = reportEntity.sakit;
    int tk = reportEntity.tk;
    int telat = reportEntity.telat;

    int kurang = sakit + ijin + tk + telat;

    final List<AttendanceZone> zones = AttendanceZones.activeZones;
    if (zones.isEmpty) {
      throw Exception('Tidak ada kegiatan aktif untuk dibuat laporannya.');
    }

    for (final zone in zones) {
      final String startStr = DateFormat('HH.mm').format(zone.startTime);
      final String endStr = DateFormat('HH.mm').format(zone.endTime);
      final String pukulStr = '$startStr s/d $endStr WIB';
      final String giatStr = zone.activityName;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              _buildHeader(
                pokjar,
                hariTanggalStr,
                giatStr,
                pukulStr,
                fontRegular,
                fontBold,
              ),
              pw.SizedBox(height: 12),
              _buildTitle(tahunStr, fontBold),
              pw.SizedBox(height: 12),
              _buildTable(listSerdik, fontRegular, fontBold),
              pw.SizedBox(height: 16),
              _buildFooter(
                tglLembangStr,
                tahunStr,
                total,
                hadir,
                kurang,
                sakit,
                ijin,
                tk,
                telat,
                fontRegular,
                fontBold,
              ),
            ];
          },
        ),
      );
    }

    final String formatTgl = DateFormat('ddMMyyyy').format(date);
    String numPokjar = 'I';
    if (pokjar.contains('1')) numPokjar = 'I';
    if (pokjar.contains('2')) numPokjar = 'II';
    if (pokjar.contains('3')) numPokjar = 'III';
    if (pokjar.contains('4')) numPokjar = 'IV';
    if (pokjar.contains('5')) numPokjar = 'V';

    final String filename =
        '${numPokjar}_LAPORAN_ABSENSI_HARIAN_$formatTgl.pdf';

    await Printing.sharePdf(bytes: await pdf.save(), filename: filename);
  }

  static pw.Widget _buildHeader(
    String pokjar,
    String hariTanggal,
    String giat,
    String pukul,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    String numPokjar = 'I';
    if (pokjar.contains('1')) numPokjar = 'I';
    if (pokjar.contains('2')) numPokjar = 'II';
    if (pokjar.contains('3')) numPokjar = 'III';
    if (pokjar.contains('4')) numPokjar = 'IV';
    if (pokjar.contains('5')) numPokjar = 'V';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'SESPIM LEMDIKLAT POLRI',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                  pw.Text(
                    'SEKOLAH STAF DAN PIMPINAN PERTAMA',
                    style: pw.TextStyle(
                      font: fontRegular,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Hari/Tanggal',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      ':',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      hariTanggal,
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Giat',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      ':',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      giat,
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Pukul',
                        style: pw.TextStyle(font: fontRegular, fontSize: 10),
                      ),
                    ),
                    pw.Text(
                      ':',
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      pukul,
                      style: pw.TextStyle(font: fontRegular, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'POKJAR',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              numPokjar,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitle(String tahun, pw.Font fontBold) {
    return pw.Center(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'ABSENSI PESERTA DIDIK',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'SESPIMMA POLRI ANGKATAN KE-75 T.A. $tahun',
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(
    List<SerdikAttendanceStatus> listSerdik,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(100),
        3: const pw.FixedColumnWidth(120),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NO',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NAMA',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NO SERDIK',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                'DETEKSI SISTEM',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        pw.TableRow(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '1',
                style: pw.TextStyle(font: fontRegular, fontSize: 9),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '2',
                style: pw.TextStyle(font: fontRegular, fontSize: 9),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '3',
                style: pw.TextStyle(font: fontRegular, fontSize: 9),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '4',
                style: pw.TextStyle(font: fontRegular, fontSize: 9),
              ),
            ),
          ],
        ),

        ...List.generate(listSerdik.length, (index) {
          final serdik = listSerdik[index];
          String nama = serdik.nama;
          String noSerdik = serdik.noSerdik;

          String status = serdik.status;

          return pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '${index + 1}.',
                  style: pw.TextStyle(font: fontRegular, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  nama,
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: nama.length > 35 ? 6 : (nama.length > 25 ? 7 : 9),
                  ),
                  maxLines: 1,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  noSerdik,
                  style: pw.TextStyle(font: fontRegular, fontSize: 9),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 2,
                  horizontal: 4,
                ),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  status,
                  style: pw.TextStyle(font: fontRegular, fontSize: 9),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildFooter(
    String tglLembang,
    String tahun,
    int total,
    int hadir,
    int kurang,
    int sakit,
    int ijin,
    int tk,
    int telat,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    'DANTON',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                ),
                pw.SizedBox(width: 60),
                pw.Text(
                  'DANKI HARIAN',
                  style: pw.TextStyle(font: fontRegular, fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KET.',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 10,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _buildKetRow('JUMLAH', total.toString(), fontRegular),
                    _buildKetRow('HADIR', hadir.toString(), fontRegular),
                    _buildKetRow('KURANG', kurang.toString(), fontRegular),
                  ],
                ),
                pw.SizedBox(width: 60),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KET KURANG:',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 10,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    _buildKetKurangRow('SAKIT', sakit.toString(), fontRegular),
                    _buildKetKurangRow('IJIN', ijin.toString(), fontRegular),
                    _buildKetKurangRow('TK', tk.toString(), fontRegular),
                    _buildKetKurangRow('TELAT', telat.toString(), fontRegular),
                  ],
                ),
              ],
            ),
          ],
        ),

        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'LEMBANG, $tglLembang $tahun',
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'KAKORSIS',
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
            pw.SizedBox(height: 35),
            pw.Text(
              'SUPRAYITNO, S.H.,S.I.K.',
              style: pw.TextStyle(
                font: fontRegular,
                fontSize: 10,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text(
              'KOMBES POL NRP. 70012128',
              style: pw.TextStyle(font: fontRegular, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildKetRow(
    String label,
    String value,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 60,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: fontRegular, fontSize: 10),
          ),
        ),
        pw.Text(':', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.SizedBox(width: 8),
        pw.Text(value, style: pw.TextStyle(font: fontRegular, fontSize: 10)),
      ],
    );
  }

  static pw.Widget _buildKetKurangRow(
    String label,
    String value,
    pw.Font fontRegular,
  ) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 40,
          child: pw.Text(
            label,
            style: pw.TextStyle(font: fontRegular, fontSize: 10),
          ),
        ),
        pw.Text(':', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
        pw.SizedBox(width: 8),
        pw.SizedBox(
          width: 20,
          child: pw.Text(
            value,
            style: pw.TextStyle(font: fontRegular, fontSize: 10),
          ),
        ),
        pw.Text('an.', style: pw.TextStyle(font: fontRegular, fontSize: 10)),
      ],
    );
  }
}

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import '../../data/models/final_recap_model.dart';

class PdfReportService {
  static Future<void> generateLeadershipReport({
    required List<FinalRecapModel> data,
    required String pokjar,
  }) async {
    final pdf = pw.Document();

    final fontBoldData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Bold.ttf',
    );
    final fontBold = pw.Font.ttf(fontBoldData);
    final fontRegularData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Regular.ttf',
    );
    final fontRegular = pw.Font.ttf(fontRegularData);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            _buildHeader(fontBold, fontRegular),
            pw.SizedBox(height: 20),
            _buildTitle(fontBold, pokjar),
            pw.SizedBox(height: 20),
            _buildTable(data, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            _buildSummary(data, fontBold, fontRegular),
            pw.SizedBox(height: 40),
            _buildFooter(fontBold, fontRegular),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Kepemimpinan_${pokjar.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildHeader(pw.Font bold, pw.Font regular) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SESPIM LEMDIKLAT POLRI',
          style: pw.TextStyle(font: bold, fontSize: 10),
        ),
        pw.Text(
          'SEKOLAH STAF DAN PIMPINAN PERTAMA',
          style: pw.TextStyle(font: bold, fontSize: 10),
        ),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 2),
          width: 210,
          child: pw.Divider(thickness: 1),
        ),
      ],
    );
  }

  static pw.Widget _buildTitle(pw.Font bold, String pokjar) {
    final year = DateTime.now().year;
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'LAPORAN HASIL NILAI AKHIR KESELURUHAN SERDIK',
            style: pw.TextStyle(font: bold, fontSize: 12),
          ),
          pw.Text(
            'SESPIM LEMDIKLAT POLRI ANGKATAN KE-75 T.A.$year',
            style: pw.TextStyle(font: bold, fontSize: 12),
          ),
          if (pokjar != 'Semua') ...[
            pw.SizedBox(height: 5),
            pw.Text(
              'WILAYAH MONITORING: ${pokjar.toUpperCase()}',
              style: pw.TextStyle(font: bold, fontSize: 11),
            ),
          ],
          pw.SizedBox(height: 5),
          pw.Container(width: 400, child: pw.Divider(thickness: 2)),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(
    List<FinalRecapModel> data,
    pw.Font bold,
    pw.Font regular,
  ) {
    final headers = [
      'NO',
      'NAMA / NOSIS',
      'POKJAR',
      'AKADEMIK',
      'MENTAL',
      'JASMANI',
      'NAK',
      'STATUS',
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: List.generate(data.length, (index) {
        final item = data[index];
        final isLulus = item.average >= 70.0;
        return [
          '${index + 1}',
          '${item.name}\n${item.nosis}',
          item.pokjar,
          item.academicScore.toStringAsFixed(2),
          item.mentalScore.toStringAsFixed(2),
          item.physicalScore.toStringAsFixed(2),
          item.average.toStringAsFixed(2),
          isLulus ? 'LULUS' : 'TIDAK LULUS',
        ];
      }),
      headerStyle: pw.TextStyle(
        font: bold,
        fontSize: 9,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellStyle: pw.TextStyle(font: regular, fontSize: 8),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FixedColumnWidth(55),
        4: const pw.FixedColumnWidth(45),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FixedColumnWidth(40),
        7: const pw.FixedColumnWidth(65),
      },
      cellAlignment: pw.Alignment.center,
      cellAlignments: {1: pw.Alignment.centerLeft},
    );
  }

  static pw.Widget _buildSummary(
    List<FinalRecapModel> data,
    pw.Font bold,
    pw.Font regular,
  ) {
    final int lulus = data.where((r) => r.average >= 70.0).length;
    final int tidakLulus = data.length - lulus;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'RINGKASAN KELULUSAN:',
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Total Serdik Terpilih : ${data.length} Orang',
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
            pw.Text(
              'Memenuhi Syarat (Lulus) : $lulus Orang',
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
            pw.Text(
              'Peringatan Khusus      : $tidakLulus Orang',
              style: pw.TextStyle(font: regular, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font bold, pw.Font regular) {
    final date = DateTime.now();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dateStr = '${date.day} ${months[date.month - 1]} ${date.year}';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'Ditetapkan di: Lembang\npada tanggal: $dateStr',
              style: pw.TextStyle(font: regular, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'KA SESPIMMA SESPIM LEMDIKLAT POLRI',
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
            pw.SizedBox(height: 60),
            pw.Text(
              'VICTOR T. OGI TAMBUNAN, S.H., S.I.K.',
              style: pw.TextStyle(
                font: bold,
                fontSize: 10,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text(
              'BRIGADIR JENDERAL POLISI',
              style: pw.TextStyle(font: regular, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

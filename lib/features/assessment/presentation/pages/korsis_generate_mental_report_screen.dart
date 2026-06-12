import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/data/datasources/korsis_real_data.dart';
import 'package:sespimma/features/assessment/data/models/serdik_mental_scores.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class KorsisGenerateMentalReportScreen extends StatefulWidget {
  const KorsisGenerateMentalReportScreen({super.key});

  @override
  State<KorsisGenerateMentalReportScreen> createState() =>
      _KorsisGenerateMentalReportScreenState();
}

class _KorsisGenerateMentalReportScreenState
    extends State<KorsisGenerateMentalReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _noNotaController = TextEditingController();
  final _angkatanController = TextEditingController();
  final _tahunController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final _tempatController = TextEditingController(text: 'LEMBANG');

  final _namaKetuaController = TextEditingController();
  final _pangkatNrpController = TextEditingController();

  DateTime _tanggalPembuatan = DateTime.now();
  DateTimeRange _laporanTanggal = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _loadKetuaPelaksana();
  }

  void _loadKetuaPelaksana() {
    try {
      final ketua = KorsisRealData.records.firstWhere(
        (k) => k['peran_pengasuhan'] == 'Ketua Pelaksana',
        orElse: () => <String, dynamic>{},
      );

      if (ketua.isNotEmpty) {
        final nama = ketua['nama']?.toString().toUpperCase() ?? '';
        final pangkat = _mapPangkat(ketua['pangkat']?.toString() ?? '');
        final nrp = ketua['nrp_nip']?.toString() ?? '';

        _namaKetuaController.text = nama;
        _pangkatNrpController.text = '$pangkat NRP. $nrp';
      }
    } catch (_) {}
  }

  String _mapPangkat(String pangkatLengkap) {
    switch (pangkatLengkap.toLowerCase()) {
      case 'komisaris besar polisi':
        return 'KOMBES POL';
      case 'ajun komisaris besar polisi':
        return 'AKBP';
      case 'komisaris polisi':
        return 'KOMPOL';
      case 'inspektur satu':
        return 'IPTU';
      case 'inspektur dua':
        return 'IPDA';
      default:
        return pangkatLengkap.toUpperCase();
    }
  }

  @override
  void dispose() {
    _noNotaController.dispose();
    _angkatanController.dispose();
    _tahunController.dispose();
    _tempatController.dispose();
    _namaKetuaController.dispose();
    _pangkatNrpController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalPembuatan() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPembuatan,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _tanggalPembuatan = picked);
    }
  }

  Future<void> _pickLaporanTanggal() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _laporanTanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _laporanTanggal = picked);
    }
  }

  List<Map<String, dynamic>> _getSortedSerdikData() {
    List<Map<String, dynamic>> allSerdik = SerdikRealData.records
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    for (var s in allSerdik) {
      final nosis = s['no_serdik'].toString();
      final mentalData = SerdikMentalScores.getScores(nosis);
      s['moral'] = mentalData['moral'] ?? 0.0;
      s['disiplin'] = mentalData['disiplin'] ?? 0.0;
      s['kepemimpinan'] = mentalData['kepemimpinan'] ?? 0.0;
      s['pengendalian_diri'] = mentalData['pengendalian_diri'] ?? 0.0;
      s['penampilan'] = mentalData['penampilan'] ?? 0.0;
      final socA = mentalData['sosiometri_awal'] ?? 0.0;
      final socB = mentalData['sosiometri_akhir'] ?? 0.0;
      s['sosiometri'] = (socA + socB) / 2;
      s['nilai'] = mentalData['nilai'] ?? 0.0;
      s['ket'] = s['jabatan_senat'] ?? '';
    }

    allSerdik.sort(
      (a, b) => (b['nilai'] as double).compareTo(a['nilai'] as double),
    );
    return allSerdik;
  }

  String _toRoman(int number) {
    if (number < 1 || number > 12) return '';
    const romans = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
    ];
    return romans[number - 1];
  }

  Future<void> _generatePDF() async {
    if (!_formKey.currentState!.validate()) return;

    final serdikData = _getSortedSerdikData();
    final pdf = pw.Document();

    const f4 = PdfPageFormat(
      210 * PdfPageFormat.mm,
      330 * PdfPageFormat.mm,
      marginAll: 40,
    );
    final fontBaseData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Regular.ttf',
    );
    final fontBase = pw.Font.ttf(fontBaseData);
    final fontBoldData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Bold.ttf',
    );
    final fontBold = pw.Font.ttf(fontBoldData);

    final romanMonth = _toRoman(_tanggalPembuatan.month);
    final nomorDinas =
        'B/ND - ${_noNotaController.text.trim()}/$romanMonth/DIK.2.2./${_tanggalPembuatan.year}/Korsis';
    final tglBuatStr =
        '${_tempatController.text.toUpperCase()}, ${_tanggalPembuatan.day} ${_getMonthName(_tanggalPembuatan.month)} ${_tanggalPembuatan.year}'
            .toUpperCase();
    final tglMulaiStr =
        '${_laporanTanggal.start.day} ${_getMonthName(_laporanTanggal.start.month)} ${_laporanTanggal.start.year}';
    final tglAkhirStr =
        '${_laporanTanggal.end.day} ${_getMonthName(_laporanTanggal.end.month)} ${_laporanTanggal.end.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: f4,
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'SESPIMMA SESPIM LEMDIKLAT POLRI',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'KOORDINATOR SISWA',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 2),
                      width: 200,
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ],
                ),
                pw.SizedBox(),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'NOTA DINAS',
                  style: pw.TextStyle(
                    font: fontBase,
                    fontSize: 11,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Nomor : $nomorDinas',
                  style: pw.TextStyle(font: fontBase, fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text(
                          'Kepada',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        ':',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Text(
                          'Yth. Kepala Sekolah Staf dan Pimpinan Pertama Lemdiklat Polri',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text(
                          'Dari',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        ':',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Text(
                          'Kepala Koordinator Siswa Sespimma Polri',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 50,
                        child: pw.Text(
                          'Perihal',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                      pw.Text(
                        ':',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Text(
                          'laporan Nilai Mental Kepribadian Serdik Sespimma Polri Angkatan ke-${_angkatanController.text} T.A.${_tahunController.text}.',
                          style: pw.TextStyle(font: fontBase, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '1.  ',
                  style: pw.TextStyle(font: fontBase, fontSize: 11),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Rujukan :',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'a.  ',
                            style: pw.TextStyle(font: fontBase, fontSize: 11),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Keputusan Kepala Kepolisian Negara Republik Indonesia Nomor: Kep/1954/XII/2025 tanggal 18 Desember 2025 tentang Program dan Pelatihan Polri Tahun Anggaran 2026;',
                              style: pw.TextStyle(font: fontBase, fontSize: 11),
                              textAlign: pw.TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'b.  ',
                            style: pw.TextStyle(font: fontBase, fontSize: 11),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Keputusan Kepala Lembaga Pendidikan dan Pelatihan Polri Nomor: Kep/1008/XII/2025 tanggal 01 Desember 2025 Tentang Kurikulum Sekolah Staf dan Pimpinan Pertama Polri Tahun Anggaran 2026;',
                              style: pw.TextStyle(font: fontBase, fontSize: 11),
                              textAlign: pw.TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'c.  ',
                            style: pw.TextStyle(font: fontBase, fontSize: 11),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Keputusan Kepala Sekolah staf dan Pimpinan Pertama Nomor: Kep/14/II/2026 tanggal 09 Februari 2026 Tentang Peraturan Kehidupan Siswa Peserta Didik Sespimma Polri Tahun Anggaran 2026.',
                              style: pw.TextStyle(font: fontBase, fontSize: 11),
                              textAlign: pw.TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '2.  ',
                  style: pw.TextStyle(font: fontBase, fontSize: 11),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Sehubungan dengan rujukan di atas, dengan ini dilaporkan kepada Jenderal Nilai Mental Kepribadian mulai tanggal $tglMulaiStr sd $tglAkhirStr Serdik Sespimma Polri Angkatan ke-${_angkatanController.text} T.A. ${_tahunController.text}. Adapun komponen penilaian Mental adalah :',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'a.  Reward Keaktifan Perangkat Senat;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'b.  Reward Sprin Penugasan;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'c.  Reward Keagamaan;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'd.  Reward Danki Harian;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'e.  Reward Pengibar Bendera;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'f.  Reward Bakti Sosial;',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                      pw.Text(
                        'g.  Reward Sumbang Buku.',
                        style: pw.TextStyle(font: fontBase, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '3.  ',
                  style: pw.TextStyle(font: fontBase, fontSize: 11),
                ),
                pw.Expanded(
                  child: pw.Text(
                    'Demikian untuk menjadi maklum.',
                    style: pw.TextStyle(font: fontBase, fontSize: 11),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      tglBuatStr,
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                    pw.Text(
                      'KAKORSIS SESPIMMA',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Text(
                      _namaKetuaController.text.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text(
                      _pangkatNrpController.text.toUpperCase(),
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),

            pw.NewPage(),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'SESPIM LEMDIKLAT POLRI',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      'SEKOLAH STAF DAN PIMPINAN PERTAMA',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Container(
                      margin: const pw.EdgeInsets.only(top: 2),
                      width: 210,
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'NILAI MENTAL KEPRIBADIAN SERDIK SESPIMMA SESPIM LEMDIKLAT POLRI ANGKATAN KE-${_angkatanController.text} T.A.${_tahunController.text}',
                  style: pw.TextStyle(
                    font: fontBase,
                    fontSize: 10,
                    decoration: pw.TextDecoration.underline,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
            pw.SizedBox(height: 15),

            _buildTable(
              serdikData,
              fontBase,
              fontBold,
              tglMulaiStr,
              tglAkhirStr,
            ),

            pw.SizedBox(height: 30),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      tglBuatStr,
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                    pw.Text(
                      'KAKORSIS SESPIMMA',
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Text(
                      _namaKetuaController.text.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text(
                      _pangkatNrpController.text.toUpperCase(),
                      style: pw.TextStyle(font: fontBase, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/Laporan_Mental_Korsis.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        AppNotifier.showSuccess(
          context,
          'Laporan berhasil dibuat! Membuka file...',
        );
      }

      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(context, 'Gagal membuat laporan: $e');
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _formatDateUI(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  pw.Widget _buildTable(
    List<Map<String, dynamic>> data,
    pw.Font base,
    pw.Font bold,
    String startStr,
    String endStr,
  ) {
    final subHeaderRange =
        'DARI TGL ${startStr.toUpperCase()} S/D ${endStr.toUpperCase()}';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(3.3),
        2: const pw.FlexColumnWidth(1.8),
        3: const pw.FlexColumnWidth(7.5),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(2.5),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 36,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NO',
                style: pw.TextStyle(font: bold, fontSize: 7),
              ),
            ),
            pw.Container(
              height: 36,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NAMA',
                style: pw.TextStyle(font: bold, fontSize: 7),
              ),
            ),
            pw.Container(
              height: 36,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NOSIS',
                style: pw.TextStyle(font: bold, fontSize: 7),
              ),
            ),

            pw.Container(
              height: 36,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Text(
                      subHeaderRange,
                      style: pw.TextStyle(font: bold, fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildSubHeaderCell('MORAL', bold, flex: 10),
                        _buildSubHeaderCell('DISIPLIN', bold, flex: 10),
                        _buildSubHeaderCell('KEPEMIM\nPINAN', bold, flex: 10),
                        _buildSubHeaderCell('PENGEN.D', bold, flex: 10),
                        _buildSubHeaderCell('PENAM\nPILAN', bold, flex: 10),
                        _buildSubHeaderCell(
                          'SOSIO\nMETRI',
                          bold,
                          flex: 10,
                          noRightBorder: true,
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          top: pw.BorderSide(
                            color: PdfColors.black,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _buildSubHeaderCell('20%', bold, flex: 10),
                          _buildSubHeaderCell('15%', bold, flex: 10),
                          _buildSubHeaderCell('20%', bold, flex: 10),
                          _buildSubHeaderCell('15%', bold, flex: 10),
                          _buildSubHeaderCell('15%', bold, flex: 10),
                          _buildSubHeaderCell(
                            '15%',
                            bold,
                            flex: 10,
                            noRightBorder: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 36,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'NILAI',
                style: pw.TextStyle(font: bold, fontSize: 7),
              ),
            ),
            pw.Container(
              height: 36,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'KET',
                style: pw.TextStyle(font: bold, fontSize: 7),
              ),
            ),
          ],
        ),

        for (var i = 0; i < data.length; i++)
          pw.TableRow(
            children: [
              _buildDataCell('${i + 1}', base),
              _buildDataCell(
                data[i]['nama_lengkap'] ?? '-',
                base,
                align: pw.Alignment.centerLeft,
              ),
              _buildDataCell(data[i]['no_serdik'] ?? '-', base),

              pw.Row(
                children: [
                  _buildSubDataCell(
                    (data[i]['moral'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                  ),
                  _buildSubDataCell(
                    (data[i]['disiplin'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                  ),
                  _buildSubDataCell(
                    (data[i]['kepemimpinan'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                  ),
                  _buildSubDataCell(
                    (data[i]['pengendalian_diri'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                  ),
                  _buildSubDataCell(
                    (data[i]['penampilan'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                  ),
                  _buildSubDataCell(
                    (data[i]['sosiometri'] as double).toStringAsFixed(2),
                    base,
                    flex: 10,
                    noRightBorder: true,
                  ),
                ],
              ),
              _buildDataCell(
                (data[i]['nilai'] as double).toStringAsFixed(2),
                base,
              ),
              _buildDataCell(
                data[i]['ket']?.toString() ?? '',
                base,
                align: pw.Alignment.center,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildSubHeaderCell(
    String text,
    pw.Font bold, {
    int flex = 1,
    bool noRightBorder = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: noRightBorder
              ? null
              : const pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: bold, fontSize: 5),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildSubDataCell(
    String text,
    pw.Font base, {
    int flex = 1,
    bool noRightBorder = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        decoration: pw.BoxDecoration(
          border: noRightBorder
              ? null
              : const pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
        ),
        child: pw.Text(text, style: pw.TextStyle(font: base, fontSize: 7)),
      ),
    );
  }

  pw.Widget _buildDataCell(
    String text,
    pw.Font base, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(2),
      child: pw.FittedBox(
        fit: pw.BoxFit.scaleDown,
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(font: base, fontSize: 7),
          textAlign: align == pw.Alignment.center
              ? pw.TextAlign.center
              : pw.TextAlign.left,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        centerTitle: true,
        title: const Text(
          'Generate Laporan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXl,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('INFORMASI LAPORAN'),
              const SizedBox(height: AppDimensions.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nomor',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _noNotaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Wajib diisi' : null,
                    decoration: InputDecoration(
                      prefixText: 'B/ND - ',
                      prefixStyle: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      hintText:
                          '.../${_toRoman(DateTime.now().month)}/DIK.2.2./${DateTime.now().year}/Korsis',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primaryNavy,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Angkatan',
                      controller: _angkatanController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      hint: 'Contoh: 75',
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildTextField(
                      label: 'Tahun Ajaran',
                      controller: _tahunController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              _buildDateField(
                label: 'Laporan Periode Tanggal',
                value:
                    '${_formatDateUI(_laporanTanggal.start)} - ${_formatDateUI(_laporanTanggal.end)}',
                onTap: _pickLaporanTanggal,
              ),

              const SizedBox(height: AppDimensions.xl),
              _buildSectionTitle('PEMBUATAN SURAT'),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Tempat',
                      controller: _tempatController,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildDateField(
                      label: 'Tanggal Surat',
                      value: _formatDateUI(_tanggalPembuatan),
                      onTap: _pickTanggalPembuatan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              _buildTextField(
                label: 'KAKORSIS SESPIMMA',
                controller: _namaKetuaController,
                readOnly: true,
              ),
              const SizedBox(height: AppDimensions.md),
              _buildTextField(
                label: 'PANGKAT NRP',
                controller: _pangkatNrpController,
                readOnly: true,
              ),

              const SizedBox(height: AppDimensions.xxl),
              ElevatedButton.icon(
                onPressed: _generatePDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.white,
                ),
                label: const Text(
                  'GENERATE LAPORAN',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          validator: (value) =>
              value == null || value.isEmpty ? 'Wajib diisi' : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primaryNavy,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.blueGrey.shade400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

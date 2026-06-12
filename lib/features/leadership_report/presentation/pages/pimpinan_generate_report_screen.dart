import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/features/leadership_report/data/models/final_recap_model.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

class PimpinanGenerateReportScreen extends StatefulWidget {
  const PimpinanGenerateReportScreen({super.key});

  @override
  State<PimpinanGenerateReportScreen> createState() =>
      _PimpinanGenerateReportScreenState();
}

class _PimpinanGenerateReportScreenState
    extends State<PimpinanGenerateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _angkatanController = TextEditingController(text: '75');
  final _tahunController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  final _tempatController = TextEditingController(text: 'Lembang');

  final _namaKepalaController = TextEditingController(
    text: 'VICTOR T. OGI TAMBUNAN, S.H., S.I.K.',
  );
  final _pangkatController = TextEditingController(
    text: 'BRIGADIR JENDERAL POLISI',
  );

  DateTime _tanggalPembuatan = DateTime.now();

  @override
  void dispose() {
    _angkatanController.dispose();
    _tahunController.dispose();
    _tempatController.dispose();
    _namaKepalaController.dispose();
    _pangkatController.dispose();
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

  List<FinalRecapModel> get _allReports =>
      ScoreCalculatorService.generateRealReports();

  Future<void> _generatePDF() async {
    if (!_formKey.currentState!.validate()) return;

    final data = _allReports;
    final pdf = pw.Document();

    final fontBaseData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Regular.ttf',
    );
    final fontBase = pw.Font.ttf(fontBaseData);
    final fontBoldData = await rootBundle.load(
      'assets/fonts/Inter/static/Inter_18pt-Bold.ttf',
    );
    final fontBold = pw.Font.ttf(fontBoldData);

    final angkatan = _angkatanController.text.trim();
    final tahun = _tahunController.text.trim();
    final tglBuatStr =
        '${_tanggalPembuatan.day} ${_getMonthName(_tanggalPembuatan.month)} ${_tanggalPembuatan.year}';

    final int lulus = data.where((r) => r.average >= 70.0).length;
    final int tidakLulus = data.length - lulus;

    final sorted = List<FinalRecapModel>.from(data)
      ..sort((a, b) => b.average.compareTo(a.average));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: const PdfPageFormat(
          210 * PdfPageFormat.mm,
          330 * PdfPageFormat.mm,
          marginAll: 40,
        ),
        build: (pw.Context context) {
          return [
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
                pw.Expanded(
                  child: pw.Text(
                    'LAPORAN HASIL NILAI AKHIR KESELURUHAN SERDIK SESPIM LEMDIKLAT POLRI ANGKATAN KE-$angkatan T.A.$tahun',
                    style: pw.TextStyle(
                      font: fontBase,
                      fontSize: 10,
                      decoration: pw.TextDecoration.underline,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 15),

            _buildTable(sorted, fontBase, fontBold),

            pw.SizedBox(height: 20),

            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RINGKASAN KELULUSAN:',
                  style: pw.TextStyle(font: fontBold, fontSize: 10),
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 70,
                      child: pw.Text(
                        'Total Serdik',
                        style: pw.TextStyle(font: fontBase, fontSize: 9),
                      ),
                    ),
                    pw.Text(
                      ': ${data.length} Orang',
                      style: pw.TextStyle(font: fontBase, fontSize: 9),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 70,
                      child: pw.Text(
                        'Lulus',
                        style: pw.TextStyle(font: fontBase, fontSize: 9),
                      ),
                    ),
                    pw.Text(
                      ': $lulus Orang',
                      style: pw.TextStyle(font: fontBase, fontSize: 9),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Container(
                      width: 70,
                      child: pw.Text(
                        'Tidak Lulus',
                        style: pw.TextStyle(font: fontBase, fontSize: 9),
                      ),
                    ),
                    pw.Text(
                      ': $tidakLulus Orang',
                      style: pw.TextStyle(font: fontBase, fontSize: 9),
                    ),
                  ],
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
                      'Ditetapkan di: ${_tempatController.text}',
                      style: pw.TextStyle(font: fontBase, fontSize: 10),
                    ),
                    pw.Text(
                      'pada tanggal: $tglBuatStr',
                      style: pw.TextStyle(font: fontBase, fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'KA SESPIMMA SESPIM LEMDIKLAT POLRI',
                      style: pw.TextStyle(font: fontBase, fontSize: 10),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Text(
                      _namaKepalaController.text.toUpperCase(),
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Text(
                      _pangkatController.text.toUpperCase(),
                      style: pw.TextStyle(font: fontBase, fontSize: 10),
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
      final file = File('${output.path}/Laporan_Nilai_Akhir_Keseluruhan.pdf');
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

  pw.Widget _buildTable(
    List<FinalRecapModel> data,
    pw.Font base,
    pw.Font bold,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(2.0),
        3: const pw.FlexColumnWidth(1.0),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.0),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(1.0),
        8: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildHeaderCell('NO', bold),
            _buildHeaderCell('NAMA', bold),
            _buildHeaderCell('NOSIS', bold),
            _buildHeaderCell('POKJAR', bold),
            _buildHeaderCell('AKADEMIK', bold),
            _buildHeaderCell('MENTAL', bold),
            _buildHeaderCell('JASMANI', bold),
            _buildHeaderCell('NAK', bold),
            _buildHeaderCell('STATUS', bold),
          ],
        ),

        for (var i = 0; i < data.length; i++)
          pw.TableRow(
            children: [
              _buildDataCell('${i + 1}', base),
              _buildDataCell(
                data[i].name,
                base,
                align: pw.Alignment.centerLeft,
              ),
              _buildDataCell(data[i].nosis, base),
              _buildDataCell(data[i].pokjar, base),
              _buildDataCell(data[i].academicScore.toStringAsFixed(2), base),
              _buildDataCell(data[i].mentalScore.toStringAsFixed(2), base),
              _buildDataCell(data[i].physicalScore.toStringAsFixed(2), base),
              _buildDataCell(data[i].average.toStringAsFixed(2), base),
              _buildDataCell(
                data[i].average >= 70.0 ? 'LULUS' : 'TIDAK LULUS',
                base,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text, pw.Font bold) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: bold, fontSize: 7),
        textAlign: pw.TextAlign.center,
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

              const SizedBox(height: AppDimensions.xl),
              _buildSectionTitle('TANDA TANGAN'),
              const SizedBox(height: AppDimensions.md),
              _buildTextField(
                label: 'Nama Lengkap',
                controller: _namaKepalaController,
              ),
              const SizedBox(height: AppDimensions.md),
              _buildTextField(label: 'Pangkat', controller: _pangkatController),

              const SizedBox(height: AppDimensions.xxl),

              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Preview Informasi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.blue.shade800,
                            fontSize: AppDimensions.fontMd,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    const SizedBox(height: AppDimensions.sm),
                    _buildPreviewRow(
                      icon: Icons.groups_rounded,
                      label: 'Total Serdik:',
                      value: '${_allReports.length} Orang',
                      color: Colors.blueGrey.shade700,
                    ),
                    const SizedBox(height: 6),
                    _buildPreviewRow(
                      icon: Icons.check_circle_rounded,
                      label: 'Lulus:',
                      value:
                          '${_allReports.where((r) => r.average >= 70.0).length} Orang',
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 6),
                    _buildPreviewRow(
                      icon: Icons.cancel_rounded,
                      label: 'Tidak Lulus:',
                      value:
                          '${_allReports.where((r) => r.average < 70.0).length} Orang',
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.xl),
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

  Widget _buildPreviewRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

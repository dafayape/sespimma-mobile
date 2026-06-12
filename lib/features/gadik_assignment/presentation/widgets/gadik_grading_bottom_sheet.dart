import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import '../../data/models/gadik_assignment_model.dart';
import '../../data/models/gadik_submission_model.dart';
import 'package:sespimma/features/assessment/data/models/serdik_academic_scores.dart';

class GadikGradingBottomSheet extends StatefulWidget {
  final GadikAssignmentModel assignment;
  final GadikSubmissionModel submission;
  final Function(GadikSubmissionModel) onSaved;

  const GadikGradingBottomSheet({
    super.key,
    required this.assignment,
    required this.submission,
    required this.onSaved,
  });

  @override
  State<GadikGradingBottomSheet> createState() =>
      _GadikGradingBottomSheetState();
}

class _GadikGradingBottomSheetState extends State<GadikGradingBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _materiCtrl;
  late TextEditingController _penulisanCtrl;
  late TextEditingController _paparanCtrl;
  late TextEditingController _keaktifanCtrl;

  late TextEditingController _ujianCtrl;

  late TextEditingController _keaktifanPerseoranganCtrl;
  late TextEditingController _produkPerseoranganCtrl;
  late TextEditingController _tataRuangCtrl;

  late TextEditingController _catatanCtrl;
  late TextEditingController _beritaAcaraCtrl;

  double _calculatedNA = 0.0;

  String _getAssignmentCode(String jenis) {
    final lower = jenis.toLowerCase();
    if (lower.contains('ujian') || lower.contains('esai')) return 'NUMP';
    if (lower.contains('nkkp')) return 'NKKP';
    if (lower.contains('npkp')) return 'NPKP';
    if (lower.contains('simulasi') || lower.contains('nsk')) return 'NSK';
    if (lower.contains('nptt') || lower.contains('taskap')) return 'NPTT';
    if (lower.contains('nkp')) return 'NKP';
    return 'NILAI';
  }

  @override
  void initState() {
    super.initState();
    final s = widget.submission;

    _materiCtrl = TextEditingController(text: s.scoreMateri?.toString() ?? '');
    _penulisanCtrl = TextEditingController(
      text: s.scorePenulisan?.toString() ?? '',
    );
    _paparanCtrl = TextEditingController(
      text: s.scorePaparan?.toString() ?? '',
    );
    _keaktifanCtrl = TextEditingController(
      text: s.scoreKeaktifan?.toString() ?? '',
    );
    _ujianCtrl = TextEditingController(text: s.scoreUjian?.toString() ?? '');
    _keaktifanPerseoranganCtrl = TextEditingController(
      text: s.scoreKeaktifanPerseorangan?.toString() ?? '',
    );
    _produkPerseoranganCtrl = TextEditingController(
      text: s.scoreProdukPerseorangan?.toString() ?? '',
    );
    _tataRuangCtrl = TextEditingController(
      text: s.scoreTataRuang?.toString() ?? '',
    );
    _catatanCtrl = TextEditingController(text: s.catatanPengajar ?? '');
    _beritaAcaraCtrl = TextEditingController(text: '');

    _materiCtrl.addListener(_calculate);
    _penulisanCtrl.addListener(_calculate);
    _paparanCtrl.addListener(_calculate);
    _keaktifanCtrl.addListener(_calculate);
    _ujianCtrl.addListener(_calculate);
    _keaktifanPerseoranganCtrl.addListener(_calculate);
    _produkPerseoranganCtrl.addListener(_calculate);
    _tataRuangCtrl.addListener(_calculate);

    _calculate();
  }

  @override
  void dispose() {
    _materiCtrl.dispose();
    _penulisanCtrl.dispose();
    _paparanCtrl.dispose();
    _keaktifanCtrl.dispose();
    _ujianCtrl.dispose();
    _keaktifanPerseoranganCtrl.dispose();
    _produkPerseoranganCtrl.dispose();
    _tataRuangCtrl.dispose();
    _catatanCtrl.dispose();
    _beritaAcaraCtrl.dispose();
    super.dispose();
  }

  double _parse(String val) {
    if (val.isEmpty) return 0.0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
  }

  void _calculate() {
    double total = 0.0;
    final jenis = widget.assignment.jenisTugas;

    if (jenis == 'Ujian Mata Pelajaran atau Esai') {
      total = _parse(_ujianCtrl.text);
    } else if (jenis == 'Naskah Kuliah Kerja Profesi (NKKP)' ||
        jenis == 'NKKP (Naskah Kuliah Kerja Profesi)' ||
        jenis == 'Naskah Praktek Kerja Profesi (NPKP)' ||
        jenis == 'NPKP (Naskah Praktek Kerja Profesi)') {
      double m = _parse(_materiCtrl.text);
      double p = _parse(_paparanCtrl.text);
      double k = _parse(_keaktifanCtrl.text);
      total = ((m * 35) + (p * 35) + (k * 30)) / 100;
    } else if (jenis == 'Naskah Karya Perseorangan (NKP)' ||
        jenis == 'NKP (Naskah Karya Perseorangan)') {
      double m = _parse(_materiCtrl.text);
      double p = _parse(_paparanCtrl.text);
      total = ((m * 50) + (p * 50)) / 100;
    } else if (jenis == 'Simulasi Kepemimpinan Kontemporer' ||
        jenis == 'Simulasi Kepemimpinan Kontemporer (NSK)') {
      double k = _parse(_keaktifanPerseoranganCtrl.text);
      double p = _parse(_produkPerseoranganCtrl.text);
      double t = _parse(_tataRuangCtrl.text);
      total = ((k * 60) + (p * 20) + (t * 20)) / 100;
    } else if (jenis == 'Naskah Program Transformasi Teknis (NPTT)' ||
        jenis == 'NPTT (Naskah Program Transformasi Teknis)') {
      double m = _parse(_materiCtrl.text);
      double pe = _parse(_penulisanCtrl.text);
      double p = _parse(_paparanCtrl.text);
      total = ((m * 40) + (pe * 30) + (p * 30)) / 100;
    }

    setState(() {
      _calculatedNA = total;
    });
  }

  Color _getScoreColor(double score) {
    if (score == 0) return AppColors.primaryNavy;
    if (score > 85.00) return Colors.green.shade800;
    if (score > 80.00) return Colors.green.shade500;
    if (score > 75.00) return Colors.lime.shade700;
    if (score > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
  }

  String _getScoreCategory(double score) {
    if (score == 0) return '-';
    if (score < 70.01) return 'Kurang (K)';
    if (score <= 75.00) return 'Cukup (C)';
    if (score <= 80.00) return 'Baik (B)';
    if (score <= 85.00) return 'Memuaskan (M)';
    return 'Sangat Memuaskan (SM)';
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final s = GadikSubmissionModel(
        id: widget.submission.id,
        assignmentId: widget.submission.assignmentId,
        serdikName: widget.submission.serdikName,
        serdikNrp: widget.submission.serdikNrp,
        serdikPangkat: widget.submission.serdikPangkat,
        serdikNosis: widget.submission.serdikNosis,
        submittedAt: widget.submission.submittedAt,
        fileName: widget.submission.fileName,
        fileUrl: widget.submission.fileUrl,
        isGraded: true,
        nilaiAkhir: _calculatedNA,
        catatanPengajar: _calculatedNA > 90.00
            ? '${_beritaAcaraCtrl.text}${_catatanCtrl.text.isNotEmpty ? "\n\n${_catatanCtrl.text}" : ""}'
            : _catatanCtrl.text,
        scoreMateri: _materiCtrl.text.isNotEmpty
            ? _parse(_materiCtrl.text)
            : null,
        scorePenulisan: _penulisanCtrl.text.isNotEmpty
            ? _parse(_penulisanCtrl.text)
            : null,
        scorePaparan: _paparanCtrl.text.isNotEmpty
            ? _parse(_paparanCtrl.text)
            : null,
        scoreKeaktifan: _keaktifanCtrl.text.isNotEmpty
            ? _parse(_keaktifanCtrl.text)
            : null,
        scoreUjian: _ujianCtrl.text.isNotEmpty ? _parse(_ujianCtrl.text) : null,
        scoreKeaktifanPerseorangan: _keaktifanPerseoranganCtrl.text.isNotEmpty
            ? _parse(_keaktifanPerseoranganCtrl.text)
            : null,
        scoreProdukPerseorangan: _produkPerseoranganCtrl.text.isNotEmpty
            ? _parse(_produkPerseoranganCtrl.text)
            : null,
        scoreTataRuang: _tataRuangCtrl.text.isNotEmpty
            ? _parse(_tataRuangCtrl.text)
            : null,
      );

      final nosis = widget.submission.serdikNosis ?? '202602003001';
      final jenis = widget.assignment.jenisTugas;
      if (jenis == 'Ujian Mata Pelajaran atau Esai') {
        SerdikAcademicScores.updateScore(nosis, 'nump', _calculatedNA);
      } else if (jenis.contains('NKKP')) {
        SerdikAcademicScores.updateScore(nosis, 'nkkp', _calculatedNA);
      } else if (jenis.contains('NPKP')) {
        SerdikAcademicScores.updateScore(nosis, 'npkp', _calculatedNA);
      } else if (jenis.contains('NKP')) {
        SerdikAcademicScores.updateScore(nosis, 'nkp', _calculatedNA);
      } else if (jenis.contains('Simulasi') || jenis.contains('NSK')) {
        SerdikAcademicScores.updateScore(
          nosis,
          'nsk_keaktifan',
          _parse(_keaktifanPerseoranganCtrl.text),
        );
        SerdikAcademicScores.updateScore(
          nosis,
          'nsk_produk',
          _parse(_produkPerseoranganCtrl.text),
        );
        SerdikAcademicScores.updateScore(
          nosis,
          'nsk_tata_ruang',
          _parse(_tataRuangCtrl.text),
        );
      } else if (jenis.contains('NPTT') || jenis.contains('Taskap')) {
        SerdikAcademicScores.updateScore(
          nosis,
          'nt_materi',
          _parse(_materiCtrl.text),
        );
        SerdikAcademicScores.updateScore(
          nosis,
          'nt_penulisan',
          _parse(_penulisanCtrl.text),
        );
        SerdikAcademicScores.updateScore(
          nosis,
          'nt_paparan',
          _parse(_paparanCtrl.text),
        );
      }

      widget.onSaved(s);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _getAssignmentCode(widget.assignment.jenisTugas);
    final serdikNosis = widget.submission.serdikNosis ?? '202602003001';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Penilaian Serdik',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '${widget.submission.serdikName} · $serdikNosis',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  _buildDynamicForm(),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getScoreColor(
                        _calculatedNA,
                      ).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getScoreColor(
                          _calculatedNA,
                        ).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kalkulasi $code:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_calculatedNA),
                          ),
                        ),
                        Text(
                          _calculatedNA.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _getScoreColor(_calculatedNA),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_calculatedNA > 0) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getScoreColor(
                            _calculatedNA,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getScoreColor(
                              _calculatedNA,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _getScoreCategory(_calculatedNA),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _getScoreColor(_calculatedNA),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (_calculatedNA > 90.00) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Berita Acara',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _beritaAcaraCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Masukkan justifikasi pemberian nilai di atas 90',
                        filled: true,
                        fillColor: Colors.purple.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          borderSide: BorderSide(color: Colors.purple.shade200),
                        ),
                      ),
                      validator: (value) {
                        if (_calculatedNA > 90.00 &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Berita Acara wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  const Text(
                    'Catatan Pengajar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _catatanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Masukkan catatan, saran, atau komentar',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                      ),
                      child: const Text(
                        'SIMPAN NILAI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicForm() {
    final jenis = widget.assignment.jenisTugas;
    final lower = jenis.toLowerCase();

    if (lower.contains('ujian') || lower.contains('esai')) {
      return _buildInputRow('Nilai Ujian MP / Esai (100%)', _ujianCtrl);
    } else if (lower.contains('nkkp') || lower.contains('npkp')) {
      return Column(
        children: [
          _buildInputRow('Materi & Penulisan (35%)', _materiCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Paparan (35%)', _paparanCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Keaktifan (30%)', _keaktifanCtrl),
        ],
      );
    } else if (lower.contains('nkp') &&
        !lower.contains('nkkp') &&
        !lower.contains('npkp')) {
      return Column(
        children: [
          _buildInputRow('Materi & Penulisan (50%)', _materiCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Paparan (50%)', _paparanCtrl),
        ],
      );
    } else if (lower.contains('simulasi') || lower.contains('nsk')) {
      return Column(
        children: [
          _buildInputRow(
            'Keaktifan Perseorangan (60%)',
            _keaktifanPerseoranganCtrl,
          ),
          const SizedBox(height: 12),
          _buildInputRow('Produk Perseorangan (20%)', _produkPerseoranganCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Tata Ruang Kelompok (20%)', _tataRuangCtrl),
        ],
      );
    } else if (lower.contains('nptt') || lower.contains('taskap')) {
      return Column(
        children: [
          _buildInputRow('Materi (40%)', _materiCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Penulisan (30%)', _penulisanCtrl),
          const SizedBox(height: 12),
          _buildInputRow('Paparan & Diskusi (30%)', _paparanCtrl),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInputRow(String label, TextEditingController controller) {
    final double val = _parse(controller.text);
    final color = val > 0 ? _getScoreColor(val) : AppColors.primaryNavy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade700,
                ),
              ),
              if (val > 0)
                Text(
                  _getScoreCategory(val),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: 80,
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final val = double.tryParse(newValue.text);
                if (val == null || val > 100 || val < 0) {
                  return oldValue;
                }
                return newValue;
              }),
            ],
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              filled: true,
              fillColor: val > 0 ? color.withValues(alpha: 0.05) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: val > 0
                      ? color.withValues(alpha: 0.5)
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Isi';
              final d = double.tryParse(value.replaceAll(',', '.'));
              if (d == null || d < 0 || d > 100) return '0-100';
              return null;
            },
          ),
        ),
      ],
    );
  }
}

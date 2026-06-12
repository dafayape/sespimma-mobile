import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/gadik_assignment_model.dart';
import '../../data/datasources/gadik_assignment_mock_data.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assignment/data/models/tugas_model.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/features/auth/data/datasources/gadik_real_data.dart';

class GadikCreateAssignmentScreen extends StatefulWidget {
  final bool isRemedialMode;
  final List<String>? remedialSerdiks;

  const GadikCreateAssignmentScreen({
    super.key,
    this.isRemedialMode = false,
    this.remedialSerdiks,
  });

  @override
  State<GadikCreateAssignmentScreen> createState() =>
      _GadikCreateAssignmentScreenState();
}

class _GadikCreateAssignmentScreenState
    extends State<GadikCreateAssignmentScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _instruksiController = TextEditingController();

  String _jenisTugas = 'Ujian Mata Pelajaran atau Esai (NUMP)';
  DateTime? _deadline;
  String _targetPokjar = 'Semua Pokjar';
  String? _fileName;

  final List<String> _jenisTugasList = [
    'Ujian Mata Pelajaran atau Esai (NUMP)',
    'Naskah Kuliah Kerja Profesi (NKKP)',
    'Naskah Praktek Kerja Profesi (NPKP)',
    'Naskah Karya Perseorangan (NKP)',
    'Simulasi Kepemimpinan Kontemporer (NSK)',
    'Naskah Program Transformasi Teknis (NPTT)',
  ];

  final List<String> _pokjarList = [
    'Semua Pokjar',
    'Pokjar I',
    'Pokjar II',
    'Pokjar III',
    'Pokjar IV',
    'Pokjar V',
  ];

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_deadline == null) {
        AppNotifier.showError(context, 'Batas pengumpulan wajib diisi');
        return;
      }

      final String id = 'G-${DateTime.now().millisecondsSinceEpoch}';

      final newTask = GadikAssignmentModel(
        id: id,
        judul: _judulController.text,
        jenisTugas: _jenisTugas,
        deadline: _deadline!,
        targetPokjar: _targetPokjar,
        instruksi: _instruksiController.text,
        status: 'Belum Mulai',
        createdBy: GadikRealData.records.first['nama'],
        createdAt: DateTime.now(),
        fileName: _fileName,
        fileUrl: _fileName != null ? 'https://example.com/$_fileName' : null,
      );

      GadikAssignmentMockData.assignments.add(newTask);

      final newSerdikTask = TugasModel(
        id: id,
        judul: _judulController.text,
        deskripsi: _instruksiController.text,
        mapel: _jenisTugas,
        deadline: _deadline!,
        status: 'Aktif',
        createdBy: GadikRealData.records.first['nrp_nip'],
        createdByName: GadikRealData.records.first['nama'],
      );
      PimpinanMockData.sharedTasks.add(newSerdikTask);

      HapticFeedback.lightImpact();
      Navigator.pop(context, true);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryNavy,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: _primaryNavy,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (timePicked != null) {
        setState(() {
          _deadline = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result != null) {
      setState(() {
        _fileName = result.files.single.name;
      });
    }
  }

  void _removeFile() {
    setState(() {
      _fileName = null;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isRemedialMode) {
      _targetPokjar = 'Target Serdik (Remedial)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _primaryNavy,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            title: Text(
              widget.isRemedialMode ? 'Buat Tugas Remedial' : 'Buat Tugas Baru',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: AppDimensions.fontLg,
                letterSpacing: -0.3,
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informasi Utama'),
                      const SizedBox(height: AppDimensions.md),
                      _buildLabel('Judul Tugas'),
                      TextFormField(
                        controller: _judulController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryNavy,
                        ),
                        decoration: _inputDecoration(
                          'Contoh: Analisis Kebijakan...',
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Judul wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      _buildLabel('Jenis Tugas'),
                      DropdownButtonFormField<String>(
                        initialValue: _jenisTugas,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _primaryNavy,
                        ),
                        decoration: _inputDecoration('Pilih jenis tugas'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _primaryNavy,
                          fontSize: AppDimensions.fontLg,
                        ),
                        items: _jenisTugasList
                            .map(
                              (j) => DropdownMenuItem(
                                value: j,
                                child: Text(
                                  j,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _jenisTugas = val!;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      const Divider(height: 32, color: Color(0xFFF1F5F9)),
                      _buildSectionTitle('Pengaturan Distribusi'),
                      const SizedBox(height: AppDimensions.md),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Batas Waktu'),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _selectDate,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusLg,
                                    ),
                                    child: InputDecorator(
                                      decoration: _inputDecoration(
                                        'Pilih Tanggal',
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _deadline != null
                                                  ? DateFormat(
                                                      'dd MMM yy, HH:mm',
                                                      'id_ID',
                                                    ).format(_deadline!)
                                                  : 'Pilih Jadwal',
                                              style: TextStyle(
                                                color: _deadline != null
                                                    ? _primaryNavy
                                                    : Colors.blueGrey.shade400,
                                                fontWeight: _deadline != null
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                fontSize: AppDimensions.fontSm,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            size: 18,
                                            color: _deadline != null
                                                ? _primaryNavy
                                                : Colors.blueGrey.shade400,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel(
                                  widget.isRemedialMode
                                      ? 'Target Serdik'
                                      : 'Target Pokjar',
                                ),
                                if (widget.isRemedialMode)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: (widget.remedialSerdiks ?? [])
                                        .map((serdikName) {
                                          return Chip(
                                            label: Text(
                                              serdikName,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.red.shade400,
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              side: BorderSide.none,
                                            ),
                                          );
                                        })
                                        .toList(),
                                  )
                                else
                                  DropdownButtonFormField<String>(
                                    initialValue: _targetPokjar,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _primaryNavy,
                                      size: 20,
                                    ),
                                    decoration: _inputDecoration(
                                      'Pilih Target',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _primaryNavy,
                                      fontSize: AppDimensions.fontSm,
                                    ),
                                    items: _pokjarList
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(
                                              p,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) =>
                                        setState(() => _targetPokjar = val!),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 32, color: Color(0xFFF1F5F9)),
                      _buildSectionTitle('Lampiran Dokumen'),
                      const SizedBox(height: AppDimensions.md),

                      _buildLabel('Instruksi Tambahan'),
                      TextFormField(
                        controller: _instruksiController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _primaryNavy,
                        ),
                        decoration: _inputDecoration(
                          'Ketik instruksi spesifik di sini...',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),

                      _buildLabel('Unggah File Pendukung'),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _pickFile,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(AppDimensions.lg),
                            decoration: BoxDecoration(
                              color: _fileName != null
                                  ? _primaryNavy.withValues(alpha: 0.05)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              border: Border.all(
                                color: _fileName == null
                                    ? Colors.grey.shade200
                                    : _primaryNavy.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: _fileName == null
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.cloud_upload_rounded,
                                          color: Colors.blueGrey.shade400,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Pilih File Dokumen',
                                        style: TextStyle(
                                          color: Colors.blueGrey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _primaryNavy.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            AppDimensions.radiusMd,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.description_rounded,
                                          color: _primaryNavy,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _fileName!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: _primaryNavy,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel_rounded,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                        onPressed: _removeFile,
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xxxl),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryNavy,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: _primaryNavy.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXl,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'TERBITKAN TUGAS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppDimensions.fontLg,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: _primaryNavy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.blueGrey.shade300,
        fontSize: AppDimensions.fontSm,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: const BorderSide(color: _primaryNavy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
      ),
    );
  }
}

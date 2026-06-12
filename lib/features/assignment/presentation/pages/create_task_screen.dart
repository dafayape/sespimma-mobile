import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/assignment/data/models/tugas_model.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String? _selectedSubject;
  String? _selectedKompetensi;
  String? _selectedMental;

  late AnimationController _animController;
  late Animation<double> _formAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _formAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _buttonAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  String? _selectedPokjar;
  DateTime? _selectedDeadline;
  String? _attachedFileName;
  bool _isAttaching = false;

  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _lightGrey = Color(0xFFF8FAFC);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _surfaceColor = Colors.white;

  final List<String> _pokjarList = [
    'Semua POKJAR',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  final List<String> _subjectList = [
    'NKP (Naskah Karya Perseorangan)',
    'NKKP (Naskah Kuliah Kerja Profesi)',
    'NPKP (Naskah Praktek Kerja Profesi)',
    'Ujian MP / Esai',
    'Mental Kepribadian',
    'Etika & Kepemimpinan',
    'Manajemen Strategis',
    'Sistem Informasi Publik',
  ];

  final List<String> _kompetensiList = [
    'Kemampuan Membuat Keputusan Strategis',
    'Kecerdasan Emosional (EQ)',
    'Komunikasi Efektif',
    'Kemampuan Membangun dan Memimpin',
    'Adaptabilitas & Pembelajaran Kontinu',
    'Visi & Strategic Thinking',
    'Integritas & Etika',
    'Kemampuan Mendayagunakan Teknologi',
    'Empati & Pelayanan',
    'Resilience & Ketahanan Mental',
  ];

  final List<String> _mentalList = [
    'Aspek Moral (Taat Beragama, dll)',
    'Aspek Disiplin',
    'Aspek Kepemimpinan',
    'Aspek Pengendalian Diri',
    'Aspek Penampilan',
  ];

  @override
  void dispose() {
    _animController.dispose();
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isAttaching = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(
          context,
          'Gagal memilih file. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAttaching = false);
      }
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryNavy,
              onPrimary: Colors.white,
              onSurface: _primaryNavy,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _primaryNavy,
                onPrimary: Colors.white,
                onSurface: _primaryNavy,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDeadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _publishTask() {
    if (_formKey.currentState!.validate()) {
      if (_selectedSubject == null) {
        AppNotifier.showError(
          context,
          'Silahkan pilih mata pelajaran terlebih dahulu',
        );
        return;
      }

      if (_selectedSubject == 'NKP (Naskah Karya Perseorangan)' &&
          _selectedKompetensi == null) {
        AppNotifier.showError(
          context,
          'Silahkan pilih kompetensi inti untuk NKP',
        );
        return;
      }

      if (_selectedSubject == 'Mental Kepribadian' && _selectedMental == null) {
        AppNotifier.showError(
          context,
          'Silahkan pilih aspek penilaian untuk Mental Kepribadian',
        );
        return;
      }

      if (_selectedPokjar == null) {
        AppNotifier.showError(
          context,
          'Silahkan pilih target POKJAR terlebih dahulu',
        );
        return;
      }

      if (_selectedDeadline == null) {
        AppNotifier.showError(context, 'Silahkan tentukan tenggat waktu tugas');
        return;
      }

      final authState = context.read<AuthBloc>().state;
      String currentNrp = '';
      String currentName = 'Pengajar';

      if (authState is AuthSuccess) {
        currentNrp = authState.user.nrp;
        currentName = authState.user.name;
      }

      final newTask = TugasModel(
        id: 'TSK-${DateTime.now().millisecondsSinceEpoch}',
        judul: _judulController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        mapel: _selectedSubject == 'NKP (Naskah Karya Perseorangan)'
            ? 'NKP - $_selectedKompetensi'
            : _selectedSubject == 'Mental Kepribadian'
            ? 'Mental - $_selectedMental'
            : _selectedSubject!,
        deadline: _selectedDeadline!,
        status: 'Aktif',
        createdBy: currentNrp,
        createdByName: currentName,
      );

      setState(() {
        PimpinanMockData.sharedTasks.insert(0, newTask);

        for (var serdik in PimpinanMockData.sharedReportData.take(5)) {
          PimpinanMockData.sharedTaskSubmissions.add({
            'taskId': newTask.id,
            'name': serdik.name,
            'nrp': serdik.nrp,
            'pokjar': serdik.pokjar.toUpperCase(),
            'status': 'belum',
            'file': null,
            'time': '-',
          });
        }
      });

      AppNotifier.showSuccess(
        context,
        'Tugas berhasil dipublikasikan ke Serdik.',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Buat Tugas Baru',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _formAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(_formAnimation),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.xxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Tugas',
                            style: TextStyle(
                              fontSize: AppDimensions.fontXxl,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          _buildTextField(
                            controller: _judulController,
                            label: 'Judul Tugas',
                            hint: 'Masukkan judul tugas...',
                            icon: Icons.title_rounded,
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          _buildSubjectDropdownField(),
                          const SizedBox(height: AppDimensions.xl),

                          if (_selectedSubject ==
                              'NKP (Naskah Karya Perseorangan)') ...[
                            _buildKompetensiDropdownField(),
                            const SizedBox(height: AppDimensions.xl),
                          ] else if (_selectedSubject ==
                              'Mental Kepribadian') ...[
                            _buildMentalDropdownField(),
                            const SizedBox(height: AppDimensions.xl),
                          ],

                          _buildDropdownField(),
                          const SizedBox(height: AppDimensions.xl),

                          _buildDeadlineField(),
                          const SizedBox(height: AppDimensions.xl),

                          _buildTextField(
                            controller: _deskripsiController,
                            label: 'Deskripsi dan Instruksi',
                            hint: 'Tuliskan instruksi tugas secara detail...',
                            icon: Icons.description_outlined,
                            maxLines: 5,
                          ),
                          const SizedBox(height: AppDimensions.xl),

                          _buildAttachmentField(),
                          const SizedBox(height: AppDimensions.xl * 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _buttonAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_buttonAnimation),
                child: _buildBottomActionButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label wajib diisi';
            }
            return null;
          },
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w600,
            color: _primaryNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: maxLines == 1
                ? Icon(
                    icon,
                    color: Colors.blueGrey.shade400,
                    size: AppDimensions.iconLg,
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Icon(
                      icon,
                      color: Colors.blueGrey.shade400,
                      size: AppDimensions.iconLg,
                    ),
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: _primaryNavy, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            filled: true,
            fillColor: _surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mata Pelajaran',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubject,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blueGrey.shade400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.menu_book_rounded,
              color: Colors.blueGrey.shade400,
              size: AppDimensions.iconLg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: _primaryNavy, width: 2),
            ),
            filled: true,
            fillColor: _surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          hint: Text(
            'Pilih mata pelajaran',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: AppDimensions.fontLg,
            ),
          ),
          items: _subjectList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w600,
                  color: _primaryNavy,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedSubject = newValue;
              if (_selectedSubject != 'NKP (Naskah Karya Perseorangan)') {
                _selectedKompetensi = null;
              }
              if (_selectedSubject != 'Mental Kepribadian') {
                _selectedMental = null;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildKompetensiDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kompetensi Inti Kepemimpinan (NKP)',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedKompetensi,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blueGrey.shade400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.psychology_rounded,
              color: Colors.blueGrey.shade400,
              size: AppDimensions.iconLg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: _primaryNavy, width: 2),
            ),
            filled: true,
            fillColor: _surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          hint: Text(
            'Pilih 10 kompetensi inti',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: AppDimensions.fontLg,
            ),
          ),
          items: _kompetensiList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w600,
                  color: _primaryNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedKompetensi = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMentalDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aspek Penilaian Mental Kepribadian',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedMental,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blueGrey.shade400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.psychology_alt_rounded,
              color: Colors.blueGrey.shade400,
              size: AppDimensions.iconLg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: _primaryNavy, width: 2),
            ),
            filled: true,
            fillColor: _surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          hint: Text(
            'Pilih Aspek Penilaian Mental',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: AppDimensions.fontLg,
            ),
          ),
          items: _mentalList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w600,
                  color: _primaryNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedMental = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Distribusi (POKJAR)',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        DropdownButtonFormField<String>(
          initialValue: _selectedPokjar,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.blueGrey.shade400,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.groups_rounded,
              color: Colors.blueGrey.shade400,
              size: AppDimensions.iconLg,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(color: _primaryNavy, width: 2),
            ),
            filled: true,
            fillColor: _surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
          ),
          hint: Text(
            'Pilih kelompok belajar sasaran',
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontSize: AppDimensions.fontLg,
            ),
          ),
          items: _pokjarList.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w600,
                  color: _primaryNavy,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPokjar = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    final String displayDate = _selectedDeadline != null
        ? '${_selectedDeadline!.day.toString().padLeft(2, '0')}/${_selectedDeadline!.month.toString().padLeft(2, '0')}/${_selectedDeadline!.year} - ${_selectedDeadline!.hour.toString().padLeft(2, '0')}:${_selectedDeadline!.minute.toString().padLeft(2, '0')} WIB'
        : 'Pilih Tenggat Waktu';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tenggat Waktu',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: _selectDeadline,
            child: Ink(
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: _selectedDeadline != null
                      ? _primaryNavy
                      : Colors.grey.shade300,
                  width: _selectedDeadline != null ? 2.0 : 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: _selectedDeadline != null
                        ? _primaryNavy
                        : Colors.blueGrey.shade400,
                    size: AppDimensions.iconLg,
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: _selectedDeadline != null
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _selectedDeadline != null
                            ? _primaryNavy
                            : Colors.blueGrey.shade400,
                      ),
                    ),
                  ),
                  if (_selectedDeadline != null)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _successGreen,
                      size: AppDimensions.iconDefault,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _publishTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              elevation: 4,
              shadowColor: _primaryNavy.withValues(alpha: 0.4),
            ),
            icon: const Icon(Icons.send_rounded, size: AppDimensions.iconLg),
            label: const Text(
              'PUBLIKASIKAN TUGAS',
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lampiran',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w700,
            color: _primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isAttaching ? null : _pickFile,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Ink(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(
                  color: _attachedFileName != null
                      ? _primaryNavy
                      : Colors.grey.shade300,
                  width: _attachedFileName != null ? 2.0 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm + 4),
                    decoration: BoxDecoration(
                      color: _attachedFileName != null
                          ? _primaryNavy.withValues(alpha: 0.1)
                          : Colors.blueGrey.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: _isAttaching
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryNavy,
                            ),
                          )
                        : Icon(
                            _attachedFileName != null
                                ? Icons.description_rounded
                                : Icons.attach_file_rounded,
                            color: _attachedFileName != null
                                ? _primaryNavy
                                : Colors.blueGrey.shade400,
                            size: AppDimensions.iconLg,
                          ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _attachedFileName ?? 'Pilih file lampiran tugas',
                          style: TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: _attachedFileName != null
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _attachedFileName != null
                                ? _primaryNavy
                                : Colors.blueGrey.shade400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_attachedFileName == null)
                          Text(
                            'Format: PDF, DOC, PPT',
                            style: TextStyle(
                              fontSize: AppDimensions.fontMd,
                              color: Colors.blueGrey.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_attachedFileName != null)
                    IconButton(
                      onPressed: () => setState(() => _attachedFileName = null),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.red.shade400,
                        size: AppDimensions.iconLg,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

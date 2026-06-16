import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/features/assignment/data/models/tugas_model.dart';
import 'package:sespimma/features/assignment/data/datasources/assignment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class MonitoringTaskScreen extends StatefulWidget {
  const MonitoringTaskScreen({super.key});

  @override
  State<MonitoringTaskScreen> createState() => _MonitoringTaskScreenState();
}

class _MonitoringTaskScreenState extends State<MonitoringTaskScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Semua';
  String _selectedPokjar = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;
  
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = false;
  bool _initialized = false;
  late TugasModel _task;

  Future<void> _fetchSubmissions(String taskId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await sl<AssignmentRemoteDataSource>().getSubmissions(taskId);
      if (mounted) {
        setState(() {
          _submissions = data.map((s) {
            final isGraded = s['isGraded'] ?? false;
            final submittedAt = s['submittedAt'];
            final hasFile = s['fileName'] != null;

            String status = 'belum';
            if (hasFile) {
              if (isGraded) {
                status = 'dinilai';
              } else {
                status = 'sudah';
              }
            }

            return {
              'id': s['id']?.toString() ?? '',
              'taskId': s['assignmentId']?.toString() ?? taskId,
              'name': s['serdikName'] ?? '',
              'nrp': s['serdikNrp'] ?? '',
              'pokjar': (s['serdikPokjar'] ?? s['pokjar'] ?? '').toString().toUpperCase(),
              'status': status,
              'file': s['fileName'],
              'time': submittedAt != null ? DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(submittedAt)) : '-',
              'score': s['nilaiAkhir'],
              'comment': s['catatanPengajar'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(context, 'Gagal memuat pengumpulan: $e');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final taskArg = ModalRoute.of(context)?.settings.arguments as TugasModel?;
      if (taskArg != null) {
        _task = taskArg;
        _fetchSubmissions(_task.id);
      }
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  static const Color _primaryNavy = Color(0xFF0F172A);
  static const Color _lightGrey = Color(0xFFF8FAFC);
  static const Color _successGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _warningOrange = Color(0xFFF59E0B);
  static const Color _surfaceColor = Colors.white;

  void _showGradeDialog(Map<String, dynamic> submission) {
    final scoreCtrl = TextEditingController(
      text: submission['score'] != null ? submission['score'].toString() : '',
    );
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Penilaian Tugas',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXxl,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.blueGrey,
                        size: AppDimensions.iconLg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _dangerRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: _dangerRed,
                          size: AppDimensions.iconXl,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              submission['file'] ?? 'Tidak ada file',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontLg,
                                fontWeight: FontWeight.w700,
                                color: _primaryNavy,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppDimensions.xs),
                            Text(
                              'Diserahkan: ${submission['time']}',
                              style: TextStyle(
                                fontSize: AppDimensions.fontMd,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.visibility_rounded,
                              color: _primaryNavy,
                              size: AppDimensions.iconLg,
                            ),
                            onPressed: () {
                              final filename =
                                  submission['file'] ?? 'document.pdf';
                              _showPreviewDialog(filename);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.file_download_outlined,
                              color: _primaryNavy,
                              size: AppDimensions.iconLg,
                            ),
                            onPressed: () => _downloadFile(
                              submission['file'] ?? 'document.pdf',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                const Text(
                  'Beri Nilai (0 - 100)',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w700,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: scoreCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nilai wajib diisi';
                    }
                    final num? val = num.tryParse(value);
                    if (val == null) {
                      return 'Format nilai tidak valid';
                    }
                    if (val < 0 || val > 100) {
                      return 'Nilai harus di antara 0 - 100';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Contoh: 85.5',
                    hintStyle: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: const BorderSide(
                        color: _primaryNavy,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: BorderSide(color: Colors.red.shade400),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    filled: true,
                    fillColor: _surfaceColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
                const Text(
                  'Catatan Pengajar (Opsional)',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w700,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                TextFormField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w600,
                    color: _primaryNavy,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Berikan masukan atau evaluasi untuk Serdik...',
                    hintStyle: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.normal,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                      borderSide: const BorderSide(
                        color: _primaryNavy,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                    filled: true,
                    fillColor: _surfaceColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.xl * 1.5),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final double newScore =
                            double.tryParse(scoreCtrl.text) ?? 0.0;
                        final String note = noteCtrl.text.trim();

                        Navigator.pop(sheetCtx);

                        try {
                          await sl<AssignmentRemoteDataSource>().gradeSubmission(
                            submissionId: submission['id'],
                            nilaiAkhir: newScore,
                            catatanPengajar: note.isNotEmpty ? note : null,
                          );
                          _fetchSubmissions(submission['taskId']);
                          if (!mounted) return;
                          AppNotifier.showSuccess(
                            context,
                            'Nilai berhasil disimpan untuk ${submission["name"]}',
                          );
                        } catch (e) {
                          if (!mounted) return;
                          AppNotifier.showError(
                            context,
                            'Gagal menyimpan nilai: $e',
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                      elevation: 4,
                      shadowColor: _primaryNavy.withValues(alpha: 0.4),
                    ),
                    child: const Text(
                      'SIMPAN NILAI',
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.xl),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPreviewDialog(String filename) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        insetPadding: const EdgeInsets.all(AppDimensions.xl),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.65,
          color: _lightGrey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                color: _primaryNavy,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pratinjau: $filename',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: AppDimensions.iconLg,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          size: 80,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      Text(
                        'Simulasi Pratinjau Dokumen\n($filename)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
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
    );
  }

  Future<void> _downloadFile(String filename) async {
    final navigator = Navigator.of(context);

    final String? selectedFolder = await FilePicker.getDirectoryPath(
      dialogTitle: 'Pilih Folder Penyimpanan',
    );

    if (selectedFolder == null) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const CircularProgressIndicator(color: _primaryNavy),
              const SizedBox(width: AppDimensions.xl),
              Expanded(
                child: Text(
                  'Mengunduh $filename...',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w600,
                    color: _primaryNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final file = File('$selectedFolder/$filename');
      await file.writeAsString('Simulasi file dokumen $filename');
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      debugPrint('Error: $e');
    }

    if (!mounted) return;
    navigator.pop();
    AppNotifier.showSuccess(
      context,
      'Selesai! Disimpan ke: .../${selectedFolder.split('/').last}/$filename',
      duration: const Duration(seconds: 3),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 64,
              color: Colors.blueGrey.shade300,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const Text(
            'Data Serdik Tidak Ditemukan',
            style: TextStyle(
              fontSize: AppDimensions.fontXxl,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Belum ada data pengumpulan serdik yang sesuai\ndengan pencarian atau filter Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              color: Colors.blueGrey.shade400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _mapRomanToArabic(String roman) {
    switch (roman) {
      case 'POKJAR I':
        return 'POKJAR I';
      case 'POKJAR II':
        return 'POKJAR II';
      case 'POKJAR III':
        return 'POKJAR III';
      case 'POKJAR IV':
        return 'POKJAR IV';
      case 'POKJAR V':
        return 'POKJAR V';
      default:
        return roman;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskArg = ModalRoute.of(context)?.settings.arguments as TugasModel?;

    final TugasModel task =
        taskArg ??
        TugasModel(
          id: 'DUMMY',
          judul: 'Tugas Akademik (Mode Preview)',
          deskripsi: '-',
          mapel: '-',
          deadline: DateTime.now(),
          status: 'Aktif',
          createdBy: '00000000',
          createdByName: 'System Dummy',
        );

    final allSubmissions = _submissions;
    final filteredSubmissions = allSubmissions.where((sub) {
      final String q = _searchQuery.trim().toLowerCase();
      final String name = sub['name'].toString().toLowerCase();
      final String nrp = sub['nrp'].toString().toLowerCase();

      if (q.isNotEmpty && !name.contains(q) && !nrp.contains(q)) {
        return false;
      }

      if (_selectedPokjar != 'Semua' &&
          sub['pokjar'] != _mapRomanToArabic(_selectedPokjar)) {
        return false;
      }

      if (_selectedFilter == 'Semua') {
        return true;
      }
      if (_selectedFilter == 'Sudah' &&
          (sub['status'] == 'sudah' || sub['status'] == 'dinilai')) {
        return true;
      }
      if (_selectedFilter == 'Belum' && sub['status'] == 'belum') {
        return true;
      }
      if (_selectedFilter == 'Terlambat' && sub['status'] == 'terlambat') {
        return true;
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Pemantauan Tugas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
            letterSpacing: -0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (task.id != 'DUMMY')
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
              ),
              tooltip: 'Hapus Tugas',
              onPressed: () => _showDeleteConfirmationDialog(context, task),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTaskHeader(task, allSubmissions),
          _buildSearchAndFilterRow(),
          Expanded(
            child: RefreshIndicator(
              color: _primaryNavy,
              backgroundColor: _surfaceColor,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await _fetchSubmissions(task.id);
              },
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _primaryNavy,
                      ),
                    )
                  : filteredSubmissions.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            alignment: Alignment.center,
                            child: _buildEmptyState(),
                          ),
                        )
                      : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: filteredSubmissions.length,
                      itemBuilder: (context, index) {
                        final animation = CurvedAnimation(
                          parent: _animController,
                          curve: Interval(
                            (index /
                                    (filteredSubmissions.isEmpty
                                        ? 1
                                        : filteredSubmissions.length))
                                .clamp(0.0, 1.0),
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: _buildSerdikItem(filteredSubmissions[index]),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeader(
    TugasModel task,
    List<Map<String, dynamic>> submissions,
  ) {
    final int total = submissions.length;
    final int sudah = submissions
        .where((s) => s['status'] == 'sudah' || s['status'] == 'dinilai')
        .length;
    final int belum = submissions.where((s) => s['status'] == 'belum').length;
    final int terlambat = submissions
        .where((s) => s['status'] == 'terlambat')
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: _surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSm,
                        ),
                      ),
                      child: Text(
                        task.mapel.toUpperCase(),
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Text(
                      task.judul,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontXxl,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: AppDimensions.fontLg,
                          color: _warningOrange,
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          'Batas Waktu: ${task.deadline.day.toString().padLeft(2, '0')}/${task.deadline.month.toString().padLeft(2, '0')}/${task.deadline.year} ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')} WIB',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: FontWeight.w700,
                            color: _warningOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: _lightGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  'Total',
                  total.toString(),
                  Colors.blueGrey.shade700,
                ),
                _buildDivider(),
                _buildStatItem('Sudah', sudah.toString(), _successGreen),
                _buildDivider(),
                _buildStatItem('Belum', belum.toString(), _dangerRed),
                _buildDivider(),
                _buildStatItem(
                  'Terlambat',
                  terlambat.toString(),
                  _warningOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, TugasModel task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: _dangerRed,
              size: AppDimensions.iconXl,
            ),
            SizedBox(width: AppDimensions.md),
            Text(
              'Hapus Tugas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
          ],
        ),
        content: Text(
          'Anda yakin ingin menghapus tugas "${task.judul}"? Semua data pengumpulan siswa akan ikut terhapus.',
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            color: _primaryNavy,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w700,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(this.context);
              final dialogNavigator = Navigator.of(ctx);

              try {
                await sl<AssignmentRemoteDataSource>().deleteAssignment(task.id);
                if (!mounted) return;
                AppNotifier.showSuccess(
                  this.context,
                  'Tugas "${task.judul}" berhasil dihapus!',
                );
                dialogNavigator.pop();
                navigator.pop(true);
              } catch (e) {
                if (!mounted) return;
                AppNotifier.showError(
                  this.context,
                  'Gagal menghapus tugas: $e',
                );
                dialogNavigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Ya, Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimensions.fontXxl + 4,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 32, width: 1.5, color: Colors.grey.shade300);
  }

  Widget _buildSearchAndFilterRow() {
    return Container(
      color: _surfaceColor,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52.0,
              decoration: BoxDecoration(
                color: _lightGrey,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NRP...',
                  hintStyle: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: AppDimensions.fontLg,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.blueGrey.shade400,
                    size: AppDimensions.iconLg,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: _primaryNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          _buildStatusFilterDropdown(),
          const SizedBox(width: AppDimensions.sm),
          _buildPokjarFilterDropdown(),
        ],
      ),
    );
  }

  Widget _buildStatusFilterDropdown() {
    final bool isFiltered = _selectedFilter != 'Semua';
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedFilter = value;
        });
        _animController.forward(from: 0.0);
      },
      offset: const Offset(0, 52),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      itemBuilder: (context) {
        return ['Semua', 'Sudah', 'Belum', 'Terlambat'].map((item) {
          final bool isSel = _selectedFilter == item;
          return PopupMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Icon(
                  _resolveSelectionIcon(isSel),
                  color: _resolveSelectionColor(isSel),
                  size: AppDimensions.iconLg,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    color: _primaryNavy,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 52.0,
        width: 52.0,
        decoration: BoxDecoration(
          color: isFiltered
              ? _primaryNavy.withValues(alpha: 0.08)
              : _surfaceColor,
          border: Border.all(
            color: isFiltered ? _primaryNavy : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          color: isFiltered ? _primaryNavy : Colors.blueGrey.shade400,
          size: AppDimensions.iconLg,
        ),
      ),
    );
  }

  Widget _buildPokjarFilterDropdown() {
    final bool isFiltered = _selectedPokjar != 'Semua';
    final pokjars = [
      'Semua',
      'POKJAR I',
      'POKJAR II',
      'POKJAR III',
      'POKJAR IV',
      'POKJAR V',
      'Simulasi Kesatuan',
    ];
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _selectedPokjar = value;
        });
        _animController.forward(from: 0.0);
      },
      offset: const Offset(0, 52),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      itemBuilder: (context) {
        return pokjars.map((item) {
          final bool isSel = _selectedPokjar == item;
          return PopupMenuItem<String>(
            value: item,
            child: Row(
              children: [
                Icon(
                  _resolveSelectionIcon(isSel),
                  color: _resolveSelectionColor(isSel),
                  size: AppDimensions.iconLg,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  item,
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    color: _primaryNavy,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        height: 52.0,
        width: 52.0,
        decoration: BoxDecoration(
          color: isFiltered
              ? _primaryNavy.withValues(alpha: 0.08)
              : _surfaceColor,
          border: Border.all(
            color: isFiltered ? _primaryNavy : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: Icon(
          Icons.groups_rounded,
          color: isFiltered ? _primaryNavy : Colors.blueGrey.shade400,
          size: AppDimensions.iconLg,
        ),
      ),
    );
  }

  IconData _resolveSelectionIcon(bool isSel) {
    if (isSel) return Icons.check_circle_rounded;
    return Icons.circle_outlined;
  }

  Color _resolveSelectionColor(bool isSel) {
    if (isSel) return _primaryNavy;
    return Colors.grey.shade400;
  }

  Widget _buildSerdikItem(Map<String, dynamic> submission) {
    final status = submission['status'];
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (status == 'sudah') {
      statusColor = Colors.blue.shade600;
      statusText = 'Menunggu Penilaian';
      statusIcon = Icons.drive_folder_upload_rounded;
    } else if (status == 'dinilai') {
      statusColor = _successGreen;
      statusText = 'Dinilai: ${submission['score'] ?? '-'}';
      statusIcon = Icons.verified_rounded;
    } else if (status == 'terlambat') {
      statusColor = _warningOrange;
      statusText = 'Terlambat Mengumpulkan';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = _dangerRed;
      statusText = 'Belum Mengumpulkan';
      statusIcon = Icons.cancel_rounded;
    }

    final bool hasFile = submission['file'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: hasFile ? () => _showGradeDialog(submission) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(Icons.person, color: statusColor, size: 28),
                  ),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        submission['name'],
                        style: const TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w700,
                          color: _primaryNavy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'NRP: ${submission['nrp']}  •  ${submission['pokjar'] ?? '-'}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade500,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: AppDimensions.iconSm,
                              color: statusColor,
                            ),
                            const SizedBox(width: AppDimensions.xs),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasFile)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm + 4),
                    decoration: BoxDecoration(
                      color: _primaryNavy.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _primaryNavy,
                      size: AppDimensions.iconSm,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

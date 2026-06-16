import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sespimma/features/assignment/data/models/assignment_model.dart';
import 'package:sespimma/features/assignment/presentation/widgets/assignment_widgets.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/assignment/data/datasources/assignment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class AssignmentDetailScreen extends StatefulWidget {
  const AssignmentDetailScreen({super.key});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isFileAttached = false;
  String _fileName = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _stdName(AssignmentModel a, String n) {
    final serdik = SerdikRealData.records.first;
    final nosis = serdik['no_serdik'] ?? 'Unknown';
    final ext = n.contains('.') ? n.split('.').last : 'pdf';
    return '$nosis.$ext';
  }

  void _pickFile(AssignmentModel a) => showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusRound),
      ),
    ),
    builder: (_) => AssignmentFilePickerSheet(
      onPickImage: () => _pickImage(a),
      onPickDocument: () => _pickDocument(a),
    ),
  );

  Future<void> _pickImage(AssignmentModel a) async {
    Navigator.pop(context);
    final img = await ImagePicker().pickImage(source: ImageSource.camera);
    if (img == null) return;
    await HapticFeedback.mediumImpact();
    setState(() {
      _isFileAttached = true;
      _fileName = _stdName(a, img.name);
    });
  }

  Future<void> _pickDocument(AssignmentModel a) async {
    Navigator.pop(context);
    final r = await FilePicker.pickFiles(type: FileType.any);
    if (r == null) return;
    await HapticFeedback.mediumImpact();
    setState(() {
      _isFileAttached = true;
      _fileName = _stdName(a, r.files.single.name);
    });
  }

  Future<void> _removeFile() async {
    await HapticFeedback.lightImpact();
    setState(() {
      _isFileAttached = false;
      _fileName = '';
    });
  }

  Future<void> _submitTask(AssignmentModel a) async {
    await HapticFeedback.heavyImpact();

    try {
      await sl<AssignmentRemoteDataSource>().submitAssignment(
        assignmentId: a.id,
        fileName: _fileName,
        fileUrl: 'https://example.com/$_fileName',
      );

      if (!mounted) return;
      AssignmentSnackbars.showSuccess(context, 'Tugas berhasil dikumpulkan');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AssignmentSnackbars.showError(context, 'Gagal mengumpulkan tugas: $e');
    }
  }

  Future<void> _downloadFile(String name) async {
    await HapticFeedback.lightImpact();
    try {
      final dir = await FilePicker.getDirectoryPath(
        dialogTitle: 'Pilih lokasi penyimpanan berkas',
      );
      if (dir == null || !mounted) return;
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      AssignmentSnackbars.showSuccess(
        context,
        'Berkas $name berhasil disimpan di: $dir',
      );
    } catch (e) {
      if (!mounted) return;
      AssignmentSnackbars.showError(context, 'Gagal menyimpan berkas: $e');
    }
  }

  void _showSubmitSheet(bool isExpired, AssignmentModel a) =>
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => AssignmentSubmitConfirmationSheet(
          isExpired: isExpired,
          fileName: _fileName,
          onConfirm: () => _submitTask(a),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final a = ModalRoute.of(context)!.settings.arguments as AssignmentModel;
    final isAktif = a.status == 'aktif';
    final isExpired = isAktif && a.deadline.isBefore(DateTime.now());
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AssignmentDetailAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AssignmentDetailContent(
                assignment: a,
                isAktif: isAktif,
                isExpired: isExpired,
                isFileAttached: _isFileAttached,
                fileName: _fileName,
                fadeAnimation: _fadeAnimation,
                onPickFile: () => _pickFile(a),
                onRemoveFile: _removeFile,
                onDownloadFile: _downloadFile,
              ),
            ),
            if (isAktif)
              AssignmentBottomActionButton(
                isExpired: isExpired,
                isFileAttached: _isFileAttached,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _showSubmitSheet(isExpired, a);
                },
              ),
          ],
        ),
      ),
    );
  }
}

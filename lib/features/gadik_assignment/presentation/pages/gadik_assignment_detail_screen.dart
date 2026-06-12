import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import '../../data/models/gadik_assignment_model.dart';
import '../../data/models/gadik_submission_model.dart';
import '../../data/datasources/gadik_assignment_mock_data.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import '../widgets/gadik_grading_bottom_sheet.dart';

class GadikAssignmentDetailScreen extends StatefulWidget {
  final GadikAssignmentModel assignment;

  const GadikAssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<GadikAssignmentDetailScreen> createState() =>
      _GadikAssignmentDetailScreenState();
}

class _GadikAssignmentDetailScreenState
    extends State<GadikAssignmentDetailScreen> {
  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = AppColors.background;

  List<GadikSubmissionModel> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  void _loadSubmissions() {
    setState(() {
      _submissions = GadikAssignmentMockData.submissions
          .where((s) => s.assignmentId == widget.assignment.id)
          .toList();
    });
  }

  int _getTotalSerdik(String targetPokjar) {
    final target = targetPokjar.toUpperCase();
    if (target == 'SEMUA POKJAR' || target == 'SELURUH POKJAR') {
      return SerdikRealData.records.length;
    }
    return SerdikRealData.records.where((s) {
      final group = s['kelompok_kelas']?.toString().toUpperCase() ?? '';
      final groupFixed = group
          .replaceAll('POKJAR I', 'POKJAR I')
          .replaceAll('POKJAR II', 'POKJAR II')
          .replaceAll('POKJAR III', 'POKJAR III')
          .replaceAll('POKJAR IV', 'POKJAR IV')
          .replaceAll('POKJAR V', 'POKJAR V');
      return groupFixed == target;
    }).length;
  }

  String _mapArabicToRoman(String arabic) {
    switch (arabic.toUpperCase()) {
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
        return arabic.toUpperCase();
    }
  }

  String _getPokjarForSerdik(String nosis) {
    final serdik = SerdikRealData.records.firstWhere(
      (s) => s['no_serdik'] == nosis,
      orElse: () => <String, dynamic>{},
    );
    return serdik['kelompok_kelas']?.toString() ?? '-';
  }

  String _formatDeadline(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }

  IconData _getFileIcon(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }
    if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (lowerName.endsWith('.xls') || lowerName.endsWith('.xlsx')) {
      return Icons.table_chart_rounded;
    }
    if (lowerName.endsWith('.ppt') || lowerName.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    }
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi')) {
      return Icons.video_file_rounded;
    }
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png')) {
      return Icons.image_rounded;
    }
    if (lowerName.endsWith('.zip') || lowerName.endsWith('.rar')) {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getFileColor(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.pdf')) {
      return Colors.redAccent;
    }
    if (lowerName.endsWith('.doc') || lowerName.endsWith('.docx')) {
      return Colors.blue.shade700;
    }
    if (lowerName.endsWith('.xls') || lowerName.endsWith('.xlsx')) {
      return Colors.green.shade600;
    }
    if (lowerName.endsWith('.ppt') || lowerName.endsWith('.pptx')) {
      return Colors.orange.shade700;
    }
    if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi')) {
      return Colors.purple.shade500;
    }
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png')) {
      return Colors.teal.shade600;
    }
    if (lowerName.endsWith('.zip') || lowerName.endsWith('.rar')) {
      return Colors.amber.shade700;
    }
    return Colors.blueGrey;
  }

  void _openGradingSheet(GadikSubmissionModel submission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GadikGradingBottomSheet(
        assignment: widget.assignment,
        submission: submission,
        onSaved: (updatedSubmission) {
          setState(() {
            final idx = _submissions.indexWhere(
              (s) => s.id == updatedSubmission.id,
            );
            if (idx != -1) {
              _submissions[idx] = updatedSubmission;
              final mockIdx = GadikAssignmentMockData.submissions.indexWhere(
                (s) => s.id == updatedSubmission.id,
              );
              if (mockIdx != -1) {
                GadikAssignmentMockData.submissions[mockIdx] =
                    updatedSubmission;
              } else {
                GadikAssignmentMockData.submissions.add(updatedSubmission);
              }
            }
          });
        },
      ),
    );
  }

  Future<void> _downloadFile(String? url, String? fileName) async {
    if (url == null || url.isEmpty || fileName == null) return;
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      String? selectedDirectory = await FilePicker.getDirectoryPath();

      if (selectedDirectory == null) {
        return;
      }

      String savePath = '$selectedDirectory/$fileName';
      if (await File(savePath).exists()) {
        final extIndex = fileName.lastIndexOf('.');
        if (extIndex != -1) {
          final name = fileName.substring(0, extIndex);
          final ext = fileName.substring(extIndex);
          savePath =
              '$selectedDirectory/${name}_${DateTime.now().millisecondsSinceEpoch}$ext';
        } else {
          savePath =
              '$selectedDirectory/${fileName}_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      if (!mounted) return;
      AppNotifier.showInfo(context, 'Mengunduh lampiran $fileName...');

      if (url.contains('example.com')) {
        await Future.delayed(const Duration(seconds: 1));
        final file = File(savePath);
        await file.writeAsBytes([0]);
      } else {
        await Dio().download(url, savePath);
      }

      if (!mounted) return;
      AppNotifier.showSuccess(
        context,
        'Tersimpan di ${savePath.split('/').last}',
      );
    } catch (e) {
      if (!mounted) return;
      AppNotifier.showError(context, 'Gagal mengunduh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalSerdik = _getTotalSerdik(widget.assignment.targetPokjar);
    final int submittedCount = _submissions.length;
    final int gradedCount = _submissions.where((s) => s.isGraded).length;

    String getShortCat(String category) {
      final lower = category.toLowerCase();
      if (lower.contains('ujian') || lower.contains('esai')) return 'NUMP';
      if (lower.contains('nkkp')) return 'NKKP';
      if (lower.contains('npkp')) return 'NPKP';
      if (lower.contains('nkp')) return 'NKP';
      if (lower.contains('nsk') || lower.contains('simulasi')) return 'NSK';
      if (lower.contains('nptt')) return 'NPTT';

      if (category.contains('(')) {
        return category.substring(0, category.indexOf('(')).trim();
      }
      return category;
    }

    String shortCat = getShortCat(widget.assignment.jenisTugas);

    return Scaffold(
      backgroundColor: _lightGrey,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: _primaryNavy,
            pinned: true,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Detail Tugas',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
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
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: () => _showDeleteConfirmation(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.assignment.judul,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontXxl,
                        fontWeight: FontWeight.w900,
                        color: _primaryNavy,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Text(
                            shortCat,
                            style: TextStyle(
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.w800,
                              fontSize: AppDimensions.fontXs + 1,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.track_changes_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.assignment.targetPokjar.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: AppDimensions.fontXs + 1,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderStatBox(
                            icon: Icons.timer_outlined,
                            title: 'Tenggat Waktu',
                            value: _formatDeadline(widget.assignment.deadline),
                            valueColor: const Color(0xFFEF4444),
                            bgColor: Colors.white,
                            iconColor: Colors.blueGrey.shade400,
                            titleColor: Colors.blueGrey.shade500,
                            borderColor: Colors.grey.shade200,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.md),
                        Expanded(
                          child: _buildHeaderStatBox(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Progres Pengumpulan',
                            value: '$submittedCount / $totalSerdik',
                            valueColor: const Color(0xFF10B981),
                            bgColor: Colors.white,
                            iconColor: Colors.blueGrey.shade400,
                            titleColor: Colors.blueGrey.shade500,
                            borderColor: Colors.grey.shade200,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.xl),
                    const Text(
                      'Instruksi Pengerjaan',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.bold,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Text(
                      widget.assignment.instruksi,
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm,
                        color: Colors.blueGrey.shade600,
                        height: 1.5,
                      ),
                    ),
                    if (widget.assignment.fileName != null) ...[
                      const SizedBox(height: AppDimensions.xl),
                      const Text(
                        'Lampiran Tugas',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.bold,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                          onTap: () => _downloadFile(
                            widget.assignment.fileUrl,
                            widget.assignment.fileName,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusMd,
                                    ),
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
                                    _getFileIcon(
                                      widget.assignment.fileName ?? '',
                                    ),
                                    color: _getFileColor(
                                      widget.assignment.fileName ?? '',
                                    ),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.assignment.fileName!,
                                    style: const TextStyle(
                                      fontSize: AppDimensions.fontSm + 1,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryNavy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.download_rounded,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.xl,
                0,
                AppDimensions.xl,
                AppDimensions.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _primaryNavy,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  const Text(
                    'DAFTAR PENGUMPULAN',
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_submissions.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.xxxl),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.blueGrey.shade300,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      const Text(
                        'Belum Ada Pengumpulan',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Belum ada Serdik yang mengirimkan tugas ini.',
                        style: TextStyle(
                          fontSize: AppDimensions.fontLg,
                          color: Colors.blueGrey.shade400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final submittedList = _submissions.toList();
                  final sub = submittedList[index];
                  return _buildSubmissionCard(sub);
                }, childCount: _submissions.length),
              ),
            ),
          if (_submissions.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildFooterSection(submittedCount, gradedCount),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        title: const Text(
          'Hapus Tugas',
          style: TextStyle(fontWeight: FontWeight.w800, color: _primaryNavy),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus tugas ini beserta seluruh nilainya?',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            color: Colors.blueGrey,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, 'deleted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: const Text(
              'Hapus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatBox({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
    Color? bgColor,
    Color? iconColor,
    Color? titleColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: iconColor ?? Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontXs,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(GadikSubmissionModel sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade100, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: () {
            HapticFeedback.selectionClick();
            _openGradingSheet(sub);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _lightGrey,
                  backgroundImage: const AssetImage(
                    'assets/images/default_avatar.png',
                  ),
                ),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.serdikName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: AppDimensions.fontLg,
                          color: _primaryNavy,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sub.serdikPangkat ?? "Ajun Komisaris Polisi"} • ${sub.serdikNosis ?? "202602003001"}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          _mapArabicToRoman(
                            _getPokjarForSerdik(sub.serdikNosis ?? ''),
                          ),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),
                      if (sub.fileName != null && sub.fileName!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => _downloadFile(sub.fileUrl, sub.fileName),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(color: Colors.blue.shade100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getFileIcon(sub.fileName ?? ''),
                                  size: 14,
                                  color: _getFileColor(sub.fileName ?? ''),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    sub.fileName!,
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.blue.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                _buildGradingAction(sub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score == 0) return _primaryNavy;
    if (score > 85.00) return Colors.green.shade800;
    if (score > 80.00) return Colors.green.shade500;
    if (score > 75.00) return Colors.lime.shade700;
    if (score > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
  }

  Widget _buildGradingAction(GadikSubmissionModel sub) {
    if (sub.isGraded) {
      final double score = sub.nilaiAkhir ?? 0.0;
      final Color scoreColor = _getScoreColor(score);
      final Color scoreBgColor = score > 0
          ? scoreColor.withValues(alpha: 0.1)
          : const Color(0xFFECFDF5);
      final Color scoreBorderColor = score > 0
          ? scoreColor.withValues(alpha: 0.3)
          : const Color(0xFFA7F3D0);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Icon(
              Icons.edit_rounded,
              size: 16,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scoreBgColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: scoreBorderColor),
            ),
            child: Text(
              sub.nilaiAkhir?.toStringAsFixed(1) ?? '-',
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w900,
                fontSize: AppDimensions.fontLg,
              ),
            ),
          ),
        ],
      );
    } else {
      final beriNilaiBtn = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _primaryNavy,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: _primaryNavy.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'NILAI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontSm,
            letterSpacing: 0.3,
          ),
        ),
      );

      return beriNilaiBtn;
    }
  }

  Widget _buildFooterSection(int submitted, int graded) {
    if (submitted == 0) return const SizedBox.shrink();

    if (graded == submitted) {
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
            border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF047857),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Semua Nilai Telah Terintegrasi ke Sistem',
                  style: TextStyle(
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontSm + 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.xl),
      child: Text(
        'Selesaikan penilaian ($graded/$submitted) untuk menyimpan ke sistem.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.blueGrey.shade400,
          fontWeight: FontWeight.w600,
          fontSize: AppDimensions.fontSm,
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/injection_container.dart';

class InputPelanggaranScreen extends StatefulWidget {
  const InputPelanggaranScreen({super.key});

  @override
  State<InputPelanggaranScreen> createState() => _InputPelanggaranScreenState();
}

class _InputPelanggaranScreenState extends State<InputPelanggaranScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _crimsonRed = Color(0xFFEF4444);
  static const Color _previewBg = Color(0xFFFEF2F2);
  static const Color _previewBorder = Color(0xFFFCA5A5);

  final List<Map<String, dynamic>> _selectedStudents = [];
  final List<RewardPunishmentItem> _selectedActivities = [];
  File? _selectedPhoto;
  final TextEditingController _keteranganController = TextEditingController();

  List<Map<String, dynamic>> _allStudents = [];
  bool _isLoadingStudents = true;
  bool _isSubmitting = false;

  String _studentSearchQuery = '';
  String _activitySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final ds = sl<AssessmentRemoteDataSource>();
      await RewardPunishmentData.loadFromApi(ds);

      try {
        final fetched = await ds.getStudents(onlyActiveAngkatan: 1);
        if (fetched.isNotEmpty && mounted) {
          setState(() {
            _allStudents = fetched;
            _isLoadingStudents = false;
          });
        } else if (mounted) {
          setState(() {
            _allStudents = SerdikRealData.records;
            _isLoadingStudents = false;
          });
        }
      } catch (e) {
        debugPrint('Error loading active students for violation from backend API: $e');
        if (mounted) {
          setState(() {
            _allStudents = SerdikRealData.records;
            _isLoadingStudents = false;
          });
        }
      }

      // Background non-blocking fetch for real-time mental score map
      ds.getMentalRecapMap().then((scoreMap) {
        if (scoreMap.isNotEmpty && mounted) {
          setState(() {
            for (var s in _allStudents) {
              final uid = (s['user_id'] ?? s['id'] ?? s['serdik_id'])?.toString();
              if (uid != null && scoreMap.containsKey(uid)) {
                s['nilai_mental'] = scoreMap[uid];
              }
            }
          });
        }
      }).catchError((_) {});
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    super.dispose();
  }

  String _normalizePokjar(String pokjar) {
    final clean = pokjar.toUpperCase().replaceAll(' ', '');
    if (clean.contains('III') || clean.contains('3')) return 'POKJAR III';
    if (clean.contains('II') || clean.contains('2')) return 'POKJAR II';
    if (clean.contains('IV') || clean.contains('4')) return 'POKJAR IV';
    if (clean.contains('V') || clean.contains('5')) return 'POKJAR V';
    if (clean.contains('I') || clean.contains('1')) return 'POKJAR I';
    return pokjar;
  }

  double get _accumulatedPunishmentPoint {
    double total = 0.0;
    for (final act in _selectedActivities) {
      total += act.point.abs();
    }
    return total;
  }

  double get _initialAverageMentalScore {
    if (_selectedStudents.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in _selectedStudents) {
      final score = (s['nilai_mental'] as num?)?.toDouble() ??
          (s['mental_score'] as num?)?.toDouble() ??
          (s['nilaiMental'] as num?)?.toDouble() ??
          (s['score'] as num?)?.toDouble() ??
          _calculateAspectSum(s);
      sum += score;
    }
    return sum / _selectedStudents.length;
  }

  double _calculateAspectSum(Map<String, dynamic> s) {
    final moral = (s['moral'] as num?)?.toDouble();
    final disiplin = (s['disiplin'] as num?)?.toDouble();
    final kepemimpinan = (s['kepemimpinan'] as num?)?.toDouble();
    final pengendalian = (s['pengendalian_diri'] as num?)?.toDouble();
    final penampilan = (s['penampilan'] as num?)?.toDouble();
    if (moral != null || disiplin != null || kepemimpinan != null || pengendalian != null || penampilan != null) {
      return ((moral ?? 75.0) + (disiplin ?? 75.0) + (kepemimpinan ?? 75.0) + (pengendalian ?? 75.0) + (penampilan ?? 75.0)) / 5.0;
    }
    return 75.0;
  }

  double get _latestMentalScore {
    final score = _initialAverageMentalScore - _accumulatedPunishmentPoint;
    return score < 0 ? 0.0 : score;
  }

  Widget _buildStudentAvatar(String name, String? photoUrl, {double radius = 18}) {
    final provider = AvatarHelper.getImageProvider(photoUrl);
    if (provider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: provider,
        backgroundColor: Colors.grey.shade200,
      );
    }
    final initials = AvatarHelper.getInitials(name);
    final color = AvatarHelper.getAvatarColor(name);
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Unggah Bukti Gambar',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: 20),
                _buildPhotoOptionTile(
                  icon: Icons.camera_alt_outlined,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: _primaryNavy,
                  title: 'Ambil dari Kamera',
                  titleColor: _primaryNavy,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
                _buildPhotoOptionTile(
                  icon: Icons.crop_original_outlined,
                  iconBg: const Color(0xFFF1F5F9),
                  iconColor: _primaryNavy,
                  title: 'Pilih dari Galeri',
                  titleColor: _primaryNavy,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedPhoto != null) ...[
                  const SizedBox(height: 12),
                  _buildPhotoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    title: 'Hapus Foto',
                    titleColor: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedPhoto = null);
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOptionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitData() async {
    if (_selectedStudents.isEmpty || _selectedActivities.isEmpty || _selectedPhoto == null) {
      AppNotifier.showError(context, 'Lengkapi Target Peserta Didik, Jenis Pelanggaran, dan Bukti Gambar!');
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isSubmitting = true);

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();

      final List<int> userIds = _selectedStudents.map((s) {
        return int.tryParse((s['user_id'] ?? s['id'] ?? s['serdik_id'] ?? '1').toString()) ?? 1;
      }).toList();

      final List<int> itemIds = _selectedActivities.map((a) {
        return int.tryParse(a.id) ?? 1;
      }).toList();

      try {
        await dataSource.submitPelanggaranInput(
          userIds: userIds,
          itemIds: itemIds,
          notes: _keteranganController.text,
          file: _selectedPhoto,
        );
      } catch (e) {
        // Fallback row-by-row submit if batch endpoint is unavailable
        for (final uId in userIds) {
          for (final iId in itemIds) {
            final act = _selectedActivities.firstWhere(
              (a) => a.id == iId.toString(),
              orElse: () => _selectedActivities.first,
            );
            await dataSource.submitPunishmentLog({
              'user_id': uId,
              'punishment_item_id': iId,
              'point': act.point,
              'qty': 1,
              'violation_date': DateTime.now().toUtc().toIso8601String(),
              'notes': _keteranganController.text,
            });
          }
        }
      }

      if (mounted) {
        setState(() => _isSubmitting = false);
        AppNotifier.showSuccess(
          context,
          'Data pelanggaran berhasil disimpan & dicatat di Audit Trail!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppNotifier.showError(context, 'Gagal menyimpan data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid =
        _selectedStudents.isNotEmpty && _selectedActivities.isNotEmpty && _selectedPhoto != null;

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Input Pelanggaran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentsSection(),
              const SizedBox(height: 20),
              _buildActivitiesSection(),
              const SizedBox(height: 20),
              _buildImageUploadSection(),
              const SizedBox(height: 20),
              _buildKeteranganSection(),
              const SizedBox(height: 24),
              _buildMentalPreviewSection(),
              const SizedBox(height: 28),
              _buildSubmitButton(isFormValid),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                  letterSpacing: 0.5,
                ),
                children: [
                  const TextSpan(text: 'TARGET PESERTA DIDIK '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_selectedStudents.length} dipilih)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showStudentSearchModal,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.blueGrey.shade400, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Cari nama atau NRP...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedStudents.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedStudents.map((student) {
              final name = (student['nama_lengkap'] ?? student['name'] ?? '-').toString();
              final photo = student['profile_photo'] ?? student['profilePhoto'] ?? student['foto_profil'];

              return Chip(
                avatar: _buildStudentAvatar(name, photo?.toString(), radius: 12),
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryNavy),
                ),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onDeleted: () {
                  setState(() {
                    _selectedStudents.removeWhere((s) => s == student);
                  });
                },
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActivitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                  letterSpacing: 0.5,
                ),
                children: [
                  const TextSpan(text: 'JENIS PELANGGARAN '),
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${_selectedActivities.length} dipilih)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showActivitySearchModal,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: Colors.blueGrey.shade400, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Cari jenis pelanggaran...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedActivities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedActivities.map((activity) {
              return Chip(
                label: Text(
                  '${activity.description} -${activity.point.abs().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _crimsonRed),
                ),
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                onDeleted: () {
                  setState(() {
                    _selectedActivities.removeWhere((a) => a.id == activity.id);
                  });
                },
                backgroundColor: const Color(0xFFFEE2E2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
              letterSpacing: 0.5,
            ),
            children: [
              const TextSpan(text: 'BUKTI GAMBAR '),
              TextSpan(
                text: '*',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showPhotoOptions,
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedPhoto != null ? _crimsonRed : Colors.blueGrey.shade200,
                width: _selectedPhoto != null ? 2 : 1.5,
              ),
              image: _selectedPhoto != null
                  ? DecorationImage(
                      image: FileImage(_selectedPhoto!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedPhoto != null
                ? Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _selectedPhoto = null),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: Colors.blueGrey.shade400,
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14, color: _primaryNavy),
                          children: [
                            TextSpan(
                              text: 'Klik untuk unggah',
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.blue.shade700),
                            ),
                            const TextSpan(text: ' atau pilih gambar dari HP'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'PNG, JPG — bukti dokumentasi pelanggaran',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KETERANGAN',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _primaryNavy,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _keteranganController,
            maxLines: 4,
            minLines: 3,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryNavy),
            decoration: InputDecoration(
              hintText: 'Catatan tambahan dari pemberi pelanggaran...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentalPreviewSection() {
    final initialScore = _selectedStudents.isEmpty ? '—' : _initialAverageMentalScore.toStringAsFixed(2);
    final accumulatedPunishment = '-${_accumulatedPunishmentPoint.toStringAsFixed(2)}';
    final latestScore = _selectedStudents.isEmpty ? '—' : _latestMentalScore.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _previewBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _previewBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Colors.red.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'PRATINJAU NILAI MENTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.red.shade800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreColumn('NILAI MENTAL', initialScore, Colors.blueGrey.shade800),
              _buildScoreColumn('PELANGGARAN', accumulatedPunishment, _crimsonRed),
              _buildScoreColumn('NILAI MENTAL TERBARU', latestScore, _primaryNavy),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '*Nilai mental ditampilkan sebagai rata-rata dari ${_selectedStudents.length} peserta terpilih.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: valColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isValid) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (isValid && !_isSubmitting) ? _submitData : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryNavy,
          disabledBackgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded, color: Colors.white, size: 20),
        label: Text(
          _isSubmitting ? 'MENYIMPAN...' : 'Simpan Data',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showStudentSearchModal() {
    _studentSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final authState = context.read<AuthBloc>().state;
          String userPokjar = '';
          String userRole = '';
          if (authState is AuthSuccess) {
            userPokjar = authState.user.pokjar;
            userRole = authState.user.roleId.toLowerCase();
          }

          final isPatun = userRole.contains('patun') || userRole.contains('perwira');

          final filteredList = _allStudents.where((serdik) {
            final statusVal = (serdik['status'] ?? serdik['status_serdik'] ?? serdik['is_active'] ?? 'aktif').toString().toLowerCase();
            if (statusVal == 'nonaktif' || statusVal == 'inactive' || statusVal == 'false' || statusVal == '0') {
              return false;
            }

            if (isPatun && userPokjar.isNotEmpty && userPokjar != '-') {
              final studentPokjar = (serdik['kelompok_kelas'] ?? serdik['group_name'] ?? serdik['pokjar'] ?? '').toString();
              if (_normalizePokjar(studentPokjar) != _normalizePokjar(userPokjar)) {
                return false;
              }
            }

            final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '').toString().toLowerCase();
            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? serdik['nrp'] ?? serdik['nrp_nip'] ?? '').toString().toLowerCase();
            final query = _studentSearchQuery.toLowerCase();
            return name.contains(query) || noSerdik.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildModalHeader('Pilih Target Peserta Didik', () => Navigator.pop(context)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setModalState(() => _studentSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau NRP...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoadingStudents
                      ? const Center(child: CircularProgressIndicator(color: _primaryNavy))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final serdik = filteredList[index];
                            final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '-').toString();
                            final nosis = (serdik['nrp_nip'] ?? serdik['nrp'] ?? serdik['no_serdik'] ?? serdik['nip'] ?? '-').toString();
                            final photo = serdik['profile_photo'] ?? serdik['profilePhoto'] ?? serdik['foto_profil'];

                            final bool isSelected = _selectedStudents.any((s) =>
                                (s['no_serdik'] ?? s['nip'] ?? s['nrp'] ?? s['nrp_nip']) == nosis ||
                                (s['user_id'] ?? s['id']) == (serdik['user_id'] ?? serdik['id']));

                            return Material(
                              color: isSelected ? const Color(0xFFFEF2F2) : Colors.transparent,
                              child: ListTile(
                                leading: _buildStudentAvatar(name, photo?.toString(), radius: 20),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _primaryNavy)),
                                subtitle: Text(
                                  nosis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                ),
                                trailing: Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.check_box_outline_blank_rounded,
                                  color: isSelected ? _crimsonRed : Colors.grey.shade400,
                                ),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedStudents.removeWhere((s) =>
                                          (s['no_serdik'] ?? s['nip'] ?? s['nrp']) == nosis ||
                                          (s['user_id'] ?? s['id']) == (serdik['user_id'] ?? serdik['id']));
                                    } else {
                                      _selectedStudents.add(serdik);
                                    }
                                  });
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showActivitySearchModal() {
    _activitySearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final punishments = RewardPunishmentData.punishments;
          final filteredList = punishments.where((act) {
            final desc = act.description.toLowerCase();
            final aspect = act.aspect.toLowerCase();
            final query = _activitySearchQuery.toLowerCase();
            return desc.contains(query) || aspect.contains(query);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                _buildModalHeader('Pilih Jenis Pelanggaran', () => Navigator.pop(context)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (val) => setModalState(() => _activitySearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari jenis pelanggaran...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final act = filteredList[index];
                      final bool isSelected = _selectedActivities.any((a) => a.id == act.id);

                      String aspectFormatted = act.aspect;
                      if (act.aspect.isNotEmpty) {
                        aspectFormatted = act.aspect[0].toUpperCase() + act.aspect.substring(1).toLowerCase();
                      }
                      final noteStr = (act.note != null && act.note!.isNotEmpty && act.note != '-') ? ' • ${act.note}' : '';
                      final subtitleText = '$aspectFormatted$noteStr';

                      return Material(
                        color: isSelected ? const Color(0xFFFEF2F2) : Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          title: Text(
                            act.description,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _primaryNavy),
                          ),
                          subtitle: Text(
                            subtitleText,
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${act.point.abs().toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: _crimsonRed, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.check_box_outline_blank_rounded,
                                color: isSelected ? _crimsonRed : Colors.grey.shade400,
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedActivities.removeWhere((a) => a.id == act.id);
                              } else {
                                _selectedActivities.add(act);
                              }
                            });
                            setModalState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalHeader(String title, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _primaryNavy),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

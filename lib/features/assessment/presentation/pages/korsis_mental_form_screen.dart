import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/utils/reward_punishment_eligibility.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class KorsisMentalFormScreen extends StatefulWidget {
  final bool isReward;

  const KorsisMentalFormScreen({super.key, required this.isReward});

  @override
  State<KorsisMentalFormScreen> createState() => _KorsisMentalFormScreenState();
}

class _KorsisMentalFormScreenState extends State<KorsisMentalFormScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  Map<String, dynamic>? _selectedSerdik;
  RewardPunishmentItem? _selectedCategory;
  File? _selectedPhoto;
  final TextEditingController _justificationController =
      TextEditingController();

  String get _selectedSerdikName {
    if (_selectedSerdik == null) return '';
    return (_selectedSerdik!['nama_lengkap'] ?? _selectedSerdik!['name'] ?? '-').toString();
  }

  String get _selectedSerdikNosis {
    if (_selectedSerdik == null) return '';
    return (_selectedSerdik!['no_serdik'] ?? _selectedSerdik!['nip'] ?? _selectedSerdik!['nrp'] ?? '-').toString();
  }

  String get _selectedSerdikPokjar {
    if (_selectedSerdik == null) return '';
    return (_selectedSerdik!['kelompok_kelas'] ?? _selectedSerdik!['group_name'] ?? '-').toString();
  }

  String get _selectedSerdikPangkat {
    if (_selectedSerdik == null) return '';
    return (_selectedSerdik!['pangkat'] ?? '-').toString();
  }

  String? get _selectedSerdikPhoto {
    if (_selectedSerdik == null) return null;
    return (_selectedSerdik!['profile_photo'] ?? _selectedSerdik!['profilePhoto'])?.toString();
  }

  List<Map<String, dynamic>> _serdikList = [];
  String _serdikSearchQuery = '';
  String _indicatorSearchQuery = '';
  String _selectedFilterPokjar = 'Semua';

  final List<String> _pokjarOptions = [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  bool _isLoadingIndicators = true;

  @override
  void initState() {
    super.initState();
    _loadIndicators();
  }

  Future<void> _loadIndicators() async {
    try {
      final ds = sl<AssessmentRemoteDataSource>();
      await RewardPunishmentData.loadFromApi(ds);
      final fetchedStudents = await ds.getAllMentalScores();
      if (mounted) {
        setState(() {
          _serdikList = fetchedStudents;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _serdikList = SerdikRealData.records;
        });
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingIndicators = false;
      });
    }
  }

  Future<void> _fetchSelectedSerdikScores(String noSerdik) async {
    try {
      final ds = sl<AssessmentRemoteDataSource>();
      final scores = await ds.getMental(noSerdik);
      if (mounted && _selectedSerdik != null) {
        final currentNosis = (_selectedSerdik!['no_serdik'] ?? _selectedSerdik!['nip'] ?? _selectedSerdik!['nrp'] ?? '').toString();
        if (currentNosis == noSerdik) {
          setState(() {
            final updatedSerdik = Map<String, dynamic>.from(_selectedSerdik!);
            updatedSerdik['moral'] = scores['moral'] ?? 80.0;
            updatedSerdik['disiplin'] = scores['disiplin'] ?? 80.0;
            updatedSerdik['kepemimpinan'] = scores['kepemimpinan'] ?? 80.0;
            updatedSerdik['pengendalian_diri'] = scores['pengendalian_diri'] ?? 80.0;
            updatedSerdik['penampilan'] = scores['penampilan'] ?? 80.0;
            updatedSerdik['sosiometri'] = scores['sosiometri'] ?? 80.0;
            _selectedSerdik = updatedSerdik;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching serdik scores: $e');
    }
  }

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
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

  String _mapArabicToRoman(String arabic) {
    switch (arabic) {
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
        return arabic;
    }
  }

  List<RewardPunishmentItem> get _currentOptions => widget.isReward
      ? RewardPunishmentData.rewards
      : RewardPunishmentData.punishments;

  double get _calculatedFinalScore {
    double baseScore = _currentBaseScore;
    if (_selectedCategory == null) return baseScore;
    return baseScore + _selectedCategory!.point;
  }

  double get _currentBaseScore {
    if (_selectedSerdik != null) {
      if (_selectedCategory != null) {
        final aspectKey = _selectedCategory!.aspect.toLowerCase().replaceAll(' ', '_');
        final currentScore = _selectedSerdik![aspectKey] ?? _selectedSerdik![_selectedCategory!.aspect] ?? 80.0;
        return (currentScore as num).toDouble();
      }
      final double moral = (_selectedSerdik!['moral'] as num?)?.toDouble() ?? 80.0;
      final double disiplin = (_selectedSerdik!['disiplin'] as num?)?.toDouble() ?? 80.0;
      final double kepemimpinan = (_selectedSerdik!['kepemimpinan'] as num?)?.toDouble() ?? 80.0;
      final double pengendalian = (_selectedSerdik!['pengendalian_diri'] as num?)?.toDouble() ?? 80.0;
      final double penampilan = (_selectedSerdik!['penampilan'] as num?)?.toDouble() ?? 80.0;
      return (moral + disiplin + kepemimpinan + pengendalian + penampilan) / 5.0;
    }
    return 80.0;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removePhoto() {
    Navigator.pop(context);
    setState(() => _selectedPhoto = null);
  }

  Color _getScoreColor(double s) {
    if (s == 0) return Colors.blueGrey.shade800;
    if (s > 85.00) return Colors.green.shade800;
    if (s > 80.00) return Colors.green.shade500;
    if (s > 75.00) return Colors.lime.shade700;
    if (s > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
  }

  void _showPhotoOptions() {
    final bool hasPhoto = _selectedPhoto != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppDimensions.xs / 2),
                  ),
                ),
                const Text(
                  'Unggah Bukti Foto',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                _buildBottomSheetTile(
                  icon: AppIcons.camera,
                  title: 'Ambil dari Kamera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (hasPhoto)
                  _buildBottomSheetTile(
                    icon: AppIcons.trash,
                    title: 'Hapus Foto',
                    color: Colors.red.shade600,
                    onTap: _removePhoto,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: (color ?? _primaryNavy).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color ?? _primaryNavy,
            size: AppDimensions.iconLg,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? _primaryNavy,
            fontSize: AppDimensions.fontLg + 1,
          ),
        ),
        trailing: Icon(AppIcons.caretRight, color: Colors.grey.shade400),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_selectedSerdik == null || _selectedCategory == null || _selectedPhoto == null) return;
    HapticFeedback.heavyImpact();

    String dynamicSender = 'Korsis';
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      dynamicSender = '${authState.user.pangkat} ${authState.user.name}';
    }

    final newItem = InboxItem(
      id: 'mock_inbox_${DateTime.now().millisecondsSinceEpoch}',
      serdikName: _selectedSerdikName,
      pangkat: _selectedSerdikPangkat,
      nosis: _selectedSerdikNosis,
      pokjar: _selectedSerdikPokjar,
      isReward: widget.isReward,
      senderName: dynamicSender,
      timestamp: DateTime.now(),
      points: _selectedCategory!.point,
      description: _justificationController.text.isNotEmpty
          ? _justificationController.text
          : 'Telah dilakukan observasi dan pencatatan oleh Korsis.',
      rewardPunishmentName: _selectedCategory!.description,
      status: 'disetujui',
      rewardPunishmentId: _selectedCategory!.id,
      photoPath: _selectedPhoto?.path,
    );

    KorsisInboxMockData.addRecord(newItem);

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      
      int itemId = 1;
      try {
         itemId = int.parse(_selectedCategory!.id);
      } catch (_) {}

      final int studentId = int.tryParse((_selectedSerdik!['user_id'] ?? _selectedSerdik!['id'] ?? '').toString()) ?? 1;

      if (widget.isReward) {
        await dataSource.submitUserReward({
          'user_id': studentId,
          'reward_item_id': itemId,
          'point': _selectedCategory!.point,
          'qty': 1,
          'reward_date': DateTime.now().toUtc().toIso8601String(),
          'notes': _justificationController.text.isNotEmpty
              ? _justificationController.text
              : 'Telah dilakukan observasi dan pencatatan oleh Korsis.',
          'status': 'approved',
        });
      } else {
        await dataSource.submitPunishmentLog({
          'user_id': studentId,
          'punishment_item_id': itemId,
          'point': _selectedCategory!.point.abs(),
          'qty': 1,
          'violation_date': DateTime.now().toUtc().toIso8601String(),
          'notes': _justificationController.text.isNotEmpty
              ? _justificationController.text
              : 'Telah dilakukan observasi dan pencatatan oleh Korsis.',
          'status': 'approved',
        });
      }

      if (mounted) {
        AppNotifier.showSuccess(
          context,
          'Catatan berhasil ditambahkan ke sistem!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppNotifier.showError(
          context,
          'Gagal mengirim ke server: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.isReward ? 'Input Reward' : 'Input Punishment';
    final Color pointColor = widget.isReward
        ? Colors.green.shade600
        : Colors.red.shade600;

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
            letterSpacing: 0.5,
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
        padding: const EdgeInsets.all(AppDimensions.xl),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Target Serdik'),
            _buildSerdikSelectionCard(pointColor),
            const SizedBox(height: AppDimensions.xl),

            _buildSectionTitle(
              widget.isReward ? 'Indikator Prestasi' : 'Indikator Pelanggaran',
            ),
            _buildIndicatorSelectionCard(pointColor),
            const SizedBox(height: AppDimensions.xl),

            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Bukti Foto',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.xs),
                  Text(
                    '(Wajib)',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _buildPhotoUploader(),
            const SizedBox(height: AppDimensions.xxl),

            _buildSectionTitle('Keterangan Justifikasi'),
            _buildJustificationField(),
            const SizedBox(height: AppDimensions.xxl),

            _buildPreviewSection(pointColor),
            const SizedBox(height: AppDimensions.xxl),

            ElevatedButton(
              onPressed:
                  (_selectedSerdik != null &&
                      _selectedCategory != null &&
                      _selectedPhoto != null)
                  ? _submitForm
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: pointColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                elevation: 0,
              ),
              child: const Text(
                'SIMPAN KE SISTEM',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w800,
          color: _primaryNavy,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSerdikSelectionCard(Color pointColor) {
    final bool isSelected = _selectedSerdik != null;

    return InkWell(
      onTap: _showSerdikLookup,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected
                ? _primaryNavy.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            if (isSelected)
              _buildAvatar(_selectedSerdikPhoto)
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.user,
                  color: Colors.grey.shade400,
                  size: AppDimensions.iconLg,
                ),
              ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSelected
                        ? _selectedSerdikName
                        : 'Pilih Target Serdik',
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? _primaryNavy
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected
                        ? '$_selectedSerdikPangkat • No. $_selectedSerdikNosis'
                        : 'Tekan untuk mencari Serdik',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.blueGrey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.caretDown,
              color: Colors.grey.shade400,
              size: AppDimensions.iconLg,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorSelectionCard(Color pointColor) {
    final bool isSelected = _selectedCategory != null;

    return InkWell(
      onTap: _isLoadingIndicators ? null : _showIndicatorLookup,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isSelected
                ? _primaryNavy.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? pointColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isReward ? Icons.stars_rounded : Icons.warning_rounded,
                color: isSelected ? pointColor : Colors.grey.shade400,
                size: AppDimensions.iconLg,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingIndicators)
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: pointColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Memuat data...',
                          style: TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      isSelected
                          ? _selectedCategory!.description
                          : 'Pilih Indikator',
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? _primaryNavy
                            : Colors.blueGrey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (isSelected && _selectedCategory!.note != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          _selectedCategory!.note!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      )
                    else if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          _selectedCategory!.aspect.toUpperCase(),
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      )
                    else
                      Text(
                        widget.isReward
                            ? 'Pilih jenis indikator prestasi'
                            : 'Pilih jenis indikator pelanggaran',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (!_isLoadingIndicators)
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(left: AppDimensions.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pointColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    '${_selectedCategory!.point > 0 ? "+" : ""}${_selectedCategory!.point}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w900,
                      color: pointColor,
                    ),
                  ),
                )
              else
                Icon(
                  AppIcons.caretDown,
                  color: Colors.grey.shade400,
                  size: AppDimensions.iconLg,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploader() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: _selectedPhoto != null
                ? _primaryNavy.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            width: _selectedPhoto != null ? 2 : 1,
          ),
          image: _selectedPhoto != null
              ? DecorationImage(
                  image: FileImage(_selectedPhoto!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: _selectedPhoto != null
                      ? _primaryNavy.withValues(alpha: 0.2)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _selectedPhoto != null
                      ? Icons.check_circle_rounded
                      : AppIcons.cameraFill,
                  size: AppDimensions.iconXxl,
                  color: _selectedPhoto != null
                      ? Colors.white
                      : Colors.blueGrey.shade300,
                ),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                _selectedPhoto != null
                    ? 'Ketuk untuk ubah foto'
                    : 'Ambil dari Kamera',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w700,
                  color: _selectedPhoto != null
                      ? Colors.white
                      : Colors.blueGrey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJustificationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _justificationController,
        maxLines: 4,
        minLines: 3,
        style: const TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w600,
          color: _primaryNavy,
        ),
        decoration: InputDecoration(
          hintText: 'Masukkan keterangan justifikasi...',
          hintStyle: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppDimensions.lg),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(Color pointColor) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: _primaryNavy,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              const Text(
                'PREVIEW NILAI AKHIR',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: _lightGrey,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: _selectedSerdik == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.lg,
                    ),
                    child: Center(
                      child: Text(
                        'Pilih target serdik terlebih dahulu',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory != null
                                ? 'Nilai Saat Ini (${_selectedCategory!.aspect})'
                                : 'Nilai Saat Ini',
                            style: TextStyle(
                              fontSize: AppDimensions.fontMd,
                              color: Colors.blueGrey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(
                                _currentBaseScore,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Text(
                              _currentBaseScore.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: AppDimensions.fontLg,
                                color: _getScoreColor(_currentBaseScore),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCategory != null) ...[
                        const Padding(
                           padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.isReward
                                  ? 'Penambahan Poin'
                                  : 'Pengurangan Poin',
                              style: TextStyle(
                                fontSize: AppDimensions.fontMd,
                                color: Colors.blueGrey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: pointColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_selectedCategory!.point > 0 ? "+" : ""}${_selectedCategory!.point}',
                                style: TextStyle(
                                  fontSize: AppDimensions.fontMd,
                                  color: pointColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          if (_selectedSerdik != null) ...[
            const SizedBox(height: AppDimensions.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory != null
                      ? 'Estimasi Nilai Baru (${_selectedCategory!.aspect})'
                      : 'Estimasi Nilai Baru',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg,
                    color: _primaryNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(
                      _calculatedFinalScore,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    _calculatedFinalScore.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: AppDimensions.fontXxl,
                      color: _getScoreColor(_calculatedFinalScore),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoPath) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        image: DecorationImage(
          image: AvatarHelper.getAvatar(photoPath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showSerdikLookup() {
    _serdikSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredList = _serdikList.where((serdik) {
            final name = (serdik['nama_lengkap'] ?? serdik['name'] ?? '')
                .toString()
                .toLowerCase();
            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? serdik['nrp'] ?? '')
                .toString()
                .toLowerCase();
            final pokjar = (serdik['kelompok_kelas'] ?? serdik['group_name'] ?? '').toString();

            final query = _serdikSearchQuery.toLowerCase();
            final matchQuery = name.contains(query) || noSerdik.contains(query);

            final matchPokjar =
                _selectedFilterPokjar == 'Semua' ||
                pokjar == _mapRomanToArabic(_selectedFilterPokjar);

            return matchQuery && matchPokjar;
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBottomSheetHeader(
                  'Cari Serdik',
                  () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) =>
                              setModalState(() => _serdikSearchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau nomor serdik...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.grey,
                            ),
                            filled: true,
                            fillColor: _lightGrey,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Container(
                        decoration: BoxDecoration(
                          color: _selectedFilterPokjar == 'Semua'
                              ? _lightGrey
                              : _primaryNavy.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: _selectedFilterPokjar == 'Semua'
                                ? Colors.grey.shade600
                                : _primaryNavy,
                          ),
                          onSelected: (val) =>
                              setModalState(() => _selectedFilterPokjar = val),
                          itemBuilder: (context) =>
                              _pokjarOptions.map((String opt) {
                                return PopupMenuItem<String>(
                                  value: opt,
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      fontWeight: _selectedFilterPokjar == opt
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: _selectedFilterPokjar == opt
                                          ? _primaryNavy
                                          : Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final serdik = filteredList[index];
                      final photoVal = serdik['profile_photo'] ?? serdik['profilePhoto'];
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.xl,
                            vertical: 4,
                          ),
                          leading: _buildAvatar(photoVal != null ? photoVal.toString() : null),
                          title: Text(
                            (serdik['nama_lengkap'] ?? serdik['name'] ?? '-').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                            ),
                          ),
                          subtitle: Text(
                            '${serdik['pangkat'] ?? serdik['grade'] ?? '-'} • ${serdik['no_serdik'] ?? serdik['nip'] ?? serdik['nrp'] ?? '-'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                            ),
                            child: Text(
                              _mapArabicToRoman(
                                (serdik['kelompok_kelas'] ?? serdik['group_name'] ?? '-').toString(),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() => _selectedSerdik = serdik);
                            Navigator.pop(context);
                            final noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? serdik['nrp'] ?? '').toString();
                            if (noSerdik.isNotEmpty) {
                              _fetchSelectedSerdikScores(noSerdik);
                            }
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

  void _showIndicatorLookup() {
    _indicatorSearchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredList = _currentOptions.where((opt) {
            final desc = opt.description.toLowerCase();
            final type = opt.aspect.toLowerCase();
            final query = _indicatorSearchQuery.toLowerCase();
            return desc.contains(query) || type.contains(query);
          }).toList();

          final pointColor = widget.isReward
              ? Colors.green.shade600
              : Colors.red.shade600;

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: _lightGrey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBottomSheetHeader(
                  widget.isReward
                      ? 'Indikator Prestasi'
                      : 'Indikator Pelanggaran',
                  () => Navigator.pop(context),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: TextField(
                    onChanged: (val) =>
                        setModalState(() => _indicatorSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: widget.isReward
                          ? 'Cari indikator prestasi...'
                          : 'Cari indikator pelanggaran...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: _lightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.lg),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredList.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.md),
                    itemBuilder: (context, index) {
                      final opt = filteredList[index];

                      EligibilityStatus eligibility = EligibilityStatus(true);
                      if (_selectedSerdik != null && _selectedSerdikNosis != '-') {
                        eligibility =
                            RewardPunishmentEligibility.checkEligibility(
                              _selectedSerdikNosis,
                              opt,
                            );
                      }
                      final bool isGreyedOut = !eligibility.isEligible;
                      final Color effectiveColor = isGreyedOut
                          ? Colors.grey.shade400
                          : pointColor;

                      return InkWell(
                        onTap: () {
                          if (_selectedSerdik == null) {
                            AppNotifier.showError(
                              context,
                              "Silakan pilih serdik terlebih dahulu",
                            );
                            return;
                          }
                          if (isGreyedOut) {
                            AppNotifier.showError(
                              context,
                              eligibility.message ??
                                  "Item ini sudah mencapai batas maksimum",
                            );
                            return;
                          }
                          setState(() => _selectedCategory = opt);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.lg),
                          decoration: BoxDecoration(
                            color: isGreyedOut
                                ? Colors.grey.shade50
                                : Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusLg,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.01),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: effectiveColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.isReward
                                      ? Icons.stars_rounded
                                      : Icons.warning_rounded,
                                  color: effectiveColor,
                                  size: AppDimensions.iconLg,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt.description,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: AppDimensions.fontMd,
                                              color: isGreyedOut
                                                  ? Colors.grey.shade500
                                                  : _primaryNavy,
                                              decoration: isGreyedOut
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                            left: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: pointColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusSm,
                                            ),
                                          ),
                                          child: Text(
                                            '${opt.point > 0 ? "+" : ""}${opt.point}',
                                            style: TextStyle(
                                              fontSize: AppDimensions.fontLg,
                                              fontWeight: FontWeight.w900,
                                              color: effectiveColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blueGrey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusSm,
                                            ),
                                          ),
                                          child: Text(
                                            opt.aspect.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: AppDimensions.fontXs,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.blueGrey.shade600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        if (opt.note != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppDimensions.radiusSm,
                                                  ),
                                            ),
                                            child: Text(
                                              opt.note!,
                                              style: TextStyle(
                                                fontSize: AppDimensions.fontXs,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildBottomSheetHeader(String title, VoidCallback onClose) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
            color: Colors.grey.shade600,
            splashRadius: 24,
          ),
        ],
      ),
    );
  }
}

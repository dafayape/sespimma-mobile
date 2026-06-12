import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class SociometryFormScreen extends StatefulWidget {
  final String peerName;
  final String peerNrp;
  final String peerRank;
  final String imageUrl;

  const SociometryFormScreen({
    super.key,
    required this.peerName,
    required this.peerNrp,
    required this.peerRank,
    required this.imageUrl,
  });

  @override
  State<SociometryFormScreen> createState() => _SociometryFormScreenState();
}

class _SociometryFormScreenState extends State<SociometryFormScreen> {
  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  late List<TextEditingController> _scoreControllers;
  final TextEditingController _justificationController =
      TextEditingController();

  final List<Map<String, dynamic>> _indicators = const [
    {
      'pillar': 'Moral',
      'title': 'Etika dan Integritas',
      'desc':
          'Penerapan nilai-nilai etika, kejujuran, dan keluhuran budi pekerti dalam keseharian.',
    },
    {
      'pillar': 'Kepemimpinan',
      'title': 'Kemampuan Memimpin',
      'desc':
          'Kapasitas dalam mengarahkan, mengambil keputusan, dan memberikan pengaruh positif bagi rekan.',
    },
    {
      'pillar': 'Pengendalian Diri',
      'title': 'Kematangan Emosional',
      'desc':
          'Kemampuan menjaga stabilitas emosi, ketenangan dalam tekanan, dan bersikap bijaksana.',
    },
    {
      'pillar': 'Disiplin',
      'title': 'Ketaatan Aturan',
      'desc':
          'Kepatuhan terhadap tata tertib, ketepatan waktu, dan konsistensi pelaksanaan tugas.',
    },
    {
      'pillar': 'Penampilan',
      'title': 'Sikap dan Kerapian',
      'desc':
          'Kerapian seragam, kebersihan diri, dan sikap jasmani yang mencerminkan kewibawaan.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scoreControllers = List.generate(
      _indicators.length,
      (_) => TextEditingController(text: ''),
    );
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers) {
      controller.dispose();
    }
    _justificationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getQualitativeRating(double value) {
    if (value > 85.00) {
      return {'label': 'Sangat Memuaskan', 'code': 'SM', 'color': Colors.green};
    } else if (value > 80.00) {
      return {'label': 'Memuaskan', 'code': 'M', 'color': Colors.lightGreen};
    } else if (value > 75.00) {
      return {'label': 'Baik', 'code': 'B', 'color': Colors.orange};
    } else if (value > 70.00) {
      return {'label': 'Cukup', 'code': 'C', 'color': Colors.amber};
    } else {
      return {'label': 'Kurang', 'code': 'K', 'color': Colors.red};
    }
  }

  bool get _requiresJustification {
    return _scoreControllers.any((controller) {
      final val = double.tryParse(controller.text) ?? 0.0;
      return val > 90.00;
    });
  }

  bool get _isFormValid {
    for (var controller in _scoreControllers) {
      final valStr = controller.text.trim();
      if (valStr.isEmpty) return false;
      final val = double.tryParse(valStr);
      if (val == null || val < 0 || val > 100) return false;
    }

    if (_requiresJustification &&
        _justificationController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _lightGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: _primaryNavy),
          title: const Text(
            'Evaluasi Rekan',
            style: TextStyle(
              color: _primaryNavy,
              fontWeight: FontWeight.w800,
              fontSize: AppDimensions.fontXxl,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.xl - 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeerProfileHeader(),
                    const SizedBox(height: AppDimensions.lg),
                    _buildAnonymityBadge(),
                    const SizedBox(height: AppDimensions.lg),
                    const Text(
                      'Rubrik Penilaian',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.md),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _indicators.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimensions.md),
                      itemBuilder: (context, index) {
                        return _buildRatingCard(index);
                      },
                    ),
                    const SizedBox(height: AppDimensions.lg),
                    if (_requiresJustification) _buildJustificationInput(),
                    const SizedBox(height: AppDimensions.avatarMd),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _primaryIndigo.withValues(alpha: 0.1),
            backgroundImage: widget.imageUrl.isNotEmpty
                ? AssetImage(widget.imageUrl)
                : AvatarHelper.getAvatar(null),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.peerRank} ${widget.peerName}',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontLg + 1,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'NO. SERDIK: ${widget.peerNrp}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymityBadge() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _primaryIndigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: _primaryIndigo.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.shieldCheckFill,
            color: _primaryIndigo,
            size: AppDimensions.iconLg,
          ),
          const SizedBox(width: AppDimensions.md - 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistem Blind-Test Aktif',
                  style: TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w800,
                    color: _primaryIndigo,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Penilaian ini dienkripsi penuh. Nama Anda tidak akan pernah ditampilkan pada laporan individu rekan Anda.',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Colors.indigo.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(int index) {
    final item = _indicators[index];
    final controller = _scoreControllers[index];
    final bool isEmptyInput = controller.text.trim().isEmpty;

    final double currentScore = double.tryParse(controller.text) ?? 0.0;
    final ratingMeta = isEmptyInput
        ? {
            'label': 'Belum Diisi',
            'code': '-',
            'color': Colors.blueGrey.shade300,
          }
        : _getQualitativeRating(currentScore);

    final Color badgeColor = ratingMeta['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  item['pillar'].toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  '${ratingMeta['label']} (${ratingMeta['code']})',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            item['title'],
            style: const TextStyle(
              fontSize: AppDimensions.fontLg + 1,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.radiusSm),
          Text(
            item['desc'],
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Nilai Numerik (0 - 100)',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm + 1,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      'Ketik langsung nilai pencapaian rekan di sini',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Container(
                width: 110,
                height: 50,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed > 100.0) {
                      controller.text = '100.00';
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                    }
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: badgeColor.withValues(alpha: 0.03),
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontWeight: FontWeight.w600,
                    ),
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: BorderSide(
                        color: badgeColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: BorderSide(color: badgeColor, width: 2.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJustificationInput() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.warningCircleFill, color: Colors.orange.shade800),
              const SizedBox(width: AppDimensions.sm),
              Expanded(
                child: Text(
                  'Wajib Input Alasan Justifikasi',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Nilai di atas 90.00 memerlukan justifikasi. Harap cantumkan dasar atau pertimbangan objektif Anda untuk validasi audit sistem.',
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          TextField(
            controller: _justificationController,
            maxLines: 3,
            style: const TextStyle(
              fontSize: AppDimensions.fontDefault,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Contoh: Rekan ini secara konsisten menunjukkan ketaatan aturan yang mutlak serta memiliki resiliensi stres yang sangat tinggi...',
              hintStyle: TextStyle(
                fontSize: AppDimensions.fontMd,
                color: Colors.orange.shade300,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(AppDimensions.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(color: Colors.orange.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(color: Colors.orange.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide(
                  color: Colors.orange.shade600,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isFormValid
                ? () {
                    FocusScope.of(context).unfocus();
                    HapticFeedback.mediumImpact();
                    _showFinalConfirmation(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryIndigo,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade200,
              disabledForegroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SIMPAN EVALUASI',
              style: TextStyle(
                fontSize: AppDimensions.fontLg + 1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinalConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
        title: const Row(
          children: [
            Icon(
              AppIcons.shieldCheckFill,
              color: _primaryIndigo,
              size: AppDimensions.iconXl,
            ),
            SizedBox(width: AppDimensions.md - 4),
            Text(
              'Kunci Evaluasi?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
          ],
        ),
        content: const Text(
          'Tindakan evaluasi sosiometri bersifat final dan anonim. Nilai Anda akan digabungkan ke dalam basis data Pokjar. Lanjutkan?',
          style: TextStyle(
            fontSize: AppDimensions.fontDefault,
            height: 1.6,
            color: Colors.blueGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
              AppNotifier.showSuccess(
                context,
                'Evaluasi berhasil disimpan secara anonim',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: const Text(
              'Ya, Simpan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

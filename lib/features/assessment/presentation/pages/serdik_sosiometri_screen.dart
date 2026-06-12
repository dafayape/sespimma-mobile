import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'sociometry_form_screen.dart';
import '../../data/models/sociometry_period_config.dart';
import '../../data/models/sociometry_peer_model.dart';

class SerdikSosiometriScreen extends StatefulWidget {
  const SerdikSosiometriScreen({super.key});

  @override
  State<SerdikSosiometriScreen> createState() => _SerdikSosiometriScreenState();
}

class _SerdikSosiometriScreenState extends State<SerdikSosiometriScreen> {
  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  bool _isPhaseAwal = true;

  late List<SociometryPeerModel> _peersAwal;
  late List<SociometryPeerModel> _peersAkhir;

  @override
  void initState() {
    super.initState();
    _isPhaseAwal = !SociometryPeriodConfig.isAkhirActive();
    _peersAwal = SociometryPeriodConfig.peersAwal;
    _peersAkhir = SociometryPeriodConfig.peersAkhir;
  }

  List<SociometryPeerModel> get _currentPeers {
    final baseList = _isPhaseAwal
        ? List<SociometryPeerModel>.from(_peersAwal)
        : List<SociometryPeerModel>.from(_peersAkhir);

    baseList.sort((a, b) {
      if (a.isEvaluated && !b.isEvaluated) return 1;
      if (!a.isEvaluated && b.isEvaluated) return -1;
      return 0;
    });

    return baseList;
  }

  int get _evaluatedCount => _currentPeers.where((p) => p.isEvaluated).length;
  int get _totalCount => _currentPeers.length;
  bool get _isAllEvaluated => _evaluatedCount == _totalCount;

  bool get _isCurrentPhaseActive => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalActive()
      : SociometryPeriodConfig.isAkhirActive();

  bool get _isCurrentPhaseClosed => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalClosed()
      : SociometryPeriodConfig.isAkhirClosed();

  bool get _isCurrentTabLocked => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalLocked
      : SociometryPeriodConfig.isAkhirLocked;

  String _formatIndoDate(DateTime date) {
    final List<String> months = [
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
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _getDynamicPeriodRange(bool isAwal) {
    final start = isAwal
        ? SociometryPeriodConfig.awalStartDate
        : SociometryPeriodConfig.akhirStartDate;
    final end = isAwal
        ? SociometryPeriodConfig.awalEndDate
        : SociometryPeriodConfig.akhirEndDate;
    return "${_formatIndoDate(start)} - ${_formatIndoDate(end)}";
  }

  @override
  Widget build(BuildContext context) {
    final double progressPercent = _totalCount > 0
        ? _evaluatedCount / _totalCount
        : 0;

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _primaryNavy),
        title: const Text(
          'Sosiometri Peleton',
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
          _buildPhaseSelector(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: _primaryNavy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressBanner(progressPercent),
                    const SizedBox(height: AppDimensions.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Seluruh Rekan Peleton',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXl,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryNavy.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: Text(
                            'Total: $_totalCount',
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSm + 1,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.md),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentPeers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppDimensions.md),
                      itemBuilder: (context, index) {
                        return _buildPeerTile(context, index);
                      },
                    ),
                    const SizedBox(height: AppDimensions.xl),
                  ],
                ),
              ),
            ),
          ),
          if (_isAllEvaluated) _buildLockDataButton(context),
        ],
      ),
    );
  }

  Widget _buildPhaseSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.xs),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPhaseAwal = true);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPhaseAwal ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    boxShadow: _isPhaseAwal
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Awal Pendidikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w800,
                      color: _isPhaseAwal
                          ? _primaryIndigo
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPhaseAwal = false);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isPhaseAwal ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    boxShadow: !_isPhaseAwal
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Akhir Pendidikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w800,
                      color: !_isPhaseAwal
                          ? _primaryIndigo
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBanner(double percentage) {
    final periodLabel = _getDynamicPeriodRange(_isPhaseAwal);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryIndigo, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: _primaryIndigo.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAHAP AKTIF',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppDimensions.fontSm + 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    _isPhaseAwal ? 'SOSIOMETRI AWAL' : 'SOSIOMETRI AKHIR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontXxl,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.usersThreeFill,
                  color: Colors.white,
                  size: AppDimensions.iconLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  AppIcons.calendarBlankFill,
                  color: Colors.white,
                  size: AppDimensions.fontLg,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Periode: $periodLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kemajuan: $_evaluatedCount dari $_totalCount Rekan',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontDefault,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: AppDimensions.fontLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerTile(BuildContext context, int index) {
    final peer = _currentPeers[index];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap:
              (peer.isEvaluated ||
                  !_isCurrentPhaseActive ||
                  _isCurrentTabLocked)
              ? null
              : () async {
                  HapticFeedback.mediumImpact();
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SociometryFormScreen(
                        peerName: peer.name,
                        peerNrp: peer.nrp,
                        peerRank: peer.rank,
                        imageUrl: peer.imageUrl,
                      ),
                    ),
                  );

                  if (result == true) {
                    setState(() {
                      peer.isEvaluated = true;
                    });
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: _lightGrey,
                      backgroundImage: AssetImage(peer.imageUrl),
                    ),
                    if (peer.isEvaluated)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.xs / 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.checkCircleFill,
                            color: Color(0xFF059669),
                            size: AppDimensions.iconMd,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${peer.rank} ${peer.name}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w800,
                          color: (peer.isEvaluated || !_isCurrentPhaseActive)
                              ? Colors.blueGrey.shade300
                              : _primaryNavy,
                          decoration: peer.isEvaluated
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        'NO. SERDIK: ${peer.nrp}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                _buildStatusBadge(peer.isEvaluated),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isEvaluated) {
    if (!_isCurrentPhaseActive && !isEvaluated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isCurrentPhaseClosed ? 'DITUTUP' : 'BELUM DIBUKA',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: AppDimensions.xs),
            Icon(
              AppIcons.lockFill,
              color: Colors.grey.shade500,
              size: AppDimensions.iconXs,
            ),
          ],
        ),
      );
    }

    final Color bg = isEvaluated
        ? const Color(0xFFECFDF5)
        : _primaryIndigo.withValues(alpha: 0.05);
    final Color fg = isEvaluated ? const Color(0xFF047857) : _primaryIndigo;
    final String label = isEvaluated ? 'DINILAI' : 'MULAI';
    final IconData icon = isEvaluated
        ? AppIcons.checkCircleFill
        : AppIcons.caretRightBold;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Icon(icon, color: fg, size: AppDimensions.iconXs),
        ],
      ),
    );
  }

  Widget _buildLockDataButton(BuildContext context) {
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
          child: ElevatedButton.icon(
            onPressed:
                (!_isCurrentPhaseActive ||
                    !_isAllEvaluated ||
                    _isCurrentTabLocked)
                ? null
                : () {
                    HapticFeedback.heavyImpact();
                    _showFinalizeDialog(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryNavy,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _isCurrentTabLocked
                  ? const Color(0xFFECFDF5)
                  : Colors.grey.shade200,
              disabledForegroundColor: _isCurrentTabLocked
                  ? const Color(0xFF047857)
                  : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              elevation: 0,
              side: _isCurrentTabLocked
                  ? const BorderSide(color: Color(0xFF10B981), width: 1.5)
                  : BorderSide.none,
            ),
            icon: Icon(
              _isCurrentTabLocked
                  ? AppIcons.shieldCheckFill
                  : !_isCurrentPhaseActive
                  ? AppIcons.lockFill
                  : AppIcons.lockKeyFill,
            ),
            label: Text(
              _isCurrentTabLocked
                  ? 'DATA TELAH DIKUNCI PERMANEN'
                  : !_isCurrentPhaseActive
                  ? (_isCurrentPhaseClosed
                        ? 'TAHAP SUDAH DITUTUP'
                        : 'TAHAP BELUM DIBUKA')
                  : !_isAllEvaluated
                  ? 'SELESAIKAN PENILAIAN ($_evaluatedCount/$_totalCount)'
                  : 'KUNCI & KIRIM DATA',
              style: const TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFinalizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
        title: Row(
          children: [
            const Icon(
              AppIcons.lockKeyFill,
              color: _primaryNavy,
              size: AppDimensions.iconXl,
            ),
            const SizedBox(width: AppDimensions.md - 4),
            Text(
              _isPhaseAwal
                  ? 'Kunci Sosiometri Awal?'
                  : 'Kunci Sosiometri Akhir?',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
          ],
        ),
        content: Text(
          _isPhaseAwal
              ? 'Setelah dikunci, penilaian Sosiometri Awal tidak dapat diubah lagi. Data akan dirata-rata ke modul Mental IDMS. Lanjutkan?'
              : 'Setelah dikunci, penilaian Sosiometri Akhir bersifat final. Lanjutkan?',
          style: const TextStyle(
            fontSize: AppDimensions.fontDefault,
            height: 1.6,
            color: Colors.blueGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kembali',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_isPhaseAwal) {
                  SociometryPeriodConfig.lockAwal();
                } else {
                  SociometryPeriodConfig.lockAkhir();
                }
              });
              Navigator.pop(context);
              Navigator.pop(context);
              AppNotifier.showSuccess(context, 'Notifikasi');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: const Text(
              'Kunci Permanen',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

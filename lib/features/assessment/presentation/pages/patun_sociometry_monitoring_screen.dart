import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'patun_sociometry_detail_screen.dart';
import '../../data/models/sociometry_period_config.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunSociometryMonitoringScreen extends StatefulWidget {
  const PatunSociometryMonitoringScreen({super.key});

  @override
  State<PatunSociometryMonitoringScreen> createState() =>
      _PatunSociometryMonitoringScreenState();
}

class _PatunSociometryMonitoringScreenState
    extends State<PatunSociometryMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  bool _isPhaseAwal = true;

  bool get _isCurrentPhaseActive => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalActive()
      : SociometryPeriodConfig.isAkhirActive();

  bool get _isCurrentPhaseClosed => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalClosed()
      : SociometryPeriodConfig.isAkhirClosed();

  @override
  void initState() {
    super.initState();
    _isPhaseAwal = !SociometryPeriodConfig.isAkhirActive();
  }

  int _getFilledEvaluations(String nrp, int totalSerdik) {
    if (!_isCurrentPhaseActive && !_isCurrentPhaseClosed) return 0;

    int hash = nrp.hashCode;
    if (!_isPhaseAwal) hash += 1000;

    if (hash % 10 > 3) return totalSerdik;
    return hash % (totalSerdik + 1);
  }

  String _formatPokjarName(String realPokjar) {
    switch (realPokjar.toUpperCase()) {
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
        return realPokjar;
    }
  }

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
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Monitoring Sosiometri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final userPokjar = state.user.pokjar;
            final serdikList = SerdikRealData.records
                .where((s) => s['kelompok_kelas'] == userPokjar)
                .toList();

            final totalCompleted = serdikList.where((s) {
              return _getFilledEvaluations(s['nrp'], serdikList.length) ==
                  serdikList.length;
            }).length;

            final double progressPercent = serdikList.isNotEmpty
                ? totalCompleted / serdikList.length
                : 0;

            return Column(
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
                          _buildProgressBanner(
                            progressPercent,
                            totalCompleted,
                            serdikList.length,
                          ),
                          const SizedBox(height: AppDimensions.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'DAFTAR SERDIK',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontLg,
                                      fontWeight: FontWeight.w800,
                                      color: _primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primaryNavy,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _formatPokjarName(
                                        userPokjar,
                                      ).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: AppDimensions.fontXs,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryNavy,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXl,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.group_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${serdikList.length} Serdik',
                                      style: const TextStyle(
                                        fontSize: AppDimensions.fontSm,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.md),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: serdikList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: AppDimensions.md),
                            itemBuilder: (context, index) {
                              return _buildPeerTile(context, index, serdikList);
                            },
                          ),
                          const SizedBox(height: AppDimensions.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: _primaryNavy),
          );
        },
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
                    color: _isPhaseAwal ? _primaryNavy : Colors.transparent,
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
                          ? Colors.white
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
                    color: !_isPhaseAwal ? _primaryNavy : Colors.transparent,
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
                          ? Colors.white
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

  Widget _buildProgressBanner(
    double percentage,
    int totalCompleted,
    int totalSerdik,
  ) {
    final periodLabel = _getDynamicPeriodRange(_isPhaseAwal);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: _primaryNavy,
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
                  AppIcons.chartBarFill,
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
                  Icons.calendar_month_rounded,
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
                'Tuntas: $totalCompleted dari $totalSerdik Serdik',
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

  Widget _buildPeerTile(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> serdikList,
  ) {
    final serdik = serdikList[index];
    final int total = serdikList.length;
    final int filled = _getFilledEvaluations(serdik['nrp'], total);
    final bool isComplete = filled == total;

    final bool isBelum = filled == 0;

    Color badgeFg;
    Color badgeBg;
    IconData badgeIcon;
    String badgeText;

    if (!_isCurrentPhaseActive) {
      badgeFg = Colors.grey.shade500;
      badgeBg = Colors.grey.shade100;
      badgeIcon = AppIcons.lockFill;
      badgeText = _isCurrentPhaseClosed ? 'DITUTUP' : 'BELUM DIBUKA';
    } else if (isComplete) {
      badgeFg = const Color(0xFF047857);
      badgeBg = const Color(0xFFECFDF5);
      badgeIcon = Icons.check_circle_rounded;
      badgeText = 'TUNTAS';
    } else if (isBelum) {
      badgeFg = const Color(0xFFD32F2F);
      badgeBg = const Color(0xFFFFEBEE);
      badgeIcon = Icons.cancel_rounded;
      badgeText = 'BELUM';
    } else {
      badgeFg = Colors.orange.shade800;
      badgeBg = Colors.orange.shade50;
      badgeIcon = Icons.pending_actions_rounded;
      badgeText = 'PROSES';
    }

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
          onTap: !_isCurrentPhaseActive
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatunSociometryDetailScreen(
                        serdikData: serdik,
                        isPhaseAwal: _isPhaseAwal,
                        totalSerdik: total,
                      ),
                    ),
                  );
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
                      backgroundImage: AvatarHelper.getAvatar(
                        serdik['foto']?.toString(),
                      ),
                    ),
                    if (isComplete)
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
                        '${serdik['nama_lengkap']}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        '${serdik['pangkat']} • ${serdik['no_serdik']}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeFg),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: AppDimensions.fontXs,
                                fontWeight: FontWeight.w800,
                                color: badgeFg,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: badgeFg.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                          color: badgeFg,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isCurrentPhaseActive ? '$filled / $total' : '- / -',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          color: badgeFg,
                        ),
                      ),
                    ],
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

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/features/assessment/data/datasources/inbox_remote_data_source.dart';
import 'package:sespimma/features/dashboard/data/datasources/dashboard_remote_data_source.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notification/presentation/pages/notification_screen.dart';
import '../../../activity/presentation/pages/activity_history_screen.dart';
import '../../../assessment/data/models/korsis_inbox_mock_data.dart';
import '../../../notification/data/datasources/notification_mock_data.dart';
import '../../../attendance/presentation/pages/attendance_history_screen.dart';
import 'package:sespimma/shared/widgets/evidence_bottom_sheet.dart';
import '../../../assessment/data/models/sociometry_period_config.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import '../../../attendance/domain/models/map_tile_mode.dart';
import '../../../leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<InboxItem> _inboxItems = [];
  double? _dbAcademicScore;
  double? _dbMentalScore;
  double? _dbPhysicalScore;
  double? _dbRewardPoints;
  double? _dbPunishmentPoints;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInboxData();
      _fetchDashboardData();
    });
  }

  Future<void> _fetchDashboardData() async {
    final state = context.read<AuthBloc>().state;
    if (state is AuthSuccess && state.user.roleId.toLowerCase() == 'siswa') {
      try {
        final dashboardSource = sl<DashboardRemoteDataSource>();
        final data = await dashboardSource.getSerdikDashboard();
        final scoreData = data['scoreData'] as Map<String, dynamic>?;
        if (scoreData != null) {
          setState(() {
            _dbAcademicScore = (scoreData['academicScore'] as num?)?.toDouble() ?? 0.0;
            _dbMentalScore = (scoreData['mentalScore'] as num?)?.toDouble() ?? 0.0;
            _dbPhysicalScore = (scoreData['physicalScore'] as num?)?.toDouble() ?? 0.0;
            _dbRewardPoints = (scoreData['rewardPoints'] as num?)?.toDouble() ?? 0.0;
            _dbPunishmentPoints = (scoreData['punishmentPoints'] as num?)?.toDouble() ?? 0.0;
          });
        }
      } catch (e) {
        debugPrint("DEBUG HOME ERROR: failed to fetch dashboard scores: $e");
      }
    }
  }

  Future<void> _fetchInboxData() async {
    final state = context.read<AuthBloc>().state;
    debugPrint("DEBUG HOME: auth state is ${state.runtimeType}");
    if (state is AuthSuccess) {
      debugPrint("DEBUG HOME: user noSerdik=${state.user.noSerdik}, roleId=${state.user.roleId}");
      if (state.user.roleId.toLowerCase() == 'siswa') {
        try {
          final inboxSource = sl<InboxRemoteDataSource>();
          final items = await inboxSource.getInbox(status: 'all');
          debugPrint("DEBUG HOME: fetched ${items.length} inbox items");
          for (var item in items) {
            debugPrint("DEBUG HOME: item id=${item.id}, isReward=${item.isReward}, status=${item.status}, nosis=${item.nosis}, points=${item.points}");
          }
          if (mounted) {
            setState(() {
              _inboxItems = items;
            });
          }
        } catch (e, stack) {
          debugPrint("DEBUG HOME ERROR: failed to fetch inbox: $e");
          debugPrint("$stack");
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _warningOrange = Color(0xFFF57C00);
  static const Color _dangerRed = Color(0xFFD32F2F);
  static const Color _warningYellow = Color(0xFFFBC02D);

  double _getRewardPoints(UserEntity user) {
    if (_dbRewardPoints != null) return _dbRewardPoints!;
    if (user.roleId.toLowerCase() != 'siswa') return 0.0;
    return _inboxItems
        .where(
          (i) =>
              (i.status == 'disetujui' || i.status == 'approved') &&
              i.isReward &&
              i.nosis == user.noSerdik,
        )
        .fold(0.0, (sum, item) => sum + item.points);
  }

  double _getPunishmentPoints(UserEntity user) {
    if (_dbPunishmentPoints != null) return _dbPunishmentPoints!;
    if (user.roleId.toLowerCase() != 'siswa') return 0.0;
    return _inboxItems
        .where(
          (i) =>
              (i.status == 'disetujui' || i.status == 'approved') &&
              !i.isReward &&
              i.nosis == user.noSerdik,
        )
        .fold(0.0, (sum, item) => sum + item.points);
  }

  String _getDynamicDateStr(DateTime target) {
    const months = [
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
    final monthName = months[target.month - 1];
    final dayStr = target.day.toString().padLeft(2, '0');
    return '$dayStr $monthName ${target.year}';
  }

  String _formatDynamicTime(DateTime target) {
    final hourStr = target.hour.toString().padLeft(2, '0');
    final minStr = target.minute.toString().padLeft(2, '0');
    return '$hourStr.$minStr';
  }

  String _getGadikFullName(String sender) {
    if (sender == 'Gadik A') return 'Kombes Pol. Anton Suratto';
    if (sender == 'Gadik B') return 'Kombes Pol. Budi Santoso';
    if (sender == 'Gadik C') return 'Kombes Pol. Candra Muka';
    if (sender == 'Korsis A') return 'Kombes Pol. Ahmad Setiawan';
    if (sender == 'Patun A') return 'Kombes Pol. Bambang Sugeng';
    return sender;
  }

  List<Map<String, dynamic>> _getMockActivities(UserEntity user) {
    final today = DateTime.now();
    final role = user.roleId.toLowerCase();
    final List<Map<String, dynamic>> list = [];

    if (role == 'siswa') {
      final raw = ScoreCalculatorService.generateSimulatedScores(user.noSerdik);
      final double sosiometriScore = (raw['NS'] as num?)?.toDouble() ?? 0.0;

      if (sosiometriScore > 0) {
        list.add({
          'id': 'act_dyn_sosiometri',
          'title': 'Nilai Sosiometri Telah Keluar',
          'subtitle':
              'Sosiometri berhasil dinilai silahkan cek laporan nilai untuk melihat hasilnya',
          'timeRaw': _formatDynamicTime(today),
          'date': _getDynamicDateStr(today),
          'dateTime': today,
          'points': '',
          'type': 'task',
        });
      }

      for (var inbox in _inboxItems) {
        final bool isDirectOrApproved =
            inbox.status == 'approved' ||
            inbox.status == 'disetujui' ||
            inbox.senderName.toLowerCase().contains('korsis') ||
            inbox.senderName.toLowerCase().contains('sistem');
        if (isDirectOrApproved && inbox.nosis == user.noSerdik) {
          final isReward = inbox.isReward;
          final typeStr = isReward ? 'reward' : 'punishment';
          final pointStr = isReward
              ? '+${inbox.points.toStringAsFixed(2)}'
              : inbox.points.toStringAsFixed(2);
          list.add({
            'id': inbox.id,
            'title': inbox.rewardPunishmentName,
            'subtitle': 'Diberikan oleh ${_getGadikFullName(inbox.senderName)}',
            'timeRaw': _formatDynamicTime(inbox.timestamp),
            'date': _getDynamicDateStr(inbox.timestamp),
            'dateTime': inbox.timestamp,
            'points': pointStr,
            'type': typeStr,
            'photoPath': inbox.photoPath,
          });
        }
      }

      for (var zone in AttendanceZones.activeZones) {
        list.add({
          'id': 'zone_${zone.id}',
          'title': zone.activityName,
          'subtitle':
              '${zone.name} telah dibuat oleh ${_getGadikFullName(zone.creator)}. Segera melakukan presensi.',
          'timeRaw': _formatDynamicTime(zone.createdAt),
          'date': _getDynamicDateStr(zone.createdAt),
          'dateTime': zone.createdAt,
          'points': '',
          'type': 'zone',
        });
      }
    }

    list.sort((a, b) {
      final dtA = a['dateTime'] as DateTime;
      final dtB = b['dateTime'] as DateTime;
      return dtB.compareTo(dtA);
    });

    return list.take(3).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;

            final allRecaps = ScoreCalculatorService.generateRealReports();
            final finalRecap = allRecaps.firstWhere(
              (r) => r.id == user.noSerdik,
              orElse: () => allRecaps.first,
            );

            final double nilaiAkademik = _dbAcademicScore ?? finalRecap.academicScore;
            final double nilaiMental = _dbMentalScore ?? finalRecap.mentalScore;
            final double nilaiJasmani = _dbPhysicalScore ?? finalRecap.physicalScore;

            return SafeArea(
              top: false,
              child: RefreshIndicator(
                color: _primaryNavy,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await Future.wait([
                    _fetchInboxData(),
                    _fetchDashboardData(),
                  ]);
                  if (mounted) setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAnimatedSection(
                            context: context,
                            child: _buildHeader(context, user),
                            beginInterval: 0.0,
                            endInterval: 0.3,
                          ),
                          Transform.translate(
                            offset: const Offset(0, -30),
                            child: Column(
                              children: [
                                _buildAnimatedSection(
                                  context: context,
                                  child: _buildScoreOverview(
                                    context,
                                    user,
                                    nilaiAkademik,
                                    nilaiMental,
                                    nilaiJasmani,
                                  ),
                                  beginInterval: 0.2,
                                  endInterval: 0.5,
                                ),
                                if (SociometryPeriodConfig.isAnyActive()) ...[
                                  const SizedBox(height: AppDimensions.md),
                                  _buildAnimatedSection(
                                    context: context,
                                    child: _buildSosiometriBanner(context),
                                    beginInterval: 0.3,
                                    endInterval: 0.6,
                                  ),
                                ],
                                const SizedBox(height: AppDimensions.md),
                                _buildAnimatedSection(
                                  context: context,
                                  child: _buildAttendanceRecap(context),
                                  beginInterval: 0.4,
                                  endInterval: 0.7,
                                ),
                                const SizedBox(height: AppDimensions.md),
                                _buildAnimatedSection(
                                  context: context,
                                  child: _buildActivityFeed(context, user),
                                  beginInterval: 0.5,
                                  endInterval: 1.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: _primaryNavy),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserEntity user) {
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 16, 24, 60),
      decoration: const BoxDecoration(
        color: _primaryNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.xs - 1),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: _lightGrey,
              backgroundImage: AvatarHelper.getAvatar(user.profilePhoto),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()},',
                  style: TextStyle(
                    color: Colors.blueGrey.shade200,
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    user.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    user.roleId == 'siswa' ? user.noSerdik : 'NRP: ${user.nrp}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              child: ValueListenableBuilder<int>(
                valueListenable: NotificationMockData.unreadCountNotifier,
                builder: (context, unreadCount, child) {
                  return Badge(
                    isLabelVisible: unreadCount > 0,
                    backgroundColor: _dangerRed,
                    label: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: AppDimensions.fontSm,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.sm + 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.bell,
                        color: Colors.white,
                        size: AppDimensions.iconLg,
                      ),
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

  Widget _buildScoreOverview(
    BuildContext context,
    UserEntity user,
    double akademik,
    double mental,
    double jasmani,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Akumulasi Penilaian',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                Icon(AppIcons.chartBarFill, color: Colors.blueGrey.shade300),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AnimatedCircularScore(
                  label: 'Mental Kepribadian',
                  value: mental,
                  delay: 600,
                  size: 88,
                ),
                _AnimatedCircularScore(
                  label: 'Jasmani',
                  value: jasmani,
                  delay: 800,
                  size: 88,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            Row(
              children: [
                Expanded(
                  child: _buildRewardPunishmentCard(
                    context,
                    title: 'Reward',
                    points: _getRewardPoints(user) > 0
                        ? '+${_getRewardPoints(user).toStringAsFixed(2)}'
                        : '0',
                    icon: AppIcons.thumbUp,
                    color: _successGreen,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: _buildRewardPunishmentCard(
                    context,
                    title: 'Punishment',
                    points: _getPunishmentPoints(user) != 0
                        ? _getPunishmentPoints(user).toStringAsFixed(2)
                        : '0',
                    icon: AppIcons.thumbDown,
                    color: _dangerRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.lg),
            _buildAiRecommendation(
              akademik,
              mental,
              jasmani,
              _getRewardPoints(user),
              _getPunishmentPoints(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardPunishmentCard(
    BuildContext context, {
    required String title,
    required String points,
    required IconData icon,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityHistoryScreen(initialFilter: title),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: AppDimensions.iconXl),
              const SizedBox(height: AppDimensions.sm),
              Text(
                points,
                style: TextStyle(
                  fontSize: AppDimensions.fontHuge,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiRecommendation(
    double ak,
    double ment,
    double jas,
    double reward,
    double punishment,
  ) {
    String title = 'Rekomendasi';
    String message = '';
    Color cardColor;
    Color iconColor;
    IconData iconData;

    bool isRed = jas < 70 || ak < 70 || punishment > reward;
    bool isGreen = jas >= 80 && ak >= 80 && punishment == 0;

    if (isRed) {
      cardColor = const Color(0xFFFFF0F0);
      iconColor = const Color(0xFFD32F2F);
      iconData = AppIcons.warningOctagonFill;
      message =
          'Terdapat nilai di bawah standar kelulusan atau akumulasi pelanggaran yang lebih besar dari penghargaan. Segera perbaiki performa Anda.';
    } else if (isGreen) {
      cardColor = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF2E7D32);
      iconData = AppIcons.checkCircleFill;
      message =
          'Luar biasa! Seluruh pilar penilaian Anda seimbang di kategori prima, dan Anda bebas dari pelanggaran. Teruskan performa positif ini.';
    } else {
      cardColor = const Color(0xFFFFFDE7);
      iconColor = const Color(0xFFFBC02D);
      iconData = AppIcons.infoFill;
      message =
          'Perhatian: Pertahankan keseimbangan capaian Anda. Beberapa aspek atau catatan pelanggaran ringan perlu diperbaiki agar aman dari standar minimal kelulusan.';
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: 24),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontSm,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosiometriBanner(BuildContext context) {
    const Color primaryIndigo = Color(0xFF4F46E5);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          await Navigator.pushNamed(context, '/serdik-sosiometri');
          if (mounted) {
            setState(() {});
          }
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.xl - 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryIndigo.withValues(alpha: 0.08),
                primaryIndigo.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(color: primaryIndigo.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.usersThreeFill,
                  color: primaryIndigo,
                  size: AppDimensions.iconLg,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          SociometryPeriodConfig.isAkhirActive()
                              ? 'Sosiometri Akhir Peleton'
                              : 'Sosiometri Awal Peleton',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryIndigo,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSm,
                            ),
                          ),
                          child: const Text(
                            'ISI SEKARANG',
                            style: TextStyle(
                              fontSize: AppDimensions.fontXs,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.radiusSm),
                    Text(
                      'Evaluasi 5 Kompetensi Inti mental kepribadian rekan satu Pokjar Anda secara anonim.',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSm + 1,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.sm),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXs,
                            ),
                            child: LinearProgressIndicator(
                              value:
                                  SociometryPeriodConfig.getFilledCount() /
                                  SociometryPeriodConfig.getTotalCount(),
                              backgroundColor: Colors.black12,
                              color: primaryIndigo,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm + 2),
                        Text(
                          '${SociometryPeriodConfig.getFilledCount()} / ${SociometryPeriodConfig.getTotalCount()} Rekan',
                          style: const TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w800,
                            color: primaryIndigo,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceRecap(BuildContext context) {
    final history = PimpinanMockData.serdikAttendanceHistory;
    final int hadir = history.where((e) => e['type'] == 'hadir').length;
    final int telat = history.where((e) => e['type'] == 'telat').length;
    final int izin = history.where((e) => e['type'] == 'izin').length;
    final int alpha = history.where((e) => e['type'] == 'alpha').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rekapitulasi Kehadiran',
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AttendanceHistoryScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: AppDimensions.fontDefault,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl - 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildAttendanceItem(
                    'Hadir',
                    hadir.toString(),
                    _successGreen,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildAttendanceItem(
                    'Telat',
                    telat.toString(),
                    _warningYellow,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildAttendanceItem(
                    'Izin',
                    izin.toString(),
                    _warningOrange,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: _buildAttendanceItem(
                    'Tanpa Keterangan',
                    alpha.toString(),
                    _dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontHuge + 2,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFeed(BuildContext context, UserEntity user) {
    final mockActivities = _getMockActivities(user);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Aktivitas',
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivityHistoryScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          mockActivities.isEmpty
              ? _buildEmptyActivityState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: mockActivities.length,
                  itemBuilder: (context, index) {
                    final item = mockActivities[index];
                    return _ActivityTile(
                      title: item['title'] as String,
                      subtitle: item['subtitle'] as String,
                      time: item['timeRaw'] as String? ?? '',
                      date: item['date'] as String? ?? '',
                      points: item['points'] as String,
                      type: item['type'] as String,
                      photoPath: item['photoPath'] as String?,
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.xl - 4),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.calendarBlankFill,
              size: AppDimensions.iconHuge,
              color: Colors.blueGrey.shade300,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          const Text(
            'Belum Ada Riwayat Aktivitas',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Seluruh catatan tugas, pujian, dan teguran harian Anda akan otomatis tampil di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection({
    required BuildContext context,
    required Widget child,
    required double beginInterval,
    required double endInterval,
  }) {
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(beginInterval, endInterval, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _AnimatedCircularScore extends StatelessWidget {
  final String label;
  final double value;
  final int delay;
  final double size;

  const _AnimatedCircularScore({
    required this.label,
    required this.value,
    required this.delay,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    Color displayColor;
    if (value >= 80.0) {
      displayColor = const Color(0xFF2E7D32);
    } else if (value >= 70.0) {
      displayColor = const Color(0xFFF57C00);
    } else {
      displayColor = const Color(0xFFD32F2F);
    }

    final double targetValue = value > 0 ? value / 100 : 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: size,
          width: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: animValue,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade100,
                    color: displayColor,
                    strokeCap: StrokeCap.round,
                  ),
                  Center(
                    child: Text(
                      value > 0 ? (animValue * 100).toStringAsFixed(2) : '-',
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        color: displayColor,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade600,
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String date;
  final String points;
  final String type;
  final String? photoPath;

  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.points,
    required this.type,
    this.photoPath,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    switch (type) {
      case 'task':
      case 'task_dikirim':
      case 'task_dinilai':
      case 'task_remedial':
        iconColor = Colors.blue.shade600;
        iconData = AppIcons.clipboardTextFill;
        break;
      case 'reward':
        iconColor = const Color(0xFF2E7D32);
        iconData = AppIcons.thumbUp;
        break;
      case 'punishment':
        iconColor = const Color(0xFFD32F2F);
        iconData = AppIcons.thumbDown;
        break;
      case 'zone':
        iconColor = Colors.teal.shade600;
        iconData = AppIcons.mapPinLineFill;
        break;
      case 'info':
      default:
        iconColor = Colors.amber.shade700;
        iconData = AppIcons.infoFill;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: (type == 'reward' || type == 'punishment')
              ? () {
                  EvidenceBottomSheet.show(
                    context,
                    title: title,
                    description: title,
                    evaluatorName: subtitle,
                    timeText: time,
                    points: points,
                    type: type,
                    photoPath: photoPath,
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: AppDimensions.iconLg,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF001C40),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade400,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs / 2),
                      Row(
                        children: [
                          Icon(
                            AppIcons.calendarBlank,
                            size: AppDimensions.fontSm,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            AppIcons.clock,
                            size: AppDimensions.fontSm,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (points.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      points,
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg + 1,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
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

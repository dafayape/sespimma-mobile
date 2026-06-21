import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/leadership_report/presentation/widgets/ai_recommendation_card.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:dio/dio.dart';
import 'package:sespimma/injection_container.dart';
import 'package:flutter/services.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

import '../../../auth/domain/entities/user_entity.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PimpinanHomeScreen extends StatefulWidget {
  const PimpinanHomeScreen({super.key});

  @override
  State<PimpinanHomeScreen> createState() => _PimpinanHomeScreenState();
}

class _PimpinanHomeScreenState extends State<PimpinanHomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  bool _animateBars = false;

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _academicBlue = Color(0xFF1976D2);
  static const Color _mentalOrange = Color(0xFFF57C00);
  static const Color _physicalGreen = Color(0xFF10B981);
  static const Color _dangerRed = Color(0xFFEF4444);
  static const Color _successGreen = Color(0xFF2E7D32);

  int _totalSerdik = 0;
  int _totalPokjar = 0;
  double _averageAcademic = 0.0;
  double _averageMental = 0.0;
  double _averageJasmani = 0.0;
  List<Map<String, dynamic>> _pokjarDetailData = [];
  bool _isLoading = true;

  Future<void> _fetchPimpinanDashboard() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/leadership/dashboard');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (mounted) {
          setState(() {
            _totalSerdik = (data['total_serdik'] as num?)?.toInt() ?? 0;
            _totalPokjar = (data['total_pokjar'] as num?)?.toInt() ?? 0;
            _averageAcademic = (data['average_academic'] as num?)?.toDouble() ?? 0.0;
            _averageMental = (data['average_mental'] as num?)?.toDouble() ?? 0.0;
            _averageJasmani = (data['average_jasmani'] as num?)?.toDouble() ?? 0.0;
            
            final rawBreakdown = data['pokjar_breakdown'] as List<dynamic>?;
            if (rawBreakdown != null) {
              final list = rawBreakdown.map((item) {
                final m = Map<String, dynamic>.from(item);
                return {
                  'name': m['name'] as String,
                  'averageMental': (m['averageMental'] as num?)?.toDouble() ?? 0.0,
                  'averageJasmani': (m['averageJasmani'] as num?)?.toDouble() ?? 0.0,
                };
              }).toList();
              
              int getPokjarNum(String name) {
                if (name.contains('IV')) return 4;
                if (name.contains('III')) return 3;
                if (name.contains('II')) return 2;
                if (name.contains('V')) return 5;
                if (name.contains('I')) return 1;
                return 0;
              }

              list.sort(
                (a, b) => getPokjarNum(
                  a['name'] as String,
                ).compareTo(getPokjarNum(b['name'] as String)),
              );
              
              _pokjarDetailData = list;
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching pimpinan dashboard: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController?.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPimpinanDashboard();
      if (mounted) {
        setState(() {
          _animateBars = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Widget _buildAnimatedSection({
    required Widget child,
    required double beginInterval,
    required double endInterval,
  }) {
    if (_animController == null) return child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Interval(beginInterval, endInterval, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController!,
                curve: Interval(
                  beginInterval,
                  endInterval,
                  curve: Curves.easeOutQuart,
                ),
              ),
            ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;

            return SafeArea(
              top: false,
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await _fetchPimpinanDashboard();
                },
                color: _primaryNavy,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedSection(
                        child: _buildHeader(context, user),
                        beginInterval: 0.0,
                        endInterval: 0.3,
                      ),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primaryNavy,
                                ),
                              ),
                            )
                          : Transform.translate(
                              offset: const Offset(0, -30),
                              child: Column(
                                children: [
                                  _buildAnimatedSection(
                                    child: _buildGeneralStats(context),
                                    beginInterval: 0.1,
                                    endInterval: 0.4,
                                  ),
                                  const SizedBox(height: AppDimensions.md),
                                  _buildAnimatedSection(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: _buildPieChartSection(),
                                    ),
                                    beginInterval: 0.2,
                                    endInterval: 0.5,
                                  ),
                                  const SizedBox(height: AppDimensions.md),
                                  _buildAnimatedSection(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: _buildBarChartSection(),
                                    ),
                                    beginInterval: 0.3,
                                    endInterval: 0.6,
                                  ),
                                  const SizedBox(height: AppDimensions.md),
                                  _buildAnimatedSection(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: _buildAiRecommendation(),
                                    ),
                                    beginInterval: 0.4,
                                    endInterval: 0.7,
                                  ),
                                  const SizedBox(height: AppDimensions.xl),
                                ],
                              ),
                            ),
                    ],
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
    final name = user.name.split(',').first;
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 16, 24, 60),
      decoration: const BoxDecoration(color: _primaryNavy),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.xs / 2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: _lightGrey,
              backgroundImage:
                  (user.profilePhoto != null && user.profilePhoto!.isNotEmpty)
                  ? FileImage(File(user.profilePhoto!)) as ImageProvider
                  : AvatarHelper.getAvatar(null),
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
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs / 2),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
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
                    user.jabatanSenat.isNotEmpty && user.jabatanSenat != '-'
                        ? user.jabatanSenat.toUpperCase()
                        : 'PENANGGUNG JAWAB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStats(BuildContext context) {
    final double mental = _averageMental;
    final double jasmani = _averageJasmani;
    final int totalSerdik = _totalSerdik;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
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
                  'Ringkasan Eksekutif',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                ),
                Icon(
                  AppIcons.squaresFourFill,
                  color: Colors.blueGrey.shade200,
                  size: AppDimensions.iconMd,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            Column(
              children: [
                _buildColumnStatTile(
                  'Total Serdik',
                  totalSerdik.toString(),
                  AppIcons.usersFill,
                  _academicBlue,
                ),
                const SizedBox(height: 8),
                _buildColumnStatTile(
                  'Total Pokjar',
                  _totalPokjar.toString(),
                  AppIcons.treeStructureFill,
                  _mentalOrange,
                ),

                const SizedBox(height: 8),
                _buildColumnStatTile(
                  'Rata-rata Mental',
                  mental > 0 ? mental.toStringAsFixed(2) : 'BELUM DINILAI',
                  AppIcons.shieldCheckFill,
                  _mentalOrange,
                ),
                const SizedBox(height: 8),
                _buildColumnStatTile(
                  'Rata-rata Jasmani',
                  jasmani > 0 ? jasmani.toStringAsFixed(2) : 'BELUM DINILAI',
                  AppIcons.barbellFill,
                  _physicalGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconDefault),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: value == 'BELUM DINILAI'
                  ? AppDimensions.fontSm
                  : AppDimensions.fontLg,
              fontWeight: FontWeight.w900,
              color: value == 'BELUM DINILAI'
                  ? Colors.blueGrey.shade300
                  : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection() {
    final double akademik = _averageAcademic;
    final double mental = _averageMental;
    final double jasmani = _averageJasmani;

    final double nakScore =
        (akademik * 0.70) + (mental * 0.20) + (jasmani * 0.10);
    final bool hasData = nakScore > 0;
    final bool isStabil = akademik >= 70.0 && mental >= 70.0 && jasmani >= 70.0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                'Komposisi Nilai',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: _primaryNavy,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasData
                      ? (isStabil
                            ? _successGreen.withValues(alpha: 0.1)
                            : _dangerRed.withValues(alpha: 0.1))
                      : Colors.blueGrey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasData
                          ? (isStabil
                                ? AppIcons.trendUpFill
                                : AppIcons.trendDownFill)
                          : AppIcons.minusCircle,
                      size: 10,
                      color: hasData
                          ? (isStabil ? _successGreen : _dangerRed)
                          : Colors.blueGrey,
                    ),
                    const SizedBox(width: AppDimensions.xs),
                    Text(
                      hasData
                          ? (isStabil ? 'Stabil' : 'Tidak Stabil')
                          : 'Belum Dinilai',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: hasData
                            ? (isStabil ? _successGreen : _dangerRed)
                            : Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCenteredLegendItem(
                'Mental Kepribadian',
                hasData ? mental.toStringAsFixed(2) : '0',
                _mentalOrange,
                '20%',
              ),
              _buildCenteredLegendItem(
                'Jasmani',
                hasData ? jasmani.toStringAsFixed(2) : '0',
                _physicalGreen,
                '10%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredLegendItem(
    String label,
    String value,
    Color color,
    String weight,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppDimensions.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    weight,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarChartSection() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              const Expanded(
                child: Text(
                  'Analisis Rata-Rata Nilai Pokjar',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(
                Icons.sort_rounded,
                color: Colors.blueGrey.shade400,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xl),
          ..._pokjarDetailData.map((data) => _buildDetailBarRow(data)),
        ],
      ),
    );
  }

  Widget _buildDetailBarRow(Map<String, dynamic> data) {
    final String name = data['name'];
    final double mental = data['averageMental'];
    final double jasmani = data['averageJasmani'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          _buildSingleBar('Mental', mental, _mentalOrange),
          const SizedBox(height: AppDimensions.xs),
          _buildSingleBar('Jasmani', jasmani, _physicalGreen),
        ],
      ),
    );
  }

  Widget _buildSingleBar(String label, double value, Color baseColor) {
    final bool hasData = value > 0;
    final Color color = hasData ? baseColor : Colors.blueGrey.shade300;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
            child: LinearProgressIndicator(
              value: _animateBars && hasData ? value / 100 : 0,
              backgroundColor: Colors.blueGrey.shade50,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        SizedBox(
          width: 36,
          child: Text(
            hasData ? value.toStringAsFixed(1) : '0',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiRecommendation() {
    final double mental = _averageMental;
    final double jasmani = _averageJasmani;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rekomendasi Sistem',
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          AiRecommendationCard(
            academicScore: 0.0,
            mentalScore: mental,
            physicalScore: jasmani,
            showAcademic: false,
          ),
        ],
      ),
    );
  }
}

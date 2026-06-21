import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/assessment/presentation/pages/korsis_generate_mental_report_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/korsis_mental_form_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/gadik_assessment_screen.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/assessment/data/datasources/inbox_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';

class KorsisMentalMonitoringScreen extends StatefulWidget {
  const KorsisMentalMonitoringScreen({super.key});

  @override
  State<KorsisMentalMonitoringScreen> createState() =>
      _KorsisMentalMonitoringScreenState();
}

class _KorsisMentalMonitoringScreenState
    extends State<KorsisMentalMonitoringScreen> {
  static const Color _primaryNavy = AppColors.primaryNavy;
  static const Color _lightGrey = Color(0xFFF8F9FA);

  String _selectedPokjar = 'Semua Pokjar';
  final List<String> _pokjarOptions = [
    'Semua Pokjar',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  String _selectedAspect = 'Rata-rata';
  final List<String> _aspectOptions = [
    'Rata-rata',
    'Disiplin',
    'Kepemimpinan',
    'Pengendalian Diri',
    'Penampilan',
    'Sosiometri',
  ];

  String _mapRomanToArabic(String roman) {
    switch (roman) {
      case 'POKJAR I':
        return 'POKJAR 1';
      case 'POKJAR II':
        return 'POKJAR 2';
      case 'POKJAR III':
        return 'POKJAR 3';
      case 'POKJAR IV':
        return 'POKJAR 4';
      case 'POKJAR V':
        return 'POKJAR 5';
      default:
        return roman;
    }
  }

  String _mapArabicToRoman(String arabic) {
    switch (arabic) {
      case 'POKJAR 1':
      case 'POKJAR I':
        return 'POKJAR I';
      case 'POKJAR 2':
      case 'POKJAR II':
        return 'POKJAR II';
      case 'POKJAR 3':
      case 'POKJAR III':
        return 'POKJAR III';
      case 'POKJAR 4':
      case 'POKJAR IV':
        return 'POKJAR IV';
      case 'POKJAR 5':
      case 'POKJAR V':
        return 'POKJAR V';
      default:
        return arabic;
    }
  }

  bool _isLoading = false;
  List<Map<String, dynamic>> _allSerdikScores = [];
  List<InboxItem> _inboxItems = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final assessmentSource = sl<AssessmentRemoteDataSource>();
      final inboxSource = sl<InboxRemoteDataSource>();

      final scores = await assessmentSource.getAllMentalScores();
      final inbox = await inboxSource.getInbox(status: 'all');

      if (mounted) {
        setState(() {
          _allSerdikScores = scores;
          _inboxItems = inbox;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal sinkronisasi data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getProcessedSerdik() {
    List<Map<String, dynamic>> allSerdik = [];

    final inboxItemsForAspects = _inboxItems.where((item) {
      final bool isDirectOrApproved =
          item.status == 'approved' ||
          item.status == 'disetujui' ||
          item.senderName.toLowerCase().contains('korsis') ||
          item.senderName.toLowerCase().contains('sistem');
      return isDirectOrApproved && !item.isIzin;
    }).toList();

    for (var original in _allSerdikScores) {
      if (_selectedPokjar != 'Semua Pokjar') {
        final targetPokjar = _mapRomanToArabic(_selectedPokjar);
        final pokjarVal = (original['kelompok_kelas'] ?? original['pokjar'] ?? '').toString();
        if (pokjarVal != targetPokjar) continue;
      }

      final Map<String, dynamic> serdik = Map<String, dynamic>.from(original);
      final String noSerdik = (serdik['no_serdik'] ?? serdik['nip'] ?? '').toString();

      double moral = (serdik['moral'] as num?)?.toDouble() ?? 80.0;
      double disiplin = (serdik['disiplin'] as num?)?.toDouble() ?? 80.0;
      double kepemimpinan = (serdik['kepemimpinan'] as num?)?.toDouble() ?? 80.0;
      double pengendalianDiri = (serdik['pengendalian_diri'] as num?)?.toDouble() ?? 80.0;
      double penampilan = (serdik['penampilan'] as num?)?.toDouble() ?? 80.0;
      double sosiometriAwal = (serdik['sosiometri_awal'] as num?)?.toDouble() ?? 0.0;
      double sosiometriAkhir = (serdik['sosiometri_akhir'] as num?)?.toDouble() ?? 0.0;

      double dynamicReward = 0.0;
      double dynamicPunishment = 0.0;
      bool hasAppliedAspect = false;

      for (var item in inboxItemsForAspects) {
        if (item.nosis == noSerdik) {
          bool appliedToAspect = false;

          if (item.rewardPunishmentId != null) {
            try {
              final rule = RewardPunishmentData.rules.firstWhere(
                (r) => r.id == item.rewardPunishmentId || r.description.trim().toLowerCase() == item.rewardPunishmentName.trim().toLowerCase(),
              );

              final double pointValue = item.isReward
                  ? item.points
                  : -item.points.abs();

              switch (rule.aspect.toUpperCase()) {
                case 'MORAL':
                  moral += pointValue;
                  appliedToAspect = true;
                  hasAppliedAspect = true;
                  break;
                case 'DISIPLIN':
                  disiplin += pointValue;
                  appliedToAspect = true;
                  hasAppliedAspect = true;
                  break;
                case 'KEPEMIMPINAN':
                  kepemimpinan += pointValue;
                  appliedToAspect = true;
                  hasAppliedAspect = true;
                  break;
                case 'PENGENDALIAN DIRI':
                  pengendalianDiri += pointValue;
                  appliedToAspect = true;
                  hasAppliedAspect = true;
                  break;
                case 'PENAMPILAN':
                  penampilan += pointValue;
                  appliedToAspect = true;
                  hasAppliedAspect = true;
                  break;
              }
            } catch (e) {
              appliedToAspect = false;
            }
          }

          if (!appliedToAspect) {
            if (item.isReward) {
              dynamicReward += item.points;
            } else {
              dynamicPunishment += item.points.abs();
            }
          }
        }
      }

      double ns = 0.0;
      if (serdik['sosiometri'] != null) {
        ns = (serdik['sosiometri'] as num).toDouble();
      } else if (sosiometriAwal > 0 || sosiometriAkhir > 0) {
        ns = (sosiometriAwal + sosiometriAkhir) / 2;
      }

      double nk = 0.0;
      if (moral > 0 || disiplin > 0 || kepemimpinan > 0 || pengendalianDiri > 0 || penampilan > 0 || ns > 0) {
        nk = ((moral * 20) +
            (disiplin * 15) +
            (kepemimpinan * 20) +
            (pengendalianDiri * 15) +
            (penampilan * 15) +
            (ns * 15)) / 100;
        nk = nk + dynamicReward - dynamicPunishment;
      }

      bool isGraded = serdik['is_graded'] as bool? ?? false;
      if (dynamicReward > 0 || dynamicPunishment > 0 || hasAppliedAspect) {
        isGraded = true;
      }

      serdik['moral'] = isGraded ? moral : 0.0;
      serdik['disiplin'] = isGraded ? disiplin : 0.0;
      serdik['kepemimpinan'] = isGraded ? kepemimpinan : 0.0;
      serdik['pengendalian_diri'] = isGraded ? pengendalianDiri : 0.0;
      serdik['penampilan'] = isGraded ? penampilan : 0.0;
      serdik['sosiometri'] = isGraded ? ns : 0.0;
      serdik['nilai'] = isGraded ? nk : 0.0;

      allSerdik.add(serdik);
    }
    return allSerdik;
  }

  Color _getScoreColor(double s) {
    if (s == 0) return Colors.blueGrey.shade800;
    if (s > 85.00) return Colors.green.shade800;
    if (s > 80.00) return Colors.green.shade500;
    if (s > 75.00) return Colors.lime.shade700;
    if (s > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
  }

  String _getPredicate(double s) {
    if (s == 0) return '-';
    if (s > 85.00) return 'Sangat Memuaskan (SM)';
    if (s > 80.00) return 'Memuaskan (M)';
    if (s > 75.00) return 'Baik (B)';
    if (s > 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  void _showInputBottomSheet(BuildContext parentContext) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _InputTypeSheet(
        onReward: () async {
          Navigator.pop(modalContext);
          await Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => const KorsisMentalFormScreen(isReward: true),
            ),
          );
          if (mounted) setState(() {});
        },
        onPunishment: () async {
          Navigator.pop(modalContext);
          await Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => const KorsisMentalFormScreen(isReward: false),
            ),
          );
          if (mounted) setState(() {});
        },
        onNumeric: () async {
          Navigator.pop(modalContext);
          await Navigator.push(
            parentContext,
            MaterialPageRoute(
              builder: (_) => const GadikAssessmentScreen(
                categoryOverride: 'Mental Kepribadian',
              ),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Mental',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_rounded, color: Colors.white),
            tooltip: 'Generate Laporan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const KorsisGenerateMentalReportScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showInputBottomSheet(context),
        backgroundColor: _primaryNavy,
        elevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
        label: const Text(
          'Input Nilai',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontMd,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: _primaryNavy,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: _primaryNavy,
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.xl,
                    vertical: AppDimensions.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNilaiMentalSection(),
                      const SizedBox(height: AppDimensions.xxl),
                      _buildProgressSerdikSection(),
                      const SizedBox(height: AppDimensions.xxl),
                      _buildRankingSerdikSection(),
                      const SizedBox(height: AppDimensions.xxl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNilaiMentalSection() {
    final serdikList = _getProcessedSerdik();
    double getAvg(String key) {
      final gradedList = serdikList.where((s) => s['is_graded'] as bool? ?? false).toList();
      if (gradedList.isEmpty) return 0.0;
      double sum = 0;
      for (var s in gradedList) {
        sum += (s[key] as double);
      }
      return sum / gradedList.length;
    }

    final avgNilai = getAvg('nilai');
    final avgDisiplin = getAvg('disiplin');
    final avgKepemimpinan = getAvg('kepemimpinan');
    final avgKendali = getAvg('pengendalian_diri');
    final avgPenampilan = getAvg('penampilan');
    final avgSosio = getAvg('sosiometri');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  'NILAI MENTAL KEPRIBADIAN',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            StatusFilterButtonWidget(
              selectedStatus: _selectedPokjar,
              statuses: _pokjarOptions,
              onSelected: (value) {
                setState(() {
                  _selectedPokjar = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Rata-rata',
                      avgNilai,
                      AppIcons.chartBarFill,
                      Colors.blue.shade700,
                      Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildMetricItem(
                      'Disiplin',
                      avgDisiplin,
                      AppIcons.timerFill,
                      Colors.green.shade700,
                      Colors.green.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Kepemimpinan',
                      avgKepemimpinan,
                      Icons.emoji_events_rounded,
                      Colors.orange.shade700,
                      Colors.orange.shade50,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildMetricItem(
                      'Pengendalian Diri',
                      avgKendali,
                      AppIcons.shieldCheckFill,
                      Colors.red.shade700,
                      Colors.red.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Penampilan',
                      avgPenampilan,
                      Icons.checkroom_rounded,
                      Colors.purple.shade700,
                      Colors.purple.shade50,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: _buildMetricItem(
                      'Sosiometri',
                      avgSosio,
                      AppIcons.usersThreeFill,
                      Colors.teal.shade700,
                      Colors.teal.shade50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    double value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final displayColor = value == 0 ? Colors.blueGrey.shade600 : color;
    final displayBgColor = value == 0 ? Colors.blueGrey.shade50 : bgColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: displayBgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: displayColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: displayColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontSize: AppDimensions.fontXxl,
              fontWeight: FontWeight.w900,
              color: displayColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontXs,
              fontWeight: FontWeight.w700,
              color: displayColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSerdikSection() {
    final serdikList = _getProcessedSerdik();
    final serdikNosisSet = serdikList
        .map((s) => s['no_serdik'].toString())
        .toSet();

    List<double> rewardSums = [0, 0, 0, 0];
    List<double> punishSums = [0, 0, 0, 0];

    for (var item in _inboxItems) {
      if ((item.status == 'approved' ||
              item.status == 'disetujui' ||
              item.senderName.toLowerCase().contains('korsis') ||
              item.senderName.toLowerCase().contains('sistem')) &&
          serdikNosisSet.contains(item.nosis) &&
          !item.isIzin) {
        int week = ((item.timestamp.day - 1) ~/ 7).clamp(0, 3);
        if (item.isReward) {
          rewardSums[week] += item.points;
        } else {
          punishSums[week] += item.points.abs();
        }
      }
    }

    double maxVal = 0;
    for (int i = 0; i < 4; i++) {
      if (rewardSums[i] > maxVal) maxVal = rewardSums[i];
      if (punishSums[i] > maxVal) maxVal = punishSums[i];
    }
    double maxY = maxVal > 5 ? maxVal + (maxVal * 0.2) : 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              'PROGRESS SERDIK',
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        Container(
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Reward', Colors.green),
                  const SizedBox(width: AppDimensions.xl),
                  _buildLegendItem('Punishment', Colors.red),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.white,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              touchedSpot.y.toStringAsFixed(2),
                              TextStyle(
                                color: touchedSpot.bar.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 10,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                'Mg ${value.toInt()}',
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 10,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.blueGrey.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: 4,
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(1, rewardSums[0]),
                          FlSpot(2, rewardSums[1]),
                          FlSpot(3, rewardSums[2]),
                          FlSpot(4, rewardSums[3]),
                        ],
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                      LineChartBarData(
                        spots: [
                          FlSpot(1, punishSums[0]),
                          FlSpot(2, punishSums[1]),
                          FlSpot(3, punishSums[2]),
                          FlSpot(4, punishSums[3]),
                        ],
                        isCurved: true,
                        color: Colors.red,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.red.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              _buildRecommendationCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.blueGrey.shade600,
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard() {
    final currentMonth = DateFormat('MMMM', 'id_ID').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.sparkleFill,
              color: Colors.green.shade700,
              size: AppDimensions.iconSm,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi Tindakan Korsis',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  'Grafik pada bulan $currentMonth menunjukkan peningkatan Reward yang signifikan pada minggu ke-4 dan pergerakan Punishment yang fluktuatif. Pertahankan pola kedisiplinan dan lanjutkan program motivasi Serdik.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: AppDimensions.fontXs + 2,
                    fontWeight: FontWeight.w500,
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

  Widget _buildRankingSerdikSection() {
    final allSerdik = _getProcessedSerdik();
    String sortKey = 'nilai';
    switch (_selectedAspect) {
      case 'Disiplin':
        sortKey = 'disiplin';
        break;
      case 'Kepemimpinan':
        sortKey = 'kepemimpinan';
        break;
      case 'Pengendalian Diri':
        sortKey = 'pengendalian_diri';
        break;
      case 'Penampilan':
        sortKey = 'penampilan';
        break;
      case 'Sosiometri':
        sortKey = 'sosiometri';
        break;
    }

    final gradedSerdik = allSerdik.where((s) => s['is_graded'] as bool? ?? false).toList();
    gradedSerdik.sort(
      (a, b) => (b[sortKey] as double).compareTo(a[sortKey] as double),
    );
    final top5 = gradedSerdik.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                  'RANKING SERDIK',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            StatusFilterButtonWidget(
              selectedStatus: _selectedAspect,
              statuses: _aspectOptions,
              onSelected: (value) {
                setState(() {
                  _selectedAspect = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.md),
        if (top5.isEmpty)
          const Center(child: Text('Tidak ada data'))
        else
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final serdik = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.md),
              child: _buildRankCard(
                serdik,
                index + 1,
                serdik[sortKey] as double,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRankCard(Map<String, dynamic> serdik, int rank, double score) {
    final name = (serdik['nama_lengkap'] ?? '-').toString();
    final noSerdik = (serdik['no_serdik'] ?? '-').toString();
    final pangkat = (serdik['pangkat'] ?? '-').toString();
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    Color rankBgColor;
    Color rankTextColor;
    if (rank == 1) {
      rankBgColor = Colors.amber.shade100;
      rankTextColor = Colors.amber.shade900;
    } else if (rank == 2) {
      rankBgColor = Colors.grey.shade300;
      rankTextColor = Colors.grey.shade800;
    } else if (rank == 3) {
      rankBgColor = Colors.brown.shade100;
      rankTextColor = Colors.brown.shade800;
    } else {
      rankBgColor = Colors.blueGrey.shade50;
      rankTextColor = Colors.blueGrey.shade600;
    }

    final scoreColor = _getScoreColor(score);
    final predicate = _getPredicate(score);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rankBgColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankTextColor,
                  fontWeight: FontWeight.w900,
                  fontSize: AppDimensions.fontMd,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Container(
              width: AppDimensions.avatarLg - 10,
              height: AppDimensions.avatarLg - 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
                image: DecorationImage(
                  image: (profilePhoto != null && profilePhoto.isNotEmpty)
                      ? FileImage(File(profilePhoto)) as ImageProvider
                      : AvatarHelper.getAvatar(null),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    '$pangkat · $noSerdik',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      _mapArabicToRoman(
                        serdik['kelompok_kelas']?.toString() ?? '-',
                      ),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    predicate,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NILAI',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTypeSheet extends StatelessWidget {
  final VoidCallback onReward;
  final VoidCallback onPunishment;
  final VoidCallback onNumeric;

  const _InputTypeSheet({
    required this.onReward,
    required this.onPunishment,
    required this.onNumeric,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.handleWidth,
                  height: AppDimensions.bottomSheetHandle,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Input Nilai Mental',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000B1D),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Pilih jenis penilaian yang akan diinput',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
              Row(
                children: [
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Reward',
                      subtitle: 'Pujian / Positif',
                      icon: Icons.thumb_up_rounded,
                      color: const Color(0xFF1B5E20),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: onReward,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.lg),
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Punishment',
                      subtitle: 'Teguran / Negatif',
                      icon: Icons.thumb_down_rounded,
                      color: const Color(0xFFC62828),
                      bgColor: const Color(0xFFFFEBEE),
                      onTap: onPunishment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SheetOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.xl,
            horizontal: AppDimensions.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconXl),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

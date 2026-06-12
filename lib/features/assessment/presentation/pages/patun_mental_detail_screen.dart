import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/assessment/data/models/serdik_mental_scores.dart';
import 'package:sespimma/features/assessment/presentation/pages/patun_mental_activity_history_screen.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sespimma/shared/widgets/evidence_bottom_sheet.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunMentalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> serdik;

  const PatunMentalDetailScreen({super.key, required this.serdik});

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  List<Map<String, dynamic>> _getDynamicActivities() {
    final String noSerdik = (serdik['no_serdik'] as String?) ?? '-';

    final approvedItems = KorsisInboxMockData.items
        .where(
          (item) =>
              (item.status == 'Setuju' || item.status == 'approved') &&
              item.nosis == noSerdik,
        )
        .toList();

    approvedItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    String dateStr(DateTime dt) {
      const m = [
        'Januari',
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
      final dayStr = dt.day.toString().padLeft(2, '0');
      return '$dayStr ${m[dt.month]} ${dt.year}';
    }

    return approvedItems.map((item) {
      return {
        'title': item.rewardPunishmentName,
        'desc': 'Diberikan oleh ${item.senderName}',
        'justification': item.description,
        'sender': item.senderName,
        'time': fmt(item.timestamp),
        'dateStr': dateStr(item.timestamp),
        'dateTime': item.timestamp,
        'isReward': item.isReward,
        'point': item.points,
        'photoPath': item.photoPath,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String name = (serdik['nama_lengkap'] as String?) ?? '-';
    final String noSerdik = (serdik['no_serdik'] as String?) ?? '-';
    final String pangkat = (serdik['pangkat'] as String?) ?? '-';
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    final double baseScore = SerdikMentalScores.getNilai(
      noSerdik,
      (serdik['_mock_score'] as num?)?.toDouble() ?? 80.0,
    );

    final dynamicActivities = _getDynamicActivities();
    double totalDynamicPoints = 0.0;
    for (var act in dynamicActivities) {
      totalDynamicPoints += (act['point'] as num).toDouble();
    }

    final double score = (baseScore + totalDynamicPoints).clamp(0.0, 100.0);

    final String status;
    if (score >= 80.0) {
      status = 'Aman';
    } else if (score >= 70.0) {
      status = 'Warning';
    } else {
      status = 'Kritis';
    }

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Keterangan Mental',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(
                    name,
                    pangkat,
                    noSerdik,
                    status,
                    score,
                    profilePhoto,
                  ),
                  _buildMentalTrendChart(),
                  _buildActivityHistory(context),
                  _buildMentalScores(noSerdik, score, status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String pangkat,
    String noSerdik,
    String status,
    double score,
    String? profilePhoto,
  ) {
    final Color statusColor;
    final IconData statusIcon;
    final String? senatRole = serdik['jabatan_senat'] as String?;
    if (status == 'Aman') {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Warning') {
      statusColor = const Color(0xFFF57C00);
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = const Color(0xFFD32F2F);
      statusIcon = Icons.error_rounded;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _lightGrey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 2),
              image: DecorationImage(
                image: (profilePhoto != null && profilePhoto.isNotEmpty)
                    ? FileImage(File(profilePhoto)) as ImageProvider
                    : AvatarHelper.getAvatar(null),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  '$pangkat · $noSerdik',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontSize: AppDimensions.fontXs,
                              fontWeight: FontWeight.w800,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (senatRole != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1A237E,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF1A237E,
                            ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 10,
                              color: Color(0xFF1A237E),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              senatRole,
                              style: const TextStyle(
                                fontSize: AppDimensions.fontXs,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A237E),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: statusColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NILAI',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXs,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  score > 0 ? score.toStringAsFixed(2) : '-',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentalTrendChart() {
    final double score = (serdik['_mock_score'] as num?)?.toDouble() ?? 80.0;

    List<FlSpot> chartSpots;

    if (score < 70) {
      chartSpots = [
        FlSpot(0, score + 8),
        FlSpot(1, score + 5),
        FlSpot(2, score + 2),
        FlSpot(3, score),
      ];
    } else if (score < 80) {
      chartSpots = [
        FlSpot(0, score),
        FlSpot(1, score),
        FlSpot(2, score),
        FlSpot(3, score),
      ];
    } else {
      chartSpots = [
        FlSpot(0, score - 6),
        FlSpot(1, score - 3),
        FlSpot(2, score - 1),
        FlSpot(3, score),
      ];
    }

    final dynamicTitles = ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.lg,
        AppDimensions.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                'TREN PERKEMBANGAN MENTAL',
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
            padding: const EdgeInsets.all(AppDimensions.xl),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minY: 60,
                      maxY: 100,
                      minX: 0,
                      maxX: 3,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => _primaryNavy,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              return LineTooltipItem(
                                touchedSpot.y.toStringAsFixed(2),
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
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
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 10,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.blueGrey.shade400,
                                  fontSize: AppDimensions.fontXs,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < dynamicTitles.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    dynamicTitles[value.toInt()],
                                    style: TextStyle(
                                      color: Colors.blueGrey.shade600,
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 70,
                            color: Colors.red.shade400,
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(
                                right: 5,
                                bottom: 5,
                              ),
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                              labelResolver: (line) => 'AMM (70)',
                            ),
                          ),
                        ],
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartSpots,
                          isCurved: true,
                          color: _primaryNavy,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: _primaryNavy,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _primaryNavy.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
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

  Widget _buildActivityHistory(BuildContext context) {
    final activities = _getDynamicActivities();
    final displayList = activities.take(2).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.lg,
        AppDimensions.lg,
        AppDimensions.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    'RIWAYAT AKTIVITAS',
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (activities.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatunMentalActivityHistoryScreen(
                          initialActivities: activities,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: AppDimensions.xs,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          if (displayList.isEmpty)
            _buildEmptyActivity()
          else
            ...displayList.map(
              (act) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.md),
                child: _buildActivityCard(
                  context,
                  (act['title'] as String?) ?? 'Aktivitas Mental',
                  (act['desc'] as String?) ?? '-',
                  (act['justification'] as String?) ?? '-',
                  (act['sender'] as String?) ?? '-',
                  (act['time'] as String?) ?? '-',
                  (act['isReward'] as bool?) ?? true,
                  (act['point'] as num?)?.toDouble() ?? 0.0,
                  act['photoPath'] as String?,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: AppDimensions.sm),
          Text(
            'Belum ada riwayat aktivitas',
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    String title,
    String desc,
    String justification,
    String sender,
    String time,
    bool isReward,
    double point,
    String? photoPath,
  ) {
    final iconColor = isReward
        ? const Color(0xFF1B5E20)
        : const Color(0xFFB71C1C);
    final bgColor = isReward
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final iconData = isReward ? AppIcons.thumbUp : AppIcons.thumbDown;
    final pointsStr = point > 0
        ? '+${point.toStringAsFixed(2)}'
        : point.toStringAsFixed(2);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: bgColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          onTap: () {
            EvidenceBottomSheet.show(
              context,
              title: title,
              description: justification,
              evaluatorName: sender,
              timeText: time,
              points: pointsStr,
              type: isReward ? 'reward' : 'punishment',
              photoPath: photoPath,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: bgColor,
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
                          color: _primaryNavy,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Diberikan oleh $sender',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            AppIcons.clock,
                            size: 14,
                            color: Colors.blueGrey.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              color: Colors.blueGrey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    pointsStr,
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w900,
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

  Widget _buildMentalScores(String noSerdik, double baseScore, String status) {
    final scores = SerdikMentalScores.getScores(noSerdik);

    double moralPoints = 0.0;
    double disiplinPoints = 0.0;
    double kepemimpinanPoints = 0.0;
    double pdPoints = 0.0;
    double penampilanPoints = 0.0;

    final approvedItems = KorsisInboxMockData.items.where(
      (item) =>
          (item.status == 'Setuju' || item.status == 'approved') &&
          item.nosis == noSerdik,
    );

    for (var item in approvedItems) {
      if (item.rewardPunishmentId != null) {
        final rules = RewardPunishmentData.rules.where(
          (r) => r.id == item.rewardPunishmentId,
        );
        if (rules.isNotEmpty) {
          final aspect = rules.first.aspect;
          switch (aspect) {
            case 'MORAL':
              moralPoints += item.points;
              break;
            case 'DISIPLIN':
              disiplinPoints += item.points;
              break;
            case 'KEPEMIMPINAN':
              kepemimpinanPoints += item.points;
              break;
            case 'PENGENDALIAN DIRI':
              pdPoints += item.points;
              break;
            case 'PENAMPILAN':
              penampilanPoints += item.points;
              break;
          }
        }
      }
    }

    final double moral = ((scores['moral'] as num).toDouble() + moralPoints)
        .clamp(0, 100);
    final double disiplin =
        ((scores['disiplin'] as num).toDouble() + disiplinPoints).clamp(0, 100);
    final double kepemimpinan =
        ((scores['kepemimpinan'] as num).toDouble() + kepemimpinanPoints).clamp(
          0,
          100,
        );
    final double pengendalianDiri =
        ((scores['pengendalian_diri'] as num).toDouble() + pdPoints).clamp(
          0,
          100,
        );
    final double penampilan =
        ((scores['penampilan'] as num).toDouble() + penampilanPoints).clamp(
          0,
          100,
        );
    final double sosiometriAwal = (scores['sosiometri_awal'] as num).toDouble();
    final double sosiometriAkhir = (scores['sosiometri_akhir'] as num)
        .toDouble();
    final double sosiometri = (sosiometriAwal + sosiometriAkhir) / 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        0,
        AppDimensions.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppDimensions.md,
              top: AppDimensions.xs,
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
                const Expanded(
                  child: Text(
                    'SELURUH NILAI MENTAL KEPRIBADIAN',
                    style: TextStyle(
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildScoreGroup('Moral', '20%', moral, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Disiplin', '15%', disiplin, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Kepemimpinan', '20%', kepemimpinan, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Pengendalian Diri', '15%', pengendalianDiri, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Penampilan', '15%', penampilan, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Sosiometri', '15%', sosiometri, [
            _buildSubScoreItem('Sosiometri Awal', sosiometriAwal),
            _buildSubScoreItem('Sosiometri Akhir', sosiometriAkhir),
          ]),
          const SizedBox(height: AppDimensions.lg),
          _buildRecommendationCard(baseScore, status),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  Widget _buildScoreGroup(
    String title,
    String weight,
    double score,
    List<Widget> children,
  ) {
    final scoreColor = _getScoreColor(score);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: _primaryNavy.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                if (weight.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      weight,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontXs,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    score > 0 ? score.toStringAsFixed(2) : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.md,
                AppDimensions.sm,
                AppDimensions.md,
                AppDimensions.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubScoreItem(String title, double score) {
    final scoreColor = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.xs,
        left: AppDimensions.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 5, color: Colors.blueGrey.shade400),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              score > 0 ? score.toStringAsFixed(2) : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontXs + 1,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(double score, String status) {
    final isWarning = status == 'Warning';
    final isKritis = status == 'Kritis';
    final isAman = status == 'Aman';
    final isExcellent = score >= 85.0;

    final String insight;
    if (isKritis) {
      insight =
          'Sistem mendeteksi adanya pelanggaran disiplin berat atau akumulasi penilaian yang sangat kurang. Segera lakukan sidang atau tindakan pembinaan khusus.';
    } else if (isWarning) {
      insight =
          'Sistem mendeteksi adanya indikator kedisiplinan dan pengendalian diri yang perlu diperhatikan. Mohon segera berkonsultasi secara intensif dengan Pengasuh/Patun.';
    } else if (isExcellent) {
      insight =
          'Karakter dan kepemimpinan Serdik dinilai sangat inspiratif oleh rekan se-Pokjar (Sosiometri tinggi). Serdik adalah role model yang baik dalam aspek Mental Kepribadian.';
    } else {
      insight =
          'Aspek Mental Kepribadian Serdik masuk kategori baik. Terus tingkatkan inisiatif dan interaksi positif (Sosiometri) dengan rekan sejawat agar penilaian karakter semakin optimal.';
    }

    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color iconBgColor;
    Color titleColor;

    if (isAman) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade100;
      iconColor = Colors.green.shade700;
      iconBgColor = Colors.green.shade100;
      titleColor = Colors.green.shade900;
    } else if (isWarning) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade100;
      iconColor = Colors.orange.shade700;
      iconBgColor = Colors.orange.shade100;
      titleColor = Colors.orange.shade900;
    } else {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade100;
      iconColor = Colors.red.shade700;
      iconBgColor = Colors.red.shade100;
      titleColor = Colors.red.shade900;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.sparkleFill,
              color: iconColor,
              size: AppDimensions.iconSm,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi Karakter',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  insight,
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

  Color _getScoreColor(double s) {
    if (s == 0) return Colors.blueGrey.shade800;
    if (s > 85.00) return Colors.green.shade800;
    if (s > 80.00) return Colors.green.shade500;
    if (s > 75.00) return Colors.lime.shade700;
    if (s > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class ScoreLineChart extends StatelessWidget {
  final double nilaiAkademik;
  final double nilaiMental;
  final double nilaiJasmani;
  final String selectedCategory;
  final String noSerdik;

  const ScoreLineChart({
    super.key,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    required this.selectedCategory,
    required this.noSerdik,
  });

  @override
  Widget build(BuildContext context) {
    const colorAka = Color(0xFF001C40);
    const colorMen = Color(0xFF10B981);
    const colorJas = Color(0xFFF59E0B);

    final bool hasWarning =
        (nilaiAkademik > 0 && nilaiAkademik < 70.0) ||
        (nilaiMental > 0 && nilaiMental < 70.0) ||
        (nilaiJasmani > 0 && nilaiJasmani < 70.0);

    final List<FlSpot> spotsMen = _generateSpots(
      nilaiMental,
      'Mental Kepribadian',
    );
    final List<FlSpot> spotsJas = _generateSpots(nilaiJasmani, 'Jasmani');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: AppDimensions.radiusXl,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(hasWarning, colorAka),
          const SizedBox(height: AppDimensions.xxl),
          SizedBox(
            height: 200,
            child: _buildChart(spotsMen, spotsJas, colorMen, colorJas),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool hasWarning, Color colorAka) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.sm + 2),
          decoration: BoxDecoration(
            color: hasWarning ? Colors.red.shade50 : Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Icon(
            hasWarning ? AppIcons.warningOctagonFill : AppIcons.sparkleFill,
            size: AppDimensions.iconSm,
            color: hasWarning ? Colors.red.shade600 : colorAka,
          ),
        ),
        const SizedBox(width: AppDimensions.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasWarning
                    ? 'Peringatan Tren Menurun'
                    : 'Analisis Tren Perkembangan',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd,
                  fontWeight: FontWeight.w800,
                  color: hasWarning ? Colors.red.shade900 : colorAka,
                ),
              ),
              const SizedBox(height: AppDimensions.xs / 2),
              Text(
                'Grafik Perkembangan Mg 1 - Mg 4',
                style: TextStyle(
                  fontSize: AppDimensions.fontXs + 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LineChart _buildChart(
    List<FlSpot> sMen,
    List<FlSpot> sJas,
    Color cMen,
    Color cJas,
  ) {
    Color dynMen = _getScoreColor(nilaiMental, cMen);
    Color dynJas = _getScoreColor(nilaiJasmani, cJas);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade100,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 70.0,
              color: Colors.red.withValues(alpha: 0.35),
              strokeWidth: 1.5,
              dashArray: [6, 6],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                labelResolver: (_) => 'EWS (70)',
              ),
            ),
          ],
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                const style = TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontSm,
                );
                String text = '';
                if (value == 0.0) text = 'Mg 1';
                if (value == 1.0) text = 'Mg 2';
                if (value == 2.0) text = 'Mg 3';
                if (value == 3.0) text = 'Mg 4';
                if (text.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(text, style: style),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 20,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontSm,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: -0.1,
        maxX: 3.1,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          _buildLineBar(sMen, dynMen, 'Mental Kepribadian'),
          _buildLineBar(sJas, dynJas, 'Jasmani'),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF001C40),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_resolveLabel(spot.barIndex)} - ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontSm,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _resolveLabel(int barIndex) {
    if (barIndex == 0) return 'Mental';
    return 'Jasmani';
  }

  Color _getScoreColor(double score, Color defaultColor) {
    if (score == 0) return defaultColor;
    if (score >= 80.0) return Colors.green.shade700;
    if (score >= 70.0) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  LineChartBarData _buildLineBar(List<FlSpot> spots, Color color, String cat) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color.withValues(alpha: selectedCategory == cat ? 1.0 : 0.35),
      barWidth: selectedCategory == cat ? 4.0 : 2.2,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: selectedCategory == cat,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.white,
          strokeWidth: 2.5,
          strokeColor: spot.y == 0.0 ? Colors.red.shade700 : color,
        ),
      ),
    );
  }

  int _currentWeekIndex() {
    int day = DateTime.now().day;
    if (day <= 7) return 0;
    if (day <= 14) return 1;
    if (day <= 21) return 2;
    return 3;
  }

  List<FlSpot> _generateSpots(double finalScore, String cat) {
    int limit = _currentWeekIndex();
    int startIndex = 1;

    List<FlSpot> result = [];
    if (limit >= startIndex) {
      for (int i = startIndex; i <= limit; i++) {
        if (finalScore == 0) {
          result.add(FlSpot(i.toDouble(), 0));
        } else {
          result.add(FlSpot(i.toDouble(), finalScore));
        }
      }
    } else {
      result.add(FlSpot(startIndex.toDouble(), 0));
    }

    return result;
  }
}

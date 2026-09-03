import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

class NakHeroCard extends StatelessWidget {
  final double nakScore;
  final double academicScore;
  final double mentalScore;
  final double physicalScore;

  const NakHeroCard({
    super.key,
    required this.nakScore,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
  });

  String get _predikatLabel {
    if (nakScore >= 85.0) return 'Sangat Memuaskan';
    if (nakScore >= 80.0) return 'Memuaskan';
    if (nakScore >= 75.0) return 'Baik';
    if (nakScore >= 70.0) return 'Cukup';
    if (nakScore > 0) return 'Kurang';
    return '-';
  }

  Color get _predikatBgColor {
    if (nakScore >= 85.0) return const Color(0xFF065F46).withValues(alpha: 0.35); // Emerald Green
    if (nakScore >= 80.0) return const Color(0xFF15803D).withValues(alpha: 0.30); // Green (Memuaskan)
    if (nakScore >= 75.0) return const Color(0xFF1D4ED8).withValues(alpha: 0.30); // Blue (Baik)
    if (nakScore >= 70.0) return const Color(0xFFB45309).withValues(alpha: 0.30); // Amber (Cukup)
    if (nakScore > 0) return const Color(0xFFB91C1C).withValues(alpha: 0.30); // Red (Kurang)
    return Colors.white.withValues(alpha: 0.08);
  }

  Color get _predikatTextColor {
    if (nakScore >= 85.0) return const Color(0xFF34D399); // Emerald
    if (nakScore >= 80.0) return const Color(0xFF4ADE80); // Green
    if (nakScore >= 75.0) return const Color(0xFF60A5FA); // Blue
    if (nakScore >= 70.0) return const Color(0xFFFBBF24); // Amber
    if (nakScore > 0) return const Color(0xFFFCA5A5); // Red
    return Colors.white70;
  }

  Color get _predikatBorderColor {
    if (nakScore >= 85.0) return const Color(0xFF059669); // Emerald
    if (nakScore >= 80.0) return const Color(0xFF16A34A); // Green
    if (nakScore >= 75.0) return const Color(0xFF2563EB); // Blue
    if (nakScore >= 70.0) return const Color(0xFFD97706); // Amber
    if (nakScore > 0) return const Color(0xFFDC2626); // Red
    return Colors.white24;
  }

  bool get _isPassed {
    if (nakScore <= 0) return true;
    if (nakScore < 70.0) return false;
    if (academicScore > 0 && academicScore < 70.0) return false;
    if (mentalScore > 0 && mentalScore < 70.0) return false;
    if (physicalScore > 0 && physicalScore < 70.0) return false;
    return true;
  }

  IconData get _watermarkIcon {
    if (nakScore <= 0) return Icons.military_tech_rounded;
    if (!_isPassed || nakScore < 70.0) {
      return Icons.warning_amber_rounded;
    }
    if (nakScore >= 85.0) return Icons.workspace_premium_rounded;
    if (nakScore >= 80.0) return Icons.stars_rounded;
    if (nakScore >= 75.0) return Icons.verified_rounded;
    return Icons.military_tech_rounded;
  }

  Color get _watermarkColor {
    if (nakScore <= 0) return Colors.white.withValues(alpha: 0.05);
    if (!_isPassed || nakScore < 70.0) {
      return const Color(0xFFEF4444).withValues(alpha: 0.15);
    }
    if (nakScore >= 85.0) return const Color(0xFF34D399).withValues(alpha: 0.12);
    if (nakScore >= 80.0) return const Color(0xFF4ADE80).withValues(alpha: 0.12);
    if (nakScore >= 75.0) return const Color(0xFF60A5FA).withValues(alpha: 0.12);
    return const Color(0xFFFBBF24).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl + 4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Icon(
              _watermarkIcon,
              size: 130,
              color: _watermarkColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                const Text(
                  'NILAI AKHIR KUMULATIF (NAK)',
                  style: TextStyle(
                    fontSize: AppDimensions.fontXs + 1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: AppDimensions.lg),
                // Score & Predikat Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      nakScore > 0 ? nakScore.toStringAsFixed(2) : '—',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _predikatBgColor,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          border: Border.all(color: _predikatBorderColor, width: 1),
                        ),
                        child: Text(
                          _predikatLabel,
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w700,
                            color: _predikatTextColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

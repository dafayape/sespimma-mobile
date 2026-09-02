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

  static const Color accentGold = Color(0xFFF59E0B);
  static const Color emeraldBg = Color(0xFFDCFCE7);
  static const Color emeraldText = Color(0xFF15803D);
  static const Color emeraldBorder = Color(0xFF10B981);

  String get _predikatLabel {
    if (nakScore >= 85.0) return 'Sangat Baik';
    if (nakScore >= 75.0) return 'Baik';
    if (nakScore >= 65.0) return 'Cukup';
    if (nakScore > 0) return 'Kurang';
    return 'Belum Ada Nilai';
  }

  Color get _predikatBgColor {
    if (nakScore >= 85.0) return emeraldBg;
    if (nakScore >= 75.0) return const Color(0xFFDBEAFE);
    if (nakScore >= 65.0) return const Color(0xFFFEF3C7);
    if (nakScore > 0) return const Color(0xFFFEE2E2);
    return Colors.grey.shade100;
  }

  Color get _predikatTextColor {
    if (nakScore >= 85.0) return emeraldText;
    if (nakScore >= 75.0) return const Color(0xFF1D4ED8);
    if (nakScore >= 65.0) return const Color(0xFFB45309);
    if (nakScore > 0) return const Color(0xFFB91C1C);
    return Colors.grey.shade600;
  }

  bool get _isPassed {
    return nakScore >= 70.0 && academicScore >= 65.0 && mentalScore >= 65.0 && physicalScore >= 65.0;
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
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.military_tech_outlined,
              size: 140,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentGold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: accentGold,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        const Text(
                          'NILAI AKHIR KUMULATIF (NAK)',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs + 1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _predikatBgColor,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        _predikatLabel,
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                          color: _predikatTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      nakScore > 0 ? nakScore.toStringAsFixed(2) : '—',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPassed
                              ? const Color(0xFF059669).withValues(alpha: 0.2)
                              : Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isPassed ? emeraldBorder : Colors.amber.shade400,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPassed ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 14,
                              color: _isPassed ? const Color(0xFF34D399) : Colors.amber.shade300,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isPassed ? 'MEMENUHI SYARAT' : 'DALAM PENGAWASAN',
                              style: TextStyle(
                                fontSize: AppDimensions.fontXs - 1,
                                fontWeight: FontWeight.w800,
                                color: _isPassed ? const Color(0xFF34D399) : Colors.amber.shade300,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _WeightItem(label: 'Akademik', weight: '40%'),
                      Text('•', style: TextStyle(color: Colors.white38)),
                      _WeightItem(label: 'Mental', weight: '40%'),
                      Text('•', style: TextStyle(color: Colors.white38)),
                      _WeightItem(label: 'Jasmani', weight: '20%'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightItem extends StatelessWidget {
  final String label;
  final String weight;

  const _WeightItem({required this.label, required this.weight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
        Text(
          weight,
          style: const TextStyle(
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w800,
            color: NakHeroCard.accentGold,
          ),
        ),
      ],
    );
  }
}

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

  String get _predikatLabel {
    if (nakScore >= 85.0) return 'Sangat Memuaskan';
    if (nakScore >= 75.0) return 'Memuaskan';
    if (nakScore >= 65.0) return 'Cukup';
    if (nakScore > 0) return 'Perlu Pembinaan';
    return 'Proses Penilaian';
  }

  Color get _predikatBgColor {
    if (nakScore >= 85.0) return const Color(0xFF065F46).withValues(alpha: 0.35);
    if (nakScore >= 75.0) return const Color(0xFF1E40AF).withValues(alpha: 0.35);
    if (nakScore >= 65.0) return const Color(0xFF92400E).withValues(alpha: 0.35);
    if (nakScore > 0) return const Color(0xFF991B1B).withValues(alpha: 0.35);
    return Colors.white.withValues(alpha: 0.08);
  }

  Color get _predikatTextColor {
    if (nakScore >= 85.0) return const Color(0xFF34D399);
    if (nakScore >= 75.0) return const Color(0xFF60A5FA);
    if (nakScore >= 65.0) return const Color(0xFFFBBF24);
    if (nakScore > 0) return const Color(0xFFFCA5A5);
    return Colors.white70;
  }

  Color get _predikatBorderColor {
    if (nakScore >= 85.0) return const Color(0xFF059669);
    if (nakScore >= 75.0) return const Color(0xFF2563EB);
    if (nakScore >= 65.0) return const Color(0xFFD97706);
    if (nakScore > 0) return const Color(0xFFDC2626);
    return Colors.white24;
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
              Icons.military_tech_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.035),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 16,
                          decoration: BoxDecoration(
                            color: accentGold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        const Text(
                          'NILAI AKHIR KUMULATIF (NAK)',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs + 1,
                            fontWeight: FontWeight.w700,
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
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
                // Score Row
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
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPassed
                              ? const Color(0xFF059669).withValues(alpha: 0.2)
                              : const Color(0xFFB45309).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                          border: Border.all(
                            color: _isPassed ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isPassed ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                              size: 14,
                              color: _isPassed ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isPassed ? 'MEMENUHI SYARAT' : 'DALAM PENGAWASAN',
                              style: TextStyle(
                                fontSize: AppDimensions.fontXs - 1,
                                fontWeight: FontWeight.w800,
                                color: _isPassed ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                // Weight Distribution Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _WeightItem(label: 'Akademik', weight: '40%'),
                      _VerticalDivider(),
                      _WeightItem(label: 'Mental', weight: '40%'),
                      _VerticalDivider(),
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

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      color: Colors.white.withValues(alpha: 0.15),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        Text(
          weight,
          style: const TextStyle(
            fontSize: AppDimensions.fontXs,
            fontWeight: FontWeight.w700,
            color: NakHeroCard.accentGold,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sespimma/features/auth/domain/entities/user_entity.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class NakSummaryCard extends StatelessWidget {
  final UserEntity user;
  final double nak;

  const NakSummaryCard({super.key, required this.user, required this.nak});

  @override
  Widget build(BuildContext context) {
    final bool isApproved = user.isNakApproved == true;

    if (!isApproved) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.xl),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(color: Colors.blueGrey.shade200, width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_clock_rounded,
                color: AppColors.primaryNavy,
                size: AppDimensions.iconMd + 2,
              ),
            ),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EVALUASI SEDANG BERLANGSUNG',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    'Rekapitulasi Nilai Akhir Keseluruhan (NAK) Anda saat ini dalam tahap pemrosesan verifikasi Pimpinan. Data di bawah ini bersifat parsial.',
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl),
      decoration: BoxDecoration(
        color: _getCardBgColor(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor().withValues(alpha: 0.08),
            blurRadius: AppDimensions.radiusXl,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nilai Akhir Keseluruhan',
                style: TextStyle(
                  color: _getTextHeaderColor().withValues(alpha: 0.85),
                  fontSize: AppDimensions.fontMd - 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.sm),
              Text(
                nak.toStringAsFixed(2),
                style: TextStyle(
                  color: _getScoreColor(),
                  fontSize: AppDimensions.fontHuge + 6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              _buildPredikat(),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.sm,
            ),
            decoration: BoxDecoration(
              color: _getBadgeBgColor(),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: _getBadgeBgColor().withValues(alpha: 0.2),
                  blurRadius: AppDimensions.radiusMd,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              nak >= 70 ? 'LULUS' : 'TIDAK LULUS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getBadgeTextColor(),
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredikat() {
    String pred = '-';
    Color pillBg = Colors.white.withValues(alpha: 0.15);
    Color predColor = Colors.white;

    if (nak > 85.0) {
      pred = 'Sangat Memuaskan (SM)';
      pillBg = Colors.green.shade100;
      predColor = Colors.green.shade900;
    } else if (nak > 80.0) {
      pred = 'Memuaskan (M)';
      pillBg = Colors.green.shade50;
      predColor = Colors.green.shade700;
    } else if (nak > 75.0) {
      pred = 'Baik (B)';
      pillBg = Colors.lime.shade100;
      predColor = Colors.lime.shade900;
    } else if (nak > 70.0) {
      pred = 'Cukup (C)';
      pillBg = Colors.amber.shade100;
      predColor = Colors.amber.shade900;
    } else {
      pred = 'Tidak Lulus (K)';
      pillBg = Colors.red.shade100;
      predColor = Colors.red.shade900;
    }

    if (pred == '-') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: AppDimensions.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm + 2,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: predColor.withValues(alpha: 0.15)),
      ),
      child: Text(
        pred,
        style: TextStyle(
          fontSize: AppDimensions.fontXs,
          fontWeight: FontWeight.w800,
          color: predColor,
        ),
      ),
    );
  }

  Color _getCardBgColor() {
    if (nak > 85.0) return Colors.green.shade50;
    if (nak > 80.0) return Colors.green.shade50;
    if (nak > 75.0) return Colors.lime.shade50;
    if (nak > 70.0) return Colors.amber.shade50;
    return Colors.red.shade50;
  }

  Color _getBorderColor() {
    if (nak > 85.0) return Colors.green.shade300;
    if (nak > 80.0) return Colors.green.shade200;
    if (nak > 75.0) return Colors.lime.shade300;
    if (nak > 70.0) return Colors.amber.shade300;
    return Colors.red.shade300;
  }

  Color _getTextHeaderColor() {
    if (nak > 85.0) return Colors.green.shade800;
    if (nak > 80.0) return Colors.green.shade700;
    if (nak > 75.0) return Colors.lime.shade800;
    if (nak > 70.0) return Colors.amber.shade900;
    return Colors.red.shade800;
  }

  Color _getScoreColor() {
    if (nak > 85.0) return Colors.green.shade800;
    if (nak > 80.0) return Colors.green.shade500;
    if (nak > 75.0) return Colors.lime.shade700;
    if (nak > 70.0) return Colors.amber.shade500;
    return Colors.red.shade700;
  }

  Color _getBadgeBgColor() {
    if (nak > 85.0) return Colors.green.shade700;
    if (nak > 80.0) return Colors.green.shade500;
    if (nak > 75.0) return Colors.lime.shade600;
    if (nak > 70.0) return Colors.amber.shade600;
    return Colors.red.shade600;
  }

  Color _getBadgeTextColor() {
    return Colors.white;
  }
}

import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

class EwsWarningBanner extends StatelessWidget {
  final double academicScore;
  final double mentalScore;
  final double physicalScore;

  const EwsWarningBanner({
    super.key,
    required this.academicScore,
    required this.mentalScore,
    required this.physicalScore,
  });

  List<String> get _warningComponents {
    final list = <String>[];
    if (academicScore > 0 && academicScore < 70.0) list.add('Akademik (${academicScore.toStringAsFixed(1)})');
    if (mentalScore > 0 && mentalScore < 70.0) list.add('Mental Kepribadian (${mentalScore.toStringAsFixed(1)})');
    if (physicalScore > 0 && physicalScore < 70.0) list.add('Jasmani (${physicalScore.toStringAsFixed(1)})');
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final warnings = _warningComponents;
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppDimensions.lg),
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERHATIAN: Peringatan Dini (EWS)',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Komponen ${warnings.join(", ")} Anda di bawah standar kelulusan minimal (70.0). Tingkatkan capaian sebelum evaluasi akhir semester.',
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXs + 1,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB91C1C),
                    height: 1.35,
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

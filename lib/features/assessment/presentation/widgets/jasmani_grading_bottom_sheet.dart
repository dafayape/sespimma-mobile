import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/data/models/jasmani_grading_data.dart';
import 'package:sespimma/features/assessment/presentation/pages/samapta_a_screen.dart';
import 'package:sespimma/features/assessment/presentation/pages/samapta_b_screen.dart';

class JasmaniGradingBottomSheet extends StatelessWidget {
  final Map<String, dynamic> serdik;
  final JasmaniGradingData gradingData;
  final String golongan;
  final String gender;
  final VoidCallback onGradingComplete;

  const JasmaniGradingBottomSheet({
    super.key,
    required this.serdik,
    required this.gradingData,
    required this.golongan,
    required this.gender,
    required this.onGradingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGol4 = golongan == 'GOL IV';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.xl,
            vertical: AppDimensions.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Pilih Penilaian Jasmani',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: AppDimensions.md),

              _buildOptionCard(
                context,
                title: 'Samapta A',
                subtitle: isGol4
                    ? 'Jalan selama 12 menit'
                    : 'Lari selama 12 menit',
                icon: Icons.directions_run_rounded,
                isCompleted: gradingData.nilaiA != null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SamaptaAScreen(
                        serdik: serdik,
                        gradingData: gradingData,
                        golongan: golongan,
                        gender: gender,
                      ),
                    ),
                  ).then((_) => onGradingComplete());
                },
              ),

              const SizedBox(height: AppDimensions.md),

              if (!isGol4)
                _buildOptionCard(
                  context,
                  title: 'Samapta B',
                  subtitle:
                      'Pull Up, Sit Up, Push Up, dan Shuttle Run 6x10 Meter',
                  icon: Icons.fitness_center_rounded,
                  isCompleted: gradingData.isSamaptaBComplete,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SamaptaBScreen(
                          serdik: serdik,
                          gradingData: gradingData,
                          golongan: golongan,
                          gender: gender,
                        ),
                      ),
                    ).then((_) => onGradingComplete());
                  },
                ),

              const SizedBox(height: AppDimensions.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          border: Border.all(
            color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          color: isCompleted ? Colors.green.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade100
                    : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isCompleted
                    ? Colors.green.shade700
                    : AppColors.primaryNavy,
              ),
            ),
            const SizedBox(width: AppDimensions.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppDimensions.fontMd,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

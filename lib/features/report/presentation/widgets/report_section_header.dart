import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class ReportSectionHeader extends StatelessWidget {
  final String judul;

  const ReportSectionHeader({super.key, required this.judul});

  @override
  Widget build(BuildContext context) {
    return Text(
      judul,
      style: const TextStyle(
        fontSize: AppDimensions.fontLg,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryNavy,
      ),
    );
  }
}

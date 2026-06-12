import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class ReportErrorState extends StatelessWidget {
  final String message;

  const ReportErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            AppIcons.warningCircle,
            size: AppDimensions.iconXl,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: AppDimensions.md),
          const Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

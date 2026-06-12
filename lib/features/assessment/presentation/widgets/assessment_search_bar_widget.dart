import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class AssessmentSearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String? hintText;

  const AssessmentSearchBarWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.inputHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: AppDimensions.xs,
            offset: const Offset(0, AppDimensions.xs / 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: AppDimensions.fontDefault,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryNavy,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? 'Cari nama / NRP...',
          hintStyle: TextStyle(
            color: Colors.blueGrey.shade300,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.infoBlueGrey,
            size: AppDimensions.iconDefault,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: AppDimensions.iconMd,
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(
            left: AppDimensions.lg,
            right: AppDimensions.lg,
            bottom: AppDimensions.fontLg / 2,
          ),
        ),
      ),
    );
  }
}

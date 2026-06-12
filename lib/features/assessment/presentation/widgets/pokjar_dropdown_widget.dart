import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class PokjarDropdownWidget extends StatelessWidget {
  final String selectedPokjar;
  final List<String> pokjars;
  final ValueChanged<String> onChanged;

  const PokjarDropdownWidget({
    super.key,
    required this.selectedPokjar,
    required this.pokjars,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.inputHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPokjar,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryNavy,
            size: AppDimensions.iconMd,
          ),
          isExpanded: true,
          isDense: true,
          style: const TextStyle(
            fontSize: AppDimensions.fontDefault,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryNavy,
          ),
          items: pokjars.map((String pokjar) {
            return DropdownMenuItem(
              value: pokjar,
              child: Text(pokjar, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null && val != selectedPokjar) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

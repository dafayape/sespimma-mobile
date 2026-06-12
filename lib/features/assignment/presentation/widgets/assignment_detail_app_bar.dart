import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

class AssignmentDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AssignmentDetailAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(AppIcons.arrowLeft, color: AppColors.primaryNavy),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Detail Tugas',
        style: TextStyle(
          color: AppColors.primaryNavy,
          fontWeight: FontWeight.w800,
          fontSize: AppDimensions.fontXxl,
        ),
      ),
    );
  }
}

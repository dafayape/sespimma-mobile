import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class SerdikCardWidget extends StatelessWidget {
  final Map<String, String> serdik;
  final VoidCallback onTap;

  const SerdikCardWidget({
    super.key,
    required this.serdik,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool sudahDinilai = serdik['status'] == 'Sudah Dinilai';
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: AppDimensions.sm,
            offset: const Offset(0, AppDimensions.xs),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: AppDimensions.lg),
                Expanded(child: _buildInfo(sudahDinilai)),
                const SizedBox(width: AppDimensions.md),
                _buildNilaiButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final String? profilePhoto = serdik['profile_photo'];
    return Container(
      padding: const EdgeInsets.all(AppDimensions.xs / 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.blueGrey.shade100,
          width: AppDimensions.borderWidthFocus,
        ),
      ),
      child: CircleAvatar(
        radius: AppDimensions.avatarSm,
        backgroundColor: Colors.blueGrey.shade50,
        backgroundImage: (profilePhoto != null && profilePhoto.isNotEmpty)
            ? FileImage(File(profilePhoto)) as ImageProvider
            : null,
        child: (profilePhoto == null || profilePhoto.isEmpty)
            ? Icon(Icons.person_rounded, color: Colors.blueGrey.shade300)
            : null,
      ),
    );
  }

  Widget _buildInfo(bool sudahDinilai) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          serdik['name']!,
          style: const TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.xs),
        Text(
          'NOSIS: ${serdik['nosis'] ?? serdik['nrp']} • ${serdik['pokjar']}',
          style: TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade500,
          ),
        ),
        const SizedBox(height: AppDimensions.sm),
        _buildStatusChip(sudahDinilai),
      ],
    );
  }

  Widget _buildStatusChip(bool sudahDinilai) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: sudahDinilai ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: sudahDinilai ? Colors.green.shade200 : Colors.amber.shade200,
        ),
      ),
      child: Text(
        serdik['status']!,
        style: TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w800,
          color: sudahDinilai ? Colors.green.shade700 : Colors.amber.shade700,
        ),
      ),
    );
  }

  Widget _buildNilaiButton() {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.05),
        foregroundColor: AppColors.primaryNavy,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: const Text(
        'NILAI',
        style: TextStyle(
          fontSize: AppDimensions.fontMd,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

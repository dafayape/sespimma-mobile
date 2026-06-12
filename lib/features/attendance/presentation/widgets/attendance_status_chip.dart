import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';

class AttendanceStatusChip extends StatelessWidget {
  final List<AttendanceZone> zones;
  final AttendanceZone? activeZone;
  final bool isGpsLoading;
  final bool isFakeGps;
  final bool isInRadius;
  final Animation<double> chipScale;

  const AttendanceStatusChip({
    super.key,
    required this.zones,
    required this.activeZone,
    required this.isGpsLoading,
    required this.isFakeGps,
    required this.isInRadius,
    required this.chipScale,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAlpha =
        activeZone != null && DateTime.now().isAfter(activeZone!.cutoffTime);

    final label = _getLabel(isAlpha);
    final chipColor = _getChipColor(isAlpha);

    return ScaleTransition(
      scale: chipScale,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl + 8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.xl,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXxl + 8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: chipColor.withValues(alpha: 0.3),
                  blurRadius: AppDimensions.radiusXl,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGpsLoading)
                  const SizedBox(
                    width: AppDimensions.lg,
                    height: AppDimensions.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    isFakeGps || isAlpha
                        ? AppIcons.warningOctagonFill
                        : (isInRadius
                              ? AppIcons.checkCircleFill
                              : AppIcons.warningCircleFill),
                    color: Colors.white,
                    size: AppDimensions.iconSm - 2,
                  ),
                const SizedBox(width: AppDimensions.sm + 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.fontXs + 1,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLabel(bool isAlpha) {
    if (zones.isEmpty) return 'Tidak Ada Jadwal';
    if (isGpsLoading) return 'Mencari Lokasi...';
    if (isFakeGps) return 'Deteksi Manipulasi GPS!';
    if (isAlpha) return 'Batas Waktu Berakhir (ALPHA)';
    if (isInRadius) return 'Dalam Zona Absensi';
    return 'Lokasi Tidak Ditemukan';
  }

  Color _getChipColor(bool isAlpha) {
    if (zones.isEmpty) return Colors.blueGrey.shade600;
    if (isGpsLoading) return Colors.blueGrey.shade800;
    if (isFakeGps || isAlpha) return AppColors.dangerRed;
    if (isInRadius) return AppColors.successGreen;
    return AppColors.dangerRed;
  }
}

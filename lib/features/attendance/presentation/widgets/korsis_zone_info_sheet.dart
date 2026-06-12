import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:sespimma/features/attendance/presentation/widgets/korsis_zone_qr_sheet.dart';
import 'package:sespimma/features/attendance/presentation/widgets/korsis_zone_form_sheet.dart';

class KorsisZoneInfoSheet extends StatelessWidget {
  final AttendanceZone zone;
  final VoidCallback onDeleted;

  const KorsisZoneInfoSheet({
    super.key,
    required this.zone,
    required this.onDeleted,
  });

  void _showQrCode(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KorsisZoneQrSheet(zones: [zone]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
        title: const Text(
          'Hapus Zona?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus zona ${zone.name}? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('BATAL', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              onDeleted();
            },
            child: const Text(
              'HAPUS',
              style: TextStyle(
                color: AppColors.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    if (day >= 1 && day <= 7) return days[day - 1];
    return '';
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  String _getRoutineDateText(AttendanceZone zone) {
    if (zone.routineStartDate == null || zone.routineEndDate == null) return '';

    final startDayName = _getDayName(zone.routineStartDate!.weekday);
    final endDayName = _getDayName(zone.routineEndDate!.weekday);

    final startDateFormatted =
        '${zone.routineStartDate!.day.toString().padLeft(2, '0')} ${_getMonthName(zone.routineStartDate!.month)} ${zone.routineStartDate!.year}';
    final endDateFormatted =
        '${zone.routineEndDate!.day.toString().padLeft(2, '0')} ${_getMonthName(zone.routineEndDate!.month)} ${zone.routineEndDate!.year}';

    if (zone.routineStartDate!.year == zone.routineEndDate!.year &&
        zone.routineStartDate!.month == zone.routineEndDate!.month &&
        zone.routineStartDate!.day == zone.routineEndDate!.day) {
      return '$startDayName, $startDateFormatted';
    } else {
      return '$startDayName, $startDateFormatted - $endDayName, $endDateFormatted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPolygon =
        zone.polygonPoints != null && zone.polygonPoints!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.only(bottom: AppDimensions.xxxl),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppDimensions.lg),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.buildingsFill,
                    color: AppColors.primaryNavy,
                    size: AppDimensions.iconLg,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.activityName,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        zone.name,
                        style: TextStyle(
                          fontSize: AppDimensions.fontDefault,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.md,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: zone.isRoutine
                                  ? AppColors.successGreen.withValues(
                                      alpha: 0.1,
                                    )
                                  : zone.isTraining
                                  ? Colors.orange.shade700.withValues(
                                      alpha: 0.1,
                                    )
                                  : AppColors.primaryNavy.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Text(
                              zone.isRoutine
                                  ? 'Kegiatan Rutin'
                                  : zone.isTraining
                                  ? 'Kegiatan Pelatihan'
                                  : 'Kegiatan Pelatihan',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.bold,
                                color: zone.isRoutine
                                    ? AppColors.successGreen
                                    : zone.isTraining
                                    ? Colors.orange.shade700
                                    : AppColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (zone.isRoutine &&
                          zone.routineStartDate != null &&
                          zone.routineEndDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              AppIcons.calendarBlank,
                              size: 14,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _getRoutineDateText(zone),
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontSm,
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xl),
          const Divider(height: 1),
          const SizedBox(height: AppDimensions.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: AppIcons.clock,
                  title: 'Waktu Pelaksanaan',
                  value: zone.timeString,
                ),
                const SizedBox(height: AppDimensions.md),
                _buildInfoRow(
                  icon: AppIcons.warningOctagonFill,
                  title: 'Batas Absen',
                  value:
                      '${zone.cutoffTime.hour.toString().padLeft(2, '0')}:${zone.cutoffTime.minute.toString().padLeft(2, '0')} WIB',
                ),
                const SizedBox(height: AppDimensions.md),
                _buildInfoRow(
                  icon: AppIcons.mapPinLine,
                  title: 'Tipe Zona',
                  value: isPolygon
                      ? 'Polygon Area'
                      : 'Radius ${zone.radiusMeters.toInt()} meter',
                ),
                const SizedBox(height: AppDimensions.md),
                _buildInfoRow(
                  icon: AppIcons.user,
                  title: 'Pembuat Zona',
                  value: zone.creator,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xxl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) =>
                                  KorsisZoneFormSheet(existingZone: zone),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blueGrey.shade300),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                          ),
                          child: Icon(
                            AppIcons.pencilSimple,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _confirmDelete(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.dangerRed),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLg,
                              ),
                            ),
                          ),
                          child: const Icon(
                            AppIcons.trash,
                            color: AppColors.dangerRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showQrCode(context);
                    },
                    icon: const Icon(AppIcons.qrCode, color: Colors.white),
                    label: const Text(
                      'QR CODE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLg,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade400),
        const SizedBox(width: AppDimensions.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

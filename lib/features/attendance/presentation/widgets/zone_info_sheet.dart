import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';

class ZoneInfoSheet extends StatelessWidget {
  final AttendanceZone zone;
  final VoidCallback onLeaveRequest;
  final ValueChanged<bool> onToggleMakerindo;

  const ZoneInfoSheet({
    super.key,
    required this.zone,
    required this.onLeaveRequest,
    required this.onToggleMakerindo,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggleMakerindo(false),
                  child: Opacity(
                    opacity: 0.15,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                      ),
                      child: Icon(
                        Icons.arrow_left_rounded,
                        size: AppDimensions.iconSm,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggleMakerindo(true),
                  child: Opacity(
                    opacity: 0.15,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                      ),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        size: AppDimensions.iconSm,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            const Text(
              'Informasi Zona dan Kegiatan',
              style: TextStyle(
                fontSize: AppDimensions.fontLg - 1,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.lg),
            _InfoRow(
              icon: Icons.event_available_rounded,
              label: 'Kegiatan Aktif',
              value: zone.activityName,
            ),
            _InfoRow(
              icon: Icons.access_time_filled_rounded,
              label: 'Waktu Pelaksanaan',
              value: zone.timeString,
            ),
            _InfoRow(
              icon: Icons.timer_off_rounded,
              label: 'Batas Waktu Absen',
              value:
                  '${zone.deadline.hour.toString().padLeft(2, '0')}:${zone.deadline.minute.toString().padLeft(2, '0')} WIB',
              valueColor: DateTime.now().isAfter(zone.deadline)
                  ? AppColors.dangerRed
                  : AppColors.successGreen,
            ),
            _InfoRow(
              icon: Icons.person_pin_rounded,
              label: 'Pembuat Kegiatan',
              value: zone.creator,
            ),
            _InfoRow(
              icon: Icons.location_on_rounded,
              label: 'Lokasi Zona',
              value: zone.name,
            ),
            _InfoRow(
              icon: Icons.straighten_rounded,
              label:
                  (zone.polygonPoints != null && zone.polygonPoints!.isNotEmpty)
                  ? 'Polygon Absensi'
                  : 'Radius Absensi',
              value:
                  (zone.polygonPoints != null && zone.polygonPoints!.isNotEmpty)
                  ? '${zone.polygonPoints!.length} Titik'
                  : '${zone.radiusMeters.toInt()} meter',
            ),
            const SizedBox(height: AppDimensions.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onLeaveRequest,
                icon: const Icon(
                  AppIcons.fileTextBold,
                  size: AppDimensions.iconSm,
                ),
                label: const Text(
                  'AJUKAN IZIN KHUSUS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconXs + 2,
            color: AppColors.primaryNavy,
          ),
          const SizedBox(width: AppDimensions.sm + 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontXs + 1,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

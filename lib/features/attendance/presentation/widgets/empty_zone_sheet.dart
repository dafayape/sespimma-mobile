import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class EmptyZoneSheet extends StatelessWidget {
  final ValueChanged<bool> onToggleMakerindo;

  const EmptyZoneSheet({super.key, required this.onToggleMakerindo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xxl,
        AppDimensions.lg,
        AppDimensions.xxl,
        AppDimensions.xxxl + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm),
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
                  borderRadius: BorderRadius.circular(AppDimensions.xs / 2),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggleMakerindo(true),
                child: Opacity(
                  opacity: 0.15,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm),
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
          const SizedBox(height: AppDimensions.xxl + 4),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerRed.withValues(alpha: 0.05),
                ),
              ),
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerRed.withValues(alpha: 0.1),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerRed,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.dangerRed,
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: Colors.white,
                  size: AppDimensions.iconMd + 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xxl),
          const Text(
            'Koordinat Tidak Ditemukan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppDimensions.sm + 2),
          Text(
            'Posisi GPS Anda berada di luar batas radius seluruh agenda presensi aktif saat ini. Silakan mendekat ke lokasi geofence kegiatan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              color: Colors.blueGrey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.xxl + 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusLg + 2,
                  ),
                ),
              ),
              child: const Text(
                'SAYA MENGERTI',
                style: TextStyle(
                  fontSize: AppDimensions.fontMd - 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

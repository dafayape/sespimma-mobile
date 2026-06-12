import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/models/attendance_model.dart';

class AttendanceStatusCard extends StatelessWidget {
  final AttendanceSummaryModel? summary;
  final bool isLoading;

  const AttendanceStatusCard({super.key, this.summary, this.isLoading = false});

  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _warningOrange = Color(0xFFF57C00);
  static const Color _dangerRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer();

    final data =
        summary ??
        const AttendanceSummaryModel(
          presentCount: 0,
          permissionCount: 0,
          absentCount: 0,
        );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatusItem(
            'Hadir',
            data.presentCount.toString(),
            _successGreen,
            AppIcons.checkCircleFill,
          ),
          _buildDivider(),
          _buildStatusItem(
            'Izin',
            data.permissionCount.toString(),
            _warningOrange,
            AppIcons.warningCircleFill,
          ),
          _buildDivider(),
          _buildStatusItem(
            'Alpa',
            data.absentCount.toString(),
            _dangerRed,
            AppIcons.xCircleFill,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 48, width: 1.5, color: Colors.grey.shade100);
  }

  Widget _buildStatusItem(
    String label,
    String count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDimensions.iconSm, color: color),
              const SizedBox(width: AppDimensions.radiusSm),
              Text(
                count,
                style: TextStyle(
                  fontSize: AppDimensions.fontDisplay,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontDefault,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        ),
      ),
    );
  }
}

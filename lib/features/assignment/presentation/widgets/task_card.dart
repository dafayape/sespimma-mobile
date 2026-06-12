import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import '../../data/models/assignment_model.dart';

class TaskCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback? onRefresh;

  const TaskCard({super.key, required this.assignment, this.onRefresh});

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _dangerRed = Color(0xFFD32F2F);
  static const Color _warningOrange = Color(0xFFF57C00);
  static const Color _successGreen = Color(0xFF2E7D32);

  String _getDynamicCategoryName(String rawCategory) {
    if (rawCategory.contains('NKKP')) return 'NKKP';
    if (rawCategory.contains('NPKP')) return 'NPKP';
    if (rawCategory.contains('NPTT')) return 'NPTT';
    if (rawCategory.contains('NKP')) return 'NKP';
    if (rawCategory.contains('NSK')) return 'NSK';
    if (rawCategory.contains('Ujian')) return 'NUMP';
    return rawCategory;
  }

  String _getDeadlineText(DateTime deadline, String status) {
    if (status == 'diperiksa') {
      return 'Tugas Terkirim • Sedang Dinilai';
    } else if (status == 'selesai') {
      return 'Tugas Selesai • Telah Dinilai';
    }

    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Batas waktu telah habis';
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      if (days > 0) {
        return 'Sisa waktu: $days hari $hours jam';
      } else {
        return 'Sisa waktu: $hours jam $minutes menit';
      }
    }
  }

  Color _getDeadlineColor(DateTime deadline, String status) {
    if (status == 'diperiksa') return _warningOrange;
    if (status == 'selesai') return _successGreen;

    final difference = deadline.difference(DateTime.now());
    if (difference.isNegative) return _dangerRed;
    if (difference.inHours < 3) return _warningOrange;
    return _primaryNavy;
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'diperiksa':
        return AppIcons.hourglassHighFill;
      case 'selesai':
        return AppIcons.checkCircleFill;
      case 'aktif':
      default:
        return AppIcons.clipboardTextFill;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'diperiksa':
        return _warningOrange;
      case 'selesai':
        return _successGreen;
      case 'aktif':
      default:
        return _primaryNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAktif = assignment.status == 'aktif';
    final Color deadlineColor = _getDeadlineColor(
      assignment.deadline,
      assignment.status,
    );
    final statusColor = _getStatusColor(assignment.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isAktif ? Colors.transparent : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: () async {
            await Navigator.pushNamed(
              context,
              '/assignment-detail',
              arguments: assignment,
            );
            if (onRefresh != null) onRefresh!();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.xl - 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'icon-${assignment.id}',
                      child: Container(
                        padding: const EdgeInsets.all(AppDimensions.lg - 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                        ),
                        child: Icon(
                          _getStatusIcon(assignment.status),
                          color: statusColor,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm,
                                  ),
                                ),
                                child: Text(
                                  _getDynamicCategoryName(assignment.mapel),
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontXs,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blueGrey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Colors.blueGrey.shade500,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        assignment.pengajar,
                                        style: TextStyle(
                                          fontSize: AppDimensions.fontDefault,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.sm),
                          Hero(
                            tag: 'title-${assignment.id}',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                assignment.judul,
                                style: const TextStyle(
                                  fontSize: AppDimensions.fontXl,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryNavy,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.xl),
                Hero(
                  tag: 'deadline-${assignment.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: deadlineColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        border: Border.all(
                          color: deadlineColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            assignment.status == 'diperiksa'
                                ? AppIcons.hourglassHigh
                                : (assignment.status == 'selesai'
                                      ? AppIcons.checkCircle
                                      : AppIcons.timer),
                            color: deadlineColor,
                            size: AppDimensions.iconMd,
                          ),
                          const SizedBox(width: AppDimensions.sm + 2),
                          Expanded(
                            child: Text(
                              _getDeadlineText(
                                assignment.deadline,
                                assignment.status,
                              ),
                              style: TextStyle(
                                fontSize: AppDimensions.fontDefault,
                                fontWeight: FontWeight.w600,
                                color: deadlineColor,
                              ),
                            ),
                          ),
                          Icon(
                            AppIcons.caretRight,
                            color: Colors.blueGrey.shade400,
                            size: AppDimensions.iconMd,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

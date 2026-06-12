import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

enum NotificationType { success, error, warning, info }

abstract final class AppNotifier {
  static String? _lastMessage;
  static DateTime? _lastTimeShown;
  static const Duration _debounceDuration = Duration(seconds: 2);

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, NotificationType.success, duration: duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, NotificationType.error, duration: duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, NotificationType.warning, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    _show(context, message, NotificationType.info, duration: duration);
  }

  static void _show(
    BuildContext context,
    String message,
    NotificationType type, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final now = DateTime.now();
    if (_lastMessage == message && _lastTimeShown != null) {
      if (now.difference(_lastTimeShown!) < _debounceDuration) {
        return;
      }
    }

    _lastMessage = message;
    _lastTimeShown = now;

    Color backgroundColor;
    IconData icon;
    Color iconColor = Colors.white;

    switch (type) {
      case NotificationType.success:
        backgroundColor = AppColors.successGreen;
        icon = AppIcons.checkCircleFill;
        break;
      case NotificationType.error:
        backgroundColor = AppColors.dangerRed;
        icon = AppIcons.warningOctagonFill;
        break;
      case NotificationType.warning:
        backgroundColor = AppColors.warningOrange;
        icon = AppIcons.warningCircleFill;
        break;
      case NotificationType.info:
        backgroundColor = AppColors.primaryNavy;
        icon = AppIcons.infoFill;
        break;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(
        bottom: AppDimensions.xxxl,
        left: AppDimensions.lg,
        right: AppDimensions.lg,
      ),
      duration: duration ?? const Duration(seconds: 4),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: backgroundColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: AppDimensions.iconDefault,
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Future.microtask(() {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }
}

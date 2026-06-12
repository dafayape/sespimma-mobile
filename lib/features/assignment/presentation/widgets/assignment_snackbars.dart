import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';

abstract final class AssignmentSnackbars {
  static void showSuccess(BuildContext context, String message) {
    AppNotifier.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    AppNotifier.showError(context, message);
  }
}

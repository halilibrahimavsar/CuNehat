// snackbar_helper.dart
import 'package:flutter/material.dart';

class SnackbarHelper {
  // -------------------------------
  // 🔧 Core method (internal)
  // -------------------------------
  static void _show(
    BuildContext context, {
    required String message,
    required Color color,
    IconData? icon,
    bool showProgress = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      duration:
          showProgress ? const Duration(days: 1) : const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          if (!showProgress) Icon(icon, color: Colors.white),
          if (!showProgress) const SizedBox(width: 12),

          // Loading spinner
          if (showProgress)
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.3,
                color: Colors.white,
              ),
            ),
          if (showProgress) const SizedBox(width: 16),

          // Message
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
      action: showProgress
          ? SnackBarAction(
              label: 'Kapat',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // -------------------------------
  // 🟢 Success
  // -------------------------------
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.green.shade600,
      icon: Icons.check_circle,
    );
  }

  // -------------------------------
  // 🔴 Error
  // -------------------------------
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.red.shade700,
      icon: Icons.error,
    );
  }

  // -------------------------------
  // 🔵 Info
  // -------------------------------
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.blue.shade600,
      icon: Icons.info,
    );
  }

  // -------------------------------
  // 🟡 Loading
  // -------------------------------
  static void showLoading(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.grey.shade800,
      showProgress: true,
    );
  }
}

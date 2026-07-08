import 'package:flutter/material.dart';

enum SnackbarType { success, error, info }

class CustomSnackbar {
  CustomSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color color;
    final IconData icon;

    switch (type) {
      case SnackbarType.success:
        color = const Color(0xFF69D36E); // Brand Accent Green
        icon = Icons.check_circle_outline_rounded;
        break;
      case SnackbarType.error:
        color = theme.colorScheme.error;
        icon = Icons.error_outline_rounded;
        break;
      case SnackbarType.info:
        color = theme.colorScheme.primary;
        icon = Icons.info_outline_rounded;
        break;
    }

    final snackbar = SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16224A) : Colors.white, // Brand Navy or White
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackbar);
  }
}

import 'package:flutter/material.dart';

enum CustomButtonType { primary, secondary, accent, outline, text }

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final CustomButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = CustomButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 44, // Compact heights (44px) matching Notion/Linear
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getForegroundColor(theme, isDark),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: _getForegroundColor(theme, isDark)),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: _getForegroundColor(theme, isDark),
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );

    final Widget buttonWidget;
    final borderRadius = BorderRadius.circular(12.0); // 12px rounded corner

    switch (type) {
      case CustomButtonType.primary:
        buttonWidget = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          child: child,
        );
        break;
      case CustomButtonType.secondary:
        buttonWidget = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          child: child,
        );
        break;
      case CustomButtonType.accent:
        buttonWidget = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF69D36E), // Accent green
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          child: child,
        );
        break;
      case CustomButtonType.outline:
        buttonWidget = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: isDark ? theme.colorScheme.outline : theme.colorScheme.outline,
              width: 1,
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          child: child,
        );
        break;
      case CustomButtonType.text:
        buttonWidget = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(width ?? 80, height),
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          ),
          child: child,
        );
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: buttonWidget,
    );
  }

  Color _getForegroundColor(ThemeData theme, bool isDark) {
    if (onPressed == null) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }
    switch (type) {
      case CustomButtonType.primary:
        return theme.colorScheme.onPrimary;
      case CustomButtonType.secondary:
        return theme.colorScheme.onPrimaryContainer;
      case CustomButtonType.accent:
        return Colors.white;
      case CustomButtonType.outline:
      case CustomButtonType.text:
        return theme.colorScheme.primary;
    }
  }
}

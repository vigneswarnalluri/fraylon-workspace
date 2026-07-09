import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final String? confirmLabel;
  final VoidCallback? onConfirm;
  final String cancelLabel;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.onConfirm,
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? confirmLabel,
    VoidCallback? onConfirm,
    String cancelLabel = 'Cancel',
    VoidCallback? onCancel,
    bool isDestructive = false,
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => CustomDialog(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        isDestructive: isDestructive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(12.0);

    final mediaQuery = MediaQuery.of(context);
    final sanitizedQuery = mediaQuery.copyWith(
      viewInsets: EdgeInsets.only(
        left: mediaQuery.viewInsets.left.clamp(0.0, double.infinity),
        top: mediaQuery.viewInsets.top.clamp(0.0, double.infinity),
        right: mediaQuery.viewInsets.right.clamp(0.0, double.infinity),
        bottom: mediaQuery.viewInsets.bottom.clamp(0.0, double.infinity),
      ),
      viewPadding: EdgeInsets.only(
        left: mediaQuery.viewPadding.left.clamp(0.0, double.infinity),
        top: mediaQuery.viewPadding.top.clamp(0.0, double.infinity),
        right: mediaQuery.viewPadding.right.clamp(0.0, double.infinity),
        bottom: mediaQuery.viewPadding.bottom.clamp(0.0, double.infinity),
      ),
      padding: EdgeInsets.only(
        left: mediaQuery.padding.left.clamp(0.0, double.infinity),
        top: mediaQuery.padding.top.clamp(0.0, double.infinity),
        right: mediaQuery.padding.right.clamp(0.0, double.infinity),
        bottom: mediaQuery.padding.bottom.clamp(0.0, double.infinity),
      ),
    );

    return MediaQuery(
      data: sanitizedQuery,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Panel
              Flexible(
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: theme.textTheme.bodyMedium ?? const TextStyle(),
                    child: content,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onCancel ?? () => Navigator.pop(context),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  if (confirmLabel != null) ...[
                    const SizedBox(width: 8),
                    CustomButton(
                      label: confirmLabel!,
                      width: (confirmLabel!.length * 8.0 + 32.0 > 100.0)
                          ? (confirmLabel!.length * 8.0 + 32.0)
                          : 100.0,
                      height: 38,
                      type: isDestructive ? CustomButtonType.accent : CustomButtonType.primary,
                      onPressed: onConfirm,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

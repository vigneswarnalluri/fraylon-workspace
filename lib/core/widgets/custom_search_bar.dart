import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final List<Widget>? filters;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search or command...',
    this.onChanged,
    this.onFilterPressed,
    this.filters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          if (filters != null && filters!.isNotEmpty) ...[
            ...filters!,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.60),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                // Zero out all internal padding — Row handles vertical centering
                contentPadding: EdgeInsets.zero,
                isDense: true,
                fillColor: Colors.transparent,
                filled: false,
              ),
            ),
          ),
          if (onFilterPressed != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onFilterPressed,
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ] else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}

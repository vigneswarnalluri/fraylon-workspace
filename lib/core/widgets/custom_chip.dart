import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const CustomChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : (isDark ? theme.colorScheme.surface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBadge extends StatelessWidget {
  final int count;
  final Widget? child;

  const CustomBadge({
    super.key,
    required this.count,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final badgeWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    if (child == null) return badgeWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          right: -6,
          top: -6,
          child: badgeWidget,
        ),
      ],
    );
  }
}

enum StatusPillType { backlog, todo, inProgress, completed, canceled }

class StatusPill extends StatelessWidget {
  final StatusPillType type;
  final String? customLabel;

  const StatusPill({
    super.key,
    required this.type,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color color;
    final String label;

    switch (type) {
      case StatusPillType.backlog:
        color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6);
        label = 'Backlog';
        break;
      case StatusPillType.todo:
        color = theme.colorScheme.primary;
        label = 'Todo';
        break;
      case StatusPillType.inProgress:
        color = const Color(0xFF22C7D6); // Secondary Teal
        label = 'In Progress';
        break;
      case StatusPillType.completed:
        color = const Color(0xFF69D36E); // Accent Green
        label = 'Completed';
        break;
      case StatusPillType.canceled:
        color = theme.colorScheme.error;
        label = 'Canceled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Small dot indicator matching Linear/ClickUp status design
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            customLabel ?? label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

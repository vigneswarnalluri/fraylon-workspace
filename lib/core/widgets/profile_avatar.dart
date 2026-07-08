import 'package:flutter/material.dart';

enum UserStatus { online, busy, offline }

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final UserStatus status;
  final bool showStatus;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 36,
    this.status = UserStatus.offline,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatar = CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              initials.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: size * 0.38,
              ),
            )
          : null,
    );

    if (!showStatus) return avatar;

    final Color statusColor;
    switch (status) {
      case UserStatus.online:
        statusColor = const Color(0xFF69D36E); // Brand Accent Green
        break;
      case UserStatus.busy:
        statusColor = const Color(0xFFF59E0B); // Warning Amber
        break;
      case UserStatus.offline:
        statusColor = Colors.grey;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: size * 0.32,
            height: size * 0.32,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? imageUrl;
  final UserStatus status;
  final VoidCallback? onSettingsPressed;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.imageUrl,
    this.status = UserStatus.online,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final initials = name.split(' ').map((e) => e[0]).take(2).join();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          ProfileAvatar(
            initials: initials,
            imageUrl: imageUrl,
            size: 40,
            status: status,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                Text(
                  role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onSettingsPressed != null)
            IconButton(
              icon: Icon(
                Icons.settings_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onSettingsPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

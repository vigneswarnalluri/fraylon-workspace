import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onEdit,
    this.onDelete,
  });

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return AppColors.error;
      case 'Alert':
        return AppColors.warning;
      case 'Notice':
        return AppColors.secondary; // Vibrant Teal
      case 'Info':
      default:
        return AppColors.info; // Enterprise Blue
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Urgent':
        return Icons.gpp_maybe_outlined;
      case 'Alert':
        return Icons.warning_amber_rounded;
      case 'Notice':
        return Icons.campaign_outlined;
      case 'Info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'Just now';
    } else if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityColor = _getPriorityColor(announcement.priority);

    // Left border card wrapper using clip and row strip to handle rounded corners nicely
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : theme.colorScheme.outline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thicker left accent border instead of full border
              Container(
                width: 6,
                color: priorityColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Priority Pill + Title + Actions Popup
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _getPriorityIcon(announcement.priority),
                            size: 16,
                            color: priorityColor,
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              announcement.priority.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                           const Spacer(),
                           // Edit/Delete Dropdown actions
                           if (onEdit != null || onDelete != null)
                             PopupMenuButton<String>(
                               icon: Icon(
                                 Icons.more_horiz_rounded,
                                 size: 20,
                                 color: theme.colorScheme.onSurfaceVariant,
                               ),
                               padding: EdgeInsets.zero,
                               constraints: const BoxConstraints(),
                               onSelected: (value) {
                                 if (value == 'edit' && onEdit != null) {
                                   onEdit!();
                                 } else if (value == 'delete' && onDelete != null) {
                                   onDelete!();
                                 }
                               },
                               itemBuilder: (context) => [
                                 if (onEdit != null)
                                   const PopupMenuItem(
                                     value: 'edit',
                                     child: Row(
                                       children: [
                                         Icon(Icons.edit_outlined, size: 16),
                                         SizedBox(width: 8),
                                         Text('Edit Announcement'),
                                       ],
                                     ),
                                   ),
                                 if (onDelete != null)
                                   PopupMenuItem(
                                     value: 'delete',
                                     child: Row(
                                       children: [
                                         Icon(
                                           Icons.delete_outline_rounded,
                                           size: 16,
                                           color: theme.colorScheme.error,
                                         ),
                                         const SizedBox(width: 8),
                                         Text(
                                           'Delete',
                                           style: TextStyle(color: theme.colorScheme.error),
                                         ),
                                       ],
                                     ),
                                   ),
                               ],
                             ),
                         ],
                       ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        announcement.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Description
                      Text(
                        announcement.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Footer: Author & Timestamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Author Row
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                child: Text(
                                  announcement.author.isNotEmpty
                                      ? announcement.author[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                announcement.author,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          // Relative time
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatRelativeTime(announcement.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

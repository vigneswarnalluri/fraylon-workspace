import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task.dart';
import '../providers/task_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/services/permission_service.dart';

class TaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback onTap;
  final bool showStatus;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.showStatus = true,
  });

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> {
  /// Optimistic override: non-null while we're waiting for Firestore confirmation.
  bool? _pendingCompleted;

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once the stream confirms the new status, clear our local override.
    if (_pendingCompleted != null &&
        widget.task.status != oldWidget.task.status) {
      _pendingCompleted = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userProfile = ref.watch(profileProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.canDeleteTasks(userProfile);

    // Use local optimistic value if pending, otherwise use authoritative stream value.
    final isCompleted = _pendingCompleted ?? (widget.task.status == 'Completed');

    // Build the Card Widget
    final cardWidget = CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      backgroundColor: isCompleted
          ? (isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
              : Colors.grey.shade100)
          : null,
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Fast Quick Status Checkbox
              InkWell(
                onTap: () {
                  final nextIsCompleted = !isCompleted;
                  final nextStatus = nextIsCompleted ? 'Completed' : 'Todo';

                  // Apply optimistic update immediately
                  setState(() => _pendingCompleted = nextIsCompleted);

                  ref
                      .read(taskActionControllerProvider.notifier)
                      .changeTaskStatus(widget.task, nextStatus)
                      .then((success) {
                    // If the operation failed, revert the optimistic state
                    if (!success && mounted) {
                      setState(() => _pendingCompleted = null);
                    }
                  });

                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            nextIsCompleted
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: nextIsCompleted
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            nextIsCompleted
                                ? 'Task completed'
                                : 'Task marked todo',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: theme.colorScheme.primaryContainer,
                        onPressed: () {
                          final undoIsCompleted = !nextIsCompleted;
                          setState(() => _pendingCompleted = undoIsCompleted);
                          ref
                              .read(taskActionControllerProvider.notifier)
                              .changeTaskStatus(
                                widget.task,
                                undoIsCompleted ? 'Completed' : 'Todo',
                              )
                              .then((success) {
                            if (!success && mounted) {
                              setState(() => _pendingCompleted = null);
                            }
                          });
                        },
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isCompleted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      key: ValueKey<bool>(isCompleted),
                      size: 18,
                      color: isCompleted
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Task Title
              Expanded(
                child: Text(
                  widget.task.title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                  ),
                ),
              ),
              if (widget.showStatus) ...[
                const SizedBox(width: 8),
                // Status Pill
                StatusPill(
                  type: _mapStatusToType(widget.task.status),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // One-line Description with Ellipsis
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Text(
              widget.task.description.isEmpty ? 'No description' : widget.task.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          // Footer indicators
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Priority tag
                    _buildPriorityIndicator(theme, widget.task.priority),
                    const SizedBox(width: 8),
                    // Comments indicator count
                    if (widget.task.comments.isNotEmpty) ...[
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.task.comments.length}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    // Assignee indicator
                    if (widget.task.assigneeName != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.task.assigneeName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                // Due Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _isOverdue(widget.task.dueDate) && !isCompleted
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDueDate(widget.task.dueDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: _isOverdue(widget.task.dueDate) && !isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _isOverdue(widget.task.dueDate) && !isCompleted
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Mobile Swipe Gesture Actions Wrapper
    return Dismissible(
      key: Key('swipe_${widget.task.id}'),
      direction: canDelete ? DismissDirection.horizontal : DismissDirection.startToEnd,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right: Complete Task
          final nextStatus = isCompleted ? 'Todo' : 'Completed';
          ref
              .read(taskActionControllerProvider.notifier)
              .changeTaskStatus(widget.task, nextStatus);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isCompleted ? 'Marked task as Todo' : 'Task Completed!'),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (canDelete) {
          // Swipe Left: Delete Task
          ref.read(taskActionControllerProvider.notifier).deleteTask(widget.task.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${widget.task.title}" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(taskActionControllerProvider.notifier).createTask(
                        title: widget.task.title,
                        description: widget.task.description,
                        status: widget.task.status,
                        priority: widget.task.priority,
                        dueDate: widget.task.dueDate,
                      );
                },
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      background: _buildSwipeBackground(
        color: const Color(0xFF69D36E),
        icon: Icons.check_circle_rounded,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
      ),
      secondaryBackground: canDelete
          ? _buildSwipeBackground(
              color: theme.colorScheme.error,
              icon: Icons.delete_rounded,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
            )
          : null,
      child: cardWidget,
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required EdgeInsetsGeometry padding,
  }) {
    return Container(
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildPriorityIndicator(ThemeData theme, String priority) {
    final Color color;
    switch (priority) {
      case 'High':
        color = AppColors.error;
        break;
      case 'Medium':
        color = Colors.amber;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  StatusPillType _mapStatusToType(String status) {
    switch (status) {
      case 'Todo':
        return StatusPillType.todo;
      case 'In Progress':
        return StatusPillType.inProgress;
      case 'Review':
        return StatusPillType.inProgress; // Linear style in-progress mapping
      case 'Completed':
        return StatusPillType.completed;
      default:
        return StatusPillType.todo;
    }
  }

  bool _isOverdue(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) return 'Today';
    if (checkDate == tomorrow) return 'Tomorrow';
    return '${date.day}/${date.month}';
  }
}

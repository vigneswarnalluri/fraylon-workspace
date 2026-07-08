import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task.dart';
import '../providers/task_providers.dart';
import 'task_comments_section.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/services/permission_service.dart';

class TaskDetailsSheet extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailsSheet({
    super.key,
    required this.task,
  });

  static void show(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(task: task),
    );
  }

  @override
  ConsumerState<TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends ConsumerState<TaskDetailsSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _status;
  late String _priority;
  late DateTime _dueDate;
  String? _assigneeId;
  String? _assigneeName;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _status = widget.task.status;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
    _assigneeId = widget.task.assigneeId;
    _assigneeName = widget.task.assigneeName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _dueDate,
      assigneeId: _assigneeId,
      assigneeName: _assigneeName,
    );

    final success = await ref.read(taskActionControllerProvider.notifier).updateTask(updated);
    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task changes saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userProfile = ref.watch(profileProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canDelete = permissionService.canDeleteTasks(userProfile);
    final canEdit = permissionService.canCreateTasks(userProfile);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Safe drag indicator bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Header actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Editing Task' : 'Task Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_isEditing) ...[
                      TextButton(
                        onPressed: () => setState(() => _isEditing = false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                        label: 'Save',
                        width: 76,
                        height: 32,
                        onPressed: _saveChanges,
                      ),
                    ] else ...[
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => setState(() => _isEditing = true),
                          tooltip: 'Edit task properties',
                        ),
                      if (canDelete)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
                          onPressed: () {
                            ref.read(taskActionControllerProvider.notifier).deleteTask(widget.task.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task deleted')),
                            );
                          },
                          tooltip: 'Delete task',
                        ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 8),
                  // Title
                  _isEditing
                      ? TextField(
                          controller: _titleController,
                          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                          decoration: const InputDecoration(
                            labelText: 'Task Title',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        )
                      : Text(
                          widget.task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  const SizedBox(height: 14),
                  // Description
                  _isEditing
                      ? TextField(
                          controller: _descController,
                          maxLines: 3,
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            widget.task.description.isEmpty ? 'No description provided.' : widget.task.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Metadata Attributes Grid
                  Row(
                    children: [
                      if (_isEditing) ...[
                        Expanded(
                          child: CustomDropdown<String>(
                            label: 'Status',
                            value: _status,
                            items: const [
                              DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                              DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'Review', child: Text('Review')),
                              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomDropdown<String>(
                            label: 'Priority',
                            value: _priority,
                            items: const [
                              DropdownMenuItem(value: 'Low', child: Text('Low')),
                              DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                              DropdownMenuItem(value: 'High', child: Text('High')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              StatusPill(type: _mapStatusToType(_status)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              _buildPriorityTag(_priority),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Due Date Selection Row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Due date: ${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      ),
                      if (_isEditing) ...[
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _dueDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (picked != null) {
                              setState(() => _dueDate = picked);
                            }
                          },
                          child: const Text('Change Date'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Assignee Row/Dropdown
                  _isEditing
                      ? Consumer(
                          builder: (context, ref, child) {
                            final usersAsync = ref.watch(allUsersProvider);
                            return usersAsync.when(
                              data: (users) {
                                final items = [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Unassigned'),
                                  ),
                                  ...users.map((u) => DropdownMenuItem<String>(
                                        value: u.uid,
                                        child: Text(u.name),
                                      )),
                                ];

                                return CustomDropdown<String?>(
                                  label: 'Assignee',
                                  value: _assigneeId,
                                  items: items,
                                  onChanged: (val) {
                                    setState(() {
                                      _assigneeId = val;
                                      _assigneeName = val == null
                                          ? null
                                          : users.firstWhere((u) => u.uid == val).name;
                                    });
                                  },
                                );
                              },
                              loading: () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text('Loading members...', style: TextStyle(fontSize: 12)),
                              ),
                              error: (err, stack) => const Text('Error loading members', style: TextStyle(color: Colors.red)),
                            );
                          },
                        )
                      : Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned to: ${_assigneeName ?? 'Unassigned'}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                  if (!_isEditing && _status != 'Completed' && permissionService.canApproveTasks(userProfile)) ...[
                    const SizedBox(height: 16),
                    CustomButton(
                      label: 'Approve Completed Work',
                      width: double.infinity,
                      height: 40,
                      onPressed: () async {
                        setState(() => _status = 'Completed');
                        final updated = widget.task.copyWith(
                          status: 'Completed',
                        );
                        final success = await ref.read(taskActionControllerProvider.notifier).updateTask(updated);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task approved and completed successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                  const Divider(height: 32),
                  // Task Comments UI
                  TaskCommentsSection(task: widget.task),
                  const Divider(height: 32),
                  // History Log Timeline
                  Text(
                    'History Logs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.task.history.reversed.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.action,
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ),
                          Text(
                            '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
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
        return StatusPillType.inProgress;
      case 'Completed':
        return StatusPillType.completed;
      default:
        return StatusPillType.todo;
    }
  }

  Widget _buildPriorityTag(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.redAccent;
        break;
      case 'Medium':
        color = Colors.amber;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

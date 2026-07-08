import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task.dart';
import '../providers/task_providers.dart';
import '../widgets/task_card.dart';
import '../widgets/task_details_sheet.dart';
import '../widgets/calendar_view_widget.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_search_bar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/services/permission_service.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _screenFocusNode = FocusNode();

  String _selectedView = 'List'; // 'List', 'Board', 'Calendar'
  String _activeBoardColumn = 'Todo';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(taskFiltersProvider.notifier).updateSearch(_searchController.text);
    });
    // Request focus on screen for hotkeys
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _screenFocusNode.dispose();
    super.dispose();
  }

  void _showCreateTaskDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedStatus = 'Todo';
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 1));
    String? selectedAssigneeId;
    String? selectedAssigneeName;
 
    CustomDialog.show(
      context: context,
      title: 'Create New Task',
      confirmLabel: 'Create',
      onConfirm: () {
        if (titleController.text.trim().isNotEmpty) {
          ref.read(taskActionControllerProvider.notifier).createTask(
                title: titleController.text.trim(),
                description: descController.text.trim(),
                status: selectedStatus,
                priority: selectedPriority,
                dueDate: selectedDueDate,
                assigneeId: selectedAssigneeId,
                assigneeName: selectedAssigneeName,
              );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully!')),
          );
        }
      },
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Implement checkout',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add details...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Status',
                      value: selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                        DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'Review', child: Text('Review')),
                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedStatus = val);
                      },
                      hint: 'Status',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomDropdown<String>(
                      label: 'Priority',
                      value: selectedPriority,
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedPriority = val);
                      },
                      hint: 'Priority',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Consumer(
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
                        value: selectedAssigneeId,
                        items: items,
                        onChanged: (val) {
                          setDialogState(() {
                            selectedAssigneeId = val;
                            selectedAssigneeName = val == null
                                ? null
                                : users.firstWhere((u) => u.uid == val).name;
                          });
                        },
                        hint: 'Select Assignee',
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Loading members...', style: TextStyle(fontSize: 12)),
                    ),
                    error: (err, stack) => const Text('Error loading members', style: TextStyle(color: Colors.red)),
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due Date: ${selectedDueDate.day}/${selectedDueDate.month}/${selectedDueDate.year}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDueDate = picked);
                      }
                    },
                    child: const Text('Select Date', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // Handle Desktop Keyboard Shortcuts
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Escape key to clear all active filters
      if (key == LogicalKeyboardKey.escape) {
        ref.read(taskFiltersProvider.notifier).clearFilters();
        _searchController.clear();
        _screenFocusNode.requestFocus();
      }

      // '/' to focus Search Bar input field
      if (key == LogicalKeyboardKey.slash) {
        if (!_searchFocusNode.hasFocus) {
          // Delay briefly to swallow the slash character from entering the textfield
          Future.delayed(const Duration(milliseconds: 50), () {
            _searchFocusNode.requestFocus();
          });
        }
      }

      // 'N' key (without search focus) to open Create Task Modal
      if (key == LogicalKeyboardKey.keyN && !_searchFocusNode.hasFocus) {
        final userProfile = ref.read(profileProvider);
        final canCreate = ref.read(permissionServiceProvider).canCreateTasks(userProfile);
        if (canCreate) {
          _showCreateTaskDialog();
        }
      }

      // 'V' key (without search focus) to rotate views
      if (key == LogicalKeyboardKey.keyV && !_searchFocusNode.hasFocus) {
        setState(() {
          if (_selectedView == 'List') {
            _selectedView = 'Board';
          } else if (_selectedView == 'Board') {
            _selectedView = 'Calendar';
          } else {
            _selectedView = 'List';
          }
        });
      }
    }
  }

  Widget _buildInlineFilterChip(
    BuildContext context, {
    required String label,
    required VoidCallback onDelete,
    required Color color,
    required Color textColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.15), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close_rounded,
              size: 11,
              color: isDark ? Colors.white.withValues(alpha: 0.6) : color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentFilters = ref.watch(taskFiltersProvider);
            return SimpleDialog(
              title: Text(
                'Filter Tasks',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Todo', 'In Progress', 'Review', 'Completed'].map((status) {
                    final isSelected = currentFilters.selectedStatuses.contains(status);
                    return FilterChip(
                      label: Text(status, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(taskFiltersProvider.notifier).toggleStatus(status);
                      },
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ['Low', 'Medium', 'High'].map((p) {
                    final isSelected = currentFilters.selectedPriorities.contains(p);
                    return FilterChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(taskFiltersProvider.notifier).togglePriority(p);
                      },
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentFilters.selectedStatuses.isNotEmpty ||
                        currentFilters.selectedPriorities.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          ref.read(taskFiltersProvider.notifier).clearFilters();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Apply', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfile = ref.watch(profileProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canCreate = permissionService.canCreateTasks(userProfile);

    final tasksAsync = ref.watch(filteredTasksProvider);
    final allTasksAsync = ref.watch(tasksStreamProvider);
    final filters = ref.watch(taskFiltersProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 960;

    // Outer Keyboard listener node for keyboard navigation support
    return KeyboardListener(
      focusNode: _screenFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Toolbar Panel
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task Workspace',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isDesktop)
                            Text(
                              'Hotkeys: [/] Search, [N] New Task, [V] Toggle View, [Esc] Clear',
                              style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View mode segment selectors
                        ToggleButtons(
                          isSelected: [
                            _selectedView == 'List',
                            _selectedView == 'Board',
                            _selectedView == 'Calendar'
                          ],
                          onPressed: (index) {
                            setState(() {
                              if (index == 0) _selectedView = 'List';
                              if (index == 1) _selectedView = 'Board';
                              if (index == 2) _selectedView = 'Calendar';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          constraints: BoxConstraints(minWidth: isDesktop ? 56 : 40, minHeight: 32),
                          children: const [
                            Icon(Icons.list_rounded, size: 18),
                            Icon(Icons.grid_view_rounded, size: 18),
                            Icon(Icons.calendar_month_rounded, size: 18),
                          ],
                        ),
                         if (canCreate) ...[
                           const SizedBox(width: 8),
                           IconButton.filled(
                             icon: const Icon(Icons.add_rounded, size: 20),
                             onPressed: _showCreateTaskDialog,
                             style: IconButton.styleFrom(
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),
              // Search & Filter Panel Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Search title/desc...',
                        onFilterPressed: () => _showFilterMenu(context, theme),
                        filters: [
                          ...filters.selectedStatuses.map((status) {
                            return _buildInlineFilterChip(
                              context,
                              label: status,
                              onDelete: () => ref.read(taskFiltersProvider.notifier).toggleStatus(status),
                              color: theme.colorScheme.primary,
                              textColor: theme.colorScheme.primary,
                            );
                          }),
                          ...filters.selectedPriorities.map((priority) {
                            return _buildInlineFilterChip(
                              context,
                              label: priority,
                              onDelete: () => ref.read(taskFiltersProvider.notifier).togglePriority(priority),
                              color: theme.colorScheme.secondary,
                              textColor: theme.colorScheme.secondary,
                            );
                          }),
                        ],
                      ),
                    ),
                    if (filters.selectedStatuses.isNotEmpty ||
                        filters.selectedPriorities.isNotEmpty ||
                        filters.selectedDate != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          ref.read(taskFiltersProvider.notifier).clearFilters();
                          _searchController.clear();
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Task Display Area
              Expanded(
                child: tasksAsync.when(
                  data: (tasks) {
                    if (_selectedView == 'Calendar') {
                      return allTasksAsync.when(
                        data: (allTasks) => SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CalendarViewWidget(allTasks: allTasks),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error loading calendar: $e')),
                      );
                    }

                    if (tasks.isEmpty) {
                      return Center(
                        child: Text(
                          'No tasks match active criteria.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    if (_selectedView == 'Board') {
                      return _buildBoardLayout(tasks, isDesktop);
                    }

                    // Standard list view
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: tasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => TaskDetailsSheet.show(context, task),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, stack) => Center(child: Text('Error loading tasks: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Notion-style KanBan Column Builder
  Widget _buildBoardLayout(List<Task> tasks, bool isDesktop) {
    final theme = Theme.of(context);
    final columns = ['Todo', 'In Progress', 'Review', 'Completed'];

    Widget buildColumn(String status, {bool fullWidth = false}) {
      final colTasks = tasks.where((t) => t.status == status).toList();
      return Container(
        width: fullWidth ? double.infinity : (isDesktop ? 260 : MediaQuery.sizeOf(context).width * 0.75),
        margin: fullWidth ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!fullWidth) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(theme, status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${colTasks.length}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: colTasks.isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Empty Column',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                      ),
                    )
                  : ListView.separated(
                      itemCount: colTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final task = colTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () => TaskDetailsSheet.show(context, task),
                          showStatus: false,
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mobile Segment Picker
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: columns.map((col) {
                  final isActive = _activeBoardColumn == col;
                  final count = tasks.where((t) => t.status == col).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getStatusColor(theme, col),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(col, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Text(
                            '($count)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      selected: isActive,
                      onSelected: (_) {
                        setState(() {
                          _activeBoardColumn = col;
                        });
                      },
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Active Column List (Full Width)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: buildColumn(_activeBoardColumn, fullWidth: true),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: columns.map(buildColumn).toList(),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status) {
      case 'Todo':
        return theme.colorScheme.primary;
      case 'In Progress':
        return const Color(0xFF22C7D6);
      case 'Review':
        return Colors.orangeAccent;
      case 'Completed':
        return const Color(0xFF69D36E);
      default:
        return Colors.grey;
    }
  }
}

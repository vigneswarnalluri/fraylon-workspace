import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_chart.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_search_bar.dart';
import '../../../../core/widgets/quick_actions.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task.dart';

// ---------------------------------------------------------------------------
// Dashboard Models & State
// ---------------------------------------------------------------------------

class DashboardTask {
  final String id;
  final String title;
  final bool isCompleted;
  final String priority; // 'High', 'Medium', 'Low'
  final String dueDate;

  DashboardTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.priority,
    required this.dueDate,
  });

  DashboardTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? priority,
    String? dueDate,
  }) {
    return DashboardTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

class DashboardState {
  final List<DashboardTask> tasks;
  final String searchFilter;
  final List<String> notifications;
  final bool showNotifications;

  DashboardState({
    required this.tasks,
    required this.searchFilter,
    required this.notifications,
    this.showNotifications = false,
  });

  DashboardState copyWith({
    List<DashboardTask>? tasks,
    String? searchFilter,
    List<String>? notifications,
    bool? showNotifications,
  }) {
    return DashboardState(
      tasks: tasks ?? this.tasks,
      searchFilter: searchFilter ?? this.searchFilter,
      notifications: notifications ?? this.notifications,
      showNotifications: showNotifications ?? this.showNotifications,
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Notifier & Provider
// ---------------------------------------------------------------------------

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier()
      : super(DashboardState(
          tasks: [
            DashboardTask(
              id: '1',
              title: 'Refactor Auth middleware integrations',
              isCompleted: false,
              priority: 'High',
              dueDate: 'Today, 5 PM',
            ),
            DashboardTask(
              id: '2',
              title: 'Review Design System feedback',
              isCompleted: true,
              priority: 'Medium',
              dueDate: 'Today, 2 PM',
            ),
            DashboardTask(
              id: '3',
              title: 'Upgrade Flutter engine release version',
              isCompleted: false,
              priority: 'Low',
              dueDate: 'Tomorrow',
            ),
            DashboardTask(
              id: '4',
              title: 'Establish core layout responsive configs',
              isCompleted: false,
              priority: 'High',
              dueDate: 'Today, 6 PM',
            ),
          ],
          searchFilter: '',
          notifications: [
            'Security audit finished successfully.',
            'User settings updated in the workspace.',
            'Production build pipeline verified.',
          ],
        ));

  void toggleTask(String id) {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id == id) {
          return t.copyWith(isCompleted: !t.isCompleted);
        }
        return t;
      }).toList(),
    );
  }

  void addTask(String title, String priority, String dueDate) {
    final newTask = DashboardTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isCompleted: false,
      priority: priority,
      dueDate: dueDate,
    );
    state = state.copyWith(
      tasks: [...state.tasks, newTask],
    );
  }

  void updateSearch(String query) {
    state = state.copyWith(searchFilter: query);
  }

  void toggleNotifications() {
    state = state.copyWith(showNotifications: !state.showNotifications);
  }

  void clearNotifications() {
    state = state.copyWith(notifications: []);
  }

  void clearCompleted() {
    state = state.copyWith(
      tasks: state.tasks.where((t) => !t.isCompleted).toList(),
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});



// ---------------------------------------------------------------------------
// HomeScreen View
// ---------------------------------------------------------------------------

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(dashboardProvider.notifier).updateSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedDueDate = 'Today, 5 PM';

    CustomDialog.show(
      context: context,
      title: 'Create New Task',
      confirmLabel: 'Add Task',
      onConfirm: () {
        if (titleController.text.trim().isNotEmpty) {
          DateTime due;
          final now = DateTime.now();
          if (selectedDueDate == 'Today, 5 PM') {
            due = DateTime(now.year, now.month, now.day, 17, 0);
          } else if (selectedDueDate == 'Tomorrow') {
            due = DateTime(now.year, now.month, now.day + 1, 12, 0);
          } else {
            due = now.add(const Duration(days: 7));
          }
          ref.read(taskActionControllerProvider.notifier).createTask(
                title: titleController.text.trim(),
                description: 'Created from Home screen Quick Add.',
                status: 'Todo',
                priority: selectedPriority,
                dueDate: due,
              );
          Navigator.pop(context);
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
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  hintText: 'e.g. Upgrade packages',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['Low', 'Medium', 'High'].map((p) {
                  final isSelected = selectedPriority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(p),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedPriority = p);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Due Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedDueDate,
                items: const [
                  DropdownMenuItem(value: 'Today, 5 PM', child: Text('Today, 5 PM')),
                  DropdownMenuItem(value: 'Tomorrow', child: Text('Tomorrow')),
                  DropdownMenuItem(value: 'Next Week', child: Text('Next Week')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedDueDate = val);
                },
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(dashboardProvider);
    final userNameAsync = ref.watch(userDisplayNameProvider);
    final announcementsAsync = ref.watch(announcementsStreamProvider);
    final unreadNotificationsCount = ref.watch(unreadNotificationsCountProvider);

    // Live tasks from stream
    final allTasksAsync = ref.watch(tasksStreamProvider);
    final tasksList = allTasksAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <Task>[],
    );

    // Compute stats
    final totalTasks = tasksList.length;
    final completedTasks = tasksList.where((t) => t.status == 'Completed').length;
    final pendingTasks = totalTasks - completedTasks;
    
    final now = DateTime.now();
    final overdueTasks = tasksList.where((t) => t.status != 'Completed' && t.dueDate.isBefore(now)).length;
    
    final completionRate = totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

    // Filtered tasks based on search bar
    final filteredTasks = tasksList.where((t) {
      return t.title.toLowerCase().contains(state.searchFilter.toLowerCase());
    }).toList();

    // Compute last 7 days completed tasks counts for Weekly Productivity Chart
    final chartData = List<double>.filled(7, 0);
    final todayMidnight = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 7; i++) {
      final targetDay = todayMidnight.subtract(Duration(days: 6 - i));
      final nextDay = targetDay.add(const Duration(days: 1));
      
      final completedOnDayCount = tasksList.where((t) {
        if (t.status != 'Completed') return false;
        return t.updatedAt.isAfter(targetDay) && t.updatedAt.isBefore(nextDay);
      }).length;
      
      chartData[i] = completedOnDayCount.toDouble();
    }

    // Mapped Recent Activity items from Firestore tasks history
    final List<({String user, String action, String target, DateTime timestamp})> activityItems = [];
    for (var task in tasksList) {
      for (var entry in task.history) {
        String actionType = 'updated';
        if (entry.action.toLowerCase().contains('created')) {
          actionType = 'created';
        } else if (entry.action.toLowerCase().contains('status from')) {
          final parts = entry.action.split(' to ');
          if (parts.length > 1) {
            actionType = parts[1].toLowerCase() == 'completed' ? 'completed' : 'changed status to ${parts[1].toLowerCase()}';
          } else {
            actionType = 'updated status';
          }
        } else if (entry.action.toLowerCase().contains('comment')) {
          actionType = 'added comment to';
        }
        
        activityItems.add((
          user: task.assigneeName ?? 'Someone',
          action: actionType,
          target: task.title,
          timestamp: entry.timestamp,
        ));
      }
    }
    
    activityItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final recentActivitiesList = activityItems.take(5).toList();

    String formatTimeAgo(DateTime dateTime) {
      final diff = DateTime.now().difference(dateTime);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${diff.inDays}d ago';
    }

    // Responsive design widths
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 960;

    // Header Welcome Banner
    final String greeting = userNameAsync.when(
      data: (name) => 'Good morning, ${name.split(" ")[0]}',
      loading: () => 'Good morning',
      error: (_, _) => 'Good morning',
    );

    final deadlinesCount = tasksList
        .where((t) =>
            t.status != 'Completed' &&
            t.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
            t.dueDate.isBefore(now.add(const Duration(days: 7))))
        .length;

    final welcomeBanner = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Today\'s summary: $pendingTasks pending tasks and $deadlinesCount deadlines.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            // Notifications Bell with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    unreadNotificationsCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    size: 22,
                  ),
                  onPressed: () {
                    context.go('/notifications');
                  },
                ),
                if (unreadNotificationsCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            // Current Date Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatCurrentDate(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // Quick Stats Grid Section
    final statsGrid = LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: columns == 4 ? 1.6 : 1.45,
          children: [
            _buildStatCard(
              title: 'Pending Tasks',
              value: '$pendingTasks',
              icon: Icons.assignment_late_outlined,
              color: theme.colorScheme.primary,
              trendText: 'active',
              trendColor: theme.colorScheme.primary,
              context: context,
            ),
            _buildStatCard(
              title: 'Completed',
              value: '$completedTasks',
              icon: Icons.assignment_turned_in_outlined,
              color: const Color(0xFF10B981),
              trendText: '+12% wk',
              trendColor: const Color(0xFF10B981),
              context: context,
            ),
            _buildStatCard(
              title: 'Overdue Tasks',
              value: '$overdueTasks',
              icon: Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              trendText: 'needs action',
              trendColor: theme.colorScheme.error,
              context: context,
            ),
            _buildStatCard(
              title: 'Completion %',
              value: '$completionRate%',
              icon: Icons.donut_large_rounded,
              color: const Color(0xFF22C7D6),
              trendText: 'overall',
              trendColor: const Color(0xFF22C7D6),
              isProgress: true,
              progressValue: totalTasks == 0 ? 0.0 : (completedTasks / totalTasks),
              context: context,
            ),
          ],
        );
      },
    );

    // Weekly Productivity Chart
    final productivityChart = CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Productivity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Weekly completed tasks index',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomChart(
            data: chartData,
            height: 110,
          ),
        ],
      ),
    );

    // Today's Tasks Component
    final todayTasksCard = CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (completedTasks > 0)
                TextButton(
                  onPressed: () {
                    final completedList = tasksList.where((t) => t.status == 'Completed').toList();
                    for (var t in completedList) {
                      ref.read(taskActionControllerProvider.notifier).deleteTask(t.id);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared completed tasks.')),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Clear completed',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          filteredTasks.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Text(
                    state.searchFilter.isEmpty ? 'No tasks found. Create one!' : 'No search matches.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final isCompleted = task.status == 'Completed';
                    return InkWell(
                      onTap: () {
                        final nextStatus = isCompleted ? 'Todo' : 'Completed';
                        ref.read(taskActionControllerProvider.notifier).changeTaskStatus(task, nextStatus);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isCompleted ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: isCompleted ? const Color(0xFF69D36E) : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                task.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                  color: isCompleted ? theme.colorScheme.onSurfaceVariant : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPriorityPill(task.priority),
                            const SizedBox(width: 8),
                            Text(
                              '${task.dueDate.day}/${task.dueDate.month}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );

    final in7Days = now.add(const Duration(days: 7));

    final upcomingTasks = allTasksAsync.when(
      data: (tasks) => tasks
          .where((t) =>
              t.status != 'Completed' &&
              t.dueDate.isAfter(now.subtract(const Duration(days: 1))) &&
              t.dueDate.isBefore(in7Days))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate)),
      loading: () => <Task>[],
      error: (_, __) => <Task>[],
    );

    String deadlineLabel(DateTime due) {
      final diff = due.difference(now);
      if (diff.inHours < 1) return 'Due soon';
      if (diff.inHours < 24) return '${diff.inHours}h left';
      if (diff.inDays == 1) return 'Tomorrow';
      return '${due.day}/${due.month}';
    }

    Color deadlineColor(DateTime due, ThemeData t) {
      final h = due.difference(now).inHours;
      if (h < 6) return t.colorScheme.error;
      if (h < 24) return Colors.orange;
      return t.colorScheme.primary;
    }

    final upcomingDeadlines = CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Deadlines',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (upcomingTasks.isNotEmpty)
                Text(
                  '${upcomingTasks.length} tasks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          allTasksAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
            error: (_, __) => const Text('Failed to load', style: TextStyle(fontSize: 12, color: Colors.grey)),
            data: (_) {
              if (upcomingTasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('No deadlines in the next 7 days.',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingTasks.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, i) {
                  final task = upcomingTasks[i];
                  final dColor = deadlineColor(task.dueDate, theme);
                  return _buildDeadlineRow(
                    title: task.title,
                    timeLeft: deadlineLabel(task.dueDate),
                    project: task.priority,
                    color: dColor,
                    onTap: () => context.go('/tasks'),
                  );
                },
              );
            },
          ),
        ],
      ),
    );

    // Recent Activity Timeline
    final recentActivity = CustomCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (recentActivitiesList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No activity logged yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...recentActivitiesList.asMap().entries.map((e) {
              final index = e.key;
              final act = e.value;
              final isLast = index == recentActivitiesList.length - 1;
              return _buildActivityTimelineItem(
                user: act.user,
                action: act.action,
                target: act.target,
                time: formatTimeAgo(act.timestamp),
                isLast: isLast,
              );
            }),
        ],
      ),
    );

    // Recent Announcements Component
    final recentAnnouncements = CustomCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go('/announcements'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Announcements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          announcementsAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No active announcements.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                );
              }
              final displayList = list.take(2).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                itemBuilder: (context, index) {
                  final ann = displayList[index];
                  final dateStr = _formatAnnouncementDate(ann.createdAt);
                  return _buildAnnouncementRow(
                    title: ann.title,
                    date: dateStr,
                    description: ann.description,
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const Text(
              'Failed to load announcements.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    // Quick Actions Component
    final quickActions = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 8),
        QuickActions(
          crossAxisCount: isDesktop ? 2 : 3,
          actions: [
            QuickActionItem(
              label: 'New Task',
              icon: Icons.add_task_rounded,
              color: theme.colorScheme.primary,
              onTap: () => _showAddTaskDialog(context),
            ),
            QuickActionItem(
              label: 'Invite Colleague',
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _showInviteMemberDialog(context),
            ),
            QuickActionItem(
              label: 'Post Update',
              icon: Icons.campaign_rounded,
              color: const Color(0xFF22C7D6),
              onTap: () => context.go('/announcements'),
            ),
            QuickActionItem(
              label: 'Workspace settings',
              icon: Icons.settings_applications_rounded,
              color: Colors.orange,
              onTap: () => context.go('/profile'),
            ),
            QuickActionItem(
              label: 'Toggle Theme',
              icon: Icons.brightness_medium_rounded,
              color: Colors.purple,
              onTap: () {
                final currentMode = ref.read(themeProvider);
                final nextMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                ref.read(themeProvider.notifier).setThemeMode(nextMode);
              },
            ),
            QuickActionItem(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              color: theme.colorScheme.error,
              onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ],
    );

    // Search bar component
    final searchWidget = CustomSearchBar(
      controller: _searchController,
      hintText: 'Search tasks...',
    );

    // Notification Dropdown Panel
    final notificationsOverlay = const SizedBox.shrink();

    // Main layout arrangements
    Widget bodyContent;
    if (isDesktop) {
      bodyContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Left Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _animate(statsGrid, 0),
                const SizedBox(height: 12),
                _animate(productivityChart, 1),
                const SizedBox(height: 12),
                _animate(Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: todayTasksCard),
                    const SizedBox(width: 12),
                    Expanded(child: upcomingDeadlines),
                  ],
                ), 2),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Sidebar Right Column
          SizedBox(
            width: 310,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _animate(searchWidget, 3),
                const SizedBox(height: 16),
                _animate(quickActions, 4),
                const SizedBox(height: 16),
                _animate(recentActivity, 5),
                const SizedBox(height: 12),
                _animate(recentAnnouncements, 6),
              ],
            ),
          ),
        ],
      );
    } else {
      // Mobile / Tablet Stacked Layout
      bodyContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _animate(statsGrid, 0),
          const SizedBox(height: 12),
          _animate(productivityChart, 1),
          const SizedBox(height: 12),
          _animate(searchWidget, 2),
          const SizedBox(height: 8),
          _animate(todayTasksCard, 3),
          const SizedBox(height: 12),
          _animate(upcomingDeadlines, 4),
          const SizedBox(height: 12),
          _animate(quickActions, 5),
          const SizedBox(height: 12),
          _animate(recentActivity, 6),
          const SizedBox(height: 12),
          _animate(recentAnnouncements, 7),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              welcomeBanner,
              const SizedBox(height: 12),
              notificationsOverlay,
              bodyContent,
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4EE6), Color(0xFF22C7D6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4EE6).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.go('/assistant');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bolt_rounded, color: Colors.white),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget Helpers
  // ---------------------------------------------------------------------------

  Widget _animate(Widget child, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  void _showInviteMemberDialog(BuildContext context) {
    final emailController = TextEditingController();
    CustomDialog.show(
      context: context,
      title: 'Invite Team Member',
      confirmLabel: 'Send Invite',
      onConfirm: () {
        if (emailController.text.trim().isNotEmpty) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invitation sent to ${emailController.text.trim()}!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Invite colleagues to join your Fraylon enterprise workspace.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            autofocus: true,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'colleague@fraylontech.com',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trendText,
    required Color trendColor,
    bool isProgress = false,
    double progressValue = 0.0,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    if (title.contains('Pending')) {
      bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF);
    } else if (title.contains('Completed')) {
      bg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFECFDF5);
    } else if (title.contains('Overdue')) {
      bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2);
    } else {
      bg = isDark ? const Color(0xFF172554).withValues(alpha: 0.2) : const Color(0xFFF0FDFA);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.12),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontSize: 10,
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      trendText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isProgress) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 4,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityPill(String priority) {
    Color color;
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeadlineRow({
    required String title,
    required String timeLeft,
    required String project,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                project,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeLeft,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 14, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementRow({
    required String title,
    required String date,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatAnnouncementDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative) return 'Just now';
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.month}/${dt.day}';
  }

  Widget _buildActivityTimelineItem({
    required String user,
    required String action,
    required String target,
    required String time,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1,
                height: 32,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  children: [
                    TextSpan(
                      text: '$user ',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    TextSpan(text: '$action '),
                    TextSpan(
                      text: target,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatCurrentDate() {
  final date = DateTime.now();
  final weekday = _weekdayName(date.weekday);
  final month = _monthName(date.month);
  return '$weekday, $month ${date.day}';
}

String _weekdayName(int weekday) {
  switch (weekday) {
    case 1: return 'Monday';
    case 2: return 'Tuesday';
    case 3: return 'Wednesday';
    case 4: return 'Thursday';
    case 5: return 'Friday';
    case 6: return 'Saturday';
    case 7: return 'Sunday';
    default: return '';
  }
}

String _monthName(int month) {
  switch (month) {
    case 1: return 'Jan';
    case 2: return 'Feb';
    case 3: return 'Mar';
    case 4: return 'Apr';
    case 5: return 'May';
    case 6: return 'Jun';
    case 7: return 'Jul';
    case 8: return 'Aug';
    case 9: return 'Sep';
    case 10: return 'Oct';
    case 11: return 'Nov';
    case 12: return 'Dec';
    default: return '';
  }
}

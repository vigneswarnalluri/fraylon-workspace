import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/domain/models/task.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/presentation/widgets/task_card.dart';
import '../../../tasks/presentation/widgets/task_details_sheet.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/services/permission_service.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  String _selectedView = 'Month'; // 'Month', 'Week', 'Day', 'Agenda'
  DateTime _focusedDate = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  // Helper lists for week start
  List<DateTime> _getDaysInWeek(DateTime weekStart) {
    // Find the Monday of the week containing weekStart
    final dayOfWeek = weekStart.weekday;
    final monday = weekStart.subtract(Duration(days: dayOfWeek - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final dayOfWeek = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final startOffset = dayOfWeek - 1;

    final days = <DateTime>[];

    final prevMonth = DateTime(month.year, month.month - 1);
    final daysInPrevMonth = DateTime(month.year, month.month, 0).day;
    for (int i = startOffset - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
    }

    final daysInCurrentMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int i = 1; i <= daysInCurrentMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    final totalCells = ((days.length / 7).ceil()) * 7;
    final nextMonth = DateTime(month.year, month.month + 1);
    final remainingCells = totalCells - days.length;
    for (int i = 1; i <= remainingCells; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    return days;
  }

  void _navigatePrevious() {
    setState(() {
      if (_selectedView == 'Month') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
      } else if (_selectedView == 'Week') {
        _focusedDate = _focusedDate.subtract(const Duration(days: 7));
      } else {
        _focusedDate = _focusedDate.subtract(const Duration(days: 1));
      }
    });
  }

  void _navigateNext() {
    setState(() {
      if (_selectedView == 'Month') {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
      } else if (_selectedView == 'Week') {
        _focusedDate = _focusedDate.add(const Duration(days: 7));
      } else {
        _focusedDate = _focusedDate.add(const Duration(days: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasksAsync = ref.watch(tasksStreamProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 960;

    final userProfile = ref.watch(profileProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canCreateTasks = permissionService.canCreateTasks(userProfile);

    return Scaffold(
      body: SafeArea(
        child: tasksAsync.when(
          data: (tasks) {
            final pageHeader = Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calendar Schedule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage deadlines, tasks timeline, and schedules.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canCreateTasks)
                  IconButton.filled(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    tooltip: 'Create New Task',
                    onPressed: () => _showCreateTaskDialog(context, ref),
                  ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  pageHeader,
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 16),
                  // Top navigation row
                  _buildHeaderRow(theme, screenWidth < 600),
                  const SizedBox(height: 12),
                  // Animated Calendar Body switcher
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      // Key forces transition animation on months/views switch
                      key: ValueKey('${_selectedView}_${_focusedDate.year}_${_focusedDate.month}_${_focusedDate.day}'),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _buildSelectedCalendarBody(tasks, isDesktop),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading calendar tasks: $e')),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme, bool isMobile) {
    Widget buildViewSwitcher() {
      final views = ['Month', 'Week', 'Day', 'Agenda'];
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: views.map((view) {
            final isSelected = _selectedView == view;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedView = view;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  view,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    onPressed: _navigatePrevious,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getHeaderTitle(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onPressed: _navigateNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _focusedDate = DateTime.now();
                    _selectedDate = DateTime.now();
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(child: buildViewSwitcher()),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              onPressed: _navigatePrevious,
            ),
            const SizedBox(width: 4),
            Text(
              _getHeaderTitle(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onPressed: _navigateNext,
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime.now();
                  _selectedDate = DateTime.now();
                });
              },
              child: const Text('Today', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        buildViewSwitcher(),
      ],
    );
  }

  Widget _buildSelectedCalendarBody(List<Task> tasks, bool isDesktop) {
    switch (_selectedView) {
      case 'Week':
        return _buildWeekView(tasks, isDesktop);
      case 'Day':
        return _buildDayView(tasks, isDesktop);
      case 'Agenda':
        return _buildAgendaView(tasks);
      default:
        return _buildMonthView(tasks, isDesktop);
    }
  }

  // ---------------------------------------------------------------------------
  // MONTH VIEW
  // ---------------------------------------------------------------------------

  Widget _buildMonthView(List<Task> tasks, bool isDesktop) {
    final theme = Theme.of(context);
    final days = _getDaysInMonth(_focusedDate);

    final selectedTasks = tasks.where((t) {
      if (_selectedDate == null) return false;
      return t.dueDate.year == _selectedDate!.year &&
          t.dueDate.month == _selectedDate!.month &&
          t.dueDate.day == _selectedDate!.day;
    }).toList();

    final monthGrid = Column(
      children: [
        // Days labels row
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
            return Expanded(
              child: Center(
                child: Text(
                  d,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        CustomCard(
          padding: EdgeInsets.zero,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == _focusedDate.month;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;
                final isSelected = _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                // Tasks due on this day
                final dayTasks = tasks.where((t) {
                  return t.dueDate.year == date.year &&
                      t.dueDate.month == date.month &&
                      t.dueDate.day == date.day;
                }).toList();

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : (isToday
                              ? theme.colorScheme.primary.withValues(alpha: 0.05)
                              : Colors.transparent),
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 1)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day number
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: isToday
                              ? BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? Colors.white
                                  : (isCurrentMonth
                                      ? null
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Micro task badges / indicators
                        if (dayTasks.isNotEmpty) ...[
                          if (isDesktop)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: dayTasks.take(2).map((t) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(t.priority).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t.title,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: _getPriorityColor(t.priority),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: dayTasks.take(3).map((t) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(left: 2),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(t.priority),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                          if (dayTasks.length > 2 && isDesktop)
                            Padding(
                              padding: const EdgeInsets.only(top: 1, left: 2),
                              child: Text(
                                '+${dayTasks.length - 2} more',
                                style: const TextStyle(fontSize: 7.5, color: Colors.grey),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: monthGrid),
          const SizedBox(width: 16),
          // Sidebar Day Previews
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Overview: ${_selectedDate != null ? "${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}" : "Today"}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: selectedTasks.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text('No tasks due on this date.'),
                        )
                      : ListView.separated(
                          itemCount: selectedTasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = selectedTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () => TaskDetailsSheet.show(context, task),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          monthGrid,
          const SizedBox(height: 16),
          // Mobile layout day task list below
          Text(
            'Tasks for ${_selectedDate != null ? "${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}" : "Today"}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          selectedTasks.isEmpty
              ? Container(
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No tasks due this day.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: selectedTasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final task = selectedTasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => TaskDetailsSheet.show(context, task),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WEEK VIEW
  // ---------------------------------------------------------------------------

  Widget _buildWeekView(List<Task> tasks, bool isDesktop) {
    final theme = Theme.of(context);
    final days = _getDaysInWeek(_focusedDate);

    if (!isDesktop) {
      final selectedDayTasks = tasks.where((t) {
        return t.dueDate.year == _selectedDate!.year &&
            t.dueDate.month == _selectedDate!.month &&
            t.dueDate.day == _selectedDate!.day;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: days.map((d) {
                final isToday = d.year == DateTime.now().year &&
                    d.month == DateTime.now().month &&
                    d.day == DateTime.now().day;
                final isSelected = _selectedDate != null &&
                    d.year == _selectedDate!.year &&
                    d.month == _selectedDate!.month &&
                    d.day == _selectedDate!.day;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = d;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isToday
                              ? theme.colorScheme.primary.withValues(alpha: 0.1)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getWeekdayInitial(d.weekday),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: isSelected ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : (isToday ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tasks for ${_selectedDate != null ? "${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}" : "Selected Day"}',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: selectedDayTasks.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No tasks due this day.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  )
                : ListView.separated(
                    itemCount: selectedDayTasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final task = selectedDayTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () => TaskDetailsSheet.show(context, task),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Days Row Header
        Row(
          children: days.map((d) {
            final isToday = d.year == DateTime.now().year &&
                d.month == DateTime.now().month &&
                d.day == DateTime.now().day;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: isToday
                    ? BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      )
                    : null,
                child: Column(
                  children: [
                    Text(
                      _getWeekdayInitial(d.weekday),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isToday ? theme.colorScheme.primary : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        // Columns Layout
        Expanded(
          child: Row(
            children: days.map((d) {
              final dayTasks = tasks.where((t) {
                return t.dueDate.year == d.year &&
                    t.dueDate.month == d.month &&
                    t.dueDate.day == d.day;
              }).toList();

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: dayTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Free',
                            style: TextStyle(fontSize: 8, color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: dayTasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final task = dayTasks[index];
                            return _buildMicroTaskCard(theme, task);
                          },
                        ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DAY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildDayView(List<Task> tasks, bool isDesktop) {
    final theme = Theme.of(context);
    final dayTasks = tasks.where((t) {
      return t.dueDate.year == _focusedDate.year &&
          t.dueDate.month == _focusedDate.month &&
          t.dueDate.day == _focusedDate.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Timeline logs for today',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: dayTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      const Text('No tasks due today.'),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: dayTasks.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final task = dayTasks[index];
                    return TaskCard(
                      task: task,
                      onTap: () => TaskDetailsSheet.show(context, task),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AGENDA VIEW
  // ---------------------------------------------------------------------------

  Widget _buildAgendaView(List<Task> tasks) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayTasks = tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate == today;
    }).toList();

    final upcomingTasks = tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate.isAfter(today);
    }).toList();

    final overdueDeadlines = tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return taskDate.isBefore(today) && t.status != 'Completed';
    }).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // Overdue category
        if (overdueDeadlines.isNotEmpty) ...[
          _buildAgendaHeader(theme, 'Critical Overdue Deadlines', theme.colorScheme.error),
          const SizedBox(height: 8),
          ...overdueDeadlines.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TaskCard(
                  task: t,
                  onTap: () => TaskDetailsSheet.show(context, t),
                ),
              )),
          const SizedBox(height: 20),
        ],

        // Today category
        _buildAgendaHeader(theme, 'Today\'s Agenda', theme.colorScheme.primary),
        const SizedBox(height: 8),
        todayTasks.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                child: Text('No tasks due today.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            : Column(
                children: todayTasks
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskCard(
                            task: t,
                            onTap: () => TaskDetailsSheet.show(context, t),
                          ),
                        ))
                    .toList(),
              ),
        const SizedBox(height: 20),

        // Upcoming category
        _buildAgendaHeader(theme, 'Upcoming Deadlines', const Color(0xFF22C7D6)),
        const SizedBox(height: 8),
        upcomingTasks.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 4.0),
                child: Text('No upcoming tasks.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
            : Column(
                children: upcomingTasks
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TaskCard(
                            task: t,
                            onTap: () => TaskDetailsSheet.show(context, t),
                          ),
                        ))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildAgendaHeader(ThemeData theme, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OTHER MICRO BUILD HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildMicroTaskCard(ThemeData theme, Task task) {
    final color = _getPriorityColor(task.priority);
    return InkWell(
      onTap: () => TaskDetailsSheet.show(context, task),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                task.priority,
                style: TextStyle(color: color, fontSize: 6.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent;
      case 'Medium':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getWeekdayInitial(int weekday) {
    switch (weekday) {
      case 1: return 'M';
      case 2: return 'T';
      case 3: return 'W';
      case 4: return 'T';
      case 5: return 'F';
      case 6: return 'S';
      case 7: return 'S';
      default: return '';
    }
  }

  String _getHeaderTitle() {
    if (_selectedView == 'Month') {
      return '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}';
    } else if (_selectedView == 'Week') {
      final weekStart = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      return '${weekStart.day} ${_getMonthName(weekStart.month).substring(0, 3)} — ${weekEnd.day} ${_getMonthName(weekEnd.month).substring(0, 3)}';
    } else {
      return '${_focusedDate.day} ${_getMonthName(_focusedDate.month)} ${_focusedDate.year}';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedPriority = 'Medium';
    String selectedStatus = 'Todo';
    DateTime selectedDueDate = _selectedDate ?? DateTime.now().add(const Duration(days: 1));

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
}

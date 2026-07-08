import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/task.dart';

import 'task_card.dart';
import 'task_details_sheet.dart';
import '../../../../core/widgets/custom_card.dart';

class CalendarViewWidget extends ConsumerStatefulWidget {
  final List<Task> allTasks;

  const CalendarViewWidget({
    super.key,
    required this.allTasks,
  });

  @override
  ConsumerState<CalendarViewWidget> createState() => _CalendarViewWidgetState();
}

class _CalendarViewWidgetState extends ConsumerState<CalendarViewWidget> {
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate = DateTime.now();

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final dayOfWeek = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final startOffset = dayOfWeek - 1; // start from Monday

    final days = <DateTime>[];

    // Add padding days from the previous month
    final prevMonth = DateTime(month.year, month.month - 1);
    final daysInPrevMonth = DateTime(month.year, month.month, 0).day;
    for (int i = startOffset - 1; i >= 0; i--) {
      days.add(DateTime(prevMonth.year, prevMonth.month, daysInPrevMonth - i));
    }

    // Add days of the current month
    final daysInCurrentMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int i = 1; i <= daysInCurrentMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    // Add padding days for the next month to fill complete weeks (rows of 7)
    final totalCells = ((days.length / 7).ceil()) * 7;
    final nextMonth = DateTime(month.year, month.month + 1);
    final remainingCells = totalCells - days.length;
    for (int i = 1; i <= remainingCells; i++) {
      days.add(DateTime(nextMonth.year, nextMonth.month, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final days = _getDaysInMonth(_currentMonth);

    // Get the tasks that are due on the selected date
    final selectedTasks = widget.allTasks.where((t) {
      if (_selectedDate == null) return false;
      return t.dueDate.year == _selectedDate!.year &&
          t.dueDate.month == _selectedDate!.month &&
          t.dueDate.day == _selectedDate!.day;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calendar Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                    });
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime.now();
                      _selectedDate = DateTime.now();
                    });
                  },
                  child: const Text('Today', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Day Names Header row
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Days Grid view
        CustomCard(
          padding: EdgeInsets.zero,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final isCurrentMonth = date.month == _currentMonth.month;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;

              // Check if there are tasks due on this date
              final hasTasks = widget.allTasks.any((t) {
                return t.dueDate.year == date.year &&
                    t.dueDate.month == date.month &&
                    t.dueDate.day == date.day;
              });

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
                            fontSize: 11,
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Colors.white
                                : (isSelected
                                    ? theme.colorScheme.primary
                                    : (isCurrentMonth
                                        ? theme.textTheme.bodyMedium?.color
                                        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4))),
                          ),
                        ),
                      ),
                      if (hasTasks) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : theme.colorScheme.primary,
                            shape: BoxShape.circle,
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
        const SizedBox(height: 16),
        // Selected Date Task Sub-List
        if (_selectedDate != null) ...[
          Text(
            'Tasks for ${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          selectedTasks.isEmpty
              ? Container(
                  height: 60,
                  alignment: Alignment.center,
                  child: Text(
                    'No tasks due this day.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
        ],
      ],
    );
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
}

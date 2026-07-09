import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/states_widgets.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';
import '../../domain/models/app_notification.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  String _selectedTab = 'Unread'; // 'Unread', 'Read'

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return AppColors.error;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
      default:
        return Colors.grey;
    }
  }

  void _showMobileFilterSheet(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(notificationFiltersProvider);
            final allAsync = ref.watch(notificationsStreamProvider);
            
            final taskCount = allAsync.maybeWhen(
              data: (list) => list.where((n) => n.category == 'Task' && !n.isRead).length,
              orElse: () => 0,
            );
            final annCount = allAsync.maybeWhen(
              data: (list) => list.where((n) => n.category == 'Announcement' && !n.isRead).length,
              orElse: () => 0,
            );
            final sysCount = allAsync.maybeWhen(
              data: (list) => list.where((n) => n.category == 'System' && !n.isRead).length,
              orElse: () => 0,
            );

            final isDark = theme.brightness == Brightness.dark;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters & Overview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(notificationFiltersProvider.notifier).selectCategory('All');
                            ref.read(notificationFiltersProvider.notifier).selectPriority('All');
                            Navigator.pop(context);
                          },
                          child: const Text('Reset All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    const SizedBox(height: 8),
                    Text(
                      'Filter by Category',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Task', 'Announcement', 'System'].map((cat) {
                        final isSel = filters.selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          selectedColor: theme.colorScheme.primary,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          onSelected: (_) {
                            ref.read(notificationFiltersProvider.notifier).selectCategory(cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Filter by Priority',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', 'Urgent', 'High', 'Medium', 'Low'].map((pri) {
                        final isSel = filters.selectedPriority == pri;
                        final priColor = pri == 'All' ? theme.colorScheme.primary : _getPriorityColor(pri);
                        return ChoiceChip(
                          label: Text(pri),
                          selected: isSel,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          selectedColor: priColor,
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          onSelected: (_) {
                            ref.read(notificationFiltersProvider.notifier).selectPriority(pri);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    CustomCard(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: isDark ? Colors.transparent : Colors.grey.shade50.withValues(alpha: 0.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unread Inbox Status',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildCountOverviewRow('Task Alerts', taskCount, AppColors.info),
                          const Divider(height: 12),
                          _buildCountOverviewRow('Announcements', annCount, AppColors.secondary),
                          const Divider(height: 12),
                          _buildCountOverviewRow('System Warnings', sysCount, AppColors.warning),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredAsync = ref.watch(filteredNotificationsProvider);
    final allAsync = ref.watch(notificationsStreamProvider);
    final filters = ref.watch(notificationFiltersProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final totalRead = allAsync.maybeWhen(
      data: (list) => list.where((n) => n.isRead).length,
      orElse: () => 0,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 800;

    // Header Toolbar Row
    final headerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification Center',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Monitor system logs, tasks progress, and corporate alerts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Toolbar actions
        Row(
          children: [
            if (unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all_rounded, size: 20),
                tooltip: 'Mark All Read',
                onPressed: () {
                  ref.read(notificationActionControllerProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read.')),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, size: 20),
              tooltip: 'Clear All',
              onPressed: () {
                CustomDialog.show(
                  context: context,
                  title: 'Clear Notifications',
                  content: const Text('Are you sure you want to delete all notifications? This cannot be undone.'),
                  confirmLabel: 'Clear',
                  isDestructive: true,
                  onConfirm: () {
                    ref.read(notificationActionControllerProvider.notifier).clearAll();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All notifications cleared.')),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ],
    );

    // Left sidebar column filters
    Widget buildFiltersColumn() {
      // Calculate category counts dynamically
      final totalUnread = unreadCount;

      final taskCount = allAsync.maybeWhen(
        data: (list) => list.where((n) => n.category == 'Task' && !n.isRead).length,
        orElse: () => 0,
      );
      final annCount = allAsync.maybeWhen(
        data: (list) => list.where((n) => n.category == 'Announcement' && !n.isRead).length,
        orElse: () => 0,
      );
      final sysCount = allAsync.maybeWhen(
        data: (list) => list.where((n) => n.category == 'System' && !n.isRead).length,
        orElse: () => 0,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Unread vs Read Segment buttons
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'Unread',
                label: Text('Unread ($totalUnread)'),
                icon: const Icon(Icons.mark_as_unread_rounded, size: 16),
              ),
              ButtonSegment(
                value: 'Read',
                label: Text('Read ($totalRead)'),
                icon: const Icon(Icons.drafts_rounded, size: 16),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (set) {
              setState(() {
                _selectedTab = set.first;
              });
            },
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: theme.colorScheme.primaryContainer,
              selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),

          // Category Chips selector
          Text(
            'Filter by Category',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['All', 'Task', 'Announcement', 'System'].map((cat) {
              final isSel = filters.selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSel,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                selectedColor: theme.colorScheme.primary,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) {
                  ref.read(notificationFiltersProvider.notifier).selectCategory(cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Priority chips filter
          Text(
            'Filter by Priority',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['All', 'Urgent', 'High', 'Medium', 'Low'].map((pri) {
              final isSel = filters.selectedPriority == pri;
              final priColor = pri == 'All' ? theme.colorScheme.primary : _getPriorityColor(pri);
              return ChoiceChip(
                label: Text(pri),
                selected: isSel,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                selectedColor: priColor,
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) {
                  ref.read(notificationFiltersProvider.notifier).selectPriority(pri);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Count indicators overview
          CustomCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: isDark ? Colors.transparent : Colors.grey.shade50.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unread Inbox Status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCountOverviewRow('Task Alerts', taskCount, AppColors.info),
                const Divider(height: 16),
                _buildCountOverviewRow('Announcements', annCount, AppColors.secondary),
                const Divider(height: 16),
                _buildCountOverviewRow('System Warnings', sysCount, AppColors.warning),
              ],
            ),
          ),
        ],
      );
    }

    // Build notifications list
    Widget buildNotificationsList(List<AppNotification> notifications) {
      // Filter list based on selectedTab (Unread/Read)
      final tabList = notifications.where((n) {
        if (_selectedTab == 'Unread') {
          return !n.isRead;
        } else {
          return n.isRead;
        }
      }).toList();

      if (tabList.isEmpty) {
        return EmptyState(
          title: _selectedTab == 'Unread' ? 'All caught up!' : 'No historical logs',
          description: _selectedTab == 'Unread'
              ? 'You have read all notifications. New updates will appear here.'
              : 'Notifications marked as read will be archived here.',
          icon: _selectedTab == 'Unread' ? Icons.done_outline_rounded : Icons.history_rounded,
        );
      }

      return ListView.builder(
        itemCount: tabList.length,
        itemBuilder: (context, index) {
          final item = tabList[index];
          return NotificationTile(
            notification: item,
            onTap: () {
              if (!item.isRead) {
                ref.read(notificationActionControllerProvider.notifier).markAsRead(item.id);
              }
            },
            onDelete: () {
              ref.read(notificationActionControllerProvider.notifier).deleteNotification(item.id);
            },
          );
        },
      );
    }

    Widget buildMobileFilterToolbar() {
      final isCategoryFiltered = filters.selectedCategory != 'All';
      final isPriorityFiltered = filters.selectedPriority != 'All';
      final hasActiveFilters = isCategoryFiltered || isPriorityFiltered;

      return Row(
        children: [
          Expanded(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'Unread',
                  label: Text('Unread ($unreadCount)'),
                  icon: const Icon(Icons.mark_as_unread_rounded, size: 14),
                ),
                ButtonSegment(
                  value: 'Read',
                  label: Text('Read ($totalRead)'),
                  icon: const Icon(Icons.drafts_rounded, size: 14),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedTab = set.first;
                });
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: theme.colorScheme.primaryContainer,
                selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton.outlined(
                icon: const Icon(Icons.tune_rounded, size: 20),
                style: IconButton.styleFrom(
                  side: BorderSide(
                    color: hasActiveFilters
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 1,
                  ),
                  backgroundColor: hasActiveFilters
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                ),
                onPressed: () => _showMobileFilterSheet(context, theme),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }

    // Master responsive layout builder
    Widget mainLayout;
    if (isDesktop) {
      mainLayout = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left filters pane
          SizedBox(
            width: 280,
            child: buildFiltersColumn(),
          ),
          const SizedBox(width: 24),
          // Right notifications list pane
          Expanded(
            child: filteredAsync.when(
              data: (list) => buildNotificationsList(list),
              loading: () => const LoadingState(message: 'Syncing notification inbox...'),
              error: (err, _) => ErrorState(message: err.toString()),
            ),
          ),
        ],
      );
    } else {
      // Mobile Stacked layout
      mainLayout = filteredAsync.when(
        data: (list) => buildNotificationsList(list),
        loading: () => const LoadingState(message: 'Syncing notification inbox...'),
        error: (err, _) => ErrorState(message: err.toString()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerWidget,
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),
              if (!isDesktop) ...[
                buildMobileFilterToolbar(),
                const SizedBox(height: 16),
              ],
              Expanded(child: mainLayout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountOverviewRow(String label, int count, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userRepo = ref.watch(userRepositoryProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workspace Analytics & Reports',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Audit workspace efficiency, active staffing, and project delivery logs.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: FutureBuilder<List>(
                    future: Future.wait([
                      userRepo.getAllUsers(),
                    ]),
                    builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading report data: ${snapshot.error}'));
                      }

                      final allUsers = snapshot.data?[0] as List? ?? [];
                      final totalUsers = allUsers.length;
                      final activeUsers = allUsers.where((u) => u.status == 'Active').length;
                      final disabledUsers = totalUsers - activeUsers;

                      final superAdmins = allUsers.where((u) => u.role == 'Super Admin').length;
                      final orgAdmins = allUsers.where((u) => u.role == 'Organization Admin').length;
                      final managers = allUsers.where((u) => u.role == 'Manager').length;
                      final employees = allUsers.where((u) => u.role == 'Employee').length;

                      return tasksAsync.when(
                        data: (allTasks) {
                          final totalTasks = allTasks.length;
                          final completedTasks = allTasks.where((t) => t.status == 'Completed').length;
                          final reviewTasks = allTasks.where((t) => t.status == 'Review').length;
                          final inProgressTasks = allTasks.where((t) => t.status == 'In Progress').length;
                          final todoTasks = allTasks.where((t) => t.status == 'Todo').length;

                          final completionRate = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Visual Stats Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetricCard(
                                      theme,
                                      'Task Completion',
                                      '${(completionRate * 100).toInt()}%',
                                      '$completedTasks of $totalTasks finished',
                                      Colors.green,
                                      Icons.task_alt_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildMetricCard(
                                      theme,
                                      'Active Staffing',
                                      '$activeUsers',
                                      '$disabledUsers accounts disabled',
                                      theme.colorScheme.primary,
                                      Icons.people_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Task Status Distribution Chart (Custom Designed)
                              CustomCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Task Status Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 16),
                                    _buildStatusBarChart(theme, todoTasks, inProgressTasks, reviewTasks, completedTasks, totalTasks),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Team Roles & Staff Breakdowns
                              CustomCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Staff Role Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 16),
                                    _buildRoleDistributionRow(theme, 'Super Admin', superAdmins, totalUsers, Colors.purple),
                                    const Divider(height: 16),
                                    _buildRoleDistributionRow(theme, 'Org Admin', orgAdmins, totalUsers, Colors.blue),
                                    const Divider(height: 16),
                                    _buildRoleDistributionRow(theme, 'Manager', managers, totalUsers, Colors.orange),
                                    const Divider(height: 16),
                                    _buildRoleDistributionRow(theme, 'Employee', employees, totalUsers, Colors.teal),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // System Logs simulator snippet
                              CustomCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Activity Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Icon(Icons.history_toggle_off_rounded, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAuditLogItem(theme, 'User Olivia Org updated employee Emily Employee profile', '10 mins ago'),
                                    _buildAuditLogItem(theme, 'Manager Mark Manager reassigned task "Complete login screen animations & validations"', '25 mins ago'),
                                    _buildAuditLogItem(theme, 'Super Admin Sam Super created new department "Design"', '1 hour ago'),
                                    _buildAuditLogItem(theme, 'Employee Evan Employee updated task status to Completed', '2 hours ago'),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error loading tasks: $err')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(ThemeData theme, String title, String value, String desc, Color accentColor, IconData icon) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
              Icon(icon, color: accentColor, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accentColor)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _buildStatusBarChart(ThemeData theme, int todo, int inProg, int review, int completed, int total) {
    final double todoPct = total == 0 ? 0 : todo / total;
    final double inProgPct = total == 0 ? 0 : inProg / total;
    final double reviewPct = total == 0 ? 0 : review / total;
    final double completedPct = total == 0 ? 0 : completed / total;

    return Column(
      children: [
        // Composite horizontal stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                if (todoPct > 0) Expanded(flex: (todoPct * 100).toInt(), child: Container(color: Colors.grey.shade400)),
                if (inProgPct > 0) Expanded(flex: (inProgPct * 100).toInt(), child: Container(color: Colors.orange)),
                if (reviewPct > 0) Expanded(flex: (reviewPct * 100).toInt(), child: Container(color: Colors.purple)),
                if (completedPct > 0) Expanded(flex: (completedPct * 100).toInt(), child: Container(color: Colors.green)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLegendItem('Todo', todo, Colors.grey.shade400),
            _buildLegendItem('In Progress', inProg, Colors.orange),
            _buildLegendItem('Review', review, Colors.purple),
            _buildLegendItem('Completed', completed, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, int count, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$title: $count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRoleDistributionRow(ThemeData theme, String role, int count, int total, Color color) {
    final double pct = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(role, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text('$count users (${(pct * 100).toInt()}%)', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
          backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildAuditLogItem(ThemeData theme, String description, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontSize: 11.5, height: 1.35)),
                const SizedBox(height: 2),
                Text(time, style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

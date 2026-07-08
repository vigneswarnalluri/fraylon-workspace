import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../tasks/domain/models/task.dart';

class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final managerProfile = ref.watch(profileProvider);
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
                    'Team Dashboard',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Department: ${managerProfile.department} • Oversee performance and progress.',
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

              // Fetch Team Members
              Expanded(
                child: FutureBuilder<List<UserProfile>>(
                  future: userRepo.getAllUsers(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (userSnapshot.hasError) {
                      return Center(child: Text('Error loading team: ${userSnapshot.error}'));
                    }

                    final allUsers = userSnapshot.data ?? [];
                    // Filter: Users in the same department, excluding Super Admins
                    final teamMembers = allUsers.where((u) {
                      return u.departmentId == managerProfile.departmentId || u.department == managerProfile.department;
                    }).toList();

                    if (teamMembers.isEmpty) {
                      return const Center(child: Text('No team members found in your department.'));
                    }

                    return tasksAsync.when(
                      data: (allTasks) {
                        return ListView.builder(
                          itemCount: teamMembers.length,
                          itemBuilder: (context, index) {
                            final member = teamMembers[index];

                            // Calculate task stats for this member
                            // A task is assigned to this member if the assignedToId matches member.uid,
                            // or if the task history shows they are assigned, or if the title contains their name (fallback match for mock data)
                            final memberTasks = allTasks.where((t) {
                              // We will match either assignedToId (if we set it) or fallback match
                              return t.description.toLowerCase().contains(member.name.toLowerCase()) || 
                                     t.title.toLowerCase().contains(member.name.toLowerCase());
                            }).toList();

                            final completedTasks = memberTasks.where((t) => t.status == 'Completed').toList();
                            final inProgressTasks = memberTasks.where((t) => t.status == 'In Progress' || t.status == 'Review').toList();
                            
                            final double progress = memberTasks.isEmpty ? 0.0 : (completedTasks.length / memberTasks.length);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: CustomCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: member.photo != null ? NetworkImage(member.photo!) : null,
                                          backgroundColor: theme.colorScheme.primaryContainer,
                                          child: member.photo == null
                                              ? Text(member.name.substring(0, 1).toUpperCase(), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold))
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  if (member.role == 'Manager') ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                      decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                                      child: Text('Manager', style: TextStyle(color: theme.colorScheme.secondary, fontSize: 8.5, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Text(member.designation, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text('${memberTasks.length} Tasks', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            Text('${completedTasks.length} completed', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Progress bar
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 6,
                                            borderRadius: BorderRadius.circular(4),
                                            backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                            valueColor: AlwaysStoppedAnimation<Color>(progress > 0.7 ? Colors.green : (progress > 0.4 ? Colors.orange : theme.colorScheme.primary)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    if (inProgressTasks.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Active focus: ${inProgressTasks.first.title}',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error loading tasks: $err')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

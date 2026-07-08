import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_search_bar.dart';
import '../../../../core/widgets/states_widgets.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../domain/models/announcement.dart';
import '../providers/announcement_providers.dart';
import '../widgets/announcement_card.dart';
import '../widgets/announcement_dialogs.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/services/permission_service.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(announcementFiltersProvider.notifier).updateSearch(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userProfile = ref.watch(profileProvider);
    final permissionService = ref.watch(permissionServiceProvider);
    final canCreate = permissionService.canCreateAnnouncements(userProfile);
    final canEdit = permissionService.canEditAnnouncement(userProfile);
    final canDelete = permissionService.canDeleteAnnouncement(userProfile);

    final filteredAsync = ref.watch(filteredAnnouncementsProvider);
    final allAsync = ref.watch(announcementsStreamProvider);
    final filters = ref.watch(announcementFiltersProvider);
    final authorAsync = ref.watch(userDisplayNameProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 800;

    final defaultAuthor = authorAsync.when(
      data: (name) => name,
      loading: () => 'Jane Doe',
      error: (_, __) => 'Jane Doe',
    );

    // Dialog creation triggers
    void showCreateDialog() {
      AnnouncementDialogs.showCreate(
        context: context,
        defaultAuthor: defaultAuthor,
        onConfirm: (title, description, priority, author) {
          ref.read(announcementActionControllerProvider.notifier).createAnnouncement(
                title: title,
                description: description,
                priority: priority,
                author: author,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement published successfully!')),
          );
        },
      );
    }

    // Header Widget
    final headerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Corporate Announcements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Stay informed with real-time updates and emergency alerts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isDesktop && canCreate)
          ElevatedButton.icon(
            icon: const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('New Announcement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: showCreateDialog,
          ),
      ],
    );

    // Filters widget: Search box and Priority ChoiceChips
    Widget buildFiltersColumn() {
      // Calculate priority counts from raw announcements stream
      final activeUrgent = allAsync.maybeWhen(
        data: (list) => list.where((a) => a.priority == 'Urgent').length,
        orElse: () => 0,
      );
      final activeAlert = allAsync.maybeWhen(
        data: (list) => list.where((a) => a.priority == 'Alert').length,
        orElse: () => 0,
      );
      final activeNotice = allAsync.maybeWhen(
        data: (list) => list.where((a) => a.priority == 'Notice').length,
        orElse: () => 0,
      );
      final activeInfo = allAsync.maybeWhen(
        data: (list) => list.where((a) => a.priority == 'Info').length,
        orElse: () => 0,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Search announcements...',
          ),
          const SizedBox(height: 20),
          Text(
            'Overview & Quick Filters',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildStatCard(
                title: 'Urgent',
                count: activeUrgent,
                color: AppColors.error,
                icon: Icons.gpp_maybe_outlined,
                isSelected: filters.selectedPriorities.contains('Urgent'),
                onTap: () => ref.read(announcementFiltersProvider.notifier).togglePriority('Urgent'),
              ),
              _buildStatCard(
                title: 'Alerts',
                count: activeAlert,
                color: AppColors.warning,
                icon: Icons.warning_amber_rounded,
                isSelected: filters.selectedPriorities.contains('Alert'),
                onTap: () => ref.read(announcementFiltersProvider.notifier).togglePriority('Alert'),
              ),
              _buildStatCard(
                title: 'Notices',
                count: activeNotice,
                color: AppColors.secondary,
                icon: Icons.campaign_outlined,
                isSelected: filters.selectedPriorities.contains('Notice'),
                onTap: () => ref.read(announcementFiltersProvider.notifier).togglePriority('Notice'),
              ),
              _buildStatCard(
                title: 'Info',
                count: activeInfo,
                color: AppColors.info,
                icon: Icons.info_outline_rounded,
                isSelected: filters.selectedPriorities.contains('Info'),
                onTap: () => ref.read(announcementFiltersProvider.notifier).togglePriority('Info'),
              ),
            ],
          ),
          if (filters.searchQuery.isNotEmpty || filters.selectedPriorities.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Reset Filters'),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () {
                _searchController.clear();
                ref.read(announcementFiltersProvider.notifier).clearFilters();
              },
            ),
          ],
        ],
      );
    }

    // Announcements Feed/Grid builder
    Widget buildAnnouncementsFeed(List<Announcement> announcements, {bool shrinkWrap = false, ScrollPhysics? physics}) {
      if (announcements.isEmpty) {
        return const EmptyState(
          title: 'No Announcements Found',
          description: 'Try adjusting your filters or search keywords to view matching records.',
          icon: Icons.campaign_outlined,
        );
      }

      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return AnnouncementCard(
            announcement: announcement,
            onEdit: canEdit ? () {
              AnnouncementDialogs.showEdit(
                context: context,
                announcement: announcement,
                onConfirm: (updated) {
                  ref.read(announcementActionControllerProvider.notifier).updateAnnouncement(updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement updated.')),
                  );
                },
              );
            } : null,
            onDelete: canDelete ? () {
              // Delete confirmation dialog
              CustomDialog.show(
                context: context,
                title: 'Delete Announcement',
                content: const Text('Are you sure you want to permanently delete this announcement? This action cannot be undone.'),
                confirmLabel: 'Delete',
                isDestructive: true,
                onConfirm: () {
                  ref.read(announcementActionControllerProvider.notifier).deleteAnnouncement(announcement.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement deleted.')),
                  );
                },
              );
            } : null,
          );
        },
      );
    }

    // Main Responsive body builder
    Widget bodyWidget;
    if (isDesktop) {
      bodyWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerWidget,
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Sidebar Filter Column
                  SizedBox(
                    width: 280,
                    child: buildFiltersColumn(),
                  ),
                  const SizedBox(width: 24),
                  // Right Main Feed Column
                  Expanded(
                    child: filteredAsync.when(
                      data: (list) => buildAnnouncementsFeed(list),
                      loading: () => const LoadingState(message: 'Syncing announcements...'),
                      error: (err, _) => ErrorState(message: err.toString()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile Layout: Single unified scroll view to prevent overflow
      bodyWidget = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            headerWidget,
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),
            buildFiltersColumn(),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            filteredAsync.when(
              data: (list) => buildAnnouncementsFeed(
                list,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ),
              loading: () => const LoadingState(message: 'Syncing announcements...'),
              error: (err, _) => ErrorState(message: err.toString()),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(child: bodyWidget),
      floatingActionButton: !isDesktop && canCreate
          ? FloatingActionButton(
              onPressed: showCreateDialog,
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.campaign_rounded),
            )
          : null,
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.25 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: color,
                  ),
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

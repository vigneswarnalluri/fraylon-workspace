import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/navigation_shell_widgets.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final Widget mainContent = widget.child;
    final role = ref.watch(userRoleProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;

    final String location = GoRouterState.of(context).uri.path;

    // Dynamically build the navigation items based on user role
    final List<SidebarRouteItem> roleItems = [];

    if (role == 'Super Admin') {
      roleItems.addAll([
        const SidebarRouteItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/',
        ),
        const SidebarRouteItem(
          label: 'Organizations',
          icon: Icons.business_outlined,
          selectedIcon: Icons.business_rounded,
          route: '/organizations',
        ),
        const SidebarRouteItem(
          label: 'Users',
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          route: '/users',
        ),
        const SidebarRouteItem(
          label: 'Departments',
          icon: Icons.corporate_fare_outlined,
          selectedIcon: Icons.corporate_fare_rounded,
          route: '/departments',
        ),
        const SidebarRouteItem(
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          route: '/tasks',
        ),
        const SidebarRouteItem(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          route: '/calendar',
        ),
        const SidebarRouteItem(
          label: 'Announcements',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          route: '/announcements',
        ),
        const SidebarRouteItem(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          route: '/reports',
        ),
        const SidebarRouteItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          route: '/settings',
        ),
      ]);
    } else if (role == 'Organization Admin') {
      roleItems.addAll([
        const SidebarRouteItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/',
        ),
        const SidebarRouteItem(
          label: 'Users',
          icon: Icons.people_outline_rounded,
          selectedIcon: Icons.people_rounded,
          route: '/users',
        ),
        const SidebarRouteItem(
          label: 'Departments',
          icon: Icons.corporate_fare_outlined,
          selectedIcon: Icons.corporate_fare_rounded,
          route: '/departments',
        ),
        const SidebarRouteItem(
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          route: '/tasks',
        ),
        const SidebarRouteItem(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          route: '/calendar',
        ),
        const SidebarRouteItem(
          label: 'Announcements',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          route: '/announcements',
        ),
        const SidebarRouteItem(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          route: '/reports',
        ),
      ]);
    } else if (role == 'Manager') {
      roleItems.addAll([
        const SidebarRouteItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/',
        ),
        const SidebarRouteItem(
          label: 'Team',
          icon: Icons.group_outlined,
          selectedIcon: Icons.group,
          route: '/team',
        ),
        const SidebarRouteItem(
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          route: '/tasks',
        ),
        const SidebarRouteItem(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          route: '/calendar',
        ),
        const SidebarRouteItem(
          label: 'Announcements',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          route: '/announcements',
        ),
        const SidebarRouteItem(
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          route: '/reports',
        ),
      ]);
    } else {
      roleItems.addAll([
        const SidebarRouteItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: '/',
        ),
        const SidebarRouteItem(
          label: 'Tasks',
          icon: Icons.task_alt_outlined,
          selectedIcon: Icons.task_alt_rounded,
          route: '/tasks',
        ),
        const SidebarRouteItem(
          label: 'Calendar',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          route: '/calendar',
        ),
        const SidebarRouteItem(
          label: 'Announcements',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign,
          route: '/announcements',
        ),
        SidebarRouteItem(
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          selectedIcon: Icons.notifications_rounded,
          route: '/notifications',
          badgeCount: unreadCount > 0 ? unreadCount : null,
        ),
      ]);
    }

    roleItems.add(const SidebarRouteItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      route: '/profile',
    ));

    // Resolve index for current route
    int getCurrentIndex() {
      final index = roleItems.indexWhere((item) =>
          item.route == '/' ? location == '/' : location.startsWith(item.route));
      return index >= 0 ? index : 0;
    }

    final int selectedIndex = getCurrentIndex();

    // Mobile bottom navigation bar items (keep it compact: max 5 items for all roles)
    final List<SidebarRouteItem> mobileRoleItems = roleItems.where((item) =>
        item.route == '/' ||
        item.route == '/tasks' ||
        item.route == '/calendar' ||
        item.route == '/notifications' ||
        item.route == '/profile'
    ).toList();

    int getMobileSelectedIndex() {
      final index = mobileRoleItems.indexWhere((item) =>
          item.route == '/' ? location == '/' : location.startsWith(item.route));
      return index >= 0 ? index : 0;
    }

    void onDestinationSelected(int index) {
      if (index >= 0 && index < roleItems.length) {
        context.go(roleItems[index].route);
      }
    }

    void onMobileDestinationSelected(int mobileIndex) {
      if (mobileIndex >= 0 && mobileIndex < mobileRoleItems.length) {
        context.go(mobileRoleItems[mobileIndex].route);
      }
    }

    return ResponsiveLayout(
      mobile: Scaffold(
        body: Stack(
          children: [
            mainContent,
            const OnboardingTourOverlay(),
          ],
        ),
        bottomNavigationBar: CustomNavigationBar(
          selectedIndex: getMobileSelectedIndex(),
          onDestinationSelected: onMobileDestinationSelected,
          destinations: mobileRoleItems.map((item) {
            String shortLabel = item.label;
            if (shortLabel == 'Dashboard') shortLabel = 'Home';
            if (shortLabel == 'Notifications') shortLabel = 'Alerts';
            return NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: shortLabel,
            );
          }).toList(),
        ),
      ),
      desktop: Scaffold(
        body: Row(
          children: [
            // Left sidebar view for desktop
            CustomSidebar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              items: roleItems.map((item) => item.toSidebarItem()).toList(),
              activeOrgName: userProfile?.organization ?? 'Fraylon Technologies',
              onOrgSwitch: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${userProfile?.organization ?? 'Fraylon Technologies'} Selected')),
                );
              },
              onSettingsPressed: () {
                context.go('/profile');
              },
            ),
            const VerticalDivider(thickness: 1, width: 1),
            // Middle / Right Content
            Expanded(
              child: Stack(
                children: [
                  mainContent,
                  const OnboardingTourOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingTourOverlay extends ConsumerWidget {
  const OnboardingTourOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourState = ref.watch(onboardingTourProvider);
    if (tourState.step == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 800;

    final steps = [
      _TourStep(
        title: 'Step 1: The Workspace Dashboard',
        description: 'Here is your summary of pending tasks, weekly productivity metrics, and custom Quick Actions (like creating tasks or theme toggles).',
        route: '/',
        icon: Icons.dashboard_rounded,
        color: theme.colorScheme.primary,
      ),
      _TourStep(
        title: 'Step 2: Task Board',
        description: 'Visualize your work. Drag cards between columns (or use the chip selector on mobile), use inline tags inside the search bar, and complete tasks with smooth checkbox checkmark pop animations.',
        route: '/tasks',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF10B981),
      ),
      _TourStep(
        title: 'Step 3: Smart Calendar Timeline',
        description: 'Plan your schedule. Inspect borderless day cells, view the horizontal week timeline strip on mobile, and tap the "+" header button to schedule tasks.',
        route: '/calendar',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF22C7D6),
      ),
      _TourStep(
        title: 'Step 4: Inbox Alerts & Simulators',
        description: 'Review critical system alerts. Use the unread/read filters and trigger simulators in the filter options to view mock notification deliveries.',
        route: '/notifications',
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _TourStep(
        title: 'Step 5: Account & Profile Preferences',
        description: 'Configure your profile name, upload photos, select system languages, change themes, or unlock Developer Console configurations.',
        route: '/profile',
        icon: Icons.person_rounded,
        color: const Color(0xFFEC4899),
      ),
    ];

    final currentStep = steps[tourState.step - 1];

    return Positioned(
      left: isDesktop ? null : 16,
      right: isDesktop ? 24 : 16,
      bottom: isDesktop ? 24 : 74,
      width: isDesktop ? 360 : null,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: currentStep.color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(currentStep.icon, size: 20, color: currentStep.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          currentStep.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${tourState.step} of 5',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentStep.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          ref.read(onboardingTourProvider.notifier).finishTour();
                        },
                        child: Text(
                          'Skip Tour',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (tourState.step > 1)
                            OutlinedButton(
                              onPressed: () {
                                final prev = steps[tourState.step - 2];
                                ref.read(onboardingTourProvider.notifier).prevStep();
                                context.go(prev.route);
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                                minimumSize: const Size(64, 32),
                              ),
                              child: Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              ref.read(onboardingTourProvider.notifier).nextStep();
                              if (tourState.step < 5) {
                                final next = steps[tourState.step];
                                context.go(next.route);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Onboarding completed! Welcome to Fraylon.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(64, 32),
                            ),
                            child: Text(
                              tourState.step == 5 ? 'Finish' : 'Next',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourStep {
  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color color;

  _TourStep({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
  });
}

class SidebarRouteItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final int? badgeCount;

  const SidebarRouteItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.badgeCount,
  });

  SidebarItem toSidebarItem() {
    return SidebarItem(
      label: label,
      icon: icon,
      selectedIcon: selectedIcon,
      badgeCount: badgeCount,
    );
  }
}

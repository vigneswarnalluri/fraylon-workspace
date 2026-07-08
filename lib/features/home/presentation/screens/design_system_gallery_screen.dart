import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_search_bar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_skeleton.dart';
import '../../../../core/widgets/custom_chart.dart';
import '../../../../core/widgets/custom_table.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/quick_actions.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class DesignSystemGalleryScreen extends ConsumerStatefulWidget {
  const DesignSystemGalleryScreen({super.key});

  @override
  ConsumerState<DesignSystemGalleryScreen> createState() => _DesignSystemGalleryScreenState();
}

class _DesignSystemGalleryScreenState extends ConsumerState<DesignSystemGalleryScreen> {
  final _searchController = TextEditingController();
  String? _selectedDropdownVal = 'Backlog';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Showcase'),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery Header
            Text(
              'Fraylon Enterprise Design System',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Premium UI component library configured with 18px rounded corners, compact structures, and high information density.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Layout Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.sizeOf(context).width > 1000 ? 2 : 1,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.85,
              children: [
                // 1. Buttons Segment
                _buildSectionCard(
                  title: '1. Reusable Buttons & Indicators',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        label: 'Primary Button',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Secondary Action',
                        type: CustomButtonType.secondary,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Accent Success Option',
                        type: CustomButtonType.accent,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Outline Option',
                        type: CustomButtonType.outline,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Loading Primary',
                        isLoading: true,
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomButton(
                            label: 'Text Link',
                            type: CustomButtonType.text,
                            width: 140,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Selection & Inputs Segment
                _buildSectionCard(
                  title: '2. Inputs & Selectors',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomSearchBar(
                        controller: _searchController,
                        hintText: 'Press cmd+K to search items...',
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: TextEditingController(text: 'admin@fraylontech.com'),
                        label: 'Login Email',
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 16),
                      CustomDropdown<String>(
                        label: 'Task Work Status',
                        value: _selectedDropdownVal,
                        items: const [
                          DropdownMenuItem(value: 'Backlog', child: Text('Backlog')),
                          DropdownMenuItem(value: 'Todo', child: Text('Todo')),
                          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedDropdownVal = val;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Text('Selection Chips & Pills', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          CustomChip(label: 'All Tasks', isSelected: true, onTap: () {}),
                          CustomChip(label: 'Design System', icon: Icons.palette_outlined, onTap: () {}),
                          const CustomBadge(
                            count: 7,
                            child: CustomChip(label: 'Inbox Alerts'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Status Pills (Linear Style)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusPill(type: StatusPillType.backlog),
                          StatusPill(type: StatusPillType.todo),
                          StatusPill(type: StatusPillType.inProgress),
                          StatusPill(type: StatusPillType.completed),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Modals & Notifications
                _buildSectionCard(
                  title: '3. Modals & Notifications',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomButton(
                        label: 'Show Modal Dialog',
                        type: CustomButtonType.outline,
                        onPressed: () {
                          CustomDialog.show(
                            context: context,
                            title: 'Create project environment',
                            content: const Text(
                              'This action compiles the baseline framework templates inside Fraylon Workspace. Are you sure you want to proceed?',
                            ),
                            confirmLabel: 'Create',
                            onConfirm: () => Navigator.pop(context),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        label: 'Show Bottom Sheet Options',
                        type: CustomButtonType.outline,
                        onPressed: () {
                          CustomBottomSheet.show(
                            context: context,
                            title: 'Quick task configuration',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: const Text('Edit Metadata'),
                                  onTap: () => Navigator.pop(context),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.share_outlined),
                                  title: const Text('Share Access link'),
                                  onTap: () => Navigator.pop(context),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  title: const Text('Delete Resource', style: TextStyle(color: Colors.red)),
                                  onTap: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Dynamic Snackbars (Toasts)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              label: 'Success Toast',
                              type: CustomButtonType.secondary,
                              onPressed: () {
                                CustomSnackbar.show(
                                  context,
                                  message: 'Configuration saved successfully!',
                                  type: SnackbarType.success,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomButton(
                              label: 'Error Toast',
                              type: CustomButtonType.outline,
                              onPressed: () {
                                CustomSnackbar.show(
                                  context,
                                  message: 'Connection timed out. Try again.',
                                  type: SnackbarType.error,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Profile summary views', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 12),
                      const ProfileCard(
                        name: 'Vigneswar Nalluri',
                        email: 'vigneswar@fraylontech.com',
                        role: 'Principal Engineer',
                        status: UserStatus.online,
                      ),
                    ],
                  ),
                ),

                // 4. Data & Visual Analytics
                _buildSectionCard(
                  title: '4. Visual Analytics & Loading',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Compact custom charts (Metrics)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Expanded(
                            child: CustomCard(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text('Engagement rate (Line)', style: TextStyle(fontSize: 11)),
                                  CustomChart(data: [12, 19, 3, 5, 2, 3, 10], height: 80),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: CustomCard(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Text('Deployment velocity (Bar)', style: TextStyle(fontSize: 11)),
                                  CustomChart(data: [5, 12, 8, 14, 6, 18, 9], isLine: false, height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Skeleton Loading state (Shimmer)', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      const CustomCard(
                        child: Row(
                          children: [
                            CustomSkeleton.avatar(size: 40),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomSkeleton.text(width: 120),
                                  SizedBox(height: 6),
                                  CustomSkeleton.text(width: 200),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Quick Action grid keys', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 72,
                        child: QuickActions(
                          crossAxisCount: 3,
                          actions: [
                            QuickActionItem(
                              label: 'New Task',
                              icon: Icons.add_task_rounded,
                              color: theme.colorScheme.primary,
                              onTap: () {},
                            ),
                            QuickActionItem(
                              label: 'Metrics',
                              icon: Icons.bar_chart_rounded,
                              color: const Color(0xFF22C7D6),
                              onTap: () {},
                            ),
                            QuickActionItem(
                              label: 'Deployments',
                              icon: Icons.cloud_sync_rounded,
                              color: const Color(0xFF69D36E),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // High-density data table representation
            Text(
              '5. High-density Enterprise Table',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomTable(
              headers: const ['Project', 'Lead', 'Status', 'Performance', 'Actions'],
              columnWidths: const [160, 160, 130, 160, 80],
              rows: [
                CustomTableRow(
                  cells: [
                    const Text('Design Token System', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Row(
                      children: [
                        ProfileAvatar(initials: 'VN', size: 24, status: UserStatus.online),
                        SizedBox(width: 8),
                        Text('Vigneswar N.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const StatusPill(type: StatusPillType.inProgress),
                    const CustomChart(data: [2, 5, 8, 12, 10], height: 32),
                    IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 18), onPressed: () {}),
                  ],
                ),
                CustomTableRow(
                  cells: [
                    const Text('Riverpod Controllers', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Row(
                      children: [
                        ProfileAvatar(initials: 'VN', size: 24, status: UserStatus.busy),
                        SizedBox(width: 8),
                        Text('Vigneswar N.', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const StatusPill(type: StatusPillType.todo),
                    const CustomChart(data: [12, 10, 8, 14, 18], height: 32),
                    IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 18), onPressed: () {}),
                  ],
                ),
                CustomTableRow(
                  cells: [
                    const Text('Firebase Schema init', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const Row(
                      children: [
                        ProfileAvatar(initials: 'M', size: 24, status: UserStatus.offline),
                        SizedBox(width: 8),
                        Text('Mock Engineer', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const StatusPill(type: StatusPillType.completed),
                    const CustomChart(data: [5, 6, 8, 12, 15], height: 32),
                    IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 18), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}

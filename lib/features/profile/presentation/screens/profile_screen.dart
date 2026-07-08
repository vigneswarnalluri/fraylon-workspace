import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../providers/profile_providers.dart';
import '../widgets/profile_edit_dialog.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _empIdTaps = 0;

  Future<void> _pickAndUploadImage(String userId) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading profile photo to Firebase Storage...'),
          duration: Duration(days: 1),
        ),
      );

      final success = await ref.read(profileProvider.notifier).uploadAvatar(bytes, userId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Verify Firebase connection.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _copyToClipboard(String text, String message) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleEmployeeIdTap() {
    final isDevUnlocked = ref.read(developerModeProvider);
    if (isDevUnlocked) return;

    setState(() {
      _empIdTaps++;
    });

    if (_empIdTaps >= 7) {
      ref.read(developerModeProvider.notifier).state = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.terminal_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Developer mode unlocked! Mock configurations visible.'),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_empIdTaps >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap ${7 - _empIdTaps} more times to unlock developer configurations.'),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoDialog(String title, String contentText) {
    CustomDialog.show(
      context: context,
      title: title,
      content: Text(
        contentText,
        style: const TextStyle(fontSize: 13, height: 1.5),
      ),
      confirmLabel: 'Close',
      onConfirm: () => Navigator.pop(context),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    CustomDialog.show(
      context: context,
      title: 'Sign Out',
      confirmLabel: 'Sign Out',
      isDestructive: true,
      content: const Text(
        'Are you sure you want to sign out of Fraylon Workspace? This will securely end your current session.',
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
      onConfirm: () {
        Navigator.of(context, rootNavigator: true).pop();
        ref.read(authControllerProvider.notifier).signOut().then((_) {
          if (context.mounted) context.go('/login');
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profile = ref.watch(profileProvider);
    final isDevMode = ref.watch(developerModeProvider);
    final useFirebase = ref.watch(useFirebaseProvider);
    final themeMode = ref.watch(themeProvider);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 800;

    final initials = profile.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    // Large premium profile card with cover photo
    final profileHeader = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Banner Gradient
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF312E81), const Color(0xFF4F46E5)]
                    : [const Color(0xFFE0E7FF), const Color(0xFF818CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          // Overlapping Avatar & Content Stack
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickAndUploadImage(profile.employeeId),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: profile.imageUrl != null ? NetworkImage(profile.imageUrl!) : null,
                            child: profile.imageUrl == null
                                ? Text(
                                    initials.toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      letterSpacing: -0.5,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Centered Name
                  Text(
                    profile.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Role and Active badge row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.role,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Interactive Status Picker
                      PopupMenuButton<String>(
                        onSelected: (newStatus) {
                          final updated = profile.copyWith(status: newStatus);
                          ref.read(profileProvider.notifier).updateProfile(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to $newStatus.'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        itemBuilder: (context) => [
                          _buildStatusMenuItem('Active', const Color(0xFF10B981)),
                          _buildStatusMenuItem('Away', const Color(0xFFF59E0B)),
                          _buildStatusMenuItem('Do Not Disturb', const Color(0xFFEF4444)),
                          _buildStatusMenuItem('In a Meeting', const Color(0xFF8B5CF6)),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusColor(profile.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(profile.status).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(profile.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.status.isEmpty ? 'Active' : profile.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _getStatusColor(profile.status),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 12,
                                color: _getStatusColor(profile.status),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Edit Profile Quick Button
                  OutlinedButton.icon(
                    onPressed: () {
                      ProfileEditDialog.show(
                        context: context,
                        profile: profile,
                        onConfirm: (updated) {
                          ref.read(profileProvider.notifier).updateProfile(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully.')),
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit Profile', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Corporate Details Card
    final detailsCard = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Corporate Information',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.business_rounded,
            label: 'Department',
            value: profile.department,
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildDetailRow(
            icon: Icons.corporate_fare_rounded,
            label: 'Organization',
            value: profile.organization,
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildDetailRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: profile.email,
            showCopyButton: true,
            onTap: () => _copyToClipboard(profile.email, 'Email copied to clipboard'),
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildDetailRow(
            icon: Icons.phone_iphone_rounded,
            label: 'Phone Number',
            value: profile.phone,
            showCopyButton: profile.phone.isNotEmpty,
            onTap: profile.phone.isNotEmpty
                ? () => _copyToClipboard(profile.phone, 'Phone number copied to clipboard')
                : null,
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildDetailRow(
            icon: Icons.badge_outlined,
            label: 'Employee ID',
            value: profile.employeeId,
            showCopyButton: true,
            onTap: () {
              _handleEmployeeIdTap();
              _copyToClipboard(profile.employeeId, 'Employee ID copied to clipboard');
            },
          ),
          Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildDetailRow(
            icon: Icons.calendar_month_outlined,
            label: 'Joined Date',
            value: _formatDate(profile.joinedDate),
          ),
        ],
      ),
    );

    // Theme Mode Selection Card Builder
    Widget buildThemeModeCard(ThemeMode mode, String title, IconData icon) {
      final isSelected = themeMode == mode;
      return GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Preferences Card
    final preferencesCard = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferences',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          // Theme Toggles Title
          Text(
            'THEME MODE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(child: buildThemeModeCard(ThemeMode.system, 'System', Icons.settings_brightness_rounded)),
              const SizedBox(width: 8),
              Expanded(child: buildThemeModeCard(ThemeMode.light, 'Light', Icons.light_mode_rounded)),
              const SizedBox(width: 8),
              Expanded(child: buildThemeModeCard(ThemeMode.dark, 'Dark', Icons.dark_mode_rounded)),
            ],
          ),
          const SizedBox(height: 20),

          // Notifications switch
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(
              profile.notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            title: const Text('Push Notifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Receive warnings and calendar alerts', style: TextStyle(fontSize: 11)),
            value: profile.notificationsEnabled,
            onChanged: (val) {
              ref.read(profileProvider.notifier).toggleNotifications(val);
            },
          ),
          const Divider(height: 24),

          // Language selector
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.language_rounded,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            title: const Text('System Language', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Select application locale', style: TextStyle(fontSize: 11)),
            trailing: DropdownButton<String>(
              value: profile.language,
              underline: const SizedBox(),
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, color: theme.colorScheme.primary),
              items: const ['English', 'Spanish', 'German', 'French'].map((lang) {
                return DropdownMenuItem(value: lang, child: Text(lang));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(profileProvider.notifier).updateLanguage(val);
                }
              },
            ),
          ),
          const Divider(height: 24),

          // Interactive Product Tour trigger
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.explore_outlined,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            title: const Text('Interactive Product Tour', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Re-launch the step-by-step walkthrough', style: TextStyle(fontSize: 11)),
            trailing: Icon(Icons.play_circle_outline_rounded, size: 20, color: theme.colorScheme.primary),
            onTap: () {
              ref.read(onboardingTourProvider.notifier).startTour();
              context.go('/');
            },
          ),
        ],
      ),
    );

    // Links & Policies Card
    final linksCard = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Information & Policies',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.info_outline_rounded, size: 18),
            title: const Text('About Fraylon Workspace', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 18),
            onTap: () => _showInfoDialog(
              'About Fraylon Workspace',
              'Fraylon Workspace Enterprise is an integrated workflow portal designed by Fraylon Technologies LLP. It features real-time notifications, task trackers, organization switcher drawers, calendar scheduling, and clean architecture state controls.',
            ),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.gpp_good_outlined, size: 18),
            title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 18),
            onTap: () => _showInfoDialog(
              'Privacy Policy',
              'Your privacy is our priority. Fraylon Workspace processes profiles and activity streams locally in mock storage, or synchronizes with your organization\'s securely configured Firebase Cloud Firestore collection instances under strict enterprise authorization guidelines.',
            ),
          ),
          const Divider(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.description_outlined, size: 18),
            title: const Text('Terms of Service', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.keyboard_arrow_right_rounded, size: 18),
            onTap: () => _showInfoDialog(
              'Terms of Service',
              'By utilizing this enterprise application, you agree to comply with organizational data guidelines. Unauthorized reproduction or reverse engineering of built-in models and middleware integrations is strictly prohibited.',
            ),
          ),
        ],
      ),
    );

    // Hidden Developer options card
    final developerCard = isDevMode
        ? Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.red.shade50.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        'Developer Console Settings',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.cloud_outlined, size: 20),
                    title: const Text(
                      'Use Live Firebase Database',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Toggle off to use local Mock shared preferences storage.',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: useFirebase,
                    onChanged: (val) {
                      ref.read(useFirebaseProvider.notifier).state = val;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Database layer swapped to ${val ? "Firebase" : "Mock"} Mode.'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();

    // Sign Out Button
    final signOutButton = OutlinedButton.icon(
      onPressed: () => _showLogoutConfirmationDialog(context),
      icon: const Icon(Icons.logout_rounded, size: 16),
      label: const Text('Sign Out of Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.redAccent,
        side: const BorderSide(color: Colors.redAccent, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );

    // Tabs
    final profileTabs = [
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 15),
            const SizedBox(width: 6),
            Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tune_rounded, size: 15),
            const SizedBox(width: 6),
            Text(
              isDesktop ? 'Preferences' : 'Settings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
      Tab(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_good_outlined, size: 15),
            const SizedBox(width: 6),
            Text(
              isDesktop ? 'Security & System' : 'Security',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
    ];

    // Responsive Desktop Layout
    final desktopLayout = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Profile Banner Card
        SizedBox(
          width: 320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 12, top: 24, bottom: 24),
            child: profileHeader,
          ),
        ),
        
        // Right Column: Settings Tabs & Card Contents
        Expanded(
          child: Column(
            children: [
              // Custom styled sliding tab switcher
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 24, top: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    tabs: profileTabs,
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),
              
              // Tab contents
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12, right: 24, top: 20, bottom: 24),
                      child: detailsCard,
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12, right: 24, top: 20, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          preferencesCard,
                          const SizedBox(height: 20),
                          signOutButton,
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(left: 12, right: 24, top: 20, bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          linksCard,
                          developerCard,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Responsive Mobile Layout
    final mobileLayout = Column(
      children: [
        // Tab Bar
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            tabs: profileTabs,
            isScrollable: false,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        
        // Tab Contents
        Expanded(
          child: TabBarView(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    profileHeader,
                    const SizedBox(height: 16),
                    detailsCard,
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    preferencesCard,
                    const SizedBox(height: 20),
                    signOutButton,
                  ],
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    linksCard,
                    developerCard,
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Profile & Settings'),
          centerTitle: false,
          elevation: 0,
        ),
        body: SafeArea(
          child: isDesktop ? desktopLayout : mobileLayout,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981);
      case 'Away':
        return const Color(0xFFF59E0B);
      case 'Do Not Disturb':
        return const Color(0xFFEF4444);
      case 'In a Meeting':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  PopupMenuItem<String> _buildStatusMenuItem(String status, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PopupMenuItem<String>(
      value: status,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool showCopyButton = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final displayValue = value.isEmpty ? 'Not set' : value;
    final isNotSet = value.isEmpty;

    Widget rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Icon Container with soft background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          
          // Label and Value Stacked Vertically
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isNotSet
                              ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8))
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    if (showCopyButton && !isNotSet) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: rowContent,
      );
    }

    return rowContent;
  }
}

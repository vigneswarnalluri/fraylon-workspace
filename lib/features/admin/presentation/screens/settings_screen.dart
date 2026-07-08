import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _orgNameController = TextEditingController(text: 'Fraylon Technologies LLP');
  final _orgDomainController = TextEditingController(text: 'fraylontech.com');
  bool _mfaRequired = true;
  bool _auditLogsActive = true;
  bool _ipWhitelistActive = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _orgDomainController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workspace configuration saved successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useFirebase = ref.watch(useFirebaseProvider);

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
                    'Workspace Settings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Administer workspace settings, security profiles, and connection variables.',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Organization Information
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Organization Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _orgNameController,
                              label: 'Enterprise Name',
                              hint: 'e.g. Fraylon Technologies LLP',
                            ),
                            const SizedBox(height: 12),
                            CustomTextField(
                              controller: _orgDomainController,
                              label: 'Authorized Domain',
                              hint: 'e.g. fraylontech.com',
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _saveSettings,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Save Details'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Security Policies
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Security & Access Policies', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Require Multi-Factor Auth (MFA)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Enforce MFA for all managers and employees.', style: TextStyle(fontSize: 11)),
                              value: _mfaRequired,
                              onChanged: (val) => setState(() => _mfaRequired = val),
                            ),
                            const Divider(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Audit logs active', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Write administrative actions to secure activity logs.', style: TextStyle(fontSize: 11)),
                              value: _auditLogsActive,
                              onChanged: (val) => setState(() => _auditLogsActive = val),
                            ),
                            const Divider(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Enable IP range restriction', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Only allow connections from whitelisted office IPs.', style: TextStyle(fontSize: 11)),
                              value: _ipWhitelistActive,
                              onChanged: (val) => setState(() => _ipWhitelistActive = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Mode Switcher Reference
                      CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Backend Configuration', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Database Sync Connection Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(useFirebase ? 'Firebase Sync (Live cloud Firestore integration)' : 'Local Mock Mode (Offline-first SharedPreferences persistence)'),
                              trailing: Switch(
                                value: useFirebase,
                                onChanged: (val) {
                                  ref.read(useFirebaseProvider.notifier).state = val;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Switched backend to ${val ? 'Firebase' : 'Mock Mode'}!')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

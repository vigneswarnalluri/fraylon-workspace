import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_text_field.dart';

class OrgItem {
  final String id;
  final String name;
  final String code;
  final String domain;
  final String subscriptionTier; // Basic, Pro, Enterprise
  final String status; // Active, Suspended
  final int employeeCount;

  OrgItem({
    required this.id,
    required this.name,
    required this.code,
    required this.domain,
    required this.subscriptionTier,
    required this.status,
    required this.employeeCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'domain': domain,
        'subscriptionTier': subscriptionTier,
        'status': status,
        'employeeCount': employeeCount,
      };

  factory OrgItem.fromMap(Map<String, dynamic> map) => OrgItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        code: map['code'] ?? '',
        domain: map['domain'] ?? '',
        subscriptionTier: map['subscriptionTier'] ?? 'Basic',
        status: map['status'] ?? 'Active',
        employeeCount: map['employeeCount'] ?? 1,
      );
}

class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  List<OrgItem> _organizations = [];
  bool _isLoading = false;
  static const _orgsKey = 'mock_organizations_data';

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_orgsKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        setState(() {
          _organizations = decoded.map((x) => OrgItem.fromMap(x)).toList();
        });
      } else {
        _organizations = [
          OrgItem(id: 'org_fraylon', name: 'Fraylon Technologies LLP', code: 'FRAY', domain: 'fraylontech.com', subscriptionTier: 'Enterprise', status: 'Active', employeeCount: 154),
          OrgItem(id: 'org_acme', name: 'Acme Corporate Inc', code: 'ACME', domain: 'acme.org', subscriptionTier: 'Pro', status: 'Active', employeeCount: 42),
          OrgItem(id: 'org_stark', name: 'Stark Industries LLC', code: 'STARK', domain: 'stark.io', subscriptionTier: 'Enterprise', status: 'Active', employeeCount: 889),
          OrgItem(id: 'org_cyber', name: 'Cyberdyne Systems', code: 'CYBER', domain: 'cyberdyne.net', subscriptionTier: 'Basic', status: 'Suspended', employeeCount: 5),
        ];
        await _save();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _organizations.map((x) => x.toMap()).toList();
      await prefs.setString(_orgsKey, jsonEncode(list));
    } catch (_) {}
  }

  void _openOrgDialog([OrgItem? org]) {
    final isEdit = org != null;
    final nameController = TextEditingController(text: org?.name);
    final codeController = TextEditingController(text: org?.code);
    final domainController = TextEditingController(text: org?.domain);
    String selectedTier = org?.subscriptionTier ?? 'Basic';
    String selectedStatus = org?.status ?? 'Active';
    final formKey = GlobalKey<FormState>();

    CustomDialog.show(
      context: context,
      title: isEdit ? 'Edit Organization' : 'Create Organization',
      confirmLabel: isEdit ? 'Save Changes' : 'Create Organization',
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return;

        final newOrg = OrgItem(
          id: isEdit ? org.id : 'org_${DateTime.now().millisecondsSinceEpoch}',
          name: nameController.text.trim(),
          code: codeController.text.trim().toUpperCase(),
          domain: domainController.text.trim().toLowerCase(),
          subscriptionTier: selectedTier,
          status: selectedStatus,
          employeeCount: isEdit ? org.employeeCount : 1,
        );

        setState(() {
          if (isEdit) {
            final idx = _organizations.indexWhere((o) => o.id == org.id);
            if (idx >= 0) _organizations[idx] = newOrg;
          } else {
            _organizations.add(newOrg);
          }
        });
        await _save();
        Navigator.pop(context);
      },
      content: Form(
        key: formKey,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: nameController,
                  label: 'Organization Name',
                  hint: 'e.g. Stark Industries',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: codeController,
                  label: 'Org Code (Capital letters)',
                  hint: 'e.g. STARK',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Code is required' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: domainController,
                  label: 'Primary Domain Name',
                  hint: 'e.g. stark.io',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Domain is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Subscription Tier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedTier,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Basic', 'Pro', 'Enterprise'].map((tier) {
                    return DropdownMenuItem(value: tier, child: Text(tier));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedTier = val);
                  },
                ),
                const SizedBox(height: 12),
                const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Active', 'Suspended'].map((status) {
                    return DropdownMenuItem(value: status, child: Text(status));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmation(OrgItem org) {
    CustomDialog.show(
      context: context,
      title: 'Delete Organization',
      content: Text('Are you sure you want to permanently delete organization ${org.name}? This will revoke access for all associated employees. This action is irreversible.'),
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () async {
        setState(() {
          _organizations.removeWhere((o) => o.id == org.id);
        });
        await _save();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organizations Administration',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage global platform clients, subscriptions, and status logs.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openOrgDialog(),
                    icon: const Icon(Icons.add_business_rounded, size: 18),
                    label: const Text('Add Organization'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 16),

              // Organizations list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _organizations.isEmpty
                        ? const Center(child: Text('No organizations found.'))
                        : ListView.builder(
                            itemCount: _organizations.length,
                            itemBuilder: (context, index) {
                              final org = _organizations[index];
                              final isSuspended = org.status == 'Suspended';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: CustomCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSuspended
                                              ? theme.colorScheme.error.withValues(alpha: 0.08)
                                              : theme.colorScheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.business_rounded,
                                          color: isSuspended ? theme.colorScheme.error : theme.colorScheme.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  org.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: org.subscriptionTier == 'Enterprise'
                                                        ? Colors.purple.withValues(alpha: 0.1)
                                                        : (org.subscriptionTier == 'Pro' ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1)),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    org.subscriptionTier,
                                                    style: TextStyle(
                                                      color: org.subscriptionTier == 'Enterprise'
                                                          ? Colors.purple
                                                          : (org.subscriptionTier == 'Pro' ? Colors.blue : Colors.grey),
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Domain: ${org.domain} • Code: ${org.code} • Employees: ${org.employeeCount}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: isSuspended ? Colors.red : Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  org.status,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSuspended ? Colors.red : Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            _openOrgDialog(org);
                                          } else if (action == 'delete') {
                                            _showDeleteConfirmation(org);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit', style: TextStyle(fontSize: 13))],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red, fontSize: 13))],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
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

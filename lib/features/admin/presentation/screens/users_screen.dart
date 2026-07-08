import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/domain/models/user_profile.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';
  String _selectedStatusFilter = 'All';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createUser(UserProfile user) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.createUser(user);
      _showSuccess('User ${user.name} created successfully!');
      // Force UI rebuild
      ref.invalidate(userProfileProvider);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUser(UserProfile user) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.updateUser(user);
      _showSuccess('User ${user.name} updated successfully!');
      ref.invalidate(userProfileProvider);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String uid, String name) async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.deleteUser(uid);
      _showSuccess('User $name deleted successfully!');
      ref.invalidate(userProfileProvider);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openUserDialog([UserProfile? user]) {
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);
    final designationController = TextEditingController(text: user?.designation);
    final orgController = TextEditingController(text: user?.organization ?? 'Fraylon Technologies LLP');
    final deptController = TextEditingController(text: user?.department ?? 'Engineering');

    String roleVal = user?.role ?? 'Employee';
    String statusVal = user?.status ?? 'Active';

    final formKey = GlobalKey<FormState>();

    CustomDialog.show(
      context: context,
      title: isEdit ? 'Edit User details' : 'Create New User',
      confirmLabel: isEdit ? 'Save Changes' : 'Create User',
      onConfirm: () {
        if (!formKey.currentState!.validate()) return;

        final newUser = UserProfile(
          uid: isEdit ? user.uid : 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          role: roleVal,
          designation: designationController.text.trim(),
          organization: orgController.text.trim(),
          organizationId: isEdit ? user.organizationId : 'org_fraylon',
          department: deptController.text.trim(),
          departmentId: isEdit ? user.departmentId : 'dept_engineering',
          status: statusVal,
          photo: user?.photo,
          createdAt: isEdit ? user.createdAt : DateTime.now(),
          lastLogin: isEdit ? user.lastLogin : DateTime.now(),
        );

        Navigator.pop(context);
        if (isEdit) {
          _updateUser(newUser);
        } else {
          _createUser(newUser);
        }
      },
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomTextField(
                    controller: nameController,
                    label: 'Full Name',
                    hint: 'e.g. John Doe',
                    validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: emailController,
                    label: 'Email Address',
                    hint: 'e.g. john@fraylontech.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isEdit, // Prevent email edit
                    validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: designationController,
                    label: 'Designation / Job Title',
                    hint: 'e.g. Software Engineer',
                    validator: (val) => val == null || val.trim().isEmpty ? 'Designation is required' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. +1 (555) 019-2834',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: roleVal,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(value: 'Super Admin', child: Text('Super Admin')),
                            DropdownMenuItem(value: 'Organization Admin', child: Text('Org Admin')),
                            DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                            DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => roleVal = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: statusVal,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'Active', child: Text('Active')),
                            DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => statusVal = val);
                          },
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
    );
  }

  void _showDeleteConfirmation(UserProfile user) {
    CustomDialog.show(
      context: context,
      title: 'Delete User',
      content: Text('Are you sure you want to permanently delete user ${user.name}? This action is irreversible.'),
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () {
        Navigator.pop(context);
        _deleteUser(user.uid, user.name);
      },
    );
  }

  void _simulatePasswordReset(UserProfile user) {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() => _isLoading = false);
      _showSuccess('Password reset link sent to ${user.email}!');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userRepo = ref.watch(userRepositoryProvider);
    final usersFuture = ref.watch(userProfileProvider); // triggers rebuild on login/auth changes

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Management',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Provision users, configure enterprise roles, and control statuses.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openUserDialog(),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Add User'),
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
              const SizedBox(height: 12),

              // Search & Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search users by name or email...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedRoleFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Roles')),
                      DropdownMenuItem(value: 'Super Admin', child: Text('Super Admin')),
                      DropdownMenuItem(value: 'Organization Admin', child: Text('Org Admin')),
                      DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleFilter = val);
                    },
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedStatusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Status')),
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(value: 'Disabled', child: Text('Disabled')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatusFilter = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Users List Table
              Expanded(
                child: FutureBuilder<List<UserProfile>>(
                  future: userRepo.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading users: ${snapshot.error}'));
                    }

                    final users = snapshot.data ?? [];
                    // Apply filtering client-side for immediate responsive UX
                    final query = _searchController.text.toLowerCase();
                    final filteredUsers = users.where((u) {
                      final matchesSearch = u.name.toLowerCase().contains(query) || u.email.toLowerCase().contains(query);
                      final matchesRole = _selectedRoleFilter == 'All' || u.role == _selectedRoleFilter;
                      final matchesStatus = _selectedStatusFilter == 'All' || u.status == _selectedStatusFilter;
                      return matchesSearch && matchesRole && matchesStatus;
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Text('No users found matching current filters.', style: TextStyle(fontSize: 13)),
                      );
                    }

                    return ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isActive = user.status == 'Active';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
                            child: user.photo == null
                                ? Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 9.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.status,
                                  style: TextStyle(
                                    color: isActive ? Colors.green : Colors.red,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('${user.designation} • ${user.department}', style: const TextStyle(fontSize: 11)),
                              Text(user.email, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'edit') {
                                _openUserDialog(user);
                              } else if (action == 'toggle_status') {
                                final updated = user.copyWith(status: isActive ? 'Disabled' : 'Active');
                                _updateUser(updated);
                              } else if (action == 'reset_password') {
                                _simulatePasswordReset(user);
                              } else if (action == 'delete') {
                                _showDeleteConfirmation(user);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [Icon(Icons.edit_rounded, size: 16), SizedBox(width: 8), Text('Edit Details', style: TextStyle(fontSize: 13))],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_status',
                                child: Row(
                                  children: [
                                    Icon(isActive ? Icons.block_flipped : Icons.check_circle_outline, size: 16),
                                    const SizedBox(width: 8),
                                    Text(isActive ? 'Disable User' : 'Enable User', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'reset_password',
                                child: Row(
                                  children: [Icon(Icons.lock_reset_rounded, size: 16), SizedBox(width: 8), Text('Reset Password', style: TextStyle(fontSize: 13))],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16), SizedBox(width: 8), Text('Delete User', style: TextStyle(color: Colors.red, fontSize: 13))],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

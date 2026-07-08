import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../domain/models/user_profile.dart';

class ProfileEditDialog {
  ProfileEditDialog._();

  static void show({
    required BuildContext context,
    required UserProfile profile,
    required Function(UserProfile updated) onConfirm,
  }) {
    final nameController = TextEditingController(text: profile.name);
    final roleController = TextEditingController(text: profile.role);
    // Everyone should have Fraylon Technologies LLP only
    final orgController = TextEditingController(text: 'Fraylon Technologies LLP');
    final emailController = TextEditingController(text: profile.email);
    final phoneController = TextEditingController(text: profile.phone);

    final formKey = GlobalKey<FormState>();
    String selectedDept = profile.department.isEmpty ? 'Engineering' : profile.department;
    final departmentsList = [
      'Engineering',
      'Design',
      'Support',
      'HQ',
      'Operations',
      'Product Management',
      'Sales & Marketing',
      'Human Resources',
    ];
    if (!departmentsList.contains(selectedDept)) {
      departmentsList.add(selectedDept);
    }

    CustomDialog.show(
      context: context,
      title: 'Edit Profile Information',
      confirmLabel: 'Save',
      onConfirm: () {
        if (formKey.currentState?.validate() ?? false) {
          final updated = profile.copyWith(
            name: nameController.text.trim(),
            role: roleController.text.trim(),
            department: selectedDept,
            organization: orgController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
          );
          onConfirm(updated);
          Navigator.pop(context);
        }
      },
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          Widget buildCleanInput({
            required TextEditingController controller,
            required String label,
            required String hint,
            TextInputType keyboardType = TextInputType.text,
            String? Function(String?)? validator,
            bool enabled = true,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? (enabled ? const Color(0xFF94A3B8) : const Color(0xFF475569)) 
                        : (enabled ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  enabled: enabled,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark 
                        ? (enabled ? Colors.white : const Color(0xFF64748B)) 
                        : (enabled ? const Color(0xFF0F172A) : const Color(0xFF94A3B8)),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: isDark 
                        ? (enabled ? const Color(0xFF0F172A) : const Color(0xFF1E293B)) 
                        : (enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          Widget buildDropdownInput({
            required String selectedValue,
            required List<String> items,
            required String label,
            required Function(String) onChanged,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedValue,
                  items: items
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }

          return Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  buildCleanInput(
                    controller: nameController,
                    label: 'Full Name',
                    hint: 'Enter your name',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  buildCleanInput(
                    controller: roleController,
                    label: 'Job Title / Role',
                    hint: 'Role',
                    enabled: false,
                  ),
                  buildDropdownInput(
                    selectedValue: selectedDept,
                    items: departmentsList,
                    label: 'Department',
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDept = val;
                      });
                    },
                  ),
                  buildCleanInput(
                    controller: orgController,
                    label: 'Organization',
                    hint: 'Fraylon Technologies LLP',
                    enabled: false,
                  ),
                  buildCleanInput(
                    controller: emailController,
                    label: 'Email Address',
                    hint: 'e.g. jane.doe@fraylontech.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      final email = val.trim().toLowerCase();
                      if (!email.contains('@')) {
                        return 'Enter a valid email';
                      }
                      if (!email.endsWith('@fraylontech.com')) {
                        return 'Email must end with @fraylontech.com';
                      }
                      return null;
                    },
                  ),
                  buildCleanInput(
                    controller: phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. +1 (555) 019-2834',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

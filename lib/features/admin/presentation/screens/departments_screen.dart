import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class DepartmentItem {
  final String id;
  final String name;
  final String description;
  final String code;

  DepartmentItem({
    required this.id,
    required this.name,
    required this.description,
    required this.code,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'code': code,
      };

  factory DepartmentItem.fromMap(Map<String, dynamic> map) => DepartmentItem(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        code: map['code'] ?? '',
      );
}

class DepartmentsScreen extends ConsumerStatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  ConsumerState<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends ConsumerState<DepartmentsScreen> {
  List<DepartmentItem> _departments = [];
  bool _isLoading = false;
  static const _deptKey = 'mock_departments_data';

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_deptKey);
      if (jsonStr != null) {
        final List decoded = jsonDecode(jsonStr);
        setState(() {
          _departments = decoded.map((x) => DepartmentItem.fromMap(x)).toList();
        });
      } else {
        _departments = [
          DepartmentItem(id: 'dept_engineering', name: 'Engineering', description: 'Software design and infrastructure development.', code: 'ENG'),
          DepartmentItem(id: 'dept_design', name: 'Design', description: 'Product user experience and creative branding.', code: 'DSN'),
          DepartmentItem(id: 'dept_support', name: 'Support', description: 'Customer service, onboarding, and feedback loops.', code: 'SUP'),
          DepartmentItem(id: 'dept_hq', name: 'HQ', description: 'Executive operations, workspace direction, and strategy.', code: 'HQ'),
        ];
        await _save();
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _departments.map((x) => x.toMap()).toList();
      await prefs.setString(_deptKey, jsonEncode(list));
    } catch (_) {}
  }

  void _openDepartmentDialog([DepartmentItem? dept]) {
    final isEdit = dept != null;
    final nameController = TextEditingController(text: dept?.name);
    final codeController = TextEditingController(text: dept?.code);
    final descController = TextEditingController(text: dept?.description);
    final formKey = GlobalKey<FormState>();

    CustomDialog.show(
      context: context,
      title: isEdit ? 'Edit Department details' : 'Create New Department',
      confirmLabel: isEdit ? 'Save Changes' : 'Create Department',
      onConfirm: () async {
        if (!formKey.currentState!.validate()) return;

        final newDept = DepartmentItem(
          id: isEdit ? dept.id : 'dept_${DateTime.now().millisecondsSinceEpoch}',
          name: nameController.text.trim(),
          code: codeController.text.trim().toUpperCase(),
          description: descController.text.trim(),
        );

        setState(() {
          if (isEdit) {
            final idx = _departments.indexWhere((d) => d.id == dept.id);
            if (idx >= 0) _departments[idx] = newDept;
          } else {
            _departments.add(newDept);
          }
        });
        await _save();
        Navigator.pop(context);
      },
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: nameController,
              label: 'Department Name',
              hint: 'e.g. Quality Assurance',
              validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: codeController,
              label: 'Department Code',
              hint: 'e.g. QA',
              validator: (val) => val == null || val.trim().isEmpty ? 'Code is required' : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: descController,
              label: 'Description',
              hint: 'Describe department scope...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(DepartmentItem dept) {
    CustomDialog.show(
      context: context,
      title: 'Delete Department',
      content: Text('Are you sure you want to delete department ${dept.name}? This will remove department references for associated employees.'),
      confirmLabel: 'Delete',
      isDestructive: true,
      onConfirm: () async {
        setState(() {
          _departments.removeWhere((d) => d.id == dept.id);
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
                          'Departments Management',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure enterprise departments and organize team workflows.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openDepartmentDialog(),
                    icon: const Icon(Icons.corporate_fare_rounded, size: 18),
                    label: const Text('Add Department'),
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

              // Department Grid / List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _departments.isEmpty
                        ? const Center(child: Text('No departments registered.'))
                        : ListView.builder(
                            itemCount: _departments.length,
                            itemBuilder: (context, index) {
                              final dept = _departments[index];

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
                                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          dept.code,
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dept.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dept.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            _openDepartmentDialog(dept);
                                          } else if (action == 'delete') {
                                            _showDeleteConfirmation(dept);
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

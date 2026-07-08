import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_dialog.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/announcement.dart';

class AnnouncementDialogs {
  AnnouncementDialogs._();

  static void showCreate({
    required BuildContext context,
    required String defaultAuthor,
    required Function(String title, String description, String priority, String author) onConfirm,
  }) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final authorController = TextEditingController(text: defaultAuthor);
    String selectedPriority = 'Info';

    final formKey = GlobalKey<FormState>();

    CustomDialog.show(
      context: context,
      title: 'Create Announcement',
      confirmLabel: 'Post',
      onConfirm: () {
        if (formKey.currentState?.validate() ?? false) {
          onConfirm(
            titleController.text.trim(),
            descController.text.trim(),
            selectedPriority,
            authorController.text.trim().isNotEmpty ? authorController.text.trim() : 'Anonymous',
          );
          Navigator.pop(context);
        }
      },
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: titleController,
                  label: 'Title',
                  hint: 'Enter announcement title',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field with multiline style matching CustomTextField
                TextFormField(
                  controller: descController,
                  maxLines: 4,
                  minLines: 3,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter announcement details...',
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: authorController,
                  label: 'Author Name',
                  hint: 'Optional author name override',
                ),
                const SizedBox(height: 16),

                Text(
                  'Announcement Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Info', 'Notice', 'Alert', 'Urgent'].map((priority) {
                    final isSelected = selectedPriority == priority;
                    Color priorityColor;
                    switch (priority) {
                      case 'Urgent':
                        priorityColor = AppColors.error;
                        break;
                      case 'Alert':
                        priorityColor = AppColors.warning;
                        break;
                      case 'Notice':
                        priorityColor = AppColors.secondary;
                        break;
                      case 'Info':
                      default:
                        priorityColor = AppColors.info;
                    }

                    return ChoiceChip(
                      label: Text(priority),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      selectedColor: priorityColor,
                      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? priorityColor : theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setDialogState(() => selectedPriority = priority);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static void showEdit({
    required BuildContext context,
    required Announcement announcement,
    required Function(Announcement updated) onConfirm,
  }) {
    final titleController = TextEditingController(text: announcement.title);
    final descController = TextEditingController(text: announcement.description);
    final authorController = TextEditingController(text: announcement.author);
    String selectedPriority = announcement.priority;

    final formKey = GlobalKey<FormState>();

    CustomDialog.show(
      context: context,
      title: 'Edit Announcement',
      confirmLabel: 'Save',
      onConfirm: () {
        if (formKey.currentState?.validate() ?? false) {
          onConfirm(
            announcement.copyWith(
              title: titleController.text.trim(),
              description: descController.text.trim(),
              author: authorController.text.trim().isNotEmpty ? authorController.text.trim() : 'Anonymous',
              priority: selectedPriority,
            ),
          );
          Navigator.pop(context);
        }
      },
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: titleController,
                  label: 'Title',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description field with multiline style matching CustomTextField
                TextFormField(
                  controller: descController,
                  maxLines: 4,
                  minLines: 3,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Description',
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outline, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: authorController,
                  label: 'Author Name',
                ),
                const SizedBox(height: 16),

                Text(
                  'Announcement Type',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Info', 'Notice', 'Alert', 'Urgent'].map((priority) {
                    final isSelected = selectedPriority == priority;
                    Color priorityColor;
                    switch (priority) {
                      case 'Urgent':
                        priorityColor = AppColors.error;
                        break;
                      case 'Alert':
                        priorityColor = AppColors.warning;
                        break;
                      case 'Notice':
                        priorityColor = AppColors.secondary;
                        break;
                      case 'Info':
                      default:
                        priorityColor = AppColors.info;
                    }

                    return ChoiceChip(
                      label: Text(priority),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      selectedColor: priorityColor,
                      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      checkmarkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? priorityColor : theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setDialogState(() => selectedPriority = priority);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

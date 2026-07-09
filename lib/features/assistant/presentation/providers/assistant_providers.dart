import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../announcements/presentation/providers/announcement_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/permission_service.dart';
import '../../domain/models/chat_message.dart';

class AssistantNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  AssistantNotifier(this._ref)
      : super([
          ChatMessage(
            id: 'welcome_1',
            content: 'Hello! I\'m **Fraylon AI**, your virtual workplace assistant. How can I help you today?',
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
            suggestedActions: const [
              'Summarize today\'s tasks',
              'Create a high priority task to audit code tomorrow',
              'Search task "database"',
              'Workspace activity status',
            ],
          ),
        ]);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    state = [...state, userMsg];

    // Simulate thinking delay
    await Future.delayed(const Duration(milliseconds: 750));

    final reply = _processMessage(text);
    state = [...state, reply];
  }

  ChatMessage _processMessage(String text) {
    final query = text.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Task Summary Action
    if (query.contains('summarize') ||
        query.contains('summary') ||
        query.contains('today\'s tasks') ||
        query.contains('what are my tasks')) {
      final tasks = _ref.read(tasksStreamProvider).value ?? [];
      final pending = tasks.where((t) => t.status != 'Completed').toList();
      final completed = tasks.where((t) => t.status == 'Completed').toList();

      if (tasks.isEmpty) {
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'You don\'t have any tasks in your workspace yet. Try saying: *"Create task to audit security logs"* to get started.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          suggestedActions: ['Create task "Audit code"', 'Workspace activity status'],
        );
      }

      final buffer = StringBuffer();
      buffer.writeln('📋 **Workspace Task Summary**\n');
      buffer.writeln('You have **${pending.length}** pending and **${completed.length}** completed tasks.');

      if (pending.isNotEmpty) {
        buffer.writeln('\n**Pending items:**');
        for (var task in pending.take(5)) {
          final priorityPrefix = task.priority == 'High' ? '[High]' : (task.priority == 'Medium' ? '[Medium]' : '[Low]');
          buffer.writeln('- $priorityPrefix **${task.title}** (Priority: ${task.priority})');
        }
        if (pending.length > 5) {
          buffer.writeln('- *...and ${pending.length - 5} more.*');
        }
      } else {
        buffer.writeln('\nOutstanding job! You have no pending tasks.');
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: buffer.toString(),
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedActions: ['Search task "design"', 'Workspace activity status'],
      );
    }

    // 2. Create Task Action (Natural Language Regex matching)
    final createPattern = RegExp(r'(?:create|add|new)\s+task\s+(?:to\s+)?(.+)', caseSensitive: false);
    if (createPattern.hasMatch(query)) {
      final match = createPattern.firstMatch(text);
      var taskText = match?.group(1) ?? '';

      // Clean task text and parse clues
      var priority = 'Medium';
      if (taskText.toLowerCase().contains('high priority') || taskText.toLowerCase().contains('urgent')) {
        priority = 'High';
        taskText = taskText.replaceAll(RegExp(r'\bhigh priority\b', caseSensitive: false), '').trim();
        taskText = taskText.replaceAll(RegExp(r'\burgent\b', caseSensitive: false), '').trim();
      } else if (taskText.toLowerCase().contains('low priority')) {
        priority = 'Low';
        taskText = taskText.replaceAll(RegExp(r'\blow priority\b', caseSensitive: false), '').trim();
      }

      var dueDate = now.add(const Duration(days: 2)); // Default: 2 days
      if (taskText.toLowerCase().contains('tomorrow')) {
        dueDate = now.add(const Duration(days: 1));
        taskText = taskText.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '').trim();
      } else if (taskText.toLowerCase().contains('today')) {
        dueDate = now;
        taskText = taskText.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '').trim();
      } else if (taskText.toLowerCase().contains('next week')) {
        dueDate = now.add(const Duration(days: 7));
        taskText = taskText.replaceAll(RegExp(r'\bnext week\b', caseSensitive: false), '').trim();
      }

      // Final cleanups of connector words e.g. "to" or "about"
      taskText = taskText.replaceAll(RegExp(r'^(?:to|for|about|that)\s+', caseSensitive: false), '').trim();
      if (taskText.isEmpty) taskText = 'New Task';

      // Check permission — Employees cannot create tasks.
      final userProfile = _ref.read(userProfileProvider).valueOrNull;
      final permissionService = _ref.read(permissionServiceProvider);
      if (userProfile == null || !permissionService.canCreateTasks(userProfile)) {
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Sorry, you don\'t have permission to create tasks. Please ask your Manager to assign tasks to you.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          suggestedActions: ['Summarize today\'s tasks', 'Workspace activity status'],
        );
      }

      // programmatically execute task creation in database,
      // auto-assigning to the creator so it appears in their task list.
      _ref.read(taskActionControllerProvider.notifier).createTask(
            title: taskText,
            description: 'Created by Fraylon AI from natural language.',
            status: 'Todo',
            priority: priority,
            dueDate: dueDate,
            assigneeId: userProfile.uid,
            assigneeName: userProfile.name,
          );

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '**Task Created!**\n\nI have added the task successfully to your database.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        isTaskSnippet: true,
        taskTitle: taskText,
        taskPriority: priority,
        taskDueDate: dueDate,
        suggestedActions: ['Summarize today\'s tasks', 'Workspace activity status'],
      );
    }

    // 3. Search Action
    final searchPattern = RegExp(r'(?:search|find|lookup)\s+(?:for\s+)?(?:task|announcement)?\s*(.+)', caseSensitive: false);
    if (searchPattern.hasMatch(query)) {
      final match = searchPattern.firstMatch(text);
      final term = (match?.group(1) ?? '').toLowerCase().trim();

      if (term.isEmpty) {
        return ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Please enter a search query, e.g. *"Search database"*',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        );
      }

      final tasks = _ref.read(tasksStreamProvider).value ?? [];
      final announcements = _ref.read(announcementsStreamProvider).value ?? [];

      final matchedTasks = tasks.where((t) =>
          t.title.toLowerCase().contains(term) || t.description.toLowerCase().contains(term)).toList();
      final matchedAnnouncements = announcements.where((a) =>
          a.title.toLowerCase().contains(term) || a.description.toLowerCase().contains(term)).toList();

      final buffer = StringBuffer();
      buffer.writeln('🔍 **Search Results for "$term"**\n');

      if (matchedTasks.isNotEmpty) {
        buffer.writeln('**Tasks (${matchedTasks.length}):**');
        for (var t in matchedTasks.take(3)) {
          buffer.writeln('- [ ] **${t.title}** (${t.status})');
        }
      }

      if (matchedAnnouncements.isNotEmpty) {
        if (matchedTasks.isNotEmpty) buffer.writeln('');
        buffer.writeln('**Announcements (${matchedAnnouncements.length}):**');
        for (var a in matchedAnnouncements.take(3)) {
          buffer.writeln('- 📢 **${a.title}** (Author: ${a.author})');
        }
      }

      if (matchedTasks.isEmpty && matchedAnnouncements.isEmpty) {
        buffer.writeln('No tasks or announcements matching "$term" were found.');
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: buffer.toString(),
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedActions: ['Summarize today\'s tasks', 'Workspace activity status'],
      );
    }

    // 4. Suggest Priorities and Deadlines Action
    if (query.contains('suggest') || query.contains('recommend') || query.contains('priority') || query.contains('deadline')) {
      var priority = 'Medium';
      var deadlineDays = 3;
      var reason = 'Standard timeline recommendation.';

      if (query.contains('migration') || query.contains('database') || query.contains('security') || query.contains('hotfix')) {
        priority = 'High';
        deadlineDays = 2;
        reason = 'Critical infrastructure or security operations require short turnaround cycles.';
      } else if (query.contains('documentation') || query.contains('clean') || query.contains('test')) {
        priority = 'Low';
        deadlineDays = 7;
        reason = 'Non-blocking maintenance and documentation tasks can be deferred to weekly backlogs.';
      } else if (query.contains('design') || query.contains('ui') || query.contains('frontend')) {
        priority = 'Medium';
        deadlineDays = 4;
        reason = 'Creative layouts and front-end polishing require iterative review sessions.';
      }

      final dateStr = '${now.add(Duration(days: deadlineDays)).day}/${now.add(Duration(days: deadlineDays)).month}';

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '**AI Suggested Configuration**\n\nBased on task analysis:\n- **Recommended Priority**: $priority\n- **Recommended Timeline**: $deadlineDays days (Due by $dateStr)\n\n*Reasoning: $reason*',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedActions: [
          'Create task to audit databases High Priority',
          'Summarize today\'s tasks'
        ],
      );
    }

    // 5. Workspace Activity Status
    if (query.contains('status') || query.contains('activity') || query.contains('progress') || query.contains('workspace')) {
      final tasks = _ref.read(tasksStreamProvider).value ?? [];
      final completed = tasks.where((t) => t.status == 'Completed').length;
      final pending = tasks.length - completed;
      final announcementsCount = _ref.read(announcementsStreamProvider).value?.length ?? 0;

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '**Workspace Status Report**\n\n'
            '- Total Tasks: **${tasks.length}**\n'
            '- Completed: **$completed**\n'
            '- Pending: **$pending**\n'
            '- Total Announcements: **$announcementsCount**\n\n'
            'The workspace is active and up to date.',
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        suggestedActions: ['Summarize today\'s tasks', 'Search task "design"'],
      );
    }

    // Default Fallback Help Message
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'I didn\'t quite catch that. Here are some things I can assist you with:\n\n'
          '1. **Summarize** today\'s pending actions: *"Summarize my tasks"*\n'
          '2. **Create** tasks from text: *"Create task to audit security logs High Priority tomorrow"*\n'
          '3. **Search** tasks/news: *"Search announcement office closure"*\n'
          '4. **Suggest** configurations: *"Suggest priority for UI design"*',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      suggestedActions: [
        'Summarize today\'s tasks',
        'Create task to check api next week',
        'Workspace activity status'
      ],
    );
  }
}

final assistantMessagesProvider = StateNotifierProvider<AssistantNotifier, List<ChatMessage>>((ref) {
  return AssistantNotifier(ref);
});

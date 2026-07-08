import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/chat_message.dart';
import '../providers/assistant_providers.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    ref.read(assistantMessagesProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppColors.error;
      case 'Medium':
        return AppColors.warning;
      case 'Low':
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final messages = ref.watch(assistantMessagesProvider);

    // Staggered scroll updates on incoming messages
    ref.listen<List<ChatMessage>>(assistantMessagesProvider, (prev, next) {
      _scrollToBottom();
    });

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 800;

    // Direct Quick actions toolbar suggestions
    final lastMessage = messages.isNotEmpty ? messages.last : null;
    final suggestions = lastMessage?.suggestedActions ?? [
      'Summarize today\'s tasks',
      'Workspace activity status',
      'Suggest task priority',
    ];

    // Header Toolbar
    final headerWidget = Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.bolt_rounded, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fraylon AI',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69D36E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online • Ready to orchestrate workspace',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    // Message List builder
    Widget buildMessagesList() {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isUser = msg.sender == MessageSender.user;

          Widget bubbleContent = Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: isDesktop ? 600 : screenWidth * 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                      : (isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade100),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isUser ? 12 : 0),
                    bottomRight: Radius.circular(isUser ? 0 : 12),
                  ),
                  border: Border.all(
                    color: isUser
                        ? theme.colorScheme.primary.withValues(alpha: 0.25)
                        : (isDark ? theme.colorScheme.outline.withValues(alpha: 0.2) : Colors.grey.shade200),
                    width: 1,
                  ),
                ),
                child: Text(
                  msg.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (msg.isTaskSnippet && msg.taskTitle != null) ...[
                const SizedBox(height: 6),
                // Task Creation visual card snippet
                Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainer : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.assignment_turned_in_rounded, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg.taskTitle!,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Priority indicator
                          if (msg.taskPriority != null)
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(msg.taskPriority!),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  msg.taskPriority!,
                                  style: TextStyle(
                                    color: _getPriorityColor(msg.taskPriority!),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          // Due Date
                          if (msg.taskDueDate != null)
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 10, color: theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(msg.taskDueDate!),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 9.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: bubbleContent,
            ),
          );
        },
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerWidget,
              const SizedBox(height: 12),
              const Divider(height: 1, thickness: 0.5),
              const SizedBox(height: 8),
              // Message Logs
              Expanded(
                child: buildMessagesList(),
              ),
              // Quick suggestions chips bar
              if (suggestions.isNotEmpty)
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final suggest = suggestions[idx];
                      return ActionChip(
                        label: Text(
                          suggest,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        onPressed: () {
                          ref.read(assistantMessagesProvider.notifier).sendMessage(suggest);
                          _scrollToBottom();
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              // Input field container
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: (_) => _handleSend(),
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ask Fraylon AI to create a task, summarize, or search...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

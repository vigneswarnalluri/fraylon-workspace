enum MessageSender {
  user,
  ai,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final List<String> suggestedActions;
  final bool isTaskSnippet;
  final String? taskTitle;
  final String? taskPriority;
  final DateTime? taskDueDate;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.suggestedActions = const [],
    this.isTaskSnippet = false,
    this.taskTitle,
    this.taskPriority,
    this.taskDueDate,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
    List<String>? suggestedActions,
    bool? isTaskSnippet,
    String? taskTitle,
    String? taskPriority,
    DateTime? taskDueDate,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      isTaskSnippet: isTaskSnippet ?? this.isTaskSnippet,
      taskTitle: taskTitle ?? this.taskTitle,
      taskPriority: taskPriority ?? this.taskPriority,
      taskDueDate: taskDueDate ?? this.taskDueDate,
    );
  }
}

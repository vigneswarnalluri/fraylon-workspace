
class TaskComment {
  final String id;
  final String userName;
  final String text;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  TaskComment copyWith({
    String? id,
    String? userName,
    String? text,
    DateTime? createdAt,
  }) {
    return TaskComment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] ?? '',
      userName: map['userName'] ?? '',
      text: map['text'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class TaskHistoryEntry {
  final String id;
  final String action;
  final DateTime timestamp;

  TaskHistoryEntry({
    required this.id,
    required this.action,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TaskHistoryEntry.fromMap(Map<String, dynamic> map) {
    return TaskHistoryEntry(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String status; // 'Todo', 'In Progress', 'Review', 'Completed'
  final String priority; // 'Low', 'Medium', 'High'
  final DateTime dueDate;
  final List<TaskComment> comments;
  final List<TaskHistoryEntry> history;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assigneeId;
  final String? assigneeName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.comments,
    required this.history,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.assigneeName,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    List<TaskComment>? comments,
    List<TaskHistoryEntry>? history,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assigneeId,
    String? assigneeName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      history: history ?? this.history,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'comments': comments.map((x) => x.toMap()).toList(),
      'history': history.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String docId) {
    return Task(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Todo',
      priority: map['priority'] ?? 'Medium',
      dueDate: DateTime.tryParse(map['dueDate'] ?? '') ?? DateTime.now(),
      comments: (map['comments'] as List?)?.map((x) => TaskComment.fromMap(x)).toList() ?? [],
      history: (map['history'] as List?)?.map((x) => TaskHistoryEntry.fromMap(x)).toList() ?? [],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      assigneeId: map['assigneeId'],
      assigneeName: map['assigneeName'],
    );
  }
}

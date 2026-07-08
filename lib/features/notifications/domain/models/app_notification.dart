class AppNotification {
  final String id;
  final String title;
  final String message;
  final String category; // 'Task', 'Announcement', 'System'
  final String priority; // 'Low', 'Medium', 'High', 'Urgent'
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.priority,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    String? priority,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'priority': priority,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedDate = DateTime.now();
    try {
      final rawDate = map['createdAt'];
      if (rawDate != null) {
        if (rawDate is String) {
          parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
        } else {
          parsedDate = (rawDate as dynamic).toDate() as DateTime;
        }
      }
    } catch (_) {}

    return AppNotification(
      id: docId,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      category: map['category'] ?? 'System',
      priority: map['priority'] ?? 'Info',
      isRead: map['isRead'] ?? false,
      createdAt: parsedDate,
    );
  }
}

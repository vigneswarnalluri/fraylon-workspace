class Announcement {
  final String id;
  final String title;
  final String description;
  final String author;
  final DateTime createdAt;
  final String priority; // 'Info', 'Notice', 'Alert', 'Urgent'

  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.createdAt,
    required this.priority,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? description,
    String? author,
    DateTime? createdAt,
    String? priority,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, String docId) {
    return Announcement(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author'] ?? 'Unknown',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      priority: map['priority'] ?? 'Info',
    );
  }
}

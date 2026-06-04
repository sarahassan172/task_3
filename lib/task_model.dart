import 'dart:convert';

class Task {
  final String id;
  final String title;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  // Convert Task → JSON string (for SharedPreferences storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  String toJson() => jsonEncode(toMap());

  // Convert JSON string → Task (for loading from SharedPreferences)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  factory Task.fromJson(String source) =>
      Task.fromMap(jsonDecode(source));
}

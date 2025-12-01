class Todo {
  final String id;
  String title;
  bool isCompleted;
  DateTime date;

  String category;
  String details;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.category = 'Personal',
    this.details = '',
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      isCompleted: json['isCompleted'],
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      category: json['category'] ?? 'Personal',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'category': category,
      'details': details,
    };
  }
}

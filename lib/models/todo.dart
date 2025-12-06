import 'package:isar/isar.dart';

part 'todo.g.dart';

@embedded
class Subtask {
  String title;
  bool isCompleted;

  Subtask({this.title = '', this.isCompleted = false});

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      title: json['title'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'isCompleted': isCompleted};
  }
}

enum RecurrenceInterval { none, daily, weekly, monthly }

@collection
class Todo {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  final String id;
  String title;
  bool isCompleted;
  DateTime date;

  String category;
  String details;

  DateTime? reminderDateTime;

  @Enumerated(EnumType.name)
  RecurrenceInterval recurrence;

  List<Subtask> subtasks;

  int estimatedPomodoros;
  int completedPomodoros;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.date,
    this.category = 'Personal',
    this.details = '',
    this.reminderDateTime,
    this.recurrence = RecurrenceInterval.none,
    this.subtasks = const [],
    this.estimatedPomodoros = 0,
    this.completedPomodoros = 0,
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
      reminderDateTime: json['reminderDateTime'] != null
          ? DateTime.parse(json['reminderDateTime'])
          : null,
      recurrence: json['recurrence'] != null
          ? RecurrenceInterval.values.firstWhere(
              (e) => e.name == json['recurrence'],
              orElse: () => RecurrenceInterval.none,
            )
          : RecurrenceInterval.none,
      subtasks: json['subtasks'] != null
          ? (json['subtasks'] as List).map((e) => Subtask.fromJson(e)).toList()
          : [],
      estimatedPomodoros: json['estimatedPomodoros'] ?? 0,
      completedPomodoros: json['completedPomodoros'] ?? 0,
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
      'reminderDateTime': reminderDateTime?.toIso8601String(),
      'recurrence': recurrence.name,
      'subtasks': subtasks.map((e) => e.toJson()).toList(),
      'estimatedPomodoros': estimatedPomodoros,
      'completedPomodoros': completedPomodoros,
    };
  }
}

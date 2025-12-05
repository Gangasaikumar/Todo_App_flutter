import '../models/todo.dart';

class DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final Map<String, int> categoryStats;
  final List<int> weeklyCompleted;
  final List<int> weeklyPending;

  DashboardStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.categoryStats,
    required this.weeklyCompleted,
    required this.weeklyPending,
  });
}

abstract class DashboardRepository {
  Future<DashboardStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
    required List<Todo> todos,
  });
}

class LocalDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
    required List<Todo> todos,
  }) async {
    // Filter todos within range
    final rangeTodos = todos.where((todo) {
      final date = DateTime(todo.date.year, todo.date.month, todo.date.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);
      return (date.isAtSameMomentAs(start) || date.isAfter(start)) &&
          (date.isAtSameMomentAs(end) || date.isBefore(end));
    }).toList();

    final total = rangeTodos.length;
    final completed = rangeTodos.where((t) => t.isCompleted).length;
    final pending = rangeTodos.where((t) => !t.isCompleted).length;

    // Category Stats
    final categoryStats = <String, int>{};
    for (var todo in rangeTodos) {
      categoryStats[todo.category] = (categoryStats[todo.category] ?? 0) + 1;
    }

    // Weekly Stats
    final weeklyCompleted = List<int>.filled(7, 0);
    final weeklyPending = List<int>.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final date = endDate.subtract(Duration(days: 6 - i));
      final dayTodos = todos.where((todo) {
        return todo.date.year == date.year &&
            todo.date.month == date.month &&
            todo.date.day == date.day;
      }).toList();

      weeklyCompleted[i] = dayTodos.where((t) => t.isCompleted).length;
      weeklyPending[i] = dayTodos.where((t) => !t.isCompleted).length;
    }

    return DashboardStats(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
      categoryStats: categoryStats,
      weeklyCompleted: weeklyCompleted,
      weeklyPending: weeklyPending,
    );
  }
}

import '../models/todo.dart';
import '../services/isar_service.dart';
import 'package:isar/isar.dart';

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
    List<Todo>? todos,
  });
}

class LocalDashboardRepository implements DashboardRepository {
  final IsarService _isarService = IsarService();

  @override
  Future<DashboardStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
    List<Todo>? todos,
  }) async {
    final isar = await _isarService.db;

    // Normalize dates to start and end of day
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // Fetch todos for the range
    final rangeTodos = await isar.todos
        .filter()
        .dateBetween(start, end)
        .findAll();

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
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final dayTodos = await isar.todos
          .filter()
          .dateBetween(dayStart, dayEnd)
          .findAll();

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

import '../models/todo.dart';
import '../services/isar_service.dart';
import 'package:isar/isar.dart';

class DashboardStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int totalFocusMinutes;
  final int pendingFocusMinutes; // New
  final int todayFocusMinutes;
  final Map<String, int> categoryStats;
  final Map<String, int> categoryFocusMinutes; // New
  final List<int> weeklyCompleted;
  final List<int> weeklyPending;
  final List<int> weeklyFocusMinutes;
  final int totalXP; // New
  final int currentLevel; // New
  final double currentLevelProgress; // New
  final DashboardStats? comparisonStats; // New

  DashboardStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.totalFocusMinutes,
    required this.pendingFocusMinutes,
    required this.todayFocusMinutes,
    required this.categoryStats,
    required this.categoryFocusMinutes,
    required this.weeklyCompleted,
    required this.weeklyPending,
    required this.weeklyFocusMinutes,
    required this.totalXP,
    required this.currentLevel,
    required this.currentLevelProgress,
    this.comparisonStats,
  });
}

abstract class DashboardRepository {
  Future<DashboardStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
    List<Todo>? todos,
    bool includeComparison = true,
  });
}

class LocalDashboardRepository implements DashboardRepository {
  final IsarService _isarService = IsarService();

  @override
  Future<DashboardStats> getStats({
    required DateTime startDate,
    required DateTime endDate,
    List<Todo>? todos,
    bool includeComparison = true,
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

    // Calculate Total Focus Time (approx 30 mins per pomodoro)
    final totalFocusMinutes = rangeTodos.fold(
      0,
      (sum, todo) => sum + (todo.completedPomodoros * 30),
    );

    // Category Stats
    final categoryStats = <String, int>{};
    for (var todo in rangeTodos) {
      categoryStats[todo.category] = (categoryStats[todo.category] ?? 0) + 1;
    }

    // Weekly Stats
    final weeklyCompleted = List<int>.filled(7, 0);
    final weeklyPending = List<int>.filled(7, 0);
    final weeklyFocusMinutes = List<int>.filled(7, 0);

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
      weeklyFocusMinutes[i] = dayTodos.fold(
        0,
        (sum, t) => sum + (t.completedPomodoros * 30),
      );
    }

    final pendingFocusMinutes = rangeTodos.where((t) => !t.isCompleted).fold(
      0,
      (sum, todo) {
        final remaining = todo.estimatedPomodoros - todo.completedPomodoros;
        return sum + ((remaining > 0 ? remaining : 0) * 30);
      },
    );

    // Calculate Today's Focus Minutes (for Capacity Loop)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final todayTodos = await isar.todos
        .filter()
        .dateBetween(todayStart, todayEnd)
        .findAll();

    final todayFocusMinutes = todayTodos.fold(
      0,
      (sum, todo) => sum + (todo.completedPomodoros * 30),
    );

    // Calculate Category Focus Minutes
    final categoryFocusMinutes = <String, int>{};
    for (var todo in rangeTodos) {
      final focusTime = todo.completedPomodoros * 30;
      if (focusTime > 0) {
        categoryFocusMinutes[todo.category] =
            (categoryFocusMinutes[todo.category] ?? 0) + focusTime;
      }
    }

    // Calculate Gamification Stats (Global)
    final allTimeCompleted = await isar.todos
        .filter()
        .isCompletedEqualTo(true)
        .count();
    final allTimeFocusMinutes = (await isar.todos.where().findAll()).fold(
      0,
      (sum, t) => sum + (t.completedPomodoros * 30),
    );

    final totalXP = (allTimeCompleted * 10) + allTimeFocusMinutes;
    final currentLevel = (totalXP / 100).floor() + 1;
    final nextLevelXP = 100; // Fixed 100 XP per level for simplicity
    final currentLevelProgress = (totalXP % 100).toDouble();

    // Calculate Comparison Stats (Previous Period)
    DashboardStats? comparisonStats;
    if (includeComparison) {
      final duration = endDate.difference(startDate);
      // Ensure specific duration handling (e.g. if 7 days, subtract 7 days)
      // Usually startDate is 00:00, endDate is 23:59. difference is 6d 23h 59m.
      // Simply subtract (duration + 1 second) or just 7 days?
      // Let's use simpler logic: duration in days.
      final days = duration.inDays + 1;
      final prevStart = startDate.subtract(Duration(days: days));
      final prevEnd = endDate.subtract(Duration(days: days));

      comparisonStats = await getStats(
        startDate: prevStart,
        endDate: prevEnd,
        includeComparison: false,
      );
    }

    return DashboardStats(
      totalTasks: total,
      completedTasks: completed,
      pendingTasks: pending,
      totalFocusMinutes: totalFocusMinutes,
      pendingFocusMinutes: pendingFocusMinutes,
      todayFocusMinutes: todayFocusMinutes,
      categoryStats: categoryStats,
      categoryFocusMinutes: categoryFocusMinutes,
      weeklyCompleted: weeklyCompleted,
      weeklyPending: weeklyPending,
      weeklyFocusMinutes: weeklyFocusMinutes,
      totalXP: totalXP,
      currentLevel: currentLevel,
      currentLevelProgress: currentLevelProgress,
      comparisonStats: comparisonStats,
    );
  }
}

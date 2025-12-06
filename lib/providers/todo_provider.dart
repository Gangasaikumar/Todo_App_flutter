import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/todo.dart';
import '../models/category_model.dart';
import '../services/notification_service.dart';
import '../repositories/dashboard_repository.dart';
import '../services/isar_service.dart';

class TodoProvider with ChangeNotifier {
  final IsarService _isarService = IsarService();
  final AppNotificationService _notificationService = AppNotificationService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Todo> _todos = [];
  DateTime _selectedDate = DateTime.now();

  // Streak Properties
  int _streakCount = 0;
  bool _soundEnabled = true;

  List<Todo> get todos => _todos;
  DateTime get selectedDate => _selectedDate;
  int get streakCount => _streakCount;
  bool get soundEnabled => _soundEnabled;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  List<Color> _savedColors = [];
  List<Color> get savedColors => _savedColors;

  TodoProvider() {
    _init();
  }

  Future<void> _init() async {
    await _migrateFromSharedPreferences();
    await loadTodos();
    await loadCategories();
    await _loadSoundSetting();
    await _loadFocusSettings();
    await _calculateStreak();
  }

  // --- Streak & Gamification Logic ---

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    notifyListeners();
  }

  Future<void> _calculateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _streakCount = prefs.getInt('streak_count') ?? 0;

    final lastCompletionStr = prefs.getString('last_completion_date');
    if (lastCompletionStr != null) {
      final lastCompletionDate = DateTime.parse(lastCompletionStr);
      final today = DateTime.now();
      final difference = DateTime(today.year, today.month, today.day)
          .difference(
            DateTime(
              lastCompletionDate.year,
              lastCompletionDate.month,
              lastCompletionDate.day,
            ),
          )
          .inDays;

      if (difference > 1) {
        // Missed a day
        _streakCount = 0;
        await prefs.setInt('streak_count', 0);
      }
    }
    notifyListeners();
  }

  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = DateTime(today.year, today.month, today.day).toString();

    final lastCompletionStr = prefs.getString('last_completion_date');

    if (lastCompletionStr != todayStr) {
      if (lastCompletionStr != null) {
        final lastCompletionDate = DateTime.parse(lastCompletionStr);
        final difference = DateTime(today.year, today.month, today.day)
            .difference(
              DateTime(
                lastCompletionDate.year,
                lastCompletionDate.month,
                lastCompletionDate.day,
              ),
            )
            .inDays;

        if (difference == 1) {
          _streakCount++;
        } else if (difference > 1) {
          _streakCount = 1;
        }
      } else {
        _streakCount = 1;
      }

      await prefs.setInt('streak_count', _streakCount);
      await prefs.setString('last_completion_date', todayStr);
      notifyListeners();
    }
  }

  Future<void> _playSound() async {
    if (_soundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/completion.mp3'));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }
    }
  }

  // --- Theme & Color Logic ---

  void addSavedColor(Color color) {
    if (!_savedColors.contains(color)) {
      _savedColors.add(color);
      _saveSavedColors();
      notifyListeners();
    }
  }

  void _saveSavedColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colorInts = _savedColors.map((c) => c.value).toList();
    prefs.setStringList(
      'saved_colors',
      colorInts.map((e) => e.toString()).toList(),
    );
  }

  Future<void> loadSavedColors() async {
    final prefs = await SharedPreferences.getInstance();
    final colorStrings = prefs.getStringList('saved_colors');
    if (colorStrings != null) {
      _savedColors = colorStrings.map((e) => Color(int.parse(e))).toList();
      notifyListeners();
    }
  }

  // --- Search & Filter Logic ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  bool _matchesFilter(Todo todo) {
    final matchesSearch = todo.title.toLowerCase().contains(
      _searchQuery.toLowerCase(),
    );
    final matchesCategory =
        _selectedCategoryFilter == 'All' ||
        todo.category == _selectedCategoryFilter;
    return matchesSearch && matchesCategory;
  }

  // --- Helper Methods ---

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // --- Todo Data Logic ---

  List<Todo> get todosForSelectedDate {
    return _todos
        .where(
          (todo) =>
              isSameDate(todo.date, _selectedDate) && _matchesFilter(todo),
        )
        .toList();
  }

  int get totalUncompletedCount {
    return _todos.where((todo) => !todo.isCompleted).length;
  }

  Map<DateTime, List<Todo>> get todosGroupedByDate {
    final Map<DateTime, List<Todo>> grouped = {};
    for (var todo in _todos) {
      if (!_matchesFilter(todo)) continue;
      final date = DateTime(todo.date.year, todo.date.month, todo.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(todo);
    }
    // Sort keys
    final sortedKeys = grouped.keys.toList()..sort();
    final Map<DateTime, List<Todo>> sortedMap = {};
    for (var key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  // --- Pomodoro Capacity Logic ---

  // --- Pomodoro Capacity & Settings Logic ---

  int _focusDurationMinutes = 30;
  int _dailyGoalHours = 8;

  int get focusDurationMinutes => _focusDurationMinutes;
  int get dailyGoalHours => _dailyGoalHours;

  int get dailyPomodoroCapacity =>
      (_dailyGoalHours * 60) ~/ _focusDurationMinutes;

  int getDailyPomoUsage(DateTime date) {
    final todosForDate = _todos.where((t) => isSameDate(t.date, date)).toList();
    int total = 0;
    for (var t in todosForDate) {
      total += t.estimatedPomodoros;
    }
    return total;
  }

  int get remainingDailyCapacity {
    return dailyPomodoroCapacity - getDailyPomoUsage(_selectedDate);
  }

  bool canAddPomodoros(DateTime date, int amount) {
    final currentUsage = getDailyPomoUsage(date);
    return (currentUsage + amount) <= dailyPomodoroCapacity;
  }

  Future<void> _loadFocusSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _focusDurationMinutes = prefs.getInt('focusDurationMinutes') ?? 30;
    _dailyGoalHours = prefs.getInt('dailyGoalHours') ?? 8;
    notifyListeners();
  }

  Future<void> updateFocusSettings(int durationMinutes, int hours) async {
    _focusDurationMinutes = durationMinutes;
    _dailyGoalHours = hours;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('focusDurationMinutes', durationMinutes);
    await prefs.setInt('dailyGoalHours', hours);
    notifyListeners();
  }

  Future<void> incrementCompletedPomodoros(String todoId) async {
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      final todo = _todos[index];
      todo.completedPomodoros = (todo.completedPomodoros) + 1;
      await _isarService.saveTodo(todo);
      notifyListeners();
    }
  }

  Future<void> _migrateFromSharedPreferences() async {
    // Migration logic placeholder
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadTodos() async {
    _todos = await _isarService.getAllTodos();
    notifyListeners();
  }

  Future<void> addTodo(
    String title,
    DateTime date,
    String category,
    String details,
    DateTime? reminderDateTime, [
    RecurrenceInterval recurrence = RecurrenceInterval.none,
    List<Subtask> subtasks = const [],
    int estimatedPomodoros = 0,
  ]) async {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      category: category,
      details: details,
      reminderDateTime: reminderDateTime,
      recurrence: recurrence,
      subtasks: subtasks,
      estimatedPomodoros: estimatedPomodoros,
    );

    await _isarService.saveTodo(newTodo);
    _todos.add(newTodo);
    notifyListeners();

    if (reminderDateTime != null && reminderDateTime.isAfter(DateTime.now())) {
      _notificationService.scheduleNotification(
        id: newTodo.id.hashCode,
        title: 'Task Reminder',
        body: newTodo.title,
        scheduledDate: reminderDateTime,
      );
    }

    _notificationService.showNotification(
      title: 'Task Added',
      body: 'Task "${newTodo.title}" has been added successfully.',
    );
  }

  Future<void> updateTodo(Todo todo) async {
    await _isarService.saveTodo(todo);

    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      notifyListeners();

      _notificationService.cancelNotification(todo.id.hashCode);

      if (todo.reminderDateTime != null &&
          !todo.isCompleted &&
          todo.reminderDateTime!.isAfter(DateTime.now())) {
        _notificationService.scheduleNotification(
          id: todo.id.hashCode,
          title: 'Task Reminder',
          body: todo.title,
          scheduledDate: todo.reminderDateTime!,
        );
      }

      _notificationService.showNotification(
        title: 'Task Updated',
        body: 'Task "${todo.title}" has been updated successfully.',
      );
    }
  }

  Future<void> deleteTodo(String id) async {
    await _isarService.deleteTodo(id);

    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1 && !_todos[index].isCompleted) {
      _todos.removeAt(index);
      notifyListeners();
      _notificationService.cancelNotification(id.hashCode);
    }
  }

  Future<void> toggleTodoStatus(String id) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      todo.isCompleted = !todo.isCompleted;
      await _isarService.saveTodo(todo);
      notifyListeners();

      if (todo.isCompleted) {
        _notificationService.cancelNotification(id.hashCode);

        await _updateStreak();
        await _playSound();

        if (todo.recurrence != RecurrenceInterval.none) {
          DateTime nextDate = todo.date;
          switch (todo.recurrence) {
            case RecurrenceInterval.daily:
              nextDate = nextDate.add(const Duration(days: 1));
              break;
            case RecurrenceInterval.weekly:
              nextDate = nextDate.add(const Duration(days: 7));
              break;
            case RecurrenceInterval.monthly:
              nextDate = DateTime(
                nextDate.year,
                nextDate.month + 1,
                nextDate.day,
              );
              break;
            case RecurrenceInterval.none:
              break;
          }

          final newSubtasks = todo.subtasks
              .map((s) => Subtask(title: s.title, isCompleted: false))
              .toList();

          final nextTodo = Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            date: nextDate,
            category: todo.category,
            details: todo.details,
            reminderDateTime: todo.reminderDateTime?.add(
              nextDate.difference(todo.date),
            ),
            recurrence: todo.recurrence,
            subtasks: newSubtasks,
          );

          await _isarService.saveTodo(nextTodo);
          _todos.add(nextTodo);
          notifyListeners();

          _notificationService.showNotification(
            title: 'Recurring Task Created',
            body:
                'Next task scheduled for ${nextDate.toString().split(' ')[0]}',
          );
        }
      } else {
        if (todo.reminderDateTime != null &&
            todo.reminderDateTime!.isAfter(DateTime.now())) {
          _notificationService.scheduleNotification(
            id: todo.id.hashCode,
            title: 'Task Reminder',
            body: todo.title,
            scheduledDate: todo.reminderDateTime!,
          );
        }
      }
    }
  }

  Todo? findById(String id) {
    try {
      return _todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  void reorderTodos(int oldIndex, int newIndex) {
    final currentTodos = todosForSelectedDate;
    final activeTodos = currentTodos.where((t) => !t.isCompleted).toList();

    if (oldIndex < activeTodos.length && newIndex <= activeTodos.length) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = activeTodos[oldIndex];

      activeTodos.removeAt(oldIndex);
      activeTodos.insert(newIndex, item);

      final completedTodos = currentTodos.where((t) => t.isCompleted).toList();
      final newDateList = [...activeTodos, ...completedTodos];

      _todos.removeWhere((t) => isSameDate(t.date, _selectedDate));
      _todos.addAll(newDateList);

      for (var todo in newDateList) {
        _isarService.saveTodo(todo);
      }
      notifyListeners();
    }
  }

  void clearTodosForSelectedDate({bool? isCompleted}) {
    final todosToDelete = _todos.where((todo) {
      final sameDate = isSameDate(todo.date, _selectedDate);
      if (!sameDate) return false;
      if (isCompleted == null) return true; // Clear all
      return todo.isCompleted == isCompleted;
    }).toList();

    for (var todo in todosToDelete) {
      _isarService.deleteTodo(todo.id);
    }

    _todos.removeWhere((todo) {
      final sameDate = isSameDate(todo.date, _selectedDate);
      if (!sameDate) return false;
      if (isCompleted == null) return true;
      return todo.isCompleted == isCompleted;
    });

    notifyListeners();
  }

  // --- Category Logic ---

  List<CategoryModel> _categories = [
    CategoryModel(id: '1', name: 'Personal', colorValue: 0xFF2196F3), // Blue
    CategoryModel(id: '2', name: 'Work', colorValue: 0xFFF44336), // Red
    CategoryModel(id: '3', name: 'Study', colorValue: 0xFFFF9800), // Orange
  ];

  List<CategoryModel> get categories => _categories;

  Future<void> loadCategories() async {
    final loadedCategories = await _isarService.getAllCategories();
    if (loadedCategories.isNotEmpty) {
      _categories = loadedCategories;
    } else {
      await _isarService.saveAllCategories(_categories);
    }
    notifyListeners();
  }

  Future<void> addCategory(String name, Color color) async {
    final newCategory = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: color.toARGB32(),
    );
    await _isarService.saveCategory(newCategory);
    _categories.add(newCategory);
    notifyListeners();
  }

  Color getCategoryColor(String categoryName) {
    try {
      return _categories
          .firstWhere(
            (cat) => cat.name == categoryName,
            orElse: () => _categories.first,
          )
          .color;
    } catch (e) {
      return Colors.grey;
    }
  }

  // --- Dashboard Logic ---

  final DashboardRepository _dashboardRepository = LocalDashboardRepository();
  DashboardStats? _dashboardStats;
  DateTime _dashboardStartDate = DateTime.now().subtract(
    const Duration(days: 6),
  );
  DateTime _dashboardEndDate = DateTime.now();
  bool _isLoadingStats = false;

  DashboardStats? get dashboardStats => _dashboardStats;
  DateTime get dashboardStartDate => _dashboardStartDate;
  DateTime get dashboardEndDate => _dashboardEndDate;
  bool get isLoadingStats => _isLoadingStats;

  Future<void> fetchDashboardStats() async {
    _isLoadingStats = true;
    notifyListeners();

    try {
      _dashboardStats = await _dashboardRepository.getStats(
        startDate: _dashboardStartDate,
        endDate: _dashboardEndDate,
        todos: _todos,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching stats: $e');
      }
    } finally {
      _isLoadingStats = false;
      notifyListeners();
    }
  }

  void setDashboardDateRange(DateTime start, DateTime end) {
    _dashboardStartDate = start;
    _dashboardEndDate = end;
    fetchDashboardStats();
  }

  void nextWeek() {
    _dashboardStartDate = _dashboardStartDate.add(const Duration(days: 7));
    _dashboardEndDate = _dashboardEndDate.add(const Duration(days: 7));
    fetchDashboardStats();
  }

  void previousWeek() {
    _dashboardStartDate = _dashboardStartDate.subtract(const Duration(days: 7));
    _dashboardEndDate = _dashboardEndDate.subtract(const Duration(days: 7));
    fetchDashboardStats();
  }
}

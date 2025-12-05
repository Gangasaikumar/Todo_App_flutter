import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../models/category_model.dart';
import '../services/notification_service.dart';
import '../repositories/dashboard_repository.dart';
import '../services/isar_service.dart';

class TodoProvider with ChangeNotifier {
  final IsarService _isarService = IsarService();
  List<Todo> _todos = [];
  DateTime _selectedDate = DateTime.now();

  List<Todo> get todos => _todos;
  DateTime get selectedDate => _selectedDate;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  List<Color> _savedColors = [];
  List<Color> get savedColors => _savedColors;

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

  TodoProvider() {
    _init();
  }

  Future<void> _init() async {
    await _migrateFromSharedPreferences();
    await loadTodos();
    await loadCategories();
  }

  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Migrate Todos
    final String? todosString = prefs.getString('todos');
    if (todosString != null) {
      try {
        final List<dynamic> todosJson = jsonDecode(todosString);
        final todos = todosJson.map((json) => Todo.fromJson(json)).toList();
        await _isarService.saveAllTodos(todos);
        await prefs.remove('todos');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error migrating todos: $e');
        }
      }
    }

    // Migrate Categories
    final String? categoriesString = prefs.getString('categories');
    if (categoriesString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(categoriesString);
        final categories = jsonList
            .map((json) => CategoryModel.fromJson(json))
            .toList();
        await _isarService.saveAllCategories(categories);
        await prefs.remove('categories');
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error migrating categories: $e');
        }
      }
    }
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
    );

    await _isarService.saveTodo(newTodo);
    _todos.add(newTodo);
    notifyListeners();

    if (reminderDateTime != null && reminderDateTime.isAfter(DateTime.now())) {
      AppNotificationService().scheduleNotification(
        id: newTodo.id.hashCode,
        title: 'Task Reminder',
        body: newTodo.title,
        scheduledDate: reminderDateTime,
      );
    }

    // Show immediate notification for task addition
    AppNotificationService().showNotification(
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

      // Cancel existing notification
      AppNotificationService().cancelNotification(todo.id.hashCode);

      // Schedule new if applicable
      if (todo.reminderDateTime != null &&
          !todo.isCompleted &&
          todo.reminderDateTime!.isAfter(DateTime.now())) {
        AppNotificationService().scheduleNotification(
          id: todo.id.hashCode,
          title: 'Task Reminder',
          body: todo.title,
          scheduledDate: todo.reminderDateTime!,
        );
      }

      // Show immediate notification for task update
      AppNotificationService().showNotification(
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
      AppNotificationService().cancelNotification(id.hashCode);
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
        AppNotificationService().cancelNotification(id.hashCode);

        // Handle Recurrence
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

          // Create next occurrence
          // We reset subtasks completion for the new task
          final newSubtasks = todo.subtasks
              .map((s) => Subtask(title: s.title, isCompleted: false))
              .toList();

          final nextTodo = Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: todo.title,
            date: nextDate,
            category: todo.category,
            details: todo.details,
            // Adjust reminder if exists
            reminderDateTime: todo.reminderDateTime?.add(
              nextDate.difference(todo.date),
            ),
            recurrence: todo.recurrence,
            subtasks: newSubtasks,
          );

          await _isarService.saveTodo(nextTodo);
          _todos.add(nextTodo);
          notifyListeners();

          AppNotificationService().showNotification(
            title: 'Recurring Task Created',
            body:
                'Next task scheduled for ${nextDate.toString().split(' ')[0]}',
          );
        }
      } else {
        // Reschedule if uncompleted and has future reminder
        if (todo.reminderDateTime != null &&
            todo.reminderDateTime!.isAfter(DateTime.now())) {
          AppNotificationService().scheduleNotification(
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

      // Reorder in local active list
      activeTodos.removeAt(oldIndex);
      activeTodos.insert(newIndex, item);

      // Reconstruct the date's list: Active + Completed
      final completedTodos = currentTodos.where((t) => t.isCompleted).toList();
      final newDateList = [...activeTodos, ...completedTodos];

      // Remove all for this date from main list
      _todos.removeWhere((t) => isSameDate(t.date, _selectedDate));

      // Add back
      _todos.addAll(newDateList);

      // Note: Reordering in Isar is complex if we don't have an 'order' field.
      // For now, we update the local list but persistence of order might be lost on reload
      // unless we add an 'order' field to Todo.
      // Given the scope, we'll just save all reordered todos to ensure they exist,
      // but Isar returns them in default order (usually insertion or ID).
      // To fix this properly, we would need an 'order' field.
      // For now, let's just save them.
      for (var todo in newDateList) {
        _isarService.saveTodo(todo);
      }
      notifyListeners();
    }
  }

  void clearTodosForSelectedDate() {
    final todosToDelete = _todos
        .where((todo) => isSameDate(todo.date, _selectedDate))
        .toList();
    for (var todo in todosToDelete) {
      _isarService.deleteTodo(todo.id);
    }
    _todos.removeWhere((todo) => isSameDate(todo.date, _selectedDate));
    notifyListeners();
  }

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
      // First run, save default categories
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

  // Dashboard Logic
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

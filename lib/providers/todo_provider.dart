import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../models/category_model.dart';

class TodoProvider with ChangeNotifier {
  List<Todo> _todos = [];
  DateTime _selectedDate = DateTime.now();

  List<Todo> get todos => _todos;
  DateTime get selectedDate => _selectedDate;

  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;

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
    loadTodos();
    loadCategories();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? todosString = prefs.getString('todos');
      if (todosString != null) {
        final List<dynamic> todosJson = jsonDecode(todosString);
        _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      // Error loading todos
    }
  }

  Future<void> saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String todosString = jsonEncode(
        _todos.map((todo) => todo.toJson()).toList(),
      );
      await prefs.setString('todos', todosString);
    } catch (e) {
      // Error saving todos
    }
  }

  void addTodo(String title, DateTime date, String category, String details) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      category: category,
      details: details,
    );
    _todos.add(newTodo);
    saveTodos();
    notifyListeners();
  }

  void updateTodo(Todo todo) {
    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      saveTodos();
      notifyListeners();
    }
  }

  void deleteTodo(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1 && !_todos[index].isCompleted) {
      _todos.removeAt(index);
      saveTodos();
      notifyListeners();
    }
  }

  void toggleTodoStatus(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      saveTodos();
      notifyListeners();
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

      saveTodos();
      notifyListeners();
    }
  }

  void clearTodosForSelectedDate() {
    _todos.removeWhere((todo) => isSameDate(todo.date, _selectedDate));
    saveTodos();
    notifyListeners();
  }

  List<CategoryModel> _categories = [
    CategoryModel(id: '1', name: 'Personal', colorValue: 0xFF2196F3), // Blue
    CategoryModel(id: '2', name: 'Work', colorValue: 0xFFF44336), // Red
    CategoryModel(id: '3', name: 'Study', colorValue: 0xFFFF9800), // Orange
    CategoryModel(id: '4', name: 'Shopping', colorValue: 0xFF4CAF50), // Green
  ];

  List<CategoryModel> get categories => _categories;

  Future<void> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? categoriesString = prefs.getString('categories');
      if (categoriesString != null) {
        final List<dynamic> jsonList = jsonDecode(categoriesString);
        _categories = jsonList
            .map((json) => CategoryModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Error loading categories
    }
  }

  Future<void> saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String categoriesString = jsonEncode(
        _categories.map((cat) => cat.toJson()).toList(),
      );
      await prefs.setString('categories', categoriesString);
    } catch (e) {
      // Error saving categories
    }
  }

  void addCategory(String name, Color color) {
    final newCategory = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      colorValue: color.value,
    );
    _categories.add(newCategory);
    saveCategories();
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
}

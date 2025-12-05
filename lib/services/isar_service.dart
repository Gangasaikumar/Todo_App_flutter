import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/todo.dart';
import '../models/category_model.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [TodoSchema, CategoryModelSchema],
        directory: dir.path,
        inspector: true,
      );
    }
    return Future.value(Isar.getInstance());
  }

  // Todos
  Future<void> saveTodo(Todo todo) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.todos.put(todo);
    });
  }

  Future<void> saveAllTodos(List<Todo> todos) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.todos.putAll(todos);
    });
  }

  Future<List<Todo>> getAllTodos() async {
    final isar = await db;
    return await isar.todos.where().findAll();
  }

  Future<void> deleteTodo(String id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      // Delete by String id using the unique index
      await isar.todos.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<void> clearTodos() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.todos.clear();
    });
  }

  // Categories
  Future<void> saveCategory(CategoryModel category) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categoryModels.put(category);
    });
  }

  Future<void> saveAllCategories(List<CategoryModel> categories) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categoryModels.putAll(categories);
    });
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final isar = await db;
    return await isar.categoryModels.where().findAll();
  }

  Future<void> deleteCategory(String id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.categoryModels.filter().idEqualTo(id).deleteAll();
    });
  }

  Future<void> cleanDb() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}

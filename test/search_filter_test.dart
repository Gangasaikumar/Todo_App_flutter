import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_todo_app/providers/todo_provider.dart';

void main() {
  group('TodoProvider Search and Filter', () {
    late TodoProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = TodoProvider();

      // Add some sample todos
      final date = DateTime.now();
      provider.addTodo('Buy Milk', date, 'Shopping', '', null);
      provider.addTodo('Finish Report', date, 'Work', '', null);
      provider.addTodo('Call Mom', date, 'Personal', '', null);
      provider.addTodo('Buy Eggs', date, 'Shopping', '', null);
    });

    test('Search filters todos by title', () {
      provider.setSearchQuery('Buy');
      expect(provider.todosForSelectedDate.length, 2);
      expect(
        provider.todosForSelectedDate.any((t) => t.title == 'Buy Milk'),
        true,
      );
      expect(
        provider.todosForSelectedDate.any((t) => t.title == 'Buy Eggs'),
        true,
      );

      provider.setSearchQuery('Report');
      expect(provider.todosForSelectedDate.length, 1);
      expect(provider.todosForSelectedDate.first.title, 'Finish Report');
    });

    test('Category filter filters todos by category', () {
      provider.setCategoryFilter('Shopping');
      expect(provider.todosForSelectedDate.length, 2);
      expect(
        provider.todosForSelectedDate.every((t) => t.category == 'Shopping'),
        true,
      );

      provider.setCategoryFilter('Work');
      expect(provider.todosForSelectedDate.length, 1);
      expect(provider.todosForSelectedDate.first.category, 'Work');
    });

    test('Search and Category filter work together', () {
      provider.setSearchQuery('Buy');
      provider.setCategoryFilter('Shopping');

      expect(provider.todosForSelectedDate.length, 2);

      // Add a non-shopping item with 'Buy' in title
      provider.addTodo('Buy Software', DateTime.now(), 'Work', '', null);

      // Should still be 2 because 'Buy Software' is Work
      expect(provider.todosForSelectedDate.length, 2);

      provider.setCategoryFilter('Work');
      expect(provider.todosForSelectedDate.length, 1);
      expect(provider.todosForSelectedDate.first.title, 'Buy Software');
    });
  });
}

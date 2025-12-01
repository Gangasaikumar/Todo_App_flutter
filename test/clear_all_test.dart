import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_todo_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Clear all todos test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Add a todo
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('addTodoField')), 'Task 1');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Add another todo
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('addTodoField')), 'Task 2');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify todos are added
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);

    // Tap Clear All button (icon)
    await tester.tap(find.byIcon(Icons.delete_sweep));
    await tester.pumpAndSettle();

    // Confirm dialog
    await tester.tap(find.text('Clear All'));
    await tester.pumpAndSettle();

    // Verify todos are deleted
    expect(find.text('Task 1'), findsNothing);
    expect(find.text('Task 2'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_todo_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Add todo test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify that the list is empty initially
    expect(find.text('Test Todo'), findsNothing);

    // Tap the add button
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();

    // Enter text
    await tester.enterText(find.byKey(const Key('addTodoField')), 'Test Todo');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify that the todo is added
    expect(find.text('Test Todo'), findsOneWidget);
  });

  testWidgets('Delete todo test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Add a todo
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('addTodoField')), 'Delete Me');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Me'), findsOneWidget);

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Verify that the todo is deleted
    expect(find.text('Delete Me'), findsNothing);
  });

  testWidgets('Cannot delete completed todo test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Add a todo
    await tester.tap(find.text('Add New'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('addTodoField')),
      'Completed Todo',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Mark as completed
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Verify delete button is not present/disabled
    expect(find.byIcon(Icons.delete_outline), findsNothing);
  });
}

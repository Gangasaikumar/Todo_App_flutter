import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/todo_provider.dart';
import '../tasks/todo_item.dart';

class AllTasksList extends StatelessWidget {
  const AllTasksList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final groupedTodos = todoProvider.todosGroupedByDate;

        if (groupedTodos.isEmpty) {
          return const Center(
            child: Text(
              'No tasks found!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedTodos.length,
          itemBuilder: (context, index) {
            final date = groupedTodos.keys.elementAt(index);
            final todos = groupedTodos[date]!;
            final activeTodos = todos.where((t) => !t.isCompleted).toList();
            final completedTodos = todos.where((t) => t.isCompleted).toList();

            final hasBoth = activeTodos.isNotEmpty && completedTodos.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    DateFormat('MMMM d, yyyy').format(date),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF46539E),
                    ),
                  ),
                ),
                if (activeTodos.isNotEmpty) ...[
                  if (hasBoth)
                    const Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  if (hasBoth) const SizedBox(height: 8),
                  ...activeTodos.map((todo) => TodoItem(todo: todo, index: -1)),
                  const SizedBox(height: 16),
                ],
                if (completedTodos.isNotEmpty) ...[
                  if (hasBoth)
                    const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  if (hasBoth) const SizedBox(height: 8),
                  ...completedTodos.map(
                    (todo) => TodoItem(todo: todo, index: -1),
                  ),
                  const SizedBox(height: 16),
                ],
                const Divider(),
              ],
            );
          },
        );
      },
    );
  }
}

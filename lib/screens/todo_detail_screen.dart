import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/dialogs/add_todo_dialog.dart';

class TodoDetailScreen extends StatelessWidget {
  final Todo todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    // Ensure we have the latest version of the todo from the provider, 
    // or fallback to the passed one if not found (e.g. deleted).
    final currentTodo = todoProvider.todos.firstWhere(
      (t) => t.id == todo.id,
      orElse: () => todo,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Badge and Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: todoProvider
                        .getCategoryColor(currentTodo.category)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentTodo.category,
                    style: TextStyle(
                      color:
                          todoProvider.getCategoryColor(currentTodo.category),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status
                Row(
                  children: [
                    Icon(
                      currentTodo.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color:
                          currentTodo.isCompleted ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentTodo.isCompleted ? 'Completed' : 'Pending',
                      style: TextStyle(
                        fontSize: 16,
                        color: currentTodo.isCompleted
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Title
            Text(
              currentTodo.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: currentTodo.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: currentTodo.isCompleted
                    ? Colors.grey
                    : Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            // Date
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMMM d, y').format(currentTodo.date),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (currentTodo.details.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                currentTodo.details,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
            ],
            const Spacer(),
            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Edit Button
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddTodoDialog(
                        initialDate: currentTodo.date,
                        todo: currentTodo,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(width: 16),
                // Delete Button
                OutlinedButton.icon(
                  onPressed: () {
                    todoProvider.deleteTodo(currentTodo.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    side: const BorderSide(color: Colors.red),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';

class ClearTasksButton extends StatelessWidget {
  const ClearTasksButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        if (provider.todosForSelectedDate.isEmpty) {
          return const SizedBox.shrink();
        }

        return TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear All Tasks?'),
                content: const Text(
                  'This will delete all tasks for the selected date. This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.clearTodosForSelectedDate();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.delete_sweep, color: Colors.red),
          label: const Text(
            'Clear All',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
      },
    );
  }
}

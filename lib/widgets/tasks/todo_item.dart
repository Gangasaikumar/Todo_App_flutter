import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../dialogs/add_todo_dialog.dart';
import '../../screens/todo_detail_screen.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final int index;

  const TodoItem({super.key, required this.todo, required this.index});

  String _getPlainText(String details) {
    if (details.isEmpty) return '';
    try {
      final json = jsonDecode(details);
      final doc = quill.Document.fromJson(json);
      return doc.toPlainText().trim().replaceAll('\n', ' ');
    } catch (e) {
      return details;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<TodoProvider>(context, listen: false).deleteTodo(todo.id);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TodoDetailScreen(todoId: todo.id),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withAlpha(13) // 0.05 opacity
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Theme.of(context).brightness == Brightness.light
                ? Border.all(color: Colors.grey[200]!)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13), // 0.05 opacity
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Custom Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (value) {
                    Provider.of<TodoProvider>(
                      context,
                      listen: false,
                    ).toggleTodoStatus(todo.id);
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  checkColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted
                            ? Colors.grey
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87),
                      ),
                    ),
                    if (todo.details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getPlainText(todo.details),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Provider.of<TodoProvider>(context)
                                .getCategoryColor(todo.category)
                                .withAlpha(38), // 0.15 opacity
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            todo.category,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Provider.of<TodoProvider>(
                                context,
                              ).getCategoryColor(todo.category),
                            ),
                          ),
                        ),
                        if (todo.recurrence != RecurrenceInterval.none) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.repeat_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                        ],
                        if (todo.subtasks.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.checklist_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${todo.subtasks.where((s) => s.isCompleted).length}/${todo.subtasks.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (todo.estimatedPomodoros > 0) ...[
                          const SizedBox(width: 8),
                          const Text('🍅', style: TextStyle(fontSize: 14)),
                          Text(
                            ' ${todo.completedPomodoros}/${todo.estimatedPomodoros}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  todo.completedPomodoros >=
                                      todo.estimatedPomodoros
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Edit Button
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: Colors.grey[400],
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        AddTodoDialog(initialDate: todo.date, todo: todo),
                  );
                },
              ),
              // Drag Handle
              if (index != -1)
                ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

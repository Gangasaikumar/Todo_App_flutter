import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../providers/todo_provider.dart';
import '../widgets/dialogs/add_todo_dialog.dart';

class TodoDetailScreen extends StatefulWidget {
  final String todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todo = Provider.of<TodoProvider>(context).findById(widget.todoId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    if (todo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: Text('Task not found')),
      );
    }

    // Update controller text if it changed
    if (todo.details.isNotEmpty) {
      try {
        final json = jsonDecode(todo.details);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      } catch (e) {
        _quillController = QuillController(
          document: Document()..insert(0, todo.details),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        );
      }
    } else {
      _quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }

    final categoryColor = Provider.of<TodoProvider>(
      context,
      listen: false,
    ).getCategoryColor(todo.category);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Task Details',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Category and Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(51), // 0.2 opacity
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          todo.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(
                            todo.isCompleted
                                ? Icons.check_circle_outline
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: subTextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            todo.isCompleted ? 'Completed' : 'Pending',
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    todo.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: subTextColor),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMMM d, yyyy').format(todo.date),
                        style: TextStyle(color: subTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Details
                  if (todo.details.isNotEmpty)
                    QuillEditor(
                      controller: _quillController,
                      scrollController: _editorScrollController,
                      focusNode: _editorFocusNode,
                    ),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(color: bgColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Edit Button
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddTodoDialog(
                        initialDate: DateTime.now(),
                        todo: todo,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 16),

                // Delete Button
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark
                            ? const Color(0xFF2C2C2C)
                            : Colors.white,
                        title: Text(
                          'Delete Task',
                          style: TextStyle(color: textColor),
                        ),
                        content: Text(
                          'Are you sure you want to delete this task?',
                          style: TextStyle(color: textColor),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Provider.of<TodoProvider>(
                                context,
                                listen: false,
                              ).deleteTodo(todo.id);
                              Navigator.pop(ctx); // Close dialog
                              Navigator.pop(context); // Go back to list
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

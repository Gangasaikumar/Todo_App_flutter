import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../providers/todo_provider.dart';
import 'add_category_dialog.dart';
import '../../models/todo.dart';

class AddTodoDialog extends StatefulWidget {
  final DateTime initialDate;
  final Todo? todo; // Optional todo for editing

  const AddTodoDialog({super.key, required this.initialDate, this.todo});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  // ignore: unused_field
  dynamic
  _subscription; // Use dynamic to avoid import issues with StreamSubscription if not imported
  late DateTime _selectedDate;
  TimeOfDay? _selectedReminderTime;
  late String _selectedCategory;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _selectedDate = widget.todo?.date ?? widget.initialDate;
    if (widget.todo?.reminderDateTime != null) {
      _selectedReminderTime = TimeOfDay.fromDateTime(
        widget.todo!.reminderDateTime!,
      );
    } else {
      _selectedReminderTime = null;
    }
    _selectedCategory = widget.todo?.category ?? 'Personal';

    // Initialize Quill Controller
    if (widget.todo != null && widget.todo!.details.isNotEmpty) {
      try {
        // Try to parse as JSON (Quill Delta)
        final json = jsonDecode(widget.todo!.details);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
          keepStyleOnNewLine: true,
        );
      } catch (e) {
        // Fallback for plain text (legacy data)
        _quillController = QuillController(
          document: Document()..insert(0, widget.todo!.details),
          selection: const TextSelection.collapsed(offset: 0),
          keepStyleOnNewLine: true,
        );
      }
    } else {
      _quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
        keepStyleOnNewLine: true,
      );
    }

    // Manual fix for style persistence on new line
    _subscription = _quillController.changes.listen((event) {
      if (event.source == ChangeSource.local) {
        // Check if a newline was inserted
        for (final op in event.change.toList()) {
          if (op.isInsert &&
              op.data is String &&
              (op.data as String).contains('\n')) {
            final currentPos = _quillController.selection.baseOffset;
            // Check character before newline (currentPos - 2)
            if (currentPos >= 2) {
              final style = _quillController.document.collectStyle(
                currentPos - 2,
                1,
              );
              final attrs = style.attributes;
              if (attrs.isNotEmpty) {
                attrs.forEach((key, attr) {
                  _quillController.formatSelection(attr);
                });
              }
            }
            break;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    if (_subscription != null) {
      (_subscription as dynamic).cancel();
    }
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.todo != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Refined Colors for Light/Dark Mode
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[400]!;
    final toolbarColor = isDark
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF0F0F0);
    final editorColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final inputFillColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final textColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : Colors.white, // Explicit background
      surfaceTintColor: Colors.transparent, // Remove M3 tint
      title: Text(
        isEditing ? 'Edit Task' : 'Add New Task',
        style: TextStyle(color: textColor),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Task Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: inputFillColor,
                  hintStyle: TextStyle(color: hintColor),
                ),
              ),
              const SizedBox(height: 16),

              // Rich Text Editor Container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: editorColor,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Custom Quill Toolbar
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: toolbarColor,
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            QuillToolbarToggleStyleButton(
                              controller: _quillController,
                              attribute: Attribute.bold,
                            ),
                            QuillToolbarToggleStyleButton(
                              controller: _quillController,
                              attribute: Attribute.italic,
                            ),
                            const VerticalDivider(width: 16, thickness: 1),
                            QuillToolbarSelectHeaderStyleDropdownButton(
                              controller: _quillController,
                            ),
                            const VerticalDivider(width: 16, thickness: 1),
                            QuillToolbarToggleStyleButton(
                              controller: _quillController,
                              attribute: Attribute.ul,
                            ),
                            QuillToolbarToggleStyleButton(
                              controller: _quillController,
                              attribute: Attribute.ol,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quill Editor
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      child: QuillEditor(
                        controller: _quillController,
                        scrollController: _editorScrollController,
                        focusNode: _editorFocusNode,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date', style: TextStyle(color: textColor)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                              color: inputFillColor,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(_selectedDate),
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: textColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reminder', style: TextStyle(color: textColor)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime:
                                  _selectedReminderTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedReminderTime = picked;
                              });
                            } else {
                              // Optional: Allow clearing reminder?
                              // For now, just keep previous or null
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(12),
                              color: inputFillColor,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedReminderTime != null
                                      ? _selectedReminderTime!.format(context)
                                      : 'No Reminder',
                                  style: TextStyle(
                                    color: _selectedReminderTime != null
                                        ? textColor
                                        : hintColor,
                                  ),
                                ),
                                if (_selectedReminderTime != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedReminderTime = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 20,
                                      color: textColor,
                                    ),
                                  )
                                else
                                  Icon(Icons.alarm, size: 20, color: textColor),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              Consumer<TodoProvider>(
                builder: (context, provider, child) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...provider.categories.map((category) {
                        final isSelected = _selectedCategory == category.name;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category.name;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(category.colorValue)
                                  : Color(
                                      category.colorValue,
                                    ).withAlpha(25), // 0.1 opacity
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Color(category.colorValue),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Color(category.colorValue),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Add New Category Badge
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => const AddCategoryDialog(),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.grey[600]! : Colors.grey,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                size: 16,
                                color: isDark ? Colors.grey[400] : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : Colors.grey[700],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              // Serialize Quill document to JSON string
              final detailsJson = jsonEncode(
                _quillController.document.toDelta().toJson(),
              );

              DateTime? reminderDateTime;
              if (_selectedReminderTime != null) {
                reminderDateTime = DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  _selectedDate.day,
                  _selectedReminderTime!.hour,
                  _selectedReminderTime!.minute,
                );
              }

              if (isEditing) {
                Provider.of<TodoProvider>(context, listen: false).updateTodo(
                  Todo(
                    id: widget.todo!.id,
                    title: _titleController.text,
                    date: _selectedDate,
                    category: _selectedCategory,
                    details: detailsJson,
                    isCompleted: widget.todo!.isCompleted,
                    reminderDateTime: reminderDateTime,
                  ),
                );
              } else {
                Provider.of<TodoProvider>(context, listen: false).addTodo(
                  _titleController.text,
                  _selectedDate,
                  _selectedCategory,
                  detailsJson,
                  reminderDateTime,
                );
              }
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark
                ? Theme.of(context).colorScheme.primary
                : Colors.black,
            foregroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: const StadiumBorder(),
          ),
          child: Text(
            isEditing ? 'Save Task' : 'Add Task',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

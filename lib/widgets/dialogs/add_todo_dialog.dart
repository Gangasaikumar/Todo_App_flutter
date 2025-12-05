import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../providers/todo_provider.dart';
import '../../models/todo.dart';

class AddTodoDialog extends StatefulWidget {
  final Todo? todo;
  final DateTime? initialDate;

  const AddTodoDialog({super.key, this.todo, this.initialDate});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  Color _selectedCategoryColor = Colors.blue;
  DateTime? _reminderDateTime;

  // Rich Text Editor
  late QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  // Power Features
  RecurrenceInterval _selectedRecurrence = RecurrenceInterval.none;
  List<Subtask> _subtasks = [];
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo?.title ?? '');
    _selectedDate = widget.todo?.date ?? widget.initialDate ?? DateTime.now();
    _selectedCategory = widget.todo?.category ?? 'Personal';

    // Initialize color
    final provider = Provider.of<TodoProvider>(context, listen: false);
    _selectedCategoryColor = provider.getCategoryColor(_selectedCategory);

    _reminderDateTime = widget.todo?.reminderDateTime;
    _selectedRecurrence = widget.todo?.recurrence ?? RecurrenceInterval.none;

    // Deep copy subtasks to avoid modifying original list directly
    if (widget.todo != null) {
      _subtasks = widget.todo!.subtasks
          .map((s) => Subtask(title: s.title, isCompleted: s.isCompleted))
          .toList();
    }

    // Initialize Quill Controller
    if (widget.todo != null && widget.todo!.details.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.todo!.details));
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _saveTodo() {
    if (_formKey.currentState!.validate()) {
      final details = jsonEncode(_quillController.document.toDelta().toJson());
      final provider = Provider.of<TodoProvider>(context, listen: false);

      // Check if category exists, if not add it with selected color
      final categoryExists = provider.categories.any(
        (c) => c.name.toLowerCase() == _selectedCategory.toLowerCase(),
      );
      if (!categoryExists) {
        provider.addCategory(_selectedCategory, _selectedCategoryColor);
      }

      if (widget.todo == null) {
        provider.addTodo(
          _titleController.text,
          _selectedDate,
          _selectedCategory,
          details,
          _reminderDateTime,
          _selectedRecurrence,
          _subtasks,
        );
      } else {
        final updatedTodo = Todo(
          id: widget.todo!.id,
          title: _titleController.text,
          date: _selectedDate,
          isCompleted: widget.todo!.isCompleted,
          category: _selectedCategory,
          details: details,
          reminderDateTime: _reminderDateTime,
          recurrence: _selectedRecurrence,
          subtasks: _subtasks,
        );
        provider.updateTodo(updatedTodo);
      }
      Navigator.of(context).pop();
    }
  }

  void _addSubtask() {
    if (_subtaskController.text.isNotEmpty) {
      setState(() {
        _subtasks.add(Subtask(title: _subtaskController.text));
        _subtaskController.clear();
      });
    }
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final surfaceColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final hintColor = Theme.of(context).hintColor;
    final borderColor = Theme.of(context).dividerColor;

    // Editor Colors
    final toolbarColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final editorColor = isDark ? Colors.grey[900] : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.todo == null ? Icons.add_task : Icons.edit_note,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.todo == null ? 'New Task' : 'Edit Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: hintColor),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      Text(
                        'Title',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'What needs to be done?',
                          hintStyle: TextStyle(
                            color: hintColor.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[800]!.withOpacity(0.5)
                              : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Date & Category Row
                      Row(
                        children: [
                          // Date Picker
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: hintColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2101),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: primaryColor,
                                                  onPrimary: Colors.white,
                                                  surface: surfaceColor,
                                                  onSurface:
                                                      textColor ?? Colors.black,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                    if (picked != null &&
                                        picked != _selectedDate) {
                                      setState(() {
                                        _selectedDate = picked;
                                      });
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]!.withOpacity(0.5)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 20,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat(
                                            'MMM d, y',
                                          ).format(_selectedDate),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Category Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: hintColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Consumer<TodoProvider>(
                                  builder: (context, provider, child) {
                                    return LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Autocomplete<String>(
                                          initialValue: TextEditingValue(
                                            text: _selectedCategory,
                                          ),
                                          optionsBuilder:
                                              (
                                                TextEditingValue
                                                textEditingValue,
                                              ) {
                                                if (textEditingValue
                                                    .text
                                                    .isEmpty) {
                                                  return provider.categories
                                                      .map((e) => e.name);
                                                }
                                                return provider.categories
                                                    .where(
                                                      (category) => category
                                                          .name
                                                          .toLowerCase()
                                                          .contains(
                                                            textEditingValue
                                                                .text
                                                                .toLowerCase(),
                                                          ),
                                                    )
                                                    .map((e) => e.name);
                                              },
                                          onSelected: (String selection) {
                                            setState(() {
                                              _selectedCategory = selection;
                                              _selectedCategoryColor = provider
                                                  .getCategoryColor(selection);
                                            });
                                          },
                                          fieldViewBuilder:
                                              (
                                                context,
                                                textEditingController,
                                                focusNode,
                                                onFieldSubmitted,
                                              ) {
                                                if (textEditingController
                                                        .text !=
                                                    _selectedCategory) {
                                                  textEditingController.text =
                                                      _selectedCategory;
                                                }

                                                return TextFormField(
                                                  controller:
                                                      textEditingController,
                                                  focusNode: focusNode,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _selectedCategory = value;
                                                      final existingColor =
                                                          provider
                                                              .getCategoryColor(
                                                                value,
                                                              );
                                                      if (existingColor !=
                                                          Colors.grey) {
                                                        _selectedCategoryColor =
                                                            existingColor;
                                                      }
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Select or type category',
                                                    hintStyle: TextStyle(
                                                      color: hintColor
                                                          .withOpacity(0.5),
                                                      fontSize: 14,
                                                    ),
                                                    filled: true,
                                                    fillColor: isDark
                                                        ? Colors.grey[800]!
                                                              .withOpacity(0.5)
                                                        : Colors.grey[50],
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 12,
                                                        ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      borderSide:
                                                          BorderSide.none,
                                                    ),
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          borderSide: BorderSide(
                                                            color: primaryColor,
                                                            width: 2,
                                                          ),
                                                        ),
                                                    suffixIcon: Icon(
                                                      Icons.arrow_drop_down,
                                                      color: hintColor,
                                                    ),
                                                    prefixIcon: GestureDetector(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) {
                                                            Color currentColor =
                                                                _selectedCategoryColor;
                                                            String inputMode =
                                                                'Hex'; // Hex, RGB, HSL
                                                            TextEditingController
                                                            colorController =
                                                                TextEditingController();

                                                            // Helper to update text field based on color and mode
                                                            void
                                                            updateColorText(
                                                              Color color,
                                                            ) {
                                                              if (inputMode ==
                                                                  'Hex') {
                                                                colorController
                                                                        .text =
                                                                    '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
                                                              } else if (inputMode ==
                                                                  'RGB') {
                                                                colorController
                                                                        .text =
                                                                    '${color.red}, ${color.green}, ${color.blue}';
                                                              } else if (inputMode ==
                                                                  'HSL') {
                                                                HSLColor hsl =
                                                                    HSLColor.fromColor(
                                                                      color,
                                                                    );
                                                                colorController
                                                                        .text =
                                                                    '${hsl.hue.toStringAsFixed(0)}, ${(hsl.saturation * 100).toStringAsFixed(0)}%, ${(hsl.lightness * 100).toStringAsFixed(0)}%';
                                                              }
                                                            }

                                                            // Initialize text
                                                            updateColorText(
                                                              currentColor,
                                                            );

                                                            return StatefulBuilder(
                                                              builder: (context, setState) {
                                                                return AlertDialog(
                                                                  title: const Text(
                                                                    'Pick a color',
                                                                  ),
                                                                  content: SingleChildScrollView(
                                                                    child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        ColorPicker(
                                                                          pickerColor:
                                                                              currentColor,
                                                                          onColorChanged:
                                                                              (
                                                                                color,
                                                                              ) {
                                                                                setState(
                                                                                  () {
                                                                                    currentColor = color;
                                                                                    // Update text when picker changes (if not focused? simplified for now)
                                                                                    updateColorText(
                                                                                      color,
                                                                                    );
                                                                                  },
                                                                                );
                                                                                this.setState(
                                                                                  () {
                                                                                    _selectedCategoryColor = color;
                                                                                  },
                                                                                );
                                                                              },
                                                                          colorPickerWidth:
                                                                              300,
                                                                          pickerAreaHeightPercent:
                                                                              0.7,
                                                                          enableAlpha:
                                                                              false,
                                                                          displayThumbColor:
                                                                              true,
                                                                          showLabel:
                                                                              true,
                                                                          hexInputBar:
                                                                              false, // Disable built-in hex input
                                                                          paletteType:
                                                                              PaletteType.hueWheel,
                                                                          pickerAreaBorderRadius: const BorderRadius.only(
                                                                            topLeft: Radius.circular(
                                                                              2,
                                                                            ),
                                                                            topRight: Radius.circular(
                                                                              2,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                          height:
                                                                              16,
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            DropdownButton<
                                                                              String
                                                                            >(
                                                                              value: inputMode,
                                                                              items:
                                                                                  [
                                                                                        'Hex',
                                                                                        'RGB',
                                                                                        'HSL',
                                                                                      ]
                                                                                      .map(
                                                                                        (
                                                                                          mode,
                                                                                        ) => DropdownMenuItem(
                                                                                          value: mode,
                                                                                          child: Text(
                                                                                            mode,
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                      .toList(),
                                                                              onChanged:
                                                                                  (
                                                                                    val,
                                                                                  ) {
                                                                                    setState(
                                                                                      () {
                                                                                        inputMode = val!;
                                                                                        updateColorText(
                                                                                          currentColor,
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  },
                                                                              underline: Container(), // Remove underline for cleaner look
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 12,
                                                                            ),
                                                                            Expanded(
                                                                              child: TextField(
                                                                                controller: colorController,
                                                                                decoration: const InputDecoration(
                                                                                  border: OutlineInputBorder(),
                                                                                  contentPadding: EdgeInsets.symmetric(
                                                                                    horizontal: 12,
                                                                                    vertical: 8,
                                                                                  ),
                                                                                ),
                                                                                onChanged:
                                                                                    (
                                                                                      val,
                                                                                    ) {
                                                                                      Color? newColor;
                                                                                      try {
                                                                                        if (inputMode ==
                                                                                            'Hex') {
                                                                                          String hex = val.replaceAll(
                                                                                            '#',
                                                                                            '',
                                                                                          );
                                                                                          if (hex.length ==
                                                                                              6) {
                                                                                            newColor = Color(
                                                                                              int.parse(
                                                                                                '0xFF$hex',
                                                                                              ),
                                                                                            );
                                                                                          }
                                                                                        } else if (inputMode ==
                                                                                            'RGB') {
                                                                                          List<
                                                                                            String
                                                                                          >
                                                                                          parts = val.split(
                                                                                            ',',
                                                                                          );
                                                                                          if (parts.length ==
                                                                                              3) {
                                                                                            int r = int.parse(
                                                                                              parts[0].trim(),
                                                                                            );
                                                                                            int g = int.parse(
                                                                                              parts[1].trim(),
                                                                                            );
                                                                                            int b = int.parse(
                                                                                              parts[2].trim(),
                                                                                            );
                                                                                            newColor = Color.fromARGB(
                                                                                              255,
                                                                                              r,
                                                                                              g,
                                                                                              b,
                                                                                            );
                                                                                          }
                                                                                        } else if (inputMode ==
                                                                                            'HSL') {
                                                                                          // Basic HSL parsing (expecting "H, S%, L%")
                                                                                          List<
                                                                                            String
                                                                                          >
                                                                                          parts = val.split(
                                                                                            ',',
                                                                                          );
                                                                                          if (parts.length ==
                                                                                              3) {
                                                                                            double h = double.parse(
                                                                                              parts[0].trim(),
                                                                                            );
                                                                                            double s =
                                                                                                double.parse(
                                                                                                  parts[1].trim().replaceAll(
                                                                                                    '%',
                                                                                                    '',
                                                                                                  ),
                                                                                                ) /
                                                                                                100;
                                                                                            double l =
                                                                                                double.parse(
                                                                                                  parts[2].trim().replaceAll(
                                                                                                    '%',
                                                                                                    '',
                                                                                                  ),
                                                                                                ) /
                                                                                                100;
                                                                                            newColor = HSLColor.fromAHSL(
                                                                                              1.0,
                                                                                              h,
                                                                                              s,
                                                                                              l,
                                                                                            ).toColor();
                                                                                          }
                                                                                        }
                                                                                      } catch (
                                                                                        e
                                                                                      ) {
                                                                                        // Ignore parsing errors while typing
                                                                                      }

                                                                                      if (newColor !=
                                                                                          null) {
                                                                                        setState(
                                                                                          () {
                                                                                            currentColor = newColor!;
                                                                                          },
                                                                                        );
                                                                                        this.setState(
                                                                                          () {
                                                                                            _selectedCategoryColor = newColor!;
                                                                                          },
                                                                                        );
                                                                                      }
                                                                                    },
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  actions: [
                                                                    ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                        backgroundColor:
                                                                            Colors.black,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                      ),
                                                                      child: const Text(
                                                                        'Done',
                                                                      ),
                                                                      onPressed: () {
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop();
                                                                      },
                                                                    ),
                                                                  ],
                                                                );
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: Container(
                                                        margin:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        width: 16,
                                                        height: 16,
                                                        decoration: BoxDecoration(
                                                          color:
                                                              _selectedCategoryColor,
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: Colors.grey
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor,
                                                  ),
                                                );
                                              },
                                          optionsViewBuilder: (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                color: surfaceColor,
                                                child: Container(
                                                  width: constraints.maxWidth,
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxHeight: 200,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    color: surfaceColor,
                                                  ),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder:
                                                        (
                                                          BuildContext context,
                                                          int index,
                                                        ) {
                                                          final String option =
                                                              options.elementAt(
                                                                index,
                                                              );
                                                          final color = provider
                                                              .getCategoryColor(
                                                                option,
                                                              );
                                                          return ListTile(
                                                            leading: Container(
                                                              width: 12,
                                                              height: 12,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    color:
                                                                        color,
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                            ),
                                                            title: Text(
                                                              option,
                                                              style: TextStyle(
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                            onTap: () {
                                                              onSelected(
                                                                option,
                                                              );
                                                            },
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            hoverColor: isDark
                                                                ? Colors
                                                                      .grey[800]
                                                                : Colors
                                                                      .grey[100],
                                                          );
                                                        },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Reminder
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active_rounded,
                            size: 20,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reminder',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const Spacer(),
                          Switch.adaptive(
                            value: _reminderDateTime != null,
                            activeColor: primaryColor,
                            onChanged: (bool value) async {
                              if (value) {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    );
                                if (pickedTime != null) {
                                  setState(() {
                                    _reminderDateTime = DateTime(
                                      _selectedDate.year,
                                      _selectedDate.month,
                                      _selectedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              } else {
                                setState(() {
                                  _reminderDateTime = null;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      if (_reminderDateTime != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            DateFormat(
                              'MMM d, y - h:mm a',
                            ).format(_reminderDateTime!),
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Recurrence
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repeat',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<RecurrenceInterval>(
                                value: _selectedRecurrence,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: hintColor,
                                ),
                                dropdownColor: surfaceColor,
                                items: RecurrenceInterval.values.map((
                                  interval,
                                ) {
                                  String label;
                                  switch (interval) {
                                    case RecurrenceInterval.none:
                                      label = 'Does not repeat';
                                      break;
                                    case RecurrenceInterval.daily:
                                      label = 'Daily';
                                      break;
                                    case RecurrenceInterval.weekly:
                                      label = 'Weekly';
                                      break;
                                    case RecurrenceInterval.monthly:
                                      label = 'Monthly';
                                      break;
                                  }
                                  return DropdownMenuItem(
                                    value: interval,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (RecurrenceInterval? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedRecurrence = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Subtasks
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subtasks',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Add Subtask Input
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subtaskController,
                                  decoration: InputDecoration(
                                    hintText: 'Add a subtask...',
                                    hintStyle: TextStyle(
                                      color: hintColor.withOpacity(0.5),
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]!.withOpacity(0.5)
                                        : Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  onSubmitted: (_) => _addSubtask(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _addSubtask,
                                icon: const Icon(Icons.add),
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  foregroundColor: primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subtasks List
                          if (_subtasks.isNotEmpty)
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _subtasks.length,
                              itemBuilder: (context, index) {
                                final subtask = _subtasks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                        color: hintColor,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          subtask.title,
                                          style: TextStyle(color: textColor),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _removeSubtask(index),
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Colors.red[300],
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Details Editor
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rich Text Editor Container
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: editorColor,
                        ),
                        foregroundDecoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Custom Quill Toolbar
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: toolbarColor,
                                border: Border(
                                  bottom: BorderSide(color: borderColor),
                                ),
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
                                    const VerticalDivider(
                                      width: 16,
                                      thickness: 1,
                                    ),
                                    QuillToolbarSelectHeaderStyleDropdownButton(
                                      controller: _quillController,
                                    ),
                                    const VerticalDivider(
                                      width: 16,
                                      thickness: 1,
                                    ),
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
                                config: const QuillEditorConfig(
                                  placeholder: 'Add details...',
                                  padding: EdgeInsets.zero,
                                  autoFocus: false,
                                  expands: false,
                                  scrollable: true,
                                  showCursor: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: hintColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.todo == null ? 'Create Task' : 'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

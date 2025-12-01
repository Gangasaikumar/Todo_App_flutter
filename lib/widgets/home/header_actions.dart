import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/theme_provider.dart';
import 'clear_tasks_button.dart';

class HeaderActions extends StatelessWidget {
  final bool showAllTasks;
  final VoidCallback onShowAllTasksChanged;

  const HeaderActions({
    super.key,
    required this.showAllTasks,
    required this.onShowAllTasksChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<TodoProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, child) {
        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.calendar_month,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: provider.selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != provider.selectedDate) {
                  provider.selectDate(picked);
                  // If we were showing all tasks, switch back to single date view
                  if (showAllTasks) {
                    onShowAllTasksChanged();
                  }
                }
              },
            ),
            if (!showAllTasks) const ClearTasksButton(),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                themeProvider.toggleTheme(!themeProvider.isDarkMode);
              },
            ),
          ],
        );
      },
    );
  }
}

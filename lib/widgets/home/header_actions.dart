import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/settings_screen.dart';

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
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            if (provider.streakCount > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.streakCount}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
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
            if (!showAllTasks) ...[],
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

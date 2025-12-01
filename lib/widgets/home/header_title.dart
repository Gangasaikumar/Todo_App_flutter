import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/todo_provider.dart';

class HeaderTitle extends StatelessWidget {
  final bool showAllTasks;

  const HeaderTitle({super.key, required this.showAllTasks});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        final isToday = provider.isSameDate(
          provider.selectedDate,
          DateTime.now(),
        );
        final displayDate = DateFormat(
          'MMM d, yyyy',
        ).format(provider.selectedDate);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showAllTasks
                  ? 'All Tasks'
                  : (isToday
                        ? 'Today'
                        : DateFormat('EEEE').format(provider.selectedDate)),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            if (!showAllTasks)
              Text(
                displayDate,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        );
      },
    );
  }
}

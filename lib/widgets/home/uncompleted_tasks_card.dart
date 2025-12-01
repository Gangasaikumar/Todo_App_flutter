import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/theme_provider.dart';

class UncompletedTasksCard extends StatelessWidget {
  final bool showAllTasks;
  final VoidCallback onTap;

  const UncompletedTasksCard({
    super.key,
    required this.showAllTasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<TodoProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, child) {
        if (provider.totalUncompletedCount == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: showAllTasks
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.primary.withAlpha(
                            51,
                          ) // 0.2 opacity
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(25)) // 0.1 opacity
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withAlpha(51) // 0.2 opacity
                        : Colors.white),
              borderRadius: BorderRadius.circular(12),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? [
                      BoxShadow(
                        color: showAllTasks
                            ? Theme.of(context).colorScheme.primary.withAlpha(
                                51,
                              ) // 0.2 opacity
                            : Colors.grey.withAlpha(25), // 0.1 opacity
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
              border: showAllTasks
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Uncompleted Tasks',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade100
                        : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: showAllTasks
                      ? Icon(
                          Icons.close,
                          size: 20,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900
                              : Colors.white,
                        )
                      : Text(
                          '${provider.totalUncompletedCount}',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.shade900
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

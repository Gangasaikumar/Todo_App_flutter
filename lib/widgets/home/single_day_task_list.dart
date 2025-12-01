import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../tasks/todo_item.dart';
import '../common/empty_state.dart';

class SingleDayTaskList extends StatelessWidget {
  const SingleDayTaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final currentTodos = todoProvider.todosForSelectedDate;
        final activeTodos = currentTodos.where((t) => !t.isCompleted).toList();
        final completedTodos = currentTodos
            .where((t) => t.isCompleted)
            .toList();

        if (activeTodos.isEmpty && completedTodos.isEmpty) {
          return const EmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activeTodos.isNotEmpty)
              Padding(
                key: const ValueKey('ActiveHeader'),
                padding: const EdgeInsets.only(
                  bottom: 12,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Text(
                  'Active Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
              ),
            Expanded(
              child: ReorderableListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  todoProvider.reorderTodos(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue = Curves.easeInOut.transform(
                        animation.value,
                      );
                      final double elevation = lerpDouble(0, 6, animValue)!;
                      return Material(
                        elevation: elevation,
                        color: Colors.transparent,
                        shadowColor: Colors.black.withAlpha(51), // 0.2 opacity
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      );
                    },
                    child: child,
                  );
                },
                footer: completedTodos.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...completedTodos.map(
                            (todo) => TodoItem(todo: todo, index: -1),
                          ),
                        ],
                      )
                    : null,
                children: [
                  for (int i = 0; i < activeTodos.length; i++)
                    TodoItem(
                      key: ValueKey(activeTodos[i].id),
                      todo: activeTodos[i],
                      index: i,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

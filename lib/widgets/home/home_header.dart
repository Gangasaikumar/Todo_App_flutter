import 'package:flutter/material.dart';
import 'header_title.dart';
import 'header_actions.dart';

class HomeHeader extends StatelessWidget {
  final bool showAllTasks;
  final VoidCallback onShowAllTasksChanged;
  final VoidCallback onAddNew;

  const HomeHeader({
    super.key,
    required this.showAllTasks,
    required this.onShowAllTasksChanged,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomeHeader...');
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                HeaderTitle(showAllTasks: showAllTasks),
                HeaderActions(
                  showAllTasks: showAllTasks,
                  onShowAllTasksChanged: onShowAllTasksChanged,
                  onAddNew: onAddNew,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

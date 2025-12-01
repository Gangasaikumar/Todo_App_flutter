import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../widgets/home/date_timeline.dart';
import '../widgets/home/home_header.dart';
import '../widgets/home/search_bar_widget.dart';
import '../widgets/home/category_filter.dart';
import '../widgets/home/uncompleted_tasks_card.dart';
import '../widgets/dialogs/add_todo_dialog.dart';
import '../widgets/home/single_day_task_list.dart';
import '../widgets/home/all_tasks_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllTasks = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen initState');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomeScreen...');
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          HomeHeader(
            showAllTasks: _showAllTasks,
            onShowAllTasksChanged: () {
              setState(() {
                _showAllTasks = !_showAllTasks;
              });
            },
            onAddNew: () {
              showDialog(
                context: context,
                builder: (context) => AddTodoDialog(
                  initialDate: Provider.of<TodoProvider>(
                    context,
                    listen: false,
                  ).selectedDate,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const SearchBarWidget(),
          const SizedBox(height: 16),
          const CategoryFilter(),
          const SizedBox(height: 24),
          UncompletedTasksCard(
            showAllTasks: _showAllTasks,
            onTap: () {
              setState(() {
                _showAllTasks = !_showAllTasks;
              });
            },
          ),
          if (!_showAllTasks) ...[
            const SizedBox(height: 24),
            const DateTimeline(),
            const SizedBox(height: 16),
          ],
          // Todo List
          Expanded(
            child: Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                if (_showAllTasks) {
                  return const AllTasksList();
                } else {
                  return const SingleDayTaskList();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/theme_provider.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TodoProvider, ThemeProvider>(
      builder: (context, provider, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: TextField(
            key: const Key('searchBar'),
            onChanged: (value) {
              provider.setSearchQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              hintStyle: TextStyle(
                color: themeProvider.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              prefixIcon: Icon(
                Icons.search,
                color: themeProvider.isDarkMode
                    ? Colors.grey[400]
                    : Colors.grey,
              ),
              filled: true,
              fillColor: themeProvider.isDarkMode
                  ? Colors.grey[800]
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        );
      },
    );
  }
}

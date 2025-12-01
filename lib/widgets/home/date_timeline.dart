import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';

class DateTimeline extends StatelessWidget {
  const DateTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show next 30 days
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = now.add(Duration(days: index));

          return Consumer<TodoProvider>(
            builder: (context, provider, child) {
              final isSelected = provider.isSameDate(
                date,
                provider.selectedDate,
              );

              return GestureDetector(
                onTap: () {
                  provider.selectDate(date);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFBCB57) // Pastel Yellow
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        !isSelected &&
                            Theme.of(context).brightness == Brightness.light
                        ? Border.all(color: Colors.grey[300]!)
                        : null,
                    // No shadow for selected as requested
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(
                                  0xFF5D4037,
                                ) // Dark Brown/Yellow for contrast
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E').format(date), // Mon, Tue, etc.
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? const Color(
                                  0xFF5D4037,
                                ) // Dark Brown/Yellow for contrast
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

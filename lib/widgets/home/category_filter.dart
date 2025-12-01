import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: provider.selectedCategoryFilter == 'All',
                  onSelected: (selected) {
                    if (selected) {
                      provider.setCategoryFilter('All');
                    }
                  },
                  showCheckmark: true,
                  checkmarkColor: const Color(0xFF46539E),
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white.withAlpha(128), // 0.5 opacity
                  labelStyle: const TextStyle(
                    color: Color(0xFF46539E),
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: provider.selectedCategoryFilter == 'All'
                        ? const BorderSide(color: Color(0xFF46539E), width: 2)
                        : BorderSide.none,
                  ),
                ),
              ),
              ...provider.categories.map((category) {
                final isSelected =
                    provider.selectedCategoryFilter == category.name;
                final categoryColor = Color(category.colorValue);
                // Darker color for text/border
                final darkColor = HSLColor.fromColor(
                  categoryColor,
                ).withLightness(0.4).toColor();

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setCategoryFilter(category.name);
                      }
                    },
                    showCheckmark: true,
                    checkmarkColor: darkColor,
                    selectedColor: categoryColor.withAlpha(76), // 0.3 opacity
                    backgroundColor: categoryColor.withAlpha(
                      38,
                    ), // 0.15 opacity
                    labelStyle: TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: isSelected
                          ? BorderSide(color: darkColor, width: 2)
                          : BorderSide.none,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

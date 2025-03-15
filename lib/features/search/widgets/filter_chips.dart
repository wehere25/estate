import 'package:flutter/material.dart';

class FilterOption {
  final int id;
  final String label;
  final bool isSelected;

  const FilterOption({
    required this.id,
    required this.label,
    required this.isSelected,
  });
}

class FilterChips extends StatelessWidget {
  final List<FilterOption> filterOptions;
  final Function(int, bool) onFilterSelected;

  const FilterChips({
    Key? key,
    required this.filterOptions,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: filterOptions.map((filter) {
        return FilterChip(
          label: Text(
            filter.label,
            style: TextStyle(
              color: filter.isSelected
                  ? (isDark ? Colors.white : Colors.white)
                  : (isDark ? Colors.grey[300] : Colors.grey[800]),
            ),
          ),
          selected: filter.isSelected,
          onSelected: (bool selected) => onFilterSelected(filter.id, selected),
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
          selectedColor: Theme.of(context).colorScheme.primary,
          checkmarkColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}

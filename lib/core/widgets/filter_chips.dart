import 'package:flutter/material.dart';

class FilterOption {
  final String id;
  final String label;
  final bool isSelected;

  const FilterOption({
    required this.id,
    required this.label,
    this.isSelected = false,
  });

  FilterOption copyWith({
    String? id,
    String? label,
    bool? isSelected,
  }) {
    return FilterOption(
      id: id ?? this.id,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<FilterOption> filterOptions;
  final Function(String, bool) onFilterSelected;

  const FilterChips({
    super.key,
    required this.filterOptions,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
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
                fontWeight:
                    filter.isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            selected: filter.isSelected,
            onSelected: (bool selected) =>
                onFilterSelected(filter.id, selected),
            backgroundColor:
                isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
            selectedColor: Theme.of(context).colorScheme.primary,
            checkmarkColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: filter.isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
            ),
            elevation: filter.isSelected ? 2 : 0,
            pressElevation: 4,
          );
        }).toList(),
      ),
    );
  }
}

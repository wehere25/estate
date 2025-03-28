import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class QuickFilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const QuickFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip('All', context),
          _buildFilterChip('For Sale', context),
          _buildFilterChip('For Rent', context),
          _buildFilterChip('Furnished', context),
          _buildFilterChip('Newest', context),
          _buildFilterChip('Price ↓', context),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, BuildContext context) {
    final isSelected = selectedFilter == label;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onFilterSelected(label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? theme.colorScheme.primary : Colors.white)
              : (isDarkMode
                  ? theme.colorScheme.surface.withOpacity(0.7)
                  : Colors.white.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? theme.colorScheme.primary : Colors.white)
                : (isDarkMode
                    ? theme.colorScheme.onSurface.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDarkMode
                    ? theme.colorScheme.onPrimary
                    : AppColors.lightColorScheme.primary)
                : (isDarkMode ? theme.colorScheme.onSurface : Colors.white),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/constants/app_styles.dart';

enum FilterType {
  propertyType,
  price,
  bedrooms,
  location
}

class PropertyFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;
  final FilterType type;

  const PropertyFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.transparent,
        selectedColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusM,
          side: BorderSide(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingM,
          vertical: AppStyles.paddingS,
        ),
      ),
    );
  }
}

class PriceRangeFilter extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final double min;
  final double max;
  final int divisions;

  const PriceRangeFilter({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1000000,
    this.divisions = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingM),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${values.start.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\$${values.end.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        RangeSlider(
          values: values,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ],
    );
  }
}

class FilterGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onOptionSelected;
  final FilterType type;

  const FilterGroup({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppStyles.paddingM),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.paddingM),
          child: Row(
            children: options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(right: AppStyles.paddingS),
                child: PropertyFilterChip(
                  label: option,
                  isSelected: selectedOption == option,
                  onSelected: () => onOptionSelected(option),
                  type: type,
                  icon: _getIconForType(type),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData? _getIconForType(FilterType type) {
    switch (type) {
      case FilterType.propertyType:
        return Icons.home;
      case FilterType.bedrooms:
        return Icons.bed;
      case FilterType.location:
        return Icons.location_on;
      default:
        return null;
    }
  }
}

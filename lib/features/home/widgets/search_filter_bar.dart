import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearchSubmitted;
  final VoidCallback onFilterTap;

  const SearchFilterBar({
    Key? key,
    required this.controller,
    required this.onSearchSubmitted,
    required this.onFilterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('⚡ SearchFilterBar: Building widget');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color:
            Colors.white, // Always white in header for contrast with gradient
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon - matching HTML design
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.grayColor,
              size: 24,
            ),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search properties...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                hintStyle: TextStyle(
                  color: AppColors.grayColor,
                  fontSize: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.black87 : Colors.black87,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                debugPrint('🔍 SearchFilterBar: Search submitted: $value');
                onSearchSubmitted(value);
              },
            ),
          ),

          // Filter icon - matching HTML design
          Material(
            color: Colors.transparent,
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(12)),
            child: InkWell(
              onTap: () {
                debugPrint('🔴 SearchFilterBar: Filter button tapped');
                onFilterTap();
              },
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                height: 54,
                child: Icon(
                  Icons.tune, // Filter icon matching HTML
                  color: AppColors.grayColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

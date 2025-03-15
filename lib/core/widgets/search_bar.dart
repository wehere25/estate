import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onChanged;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.onFilterTap,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 20, // Slightly smaller icon to prevent overflow
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search properties...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.grey[500],
                  fontSize: 14, // Smaller font size to prevent overflow
                ),
                isDense: true, // More compact to prevent overflow
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Make sure the button doesn't cause overflow
          IconButton(
            icon: Icon(
              Icons.tune,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
              size: 20, // Slightly smaller icon
            ),
            constraints: const BoxConstraints(minWidth: 40),
            onPressed: onFilterTap,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final bool showFilterIcon;
  final VoidCallback? onFilterPressed;

  const SearchBarWidget({
    Key? key,
    this.showFilterIcon = false,
    this.onFilterPressed,
    // ...existing code...
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.2),
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
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          // ...existing TextField code...
          if (showFilterIcon)
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onPressed: onFilterPressed,
            ),
        ],
      ),
    );
  }
}

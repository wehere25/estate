import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class PropertyListHeader extends StatelessWidget {
  final String title;
  final bool isGridView;
  final VoidCallback onViewToggle;

  const PropertyListHeader({
    Key? key,
    required this.title,
    required this.isGridView,
    required this.onViewToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
            onPressed: onViewToggle,
            tooltip: isGridView ? 'Switch to list view' : 'Switch to grid view',
          ),
        ],
      ),
    );
  }
}

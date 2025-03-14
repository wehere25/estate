import 'package:flutter/material.dart';

class AmenityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AmenityChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text('$label: $value'),
    );
  }
}

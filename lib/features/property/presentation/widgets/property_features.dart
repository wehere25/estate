import 'package:flutter/material.dart';
import '../../data/models/property_dto.dart';
import '../../../../core/constants/app_styles.dart';

class PropertyFeatures extends StatelessWidget {
  final PropertyDto property;

  const PropertyFeatures({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeature(Icons.bed, '${property.bedrooms} Beds'),
        _buildFeature(Icons.bathtub, '${property.bathrooms} Baths'),
        _buildFeature(Icons.square_foot, '${property.area} m²'),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: AppStyles.paddingS),
        Text(text),
      ],
    );
  }
}

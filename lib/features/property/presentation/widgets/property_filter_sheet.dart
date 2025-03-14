import 'package:flutter/material.dart';
import '/features/property/domain/models/property_model.dart';

class PropertyFilterSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const PropertyFilterSheet({
    Key? key,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<PropertyFilterSheet> createState() => _PropertyFilterSheetState();
}

class _PropertyFilterSheetState extends State<PropertyFilterSheet> {
  double _minPrice = 50000;
  double _maxPrice = 1000000;
  int _bedrooms = 1;
  PropertyType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Properties',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Price Range
          Text(
            'Price Range',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 2000000,
            divisions: 20,
            labels: RangeLabels(
              '\$${_minPrice.round()}',
              '\$${_maxPrice.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${_minPrice.round()}'),
              Text('\$${_maxPrice.round()}'),
            ],
          ),
          const SizedBox(height: 20),
          
          // Bedrooms
          Text(
            'Bedrooms',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: _bedrooms,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: [1, 2, 3, 4, 5]
                .map((bedCount) => DropdownMenuItem(
                      value: bedCount,
                      child: Text('$bedCount+'),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _bedrooms = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          
          // Property Type
          Text(
            'Property Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _buildPropertyTypeSection(),
          const SizedBox(height: 30),
          
          // Apply Button
          ElevatedButton(
            onPressed: () {
              final filters = {
                'minPrice': _minPrice,
                'maxPrice': _maxPrice,
                'bedrooms': _bedrooms,
                'propertyType': _selectedType,
              };
              widget.onApplyFilters(filters);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPropertyTypeChip('Any', null),
            _buildPropertyTypeChip('House', PropertyType.house),
            _buildPropertyTypeChip('Apartment', PropertyType.apartment),
            _buildPropertyTypeChip('Condo', PropertyType.condo),
            _buildPropertyTypeChip('Townhouse', PropertyType.townhouse),
            _buildPropertyTypeChip('Land', PropertyType.land),
            _buildPropertyTypeChip('Commercial', PropertyType.commercial),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeChip(String label, PropertyType? type) {
    final isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }
}

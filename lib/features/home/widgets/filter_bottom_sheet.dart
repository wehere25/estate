
import 'package:flutter/material.dart';
import '/core/constants/app_colors.dart';

class FilterBottomSheetWithLogs extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApply;
  
  const FilterBottomSheetWithLogs({
    Key? key,
    this.onApply,
  }) : super(key: key);

  @override
  State<FilterBottomSheetWithLogs> createState() => _FilterBottomSheetWithLogsState();
}

class _FilterBottomSheetWithLogsState extends State<FilterBottomSheetWithLogs> {
  RangeValues _priceRange = const RangeValues(100000, 1000000);
  int _bedrooms = 0;
  int _bathrooms = 0;
  String _propertyType = 'Any';
  bool _hasParking = false;
  bool _hasPool = false;
  bool _hasPets = false;

  @override
  void initState() {
    super.initState();
    debugPrint('⚙️ FilterBottomSheet: initState called');
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('⚙️ FilterBottomSheet: Building widget');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          const Center(
            child: Text(
              'Filter Properties',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Price Range
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 2000000,
            divisions: 20,
            labels: RangeLabels(
              '₹${_priceRange.start.round()}', // Changed to ₹
              '₹${_priceRange.end.round()}', // Changed to ₹
            ),
            onChanged: (RangeValues values) {
              debugPrint('⚙️ FilterBottomSheet: Price range changed: $values');
              setState(() {
                _priceRange = values;
              });
            },
          ),
          // Price range values display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹${_priceRange.start.round()}'), // Changed to ₹
              Text('₹${_priceRange.end.round()}'), // Changed to ₹
            ],
          ),
          
          // ... other filter options ...
          
          // Apply Button
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                debugPrint('⚙️ FilterBottomSheet: Apply button tapped');
                
                final filters = {
                  'minPrice': _priceRange.start,
                  'maxPrice': _priceRange.end,
                  'bedrooms': _bedrooms > 0 ? _bedrooms : null,
                  'bathrooms': _bathrooms > 0 ? _bathrooms : null,
                  'propertyType': _propertyType != 'Any' ? _propertyType : null,
                  'hasParking': _hasParking ? true : null,
                  'hasPool': _hasPool ? true : null,
                  'hasPets': _hasPets ? true : null,
                };
                
                if (widget.onApply != null) {
                  widget.onApply!(filters);
                }
                
                Navigator.pop(context, filters);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightColorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ... rest of your methods ...
}

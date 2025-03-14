import 'package:flutter/material.dart';
import '/core/constants/app_styles.dart';
import '../../domain/models/property_model.dart';

class PropertyFilter extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onFilterChanged;

  const PropertyFilter({
    Key? key,
    required this.initialFilters,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<PropertyFilter> createState() => _PropertyFilterState();
}

class _PropertyFilterState extends State<PropertyFilter> {
  late Map<String, dynamic> _filters;
  final _formKey = GlobalKey<FormState>();
  
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  
  int _minBedrooms = 0;
  PropertyType? _selectedType;
  PropertyStatus? _selectedStatus;
  
  // Property type selections
  final List<PropertyType> _propertyTypes = PropertyType.values;
  
  // Property status selections
  final List<PropertyStatus> _propertyStatuses = PropertyStatus.values;
  
  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters);
    
    // Initialize controllers with existing values
    _minPriceController.text = _filters['minPrice']?.toString() ?? '';
    _maxPriceController.text = _filters['maxPrice']?.toString() ?? '';
    
    // Initialize other filter values
    _minBedrooms = _filters['bedrooms'] ?? 0;
    
    if (_filters['propertyType'] != null) {
      _selectedType = _propertyTypes.firstWhere(
        (type) => type.toString() == _filters['propertyType'],
        orElse: () => PropertyType.house,
      );
    }
    
    if (_filters['status'] != null) {
      _selectedStatus = _propertyStatuses.firstWhere(
        (status) => status.toString() == _filters['status'],
        orElse: () => PropertyStatus.available,
      );
    }
  }
  
  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
  
  void _applyFilters() {
    if (_formKey.currentState!.validate()) {
      final minPrice = _minPriceController.text.isNotEmpty ? 
        double.parse(_minPriceController.text) : null;
      
      final maxPrice = _maxPriceController.text.isNotEmpty ? 
        double.parse(_maxPriceController.text) : null;
      
      final updatedFilters = {
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'bedrooms': _minBedrooms > 0 ? _minBedrooms : null,
        'propertyType': _selectedType?.toString(),
        'status': _selectedStatus?.toString(),
      };
      
      // Notify parent about filter changes
      widget.onFilterChanged(updatedFilters);
      
      // Return filters to close sheet and update
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _minPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Min Price',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Price',
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Minimum Bedrooms:'),
                const SizedBox(width: 16),
                DropdownButton<int>(
                  value: _minBedrooms,
                  items: [0, 1, 2, 3, 4, 5]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e+')))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _minBedrooms = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<PropertyType>(
              value: _selectedType,
              hint: const Text('Property Type'),
              isExpanded: true,
              items: _propertyTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButton<PropertyStatus>(
              value: _selectedStatus,
              hint: const Text('Property Status'),
              isExpanded: true,
              items: _propertyStatuses
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

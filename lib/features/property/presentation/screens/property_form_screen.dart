import 'package:flutter/material.dart';
import '../../domain/models/property_model.dart';

/// Form modes for property form
enum PropertyFormMode {
  create,
  edit,
  view,
}

/// A unified form for property creation, editing, and viewing
class PropertyFormScreen extends StatefulWidget {
  final PropertyModel? property;
  final PropertyFormMode mode;
  
  const PropertyFormScreen({
    Key? key, 
    this.property, 
    this.mode = PropertyFormMode.create
  }) : super(key: key);

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _areaController;
  String _propertyType = 'House';
  String _listingType = 'Sale';
  
  bool _isReadOnly = false;
  bool _isLoading = false;
  List<String> _existingImages = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _titleController = TextEditingController();
    _priceController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _bedroomsController = TextEditingController();
    _bathroomsController = TextEditingController();
    _areaController = TextEditingController();
    
    // Initialize form based on mode
    if (widget.mode != PropertyFormMode.create && widget.property != null) {
      _populateForm(widget.property!);
    }
    
    // Set read-only mode if viewing
    _isReadOnly = widget.mode == PropertyFormMode.view;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }
  
  void _populateForm(PropertyModel property) {
    _titleController.text = property.title;
    _priceController.text = property.price.toString();
    _descriptionController.text = property.description ?? '';
    _locationController.text = property.location ?? '';
    _bedroomsController.text = property.bedrooms?.toString() ?? '';
    _bathroomsController.text = property.bathrooms?.toString() ?? '';
    _areaController.text = property.area?.toString() ?? '';
    _propertyType = property.propertyType;
    _listingType = property.listingType;
    _existingImages = List.from(property.images ?? []);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleText()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form fields would go here
                    Text('Property Form - ${widget.mode.name}'),
                    // Implement actual form fields based on property_upload_screen.dart
                  ],
                ),
              ),
            ),
    );
  }
  
  String _getTitleText() {
    switch (widget.mode) {
      case PropertyFormMode.create:
        return 'Add Property';
      case PropertyFormMode.edit:
        return 'Edit Property';
      case PropertyFormMode.view:
        return 'Property Details';
    }
  }
}

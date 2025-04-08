import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../property/domain/models/property_model.dart';
import '../../../property/presentation/providers/property_provider.dart';
import '../../../storage/providers/storage_provider.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../../features/property/presentation/widgets/shared_property_detail_view.dart';

class PropertyEditScreen extends StatefulWidget {
  final String propertyId;

  const PropertyEditScreen({Key? key, required this.propertyId})
      : super(key: key);

  @override
  State<PropertyEditScreen> createState() => _PropertyEditScreenState();
}

class _PropertyEditScreenState extends State<PropertyEditScreen> {
  final _formKey = GlobalKey<FormState>();
  PropertyModel? _property;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showPreview = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  String _propertyType = 'house';
  String _listingType = 'Sale';
  bool _featured = false;
  String _selectedStatus = 'available';

  final ImagePicker _picker = ImagePicker();
  List<XFile> _newImages = [];
  List<String> _existingImages = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProperty();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _loadProperty() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      // Use fetchPropertyById instead of getPropertyById to ensure we get the property from Firestore
      final property =
          await propertyProvider.fetchPropertyById(widget.propertyId);

      if (property == null) {
        setState(() {
          _errorMessage = "Property not found";
          _isLoading = false;
        });
        return;
      }

      // Populate form fields
      _titleController.text = property.title;
      _descriptionController.text = property.description;
      _priceController.text = property.price.toString();
      _locationController.text = property.location ?? '';
      _bedroomsController.text = property.bedrooms.toString();
      _bathroomsController.text = property.bathrooms.toString();
      _areaController.text = property.area.toString();
      _propertyType = property.propertyType.toLowerCase();
      _listingType = property.listingType;
      _featured = property.featured;
      _selectedStatus = property.status.toString().split('.').last;
      _existingImages = property.images ?? [];

      setState(() {
        _property = property;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load property: ${e.toString()}";
        _isLoading = false;
      });
      DebugLogger.error('Error loading property', e);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _newImages.addAll(pickedFiles);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(context, 'Error picking images: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _newImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(context, 'Error taking picture: $e');
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<void> _saveProperty() async {
    if (_property == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      final storageProvider =
          Provider.of<StorageProvider>(context, listen: false);

      // Upload new images if any
      List<String> allImages = [..._existingImages];
      if (_newImages.isNotEmpty) {
        try {
          List<String> uploadedImageUrls = [];
          for (final imageFile in _newImages) {
            try {
              final fileName = path.basename(imageFile.path);
              final destination =
                  'properties/${DateTime.now().millisecondsSinceEpoch}_$fileName';
              final downloadUrl = await storageProvider.uploadFile(
                File(imageFile.path),
                destination,
              );
              uploadedImageUrls.add(downloadUrl);
            } catch (e) {
              DebugLogger.error('Error uploading image', e);
              rethrow;
            }
          }
          allImages.addAll(uploadedImageUrls);
        } catch (e) {
          if (mounted) {
            SnackBarUtils.showErrorSnackBar(
                context, 'Error uploading images: $e');
          }
          return;
        }
      }

      // Create updated data map
      final Map<String, dynamic> updatedData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'location': _locationController.text,
        'bedrooms': int.parse(_bedroomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        'area': double.parse(_areaController.text),
        'propertyType': _propertyType,
        'listingType': _listingType,
        'featured': _featured,
        'status': _selectedStatus,
        'images': allImages,
      };

      // Update property
      if (_property?.id == null) return;
      await propertyProvider.updateProperty(_property!.id!, updatedData);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Property updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to update property: ${e.toString()}";
          _isLoading = false;
        });
        DebugLogger.error('Error updating property', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Property ${_property?.id ?? ''}'),
          actions: [
            // Save button
            if (_property != null && !_showPreview)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save Changes',
                onPressed: _saveProperty,
              ),
            // Preview button
            if (_property != null)
              IconButton(
                icon: const Icon(Icons.preview),
                tooltip: 'Preview Property',
                onPressed: () {
                  setState(() {
                    _showPreview = !_showPreview;
                  });
                },
              ),
          ],
        ),
        body: _errorMessage != null
            ? _buildErrorView()
            : _property == null
                ? const Center(child: CircularProgressIndicator())
                : _showPreview
                    ? _buildPreview()
                    : _buildForm(),
        floatingActionButton: _property != null && !_showPreview
            ? FloatingActionButton.extended(
                onPressed: _saveProperty,
                icon: const Icon(Icons.save),
                label: const Text('Save Changes'),
              )
            : null,
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings),
              const SizedBox(width: 8),
              const Text('ADMIN PREVIEW MODE',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Back to Edit'),
                onPressed: () {
                  setState(() {
                    _showPreview = false;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: SharedPropertyDetailView(
            property: _property!,
            isAdmin: true,
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _takePicture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Existing images
        if (_existingImages.isNotEmpty) ...[
          const Text(
            'Existing Images:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingImages[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeExistingImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],

        // New images
        if (_newImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'New Images:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_newImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeNewImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildForm() {
    if (_property == null) {
      return const Center(child: Text("Loading property..."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagesSection(),
            const SizedBox(height: 24),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  ValidationUtils.validateNotEmpty(value, "Title is required"),
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              validator: (value) => ValidationUtils.validateNotEmpty(
                  value, "Description is required"),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Price field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Price",
                border: OutlineInputBorder(),
                prefixText: "₹ ",
              ),
              validator: (value) =>
                  ValidationUtils.validateNumber(value, "Price"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 16),

            // Location field
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Location",
                border: OutlineInputBorder(),
              ),
              validator: (value) => ValidationUtils.validateNotEmpty(
                  value, "Location is required"),
            ),

            const SizedBox(height: 16),

            // Property details in a row
            Row(
              children: [
                // Bedrooms field
                Expanded(
                  child: TextFormField(
                    controller: _bedroomsController,
                    decoration: const InputDecoration(
                      labelText: "Bedrooms",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        ValidationUtils.validateNumber(value, "Bedrooms"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                // Bathrooms field
                Expanded(
                  child: TextFormField(
                    controller: _bathroomsController,
                    decoration: const InputDecoration(
                      labelText: "Bathrooms",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        ValidationUtils.validateNumber(value, "Bathrooms"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Area field
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: "Area (sq ft)",
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  ValidationUtils.validateNumber(value, "Area"),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 24),

            // Property type dropdown
            DropdownButtonFormField<String>(
              value: _propertyType.toLowerCase(),
              decoration: const InputDecoration(
                labelText: "Property Type",
                border: OutlineInputBorder(),
              ),
              items: ["house", "apartment", "condo", "land", "commercial"]
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.substring(0, 1).toUpperCase() +
                            type.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _propertyType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Listing type dropdown
            DropdownButtonFormField<String>(
              value: _listingType,
              decoration: const InputDecoration(
                labelText: "Listing Type",
                border: OutlineInputBorder(),
              ),
              items: ["Sale", "Rent"]
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _listingType = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Status dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: "Status",
                border: OutlineInputBorder(),
              ),
              items: ["available", "sold", "rented", "pending", "inactive"]
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.substring(0, 1).toUpperCase() +
                            status.substring(1)),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Featured checkbox
            CheckboxListTile(
              title: const Text("Featured Property"),
              value: _featured,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _featured = value;
                  });
                }
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProperty,
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}

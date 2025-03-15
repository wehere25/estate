import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:go_router/go_router.dart';

// App imports
import '/core/utils/snackbar_utils.dart';
import '/core/utils/validation_utils.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/providers/property_provider.dart';
import '/features/storage/providers/storage_provider.dart';
import 'package:azharapp/features/auth/domain/providers/auth_provider.dart';
import '/core/utils/dev_utils.dart';
import '/core/navigation/app_scaffold.dart'; // Keep only this import for AppScaffold
import '/features/admin/presentation/widgets/map_section_form.dart';

class PropertyUploadScreen extends StatefulWidget {
  final PropertyModel? propertyToEdit;
  final bool showNavBar;

  const PropertyUploadScreen(
      {Key? key, this.propertyToEdit, this.showNavBar = true})
      : super(key: key);

  @override
  State<PropertyUploadScreen> createState() => _PropertyUploadScreenState();
}

class _PropertyUploadScreenState extends State<PropertyUploadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController =
      TextEditingController(); // Plain text instead of QuillController

  // Property details
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  String _propertyType = 'House';
  String _listingType = 'Sale';

  final ImagePicker _picker = ImagePicker();
  List<XFile> _imageFiles = [];
  List<String> _existingImages = [];
  bool _isUploading = false;
  bool _isLoadingLocation = false;

  // Location data
  double? _latitude;
  double? _longitude;

  // Agent contact controllers
  final _agentNameController = TextEditingController();
  final _agentPhoneController = TextEditingController();
  final _agentEmailController = TextEditingController();
  final _agentAgencyController = TextEditingController();

  // Animation controller for form sections
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // If editing an existing property, populate the form
    if (widget.propertyToEdit != null) {
      _populateForm();
    }

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    if (mounted) {
      _titleController.dispose();
      _priceController.dispose();
      _addressController.dispose();
      _descriptionController.dispose();
      _bedroomsController.dispose();
      _bathroomsController.dispose();
      _areaController.dispose();
      // Dispose agent contact controllers
      _agentNameController.dispose();
      _agentPhoneController.dispose();
      _agentEmailController.dispose();
      _agentAgencyController.dispose();
      _animationController.dispose();
    }
    super.dispose();
  }

  void _populateForm() {
    final property = widget.propertyToEdit!;

    _titleController.text = property.title;
    _priceController.text = property.price.toString();
    _addressController.text =
        property.location ?? ''; // Using location instead of address
    _descriptionController.text = property.description;
    _bedroomsController.text = property.bedrooms.toString();
    _bathroomsController.text = property.bathrooms.toString();
    _areaController.text = property.area.toString();
    _propertyType = property.propertyType;
    _listingType = property.listingType;

    // Set location data
    _latitude = property.latitude;
    _longitude = property.longitude;

    // Load existing images
    _existingImages = property.images ?? [];

    // Populate agent contact details if available
    if (property.agentContact != null) {
      _agentNameController.text = property.agentContact!.name;
      _agentPhoneController.text = property.agentContact!.phone;
      _agentEmailController.text = property.agentContact!.email ?? '';
      _agentAgencyController.text = property.agentContact!.agency ?? '';
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _imageFiles.addAll(pickedFiles);
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
          _imageFiles.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(context, 'Error taking picture: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update location fields
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });

      // Get address for the location
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _addressController.text =
              '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });

      if (mounted) {
        SnackBarUtils.showErrorSnackBar(
            context, 'Error getting current location: $e');
      }
    }
  }

  // Update location from map selection
  void _updateLocationFromMap(double latitude, double longitude) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
    });

    // Try to get address for the selected location
    _getAddressFromCoordinates(latitude, longitude);
  }

  // Get address from coordinates
  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks.first;
        setState(() {
          _addressController.text =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}';
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(
            context, 'Error getting address from coordinates: $e');
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isUploading = true;
    });
    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      // Get user ID - handle development mode
      String userId;
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        userId = DevUtils.devUserId;
        DevUtils.log('Using dev user ID: $userId');
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        userId = authProvider.user?.uid ?? '';
        if (userId.isEmpty) {
          throw Exception('User not logged in');
        }
      }
      // Prepare images upload
      List<String> allImages = [..._existingImages];
      // Only try to upload new images if there are any
      if (_imageFiles.isNotEmpty) {
        try {
          final storageProvider =
              Provider.of<StorageProvider>(context, listen: false);
          List<String> uploadedImageUrls = [];
          // Upload each image with error handling
          for (final imageFile in _imageFiles) {
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
              DevUtils.log('Error uploading image: $e');
              if (DevUtils.isDev) {
                // In dev mode, use a placeholder for failed uploads
                uploadedImageUrls.add(
                    'https://via.placeholder.com/800x600?text=Upload+Failed');
              } else {
                // In production, rethrow
                rethrow;
              }
            }
          }
          allImages = [..._existingImages, ...uploadedImageUrls];
        } catch (e) {
          // In dev mode, continue with existing images
          if (!DevUtils.isDev) {
            rethrow;
          }
          DevUtils.log('Continuing with existing images only due to error: $e');
          // Check if the widget is still mounted before using BuildContext
          if (mounted) {
            SnackBarUtils.showWarningSnackBar(
                context, 'Failed to upload images, using existing only');
          }
        }
      }
      // Create agent contact data if fields are filled
      Map<String, dynamic>? agentContactData;
      if (_agentNameController.text.isNotEmpty &&
          _agentPhoneController.text.isNotEmpty) {
        agentContactData = {
          'name': _agentNameController.text,
          'phone': _agentPhoneController.text,
          'email': _agentEmailController.text.isNotEmpty
              ? _agentEmailController.text
              : null,
          'agency': _agentAgencyController.text.isNotEmpty
              ? _agentAgencyController.text
              : null,
        };
      }
      // Create property data map
      final propertyData = {
        'id': widget.propertyToEdit?.id,
        'title': _titleController.text,
        'price': double.parse(_priceController.text),
        'location': _addressController.text,
        'description': _descriptionController.text,
        'bedrooms': int.parse(_bedroomsController.text),
        'bathrooms': int.parse(_bathroomsController.text),
        'area': double.parse(_areaController.text),
        'images': allImages,
        'latitude': _latitude,
        'longitude': _longitude,
        'createdAt': widget.propertyToEdit?.createdAt ?? DateTime.now(),
        'updatedAt': DateTime.now(),
        'type': PropertyType.house
            .toString()
            .split('.')
            .last, // Use enum value's string representation
        'status': PropertyStatus.available
            .toString()
            .split('.')
            .last, // Use enum value's string representation
        'propertyType': _propertyType,
        'listingType': _listingType,
        'ownerId': userId,
        'agentContact': agentContactData,
      };
      // Save property
      if (widget.propertyToEdit != null && widget.propertyToEdit!.id != null) {
        await propertyProvider.updateProperty(
            widget.propertyToEdit!.id!, propertyData);
      } else {
        await propertyProvider.addNewProperty(propertyData);
      }
      if (mounted) {
        SnackBarUtils.showSuccessSnackBar(
            context,
            widget.propertyToEdit != null
                ? 'Property updated successfully'
                : 'Property added successfully');
        // Clear form
        if (widget.propertyToEdit == null) {
          _clearForm();
        }

        // Use GoRouter for navigation to avoid Navigator conflicts
        // Safe navigation that works with both GoRouter and Navigator scenarios
        if (widget.showNavBar) {
          // If shown with navbar, go back to home
          if (mounted) {
            GoRouter.of(context).go('/home');
          }
        } else {
          // If shown without navbar (e.g. in a sub-route), just pop back
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(context, 'Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _priceController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _bedroomsController.clear();
    _bathroomsController.clear();
    _areaController.clear();
    setState(() {
      _imageFiles = [];
      _existingImages = [];
      _latitude = null;
      _longitude = null;
    });
    // Clear agent contact fields
    _agentNameController.clear();
    _agentPhoneController.clear();
    _agentEmailController.clear();
    _agentAgencyController.clear();
  }

  // Handle the back button press with confirmation dialog
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges()) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard changes?'),
              content: const Text(
                  'You have unsaved changes. Are you sure you want to leave without saving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('DISCARD'),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  // Check if the form has unsaved changes
  bool _hasUnsavedChanges() {
    if (widget.propertyToEdit == null) {
      // For new property, check if any fields are filled
      return _titleController.text.isNotEmpty ||
          _priceController.text.isNotEmpty ||
          _addressController.text.isNotEmpty ||
          _descriptionController.text.isNotEmpty ||
          _bedroomsController.text.isNotEmpty ||
          _bathroomsController.text.isNotEmpty ||
          _areaController.text.isNotEmpty ||
          _imageFiles.isNotEmpty ||
          _agentNameController.text.isNotEmpty ||
          _agentPhoneController.text.isNotEmpty;
    } else {
      // For editing, check if any fields are different from original
      final property = widget.propertyToEdit!;
      return _titleController.text != property.title ||
          _priceController.text != property.price.toString() ||
          _addressController.text != (property.location ?? '') ||
          _descriptionController.text != property.description ||
          _bedroomsController.text != property.bedrooms.toString() ||
          _bathroomsController.text != property.bathrooms.toString() ||
          _areaController.text != property.area.toString() ||
          _propertyType != property.propertyType ||
          _listingType != property.listingType ||
          _imageFiles.isNotEmpty ||
          _existingImages.length != (property.images?.length ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Replace WillPopScope with PopScope
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppScaffold(
        currentIndex: 2,
        title: widget.propertyToEdit != null ? 'Edit Property' : 'Add Property',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _onWillPop()) {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          },
        ),
        body: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicDetailsSection(),
                        const SizedBox(height: 16),
                        _buildPropertyDetailsSection(),
                        const SizedBox(height: 16),
                        _buildLocationSection(),
                        const SizedBox(height: 16),
                        _buildAgentContactSection(), // Add agent contact section
                        const SizedBox(height: 16),
                        _buildImagesSection(),
                        const SizedBox(height: 16),
                        _buildDescriptionSection(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // Animated wrapper for section containers
  Widget _animatedSectionContainer(Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(
                  (0.05 * 255).round()), // Replace withOpacity with withAlpha
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _buildBasicDetailsSection() {
    return _animatedSectionContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_outlined),
              const SizedBox(width: 8),
              Text(
                'Basic Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rest of section remains the same
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                ValidationUtils.validateNotEmpty(value, 'Title'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) =>
                ValidationUtils.validateNumber(value, 'Price'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _listingType,
            decoration: const InputDecoration(
              labelText: 'Listing Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Sale', child: Text('For Sale')),
              DropdownMenuItem(value: 'Rent', child: Text('For Rent')),
            ],
            onChanged: (value) {
              setState(() {
                _listingType = value ?? 'Sale';
              });
            },
          ),
        ],
      ),
    );
  }

  // Update the _buildPropertyDetailsSection using the same animated container pattern
  Widget _buildPropertyDetailsSection() {
    return _animatedSectionContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment),
              const SizedBox(width: 8),
              Text(
                'Property Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rest of section remains the same
          // ... existing code ...
          DropdownButtonFormField<String>(
            value: _propertyType,
            decoration: const InputDecoration(
              labelText: 'Property Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'House', child: Text('House')),
              DropdownMenuItem(value: 'Apartment', child: Text('Apartment')),
              DropdownMenuItem(value: 'Condo', child: Text('Condo')),
              DropdownMenuItem(value: 'Townhouse', child: Text('Townhouse')),
              DropdownMenuItem(value: 'Land', child: Text('Land')),
              DropdownMenuItem(value: 'Commercial', child: Text('Commercial')),
            ],
            onChanged: (value) {
              setState(() {
                _propertyType = value ?? 'House';
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _bedroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bedrooms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      ValidationUtils.validateInteger(value, 'Bedrooms'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _bathroomsController,
                  decoration: const InputDecoration(
                    labelText: 'Bathrooms',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      ValidationUtils.validateInteger(value, 'Bathrooms'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _areaController,
            decoration: const InputDecoration(
              labelText: 'Area (sq ft)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => ValidationUtils.validateNumber(value, 'Area'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _animatedSectionContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      ValidationUtils.validateNotEmpty(value, 'Address'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          MapSectionForm(
            initialLatitude: _latitude,
            initialLongitude: _longitude,
            onLocationChanged: _updateLocationFromMap,
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return _animatedSectionContainer(
      Column(
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
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
            const SizedBox(height: 16),
          ],

          // New images
          if (_imageFiles.isNotEmpty) ...[
            const Text(
              'New Images:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageFiles.length,
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
                              File(_imageFiles[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
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
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return _animatedSectionContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Using TextFormField instead of QuillEditor
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Property Description',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 10,
            validator: (value) =>
                ValidationUtils.validateNotEmpty(value, 'Description'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.propertyToEdit != null ? Icons.update : Icons.add),
            const SizedBox(width: 8),
            Text(
              widget.propertyToEdit != null
                  ? 'Update Property'
                  : 'Add Property',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgentContactSection() {
    return _animatedSectionContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agent Contact Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agentNameController,
            decoration: const InputDecoration(
              labelText: 'Agent Name*',
              border: OutlineInputBorder(),
              hintText: 'Full name of the agent',
            ),
            validator: (value) =>
                ValidationUtils.validateNotEmpty(value, 'Agent Name'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agentPhoneController,
            decoration: const InputDecoration(
              labelText: 'Agent Phone*',
              border: OutlineInputBorder(),
              hintText: 'Contact number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) =>
                ValidationUtils.validateNotEmpty(value, 'Agent Phone'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agentEmailController,
            decoration: const InputDecoration(
              labelText: 'Agent Email',
              border: OutlineInputBorder(),
              hintText: 'Email address (optional)',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) =>
                value!.isNotEmpty ? ValidationUtils.validateEmail(value) : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _agentAgencyController,
            decoration: const InputDecoration(
              labelText: 'Agency Name',
              border: OutlineInputBorder(),
              hintText: 'Real estate agency (optional)',
              prefixIcon: Icon(Icons.business),
            ),
          ),
        ],
      ),
    );
  }
}

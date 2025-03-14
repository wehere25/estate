import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';
import '../../domain/models/property_model.dart';
import '../../domain/services/property_service.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = true;
  String? _error;
  final PropertyService _propertyService = PropertyService();
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProperty();
  }

  Future<void> _addToRecentlyViewed(String propertyId) async {
    final recentlyViewed =
        _prefs.getStringList('recently_viewed_properties') ?? [];

    // Remove if already exists to avoid duplicates
    recentlyViewed.remove(propertyId);

    // Add to the beginning of the list
    recentlyViewed.insert(0, propertyId);

    // Keep only the last 10 items
    if (recentlyViewed.length > 10) {
      recentlyViewed.removeLast();
    }

    await _prefs.setStringList('recently_viewed_properties', recentlyViewed);
  }

  Future<void> _loadProperty() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to load the property
      final property =
          await _propertyService.getPropertyById(widget.propertyId);

      if (mounted) {
        setState(() {
          _property = property;
          _isLoading = false;
        });

        // Add to recently viewed after successful load
        await _addToRecentlyViewed(widget.propertyId);
      }
    } catch (e) {
      DevUtils.log('Error loading property: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load property details';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _property != null
            ? Text(_property!.title,
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : Text('Property #${widget.propertyId}'),
        backgroundColor: AppColors.lightColorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading property details...'),
          ],
        ),
      );
    }
    if (_error != null) {
      // Remove development mode mock property creation
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading property: $_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProperty,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_property == null) {
      return const Center(
        child: Text('Property not found'),
      );
    }
    return _buildPropertyDetails();
  }

  Widget _buildPropertyDetails() {
    final property = _property!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property images
          _buildImageGallery(property),

          // Property information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price
                Text(
                  property.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${property.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.lightColorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // Location
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        property.location ?? 'Location not specified',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                // Property features
                const SizedBox(height: 24),
                _buildFeatureRow(property),

                // Status badges
                const SizedBox(height: 16),
                _buildStatusBadges(property),

                // Description
                const SizedBox(height: 24),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property.description,
                  style: const TextStyle(height: 1.5),
                ),

                // Amenities
                if (property.amenities != null &&
                    property.amenities!.isNotEmpty)
                  _buildAmenities(property),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(PropertyModel property) {
    final List<String> images = property.images ?? [];
    if (images.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported, size: 64)),
      );
    }
    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          // Don't process URL through getMockImageUrl to ensure actual uploaded images are shown
          final imageUrl = images[index];
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              DebugLogger.error('Failed to load image: $imageUrl', error);
              return Container(
                color: Colors.grey.shade300,
                child: const Center(child: Icon(Icons.broken_image, size: 64)),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(PropertyModel property) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildFeatureItem(Icons.king_bed, '${property.bedrooms} Beds'),
        _buildFeatureItem(Icons.bathroom, '${property.bathrooms} Baths'),
        _buildFeatureItem(Icons.square_foot, '${property.area} sq ft'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.lightColorScheme.primary),
        const SizedBox(height: 8),
        Text(text),
      ],
    );
  }

  Widget _buildStatusBadges(PropertyModel property) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadge(
          property.listingType == 'sale' ? 'For Sale' : 'For Rent',
          property.listingType == 'sale' ? Colors.blue : Colors.green,
        ),
        if (property.featured) _buildBadge('Featured', Colors.orange),
        if (!property.isApproved) _buildBadge('Pending Approval', Colors.red),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color),
      ),
    );
  }

  Widget _buildAmenities(PropertyModel property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: property.amenities!.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(amenity),
            );
          }).toList(),
        ),
      ],
    );
  }
}

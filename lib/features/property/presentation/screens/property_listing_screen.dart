import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/property/domain/models/property_model.dart';
import '../providers/property_provider.dart';
import '../widgets/property_filter.dart';
import '/features/property/presentation/screens/property_detail_screen.dart';

class PropertyListingScreen extends StatefulWidget {
  final String categoryId;
  const PropertyListingScreen({Key? key, required this.categoryId}) : super(key: key);

  @override
  State<PropertyListingScreen> createState() => _PropertyListingScreenState();
}

class _PropertyListingScreenState extends State<PropertyListingScreen> {
  Map<String, dynamic> _filters = {};
  bool _isLoading = false;
  bool _isMounted = true;
  final List<PropertyModel> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<void> _loadProperties() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      await provider.fetchProperties(filters: _filters);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties - ${widget.categoryId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_properties.isEmpty) {
            return const Center(child: Text('No properties found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _properties.length,
            itemBuilder: (context, index) {
              final property = _properties[index];
              return _buildPropertyCard(property);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildPropertyCard(PropertyModel property) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () => _navigateToPropertyDetail(property.id ?? ''),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16/9,
              child: property.images?.isNotEmpty == true
                ? Image.network(
                    property.images!.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${property.price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.location ?? 'No location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFeatureInfo(Icons.king_bed, '${property.bedrooms} Beds'),
                      _buildFeatureInfo(Icons.bathtub, '${property.bathrooms} Baths'),
                      _buildFeatureInfo(Icons.square_foot, '${property.area.toStringAsFixed(0)} sq ft'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context, 
                        '/property/${property.id}',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  void _showFilterDialog() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PropertyFilter(
        initialFilters: _filters,
        onFilterChanged: (filters) {
          // Handle filter changes if needed
        },
      ),
    );
    
    if (result != null && _isMounted) {
      setState(() {
        _filters = result;
      });
      _loadProperties();
    }
  }
  
  void _navigateToPropertyDetail(String propertyId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailScreen(propertyId: propertyId),
      ),
    );
  }
}

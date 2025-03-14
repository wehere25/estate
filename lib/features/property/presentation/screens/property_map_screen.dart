
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../services/map_service.dart';
import '../../domain/models/property_model.dart';
import '../../presentation/providers/property_provider.dart';
import '../../presentation/widgets/property_card.dart';
import '../../../../core/constants/app_colors.dart';

class PropertyMapScreen extends StatefulWidget {
  final List<PropertyModel>? initialProperties;
  
  const PropertyMapScreen({
    Key? key,
    this.initialProperties,
  }) : super(key: key);

  @override
  State<PropertyMapScreen> createState() => _PropertyMapScreenState();
}

class _PropertyMapScreenState extends State<PropertyMapScreen> {
  late MapController _mapController;
  LatLng? _currentLocation;
  PropertyModel? _selectedProperty;
  bool _isLoading = false;
  bool _showPropertyInfo = false;
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    
    // Load current location and properties
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current location
      _currentLocation = await MapService.getCurrentLocation();
      
      // Load properties if not provided
      if (widget.initialProperties == null) {
        await Provider.of<PropertyProvider>(context, listen: false).fetchProperties();
      }
      
      // Center map on first property or current location
      final properties = widget.initialProperties ?? 
        Provider.of<PropertyProvider>(context, listen: false).properties;
      
      if (properties.isNotEmpty && properties.first.latitude != null && properties.first.longitude != null) {
        _mapController.move(
          LatLng(properties.first.latitude!, properties.first.longitude!), 
          12.0
        );
      } else if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 12.0);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showPropertyDetails(PropertyModel property) {
    setState(() {
      _selectedProperty = property;
      _showPropertyInfo = true;
      
      // Center map on selected property
      if (property.latitude != null && property.longitude != null) {
        _mapController.move(LatLng(property.latitude!, property.longitude!), 15.0);
      }
    });
  }
  
  void _hidePropertyDetails() {
    setState(() {
      _showPropertyInfo = false;
    });
  }
  
  List<Marker> _buildMarkers(List<PropertyModel> properties) {
    return properties
        .where((p) => p.latitude != null && p.longitude != null)
        .map((property) {
          final position = LatLng(property.latitude!, property.longitude!);
          
          // Check if this is the selected property
          final isSelected = _selectedProperty?.id == property.id;
          
          return MapService.createPropertyMarker(
            id: property.id ?? '',
            position: position,
            title: property.title,
            price: property.price,
            onTap: () => _showPropertyDetails(property),
          );
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final location = await MapService.getCurrentLocation();
              if (location != null) {
                _mapController.move(location, 15.0);
              }
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, propertyProvider, child) {
          final properties = widget.initialProperties ?? propertyProvider.properties;
          
          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(34.0837, 74.7973),
                  initialZoom: 12.0,
                  onTap: (_, __) => _hidePropertyDetails(),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  // Property markers
                  MarkerLayer(
                    markers: _buildMarkers(properties),
                  ),
                  // Current location marker
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 20.0,
                          height: 20.0,
                          point: _currentLocation!,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.lightColorScheme.primary.withOpacity(0.8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Loading indicator
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              
              // Property info bottom sheet
              if (_showPropertyInfo && _selectedProperty != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle indicator
                        Center(
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        PropertyCard(
                          property: _selectedProperty!,
                          onTap: () {
                            // Navigate to property detail
                            Navigator.pushNamed(
                              context, 
                              '/property/${_selectedProperty!.id}'
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

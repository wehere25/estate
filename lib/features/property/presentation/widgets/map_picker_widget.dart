
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../services/map_service.dart';

class MapPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  
  const MapPickerWidget({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    
    if (_selectedLocation == null) {
      _getCurrentLocation();
    } else {
      _getAddressForSelectedLocation();
    }
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final currentLocation = await MapService.getCurrentLocation();
      
      if (currentLocation != null) {
        setState(() {
          _selectedLocation = currentLocation;
          _mapController.move(currentLocation, 15);
        });
        
        _getAddressForSelectedLocation();
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _getAddressForSelectedLocation() async {
    if (_selectedLocation == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final address = await MapService.getAddressFromCoordinates(_selectedLocation!);
      
      setState(() {
        _selectedAddress = address;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = null; // Reset address when location changes
    });
    
    // Notify parent
    widget.onLocationSelected(point);
    
    // Get address for new location
    _getAddressForSelectedLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map container
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? const LatLng(34.0837, 74.7973), // Kashmir coordinates as default
                  initialZoom: 15.0,
                  onTap: _handleTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  // Selected location marker
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _selectedLocation!,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              // Current location button
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'getCurrentLocationBtn',
                  mini: true,
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ),
              
              // Loading indicator
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Selected location info
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected Location:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_selectedLocation != null)
                Text(
                  'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                  'Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (_selectedAddress != null) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedAddress!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (_isLoading && _selectedAddress == null)
                const Text('Loading address...'),
            ],
          ),
        ),
      ],
    );
  }
}

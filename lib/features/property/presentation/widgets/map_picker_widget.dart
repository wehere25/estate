import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../services/map_service.dart';

class MapPickerWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng) onLocationSelected;
  final Widget Function(BuildContext)? markerBuilder;

  const MapPickerWidget({
    Key? key,
    this.initialLocation,
    required this.onLocationSelected,
    this.markerBuilder,
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

      if (currentLocation != null && mounted) {
        setState(() {
          _selectedLocation = currentLocation;
          _mapController.move(currentLocation, 15);
        });

        _getAddressForSelectedLocation();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getAddressForSelectedLocation() async {
    if (_selectedLocation == null) return;

    setState(() => _isLoading = true);

    try {
      final address =
          await MapService.getAddressFromCoordinates(_selectedLocation!);
      if (mounted) {
        setState(() => _selectedAddress = address);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
      _selectedAddress = null;
    });

    widget.onLocationSelected(point);
    _getAddressForSelectedLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter:
                      _selectedLocation ?? const LatLng(34.0837, 74.7973),
                  initialZoom: 15.0,
                  onTap: _handleTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _selectedLocation!,
                          child: widget.markerBuilder?.call(context) ??
                              const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app,
                            color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tap anywhere on map to pin a location',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'getCurrentLocationBtn',
                      mini: true,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_selectedAddress != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _selectedAddress!,
              style: const TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

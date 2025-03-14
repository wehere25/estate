
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../property/presentation/widgets/map_picker_widget.dart';

class MapSectionForm extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double, double) onLocationChanged;
  
  const MapSectionForm({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create initial location if both coordinates are provided
    LatLng? initialLocation;
    if (initialLatitude != null && initialLongitude != null) {
      initialLocation = LatLng(initialLatitude!, initialLongitude!);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Property Location',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Map picker
        MapPickerWidget(
          initialLocation: initialLocation,
          onLocationSelected: (location) {
            onLocationChanged(location.latitude, location.longitude);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Instructions text
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Tap on the map to select the exact property location. This helps buyers find your property easily.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

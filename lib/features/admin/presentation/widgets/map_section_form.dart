import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../property/presentation/widgets/map_picker_widget.dart';

class MapSectionForm extends StatefulWidget {
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
  State<MapSectionForm> createState() => _MapSectionFormState();
}

class _MapSectionFormState extends State<MapSectionForm>
    with SingleTickerProviderStateMixin {
  late AnimationController _markerAnimationController;
  late Animation<double> _markerScaleAnimation;
  late Animation<double> _markerOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _markerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _markerScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _markerAnimationController, curve: Curves.elasticOut),
    );

    _markerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerAnimationController, curve: Curves.easeIn),
    );

    _markerAnimationController.forward();
  }

  @override
  void dispose() {
    _markerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create initial location if both coordinates are provided
    LatLng? initialLocation;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      initialLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title with fade animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Property Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),

          // Map picker with animated marker
          MapPickerWidget(
            initialLocation: initialLocation,
            onLocationSelected: (location) {
              _markerAnimationController.reset();
              _markerAnimationController.forward();
              widget.onLocationChanged(location.latitude, location.longitude);
            },
            markerBuilder: (context) {
              return ScaleTransition(
                scale: _markerScaleAnimation,
                child: FadeTransition(
                  opacity: _markerOpacityAnimation,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Instructions text with slide animation
          TweenAnimationBuilder<Offset>(
            duration: const Duration(milliseconds: 500),
            tween: Tween<Offset>(
              begin: const Offset(0.0, 0.5),
              end: Offset.zero,
            ),
            curve: Curves.easeOut,
            builder: (context, offset, child) {
              return FractionalTranslation(
                translation: offset,
                child: child,
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tap on the map to select the exact property location. This helps buyers find your property easily.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

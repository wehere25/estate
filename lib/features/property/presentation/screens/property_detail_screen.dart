import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/dev_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/navigation/back_button_handler.dart';
import '../../domain/models/property_model.dart';
import '../../domain/services/property_service.dart';
import '../providers/property_provider.dart';
import '../../../../core/utils/formatting_utils.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../widgets/shared_property_detail_view.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({
    Key? key,
    required this.propertyId,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  PropertyModel? _property;
  String? _error;
  final PropertyService _propertyService = PropertyService();
  late SharedPreferences _prefs;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _showFullScreenGallery = false;
  bool _isFavorite = false;
  late AnimationController _pageIndicatorController;
  late AnimationController _galleryTransitionController;
  late AnimationController _fadeInController;

  @override
  void initState() {
    super.initState();
    _pageIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _galleryTransitionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Set status bar to transparent on screen load
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _initializePrefs();
    DebugLogger.info(
        'PropertyDetailScreen: initialized for ${widget.propertyId}');

    // Start fade-in animation
    _fadeInController.forward();
  }

  @override
  void dispose() {
    _pageIndicatorController.dispose();
    _galleryTransitionController.dispose();
    _fadeInController.dispose();
    _pageController.dispose();

    // Restore default status bar on screen dispose
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.black.withOpacity(0.2),
    ));

    super.dispose();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadProperty();
    _checkIfFavorite();

    // Add to recently viewed properties
    _addToRecentlyViewed();
  }

  // Add this property to recently viewed list
  Future<void> _addToRecentlyViewed() async {
    try {
      final recentlyViewed =
          _prefs.getStringList('recently_viewed_properties') ?? [];

      // Remove this property ID if it exists (to avoid duplicates)
      recentlyViewed.remove(widget.propertyId);

      // Add to the beginning of the list
      recentlyViewed.insert(0, widget.propertyId);

      // Keep only the most recent 20 properties
      final updatedList = recentlyViewed.take(20).toList();

      await _prefs.setStringList('recently_viewed_properties', updatedList);
      DebugLogger.info(
          'Added property ${widget.propertyId} to recently viewed');
    } catch (e) {
      DebugLogger.error('Error adding to recently viewed', e);
    }
  }

  // Check if this property is in favorites
  Future<void> _checkIfFavorite() async {
    try {
      final favoritesProvider =
          Provider.of<FavoritesProvider>(context, listen: false);
      if (mounted) {
        setState(() {
          _isFavorite = favoritesProvider.isFavorite(widget.propertyId);
        });
      }
    } catch (e) {
      // If provider is not available, default to false
      if (mounted) {
        setState(() {
          _isFavorite = false;
        });
      }
      DebugLogger.error('FavoritesProvider not available', e);
    }
  }

  // Load property with priority to provider cache
  Future<void> _loadProperty() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get property from provider first (faster)
      PropertyModel? property;

      try {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        property = propertyProvider.getPropertyById(widget.propertyId);
      } catch (e) {
        DebugLogger.error('PropertyProvider not available', e);
      }

      // If not found in provider, fetch directly
      if (property == null) {
        property = await _propertyService.getPropertyById(widget.propertyId);
      }

      if (!mounted) return;

      setState(() {
        _property = property;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load property details: ${e.toString()}';
        _isLoading = false;
      });

      DebugLogger.error('Error loading property', e);
    }
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_property == null) return;

    final favoritesProvider =
        Provider.of<FavoritesProvider>(context, listen: false);

    // Use the correct method from FavoritesProvider
    try {
      await favoritesProvider.toggleFavorite(_property!);

      if (mounted) {
        setState(() {
          _isFavorite = favoritesProvider.isFavorite(widget.propertyId);
        });

        if (_isFavorite) {
          SnackBarUtils.showSuccessSnackBar(context, 'Added to favorites');
        } else {
          SnackBarUtils.showInfoSnackBar(context, 'Removed from favorites');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showErrorSnackBar(context, 'Failed to update favorites');
      }
      DebugLogger.error('Error toggling favorite status', e);
    }
  }

  // Share property
  void _shareProperty() {
    if (_property == null) return;

    final String shareText = 'Check out this property: ${_property!.title}\n'
        'Price: \$${_property!.price}\n'
        'Location: ${_property!.location ?? 'Not specified'}\n'
        'Details: ${_property!.bedrooms} bed, ${_property!.bathrooms} bath, ${_property!.area} sqft\n'
        'View it in our app!';

    Share.share(shareText);
  }

  // Contact agent
  Future<void> _contactAgent() async {
    if (_property == null || _property!.agentContact == null) {
      if (mounted) {
        SnackBarUtils.showInfoSnackBar(
            context, 'No agent contact information available');
      }
      return;
    }

    _showAgentContactDialog();
  }

  // Show agent contact dialog
  void _showAgentContactDialog() {
    if (_property?.agentContact == null) return;

    final agent = _property!.agentContact!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (agent.agency != null && agent.agency!.isNotEmpty)
                          Text(
                            agent.agency!,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildContactOption(
                icon: Icons.phone,
                title: 'Call Agent',
                subtitle: agent.phone,
                onTap: () => _launchPhoneCall(agent.phone),
                color: Colors.green,
              ),
              if (agent.email != null && agent.email!.isNotEmpty)
                _buildContactOption(
                  icon: Icons.email,
                  title: 'Email Agent',
                  subtitle: agent.email!,
                  onTap: () => _launchEmail(agent.email!),
                  color: Colors.blue,
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Contact option widget
  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  // Launch phone call
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        SnackBarUtils.showErrorSnackBar(context, 'Could not launch phone app');
      }
    }
  }

  // Launch email
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email, queryParameters: {
      'subject': 'Inquiry about ${_property!.title}',
      'body':
          'Hello, I am interested in the property at ${_property!.location}.'
    });

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        SnackBarUtils.showErrorSnackBar(context, 'Could not launch email app');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire screen with BackButtonHandler for consistent back handling
    return BackButtonHandler(
      screenName: 'PropertyDetailScreen-${widget.propertyId}',
      onWillPop: () async {
        // Hide gallery if showing before popping the screen
        if (_showFullScreenGallery) {
          setState(() {
            _showFullScreenGallery = false;
          });
          return false; // Don't pop yet, just close gallery
        }
        DebugLogger.info('PropertyDetailScreen: Back button pressed, will pop');
        return true; // Allow regular pop
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          automaticallyImplyLeading: false, // Remove default back button
          leading: Container(
            margin: const EdgeInsets.only(left: 8, top: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [], // Remove spacer and action buttons as they are now in the shared view
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : AnimatedBuilder(
                    animation: _fadeInController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeInController.value,
                        child: SharedPropertyDetailView(
                          property: _property!,
                          isAdmin: false,
                          isFavorite: _isFavorite,
                          onToggleFavorite: _toggleFavorite,
                        ),
                      );
                    },
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
}

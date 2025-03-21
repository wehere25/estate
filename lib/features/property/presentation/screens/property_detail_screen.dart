import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
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
    _initializePrefs();
    DebugLogger.info(
        'PropertyDetailScreen: initialized for ${widget.propertyId}');
  }

  @override
  void dispose() {
    _pageIndicatorController.dispose();
    _galleryTransitionController.dispose();
    _pageController.dispose();
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
          leading: BackButton(
            onPressed: () {
              DebugLogger.info('PropertyDetailScreen: Back button tapped');
              if (_showFullScreenGallery) {
                setState(() {
                  _showFullScreenGallery = false;
                });
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            // Favorite button
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
              onPressed: () => _toggleFavorite(),
            ),
            // Share button
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareProperty(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _buildPropertyDetail(),
      ),
    );
  }

  Widget _buildPropertyDetail() {
    final property = _property!;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property images with indicators
          Stack(
            children: [
              // Image gallery
              _buildImageGallery(property),

              // Image counter indicator
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${property.images?.length ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Fullscreen button
              Positioned(
                bottom: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullScreenGallery = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Property information with card design
          Container(
            width: double.infinity,
            transform: Matrix4.translationValues(0, -20, 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and property type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      _buildBadge(
                        property.listingType == 'Sale'
                            ? 'For Sale'
                            : 'For Rent',
                        property.listingType == 'Sale'
                            ? Colors.blue
                            : Colors.green,
                      ),
                    ],
                  ),

                  // Location with icon
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          property.location ?? 'Location not specified',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Price
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.currency_rupee,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FormattingUtils.formatIndianRupees(property.price),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  const SizedBox(height: 20),
                  Divider(color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  const SizedBox(height: 20),

                  // Key features in a stylish row
                  _buildFeatureRow(property),

                  // Status badges
                  const SizedBox(height: 24),
                  _buildStatusBadges(property),

                  // Description section
                  const SizedBox(height: 24),
                  _buildSectionHeader('Description'),
                  const SizedBox(height: 12),
                  Text(
                    property.description,
                    style: TextStyle(
                      height: 1.6,
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),

                  // Agent Information Section
                  if (property.agentContact != null)
                    _buildAgentSection(property.agentContact!),

                  // Amenities section with icons
                  if (property.amenities != null &&
                      property.amenities!.isNotEmpty)
                    _buildAmenities(property),

                  // Additional space at bottom
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentSection(AgentContact agent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader('Contact Agent'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    radius: 24,
                    child: Icon(
                      Icons.person,
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (agent.agency != null && agent.agency!.isNotEmpty)
                          Text(
                            agent.agency!,
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _launchPhoneCall(agent.phone),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.phone,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        agent.phone,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (agent.email != null && agent.email!.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _launchEmail(agent.email!),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          agent.email!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildImageGallery(PropertyModel property) {
    final List<String> images = property.images ?? [];
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.image_not_supported, size: 64)),
      );
    }

    // Remove the outer Hero widget to avoid nested Hero widgets
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
          _pageIndicatorController.forward(from: 0.0);
        },
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          return GestureDetector(
            onTap: () {
              _galleryTransitionController.forward();
              setState(() {
                _showFullScreenGallery = true;
                _currentImageIndex = index;
              });
            },
            // Use a unique tag for each image to avoid conflicts
            child: Hero(
              tag: 'detail_property_image_${property.id}_$index',
              child: AnimatedBuilder(
                animation: _pageIndicatorController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: Tween<double>(
                      begin: 1.0,
                      end: _currentImageIndex == index ? 1.0 : 0.9,
                    )
                        .animate(CurvedAnimation(
                          parent: _pageIndicatorController,
                          curve: Curves.easeOut,
                        ))
                        .value,
                    child: child,
                  );
                },
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    DebugLogger.error('Failed to load image: $imageUrl', error);
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 64)),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullscreenGallery() {
    final List<String> images = _property?.images ?? [];

    return AnimatedBuilder(
      animation: _galleryTransitionController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(
            _galleryTransitionController.value,
          ),
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              '${_currentImageIndex + 1} / ${images.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained * 0.8,
                maxScale: PhotoViewComputedScale.covered * 2,
                // Update heroTag to match the detail screen
                heroAttributes: PhotoViewHeroAttributes(
                    tag: 'detail_property_image_${_property!.id}_$index'),
              );
            },
            itemCount: images.length,
            loadingBuilder: (context, event) => Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
            ),
            pageController: PageController(initialPage: _currentImageIndex),
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white.withOpacity(0.7),
            mini: true,
            child: const Icon(Icons.close, color: Colors.black),
            onPressed: () {
              setState(() {
                _showFullScreenGallery = false;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(PropertyModel property) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFeatureItem(Icons.king_bed, '${property.bedrooms}', 'Bedrooms'),
          _buildDivider(),
          _buildFeatureItem(
              Icons.bathroom, '${property.bathrooms}', 'Bathrooms'),
          _buildDivider(),
          _buildFeatureItem(Icons.square_foot, '${property.area}', 'Sq. Ft.'),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  Widget _buildFeatureItem(IconData icon, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadges(PropertyModel property) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (property.featured) _buildBadge('Featured', Colors.orange),
        if (!property.isApproved) _buildBadge('Pending Approval', Colors.red),
        _buildBadge(property.propertyType ?? 'Residential', Colors.purple),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? color.withOpacity(0.2) : color.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.withOpacity(0.9) : color.withOpacity(0.8),
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildAmenities(PropertyModel property) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader('Amenities'),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
          ),
          itemCount: property.amenities!.length,
          itemBuilder: (context, index) {
            final amenity = property.amenities![index];
            IconData iconData = _getAmenityIcon(amenity);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    iconData,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      amenity,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final String lowercaseAmenity = amenity.toLowerCase();

    if (lowercaseAmenity.contains('wifi') ||
        lowercaseAmenity.contains('internet')) {
      return Icons.wifi;
    } else if (lowercaseAmenity.contains('pool')) {
      return Icons.pool;
    } else if (lowercaseAmenity.contains('gym')) {
      return Icons.fitness_center;
    } else if (lowercaseAmenity.contains('parking')) {
      return Icons.local_parking;
    } else if (lowercaseAmenity.contains('ac') ||
        lowercaseAmenity.contains('air')) {
      return Icons.air;
    } else if (lowercaseAmenity.contains('washer') ||
        lowercaseAmenity.contains('laundry')) {
      return Icons.local_laundry_service;
    } else if (lowercaseAmenity.contains('security')) {
      return Icons.security;
    } else if (lowercaseAmenity.contains('tv')) {
      return Icons.tv;
    } else if (lowercaseAmenity.contains('kitchen')) {
      return Icons.kitchen;
    } else if (lowercaseAmenity.contains('balcony')) {
      return Icons.balcony;
    } else if (lowercaseAmenity.contains('garden')) {
      return Icons.yard;
    } else {
      return Icons.check_circle_outline;
    }
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

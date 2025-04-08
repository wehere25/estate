import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/formatting_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../domain/models/property_model.dart';

/// A shared property detail view that can be used by both admin and user interfaces
class SharedPropertyDetailView extends StatefulWidget {
  final PropertyModel property;
  final bool isAdmin;
  final Function()? onToggleFavorite;
  final bool? isFavorite;

  const SharedPropertyDetailView({
    Key? key,
    required this.property,
    this.isAdmin = false,
    this.onToggleFavorite,
    this.isFavorite,
  }) : super(key: key);

  @override
  State<SharedPropertyDetailView> createState() =>
      _SharedPropertyDetailViewState();
}

class _SharedPropertyDetailViewState extends State<SharedPropertyDetailView>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _showFullScreenGallery = false;
  late AnimationController _pageIndicatorController;
  late AnimationController _galleryTransitionController;
  bool _isFavorite = false;

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
    _isFavorite = widget.isFavorite ?? false;
  }

  @override
  void dispose() {
    _pageIndicatorController.dispose();
    _galleryTransitionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Share property
  void _shareProperty() {
    final String shareText =
        'Check out this property: ${widget.property.title}\n'
        'Price: ${FormattingUtils.formatIndianRupees(widget.property.price)}\n'
        'Location: ${widget.property.location ?? 'Not specified'}\n'
        'Details: ${widget.property.bedrooms} bed, ${widget.property.bathrooms} bath, ${widget.property.area} sqft\n'
        'View it in our app!';

    Share.share(shareText);
  }

  // Contact agent with modern dialog
  void _showAgentContactDialog() {
    if (widget.property.agentContact == null) return;

    final agent = widget.property.agentContact!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: theme.colorScheme.primary,
                      ),
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
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (agent.agency != null && agent.agency!.isNotEmpty)
                          Text(
                            agent.agency!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contact options
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildModernContactOption(
                    icon: Icons.phone,
                    iconColor: Colors.green,
                    title: 'Call Agent',
                    subtitle: agent.phone,
                    onTap: () => _launchPhoneCall(agent.phone),
                  ),
                  const SizedBox(height: 16),
                  if (agent.email != null && agent.email!.isNotEmpty)
                    _buildModernContactOption(
                      icon: Icons.email,
                      iconColor: Colors.blue,
                      title: 'Email Agent',
                      subtitle: agent.email!,
                      onTap: () => _launchEmail(agent.email!),
                    ),
                  const SizedBox(height: 16),
                  // WhatsApp option if phone is available
                  _buildModernContactOption(
                    icon: Icons.messenger_outline,
                    iconColor: Colors.green.shade600,
                    title: 'WhatsApp',
                    subtitle: 'Chat with ${agent.name}',
                    onTap: () => _launchWhatsApp(agent.phone),
                  ),
                ],
              ),
            ),

            // Close button
            Padding(
              padding:
                  const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Contact Option Widget
  Widget _buildModernContactOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Launch WhatsApp
  Future<void> _launchWhatsApp(String phoneNumber) async {
    // Remove non-numeric characters
    String formattedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Add country code if missing
    if (!formattedNumber.startsWith('+')) {
      formattedNumber =
          '+91$formattedNumber'; // Default to India, adjust as needed
    }

    final whatsappUrl = Uri.parse('https://wa.me/$formattedNumber');

    try {
      await launchUrl(whatsappUrl);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        SnackBarUtils.showErrorSnackBar(context, 'Could not launch WhatsApp');
      }
    }
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
      'subject': 'Inquiry about ${widget.property.title}',
      'body':
          'Hello, I am interested in the property at ${widget.property.location}.'
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
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Stack(
      children: [
        _buildPropertyDetail(),
        if (_showFullScreenGallery) _buildFullscreenGallery(),

        // Floating action buttons in top right, aligned with app bar
        if (!widget.isAdmin && !_showFullScreenGallery)
          Positioned(
            top: MediaQuery.of(context).padding.top +
                5, // Adjusted to match smaller header
            right: 16,
            child: Row(
              children: [
                // Share button
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: _shareProperty,
                      child: Icon(
                        Icons.share,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Favorite button
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: InkWell(
                      onTap: () {
                        if (widget.onToggleFavorite != null) {
                          widget.onToggleFavorite!();
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        }
                      },
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : primaryColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Quick Contact Floating Action Button
        if (!widget.isAdmin &&
            widget.property.agentContact != null &&
            !_showFullScreenGallery)
          Positioned(
            bottom: 20,
            right: 20,
            child: _buildQuickContactFAB(),
          ),
      ],
    );
  }

  // Quick Contact Floating Action Button
  Widget _buildQuickContactFAB() {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: () {
        if (widget.property.agentContact != null) {
          _showAgentContactDialog();
        } else {
          SnackBarUtils.showInfoSnackBar(
              context, 'No agent contact information available');
        }
      },
      backgroundColor: theme.colorScheme.primary,
      elevation: 4,
      child: const Icon(
        Icons.phone,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPropertyDetail() {
    final property = widget.property;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    // Custom styles based on the luxury HTML design
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final darkColor = isDark ? Colors.white : Colors.black87;
    final textLightColor = isDark ? Colors.grey[300] : Colors.grey[600];
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderRadius = 16.0;

    final boxShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored header bar
          Container(
            width: double.infinity,
            height: (80 + MediaQuery.of(context).padding.top) *
                0.3, // Reduced by 70%
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          ),

          // Main Content
          Container(
            color: theme.scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Header with BPR title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address moved below the header
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              property.location ?? 'Location not specified',
                              style: TextStyle(
                                color: textLightColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Property title
                      Text(
                        property.title,
                        style: TextStyle(
                          color: darkColor,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Premium tag
                      if (property.featured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                secondaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'PREMIUM LISTING',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Image Gallery
                Container(
                  height: 500,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: boxShadow,
                    color: Colors.grey.shade200,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main gallery image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(borderRadius),
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: property.images?.length ?? 0,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            if (property.images == null ||
                                property.images!.isEmpty) {
                              return const Center(
                                child: Icon(Icons.image_not_supported,
                                    size: 64, color: Colors.grey),
                              );
                            }

                            return GestureDetector(
                              onTap: () {
                                // Notify that fullscreen gallery is being requested
                                FullScreenGalleryNotification(isEntering: true)
                                    .dispatch(context);

                                // Only proceed if we're not in admin mode
                                if (!widget.isAdmin) {
                                  _galleryTransitionController.forward();
                                  setState(() {
                                    _showFullScreenGallery = true;
                                    _currentImageIndex = index;
                                  });
                                }
                              },
                              child: Hero(
                                tag:
                                    'detail_property_image_${property.id}_$index',
                                child: CachedNetworkImage(
                                  imageUrl: property.images![index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 64, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Image dots navigation
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            property.images?.length ?? 0,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentImageIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Fullscreen button
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            if (!widget.isAdmin) {
                              setState(() {
                                _showFullScreenGallery = true;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                ),
                              ],
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
                ),

                const SizedBox(height: 30),

                // Price & Listing Type
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price with currency icon
                      Row(
                        children: [
                          Text(
                            FormattingUtils.formatIndianRupees(property.price),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),

                      // Listing type pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          property.listingType == 'Sale'
                              ? 'FOR SALE'
                              : 'FOR RENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Highlights Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: boxShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitleLuxury('Property Highlights'),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: isTablet ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: isTablet ? 1.0 : 0.85,
                        children: [
                          _buildHighlightCard(
                            Icons.bed,
                            '${property.bedrooms}',
                            'Bedrooms',
                            primaryColor,
                          ),
                          _buildHighlightCard(
                            Icons.bathroom,
                            '${property.bathrooms}',
                            'Bathrooms',
                            primaryColor,
                          ),
                          _buildHighlightCard(
                            Icons.square_foot,
                            '${property.area.toInt()}',
                            'Sq. Ft.',
                            primaryColor,
                          ),
                          _buildHighlightCard(
                            Icons.home,
                            property.propertyType,
                            'Property Type',
                            primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Description Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: boxShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitleLuxury('About This Property'),
                      const SizedBox(height: 20),
                      Text(
                        property.description,
                        style: TextStyle(
                          color: darkColor,
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Amenities & Features
                if (property.amenities != null &&
                    property.amenities!.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: boxShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitleLuxury('Amenities & Features'),
                        const SizedBox(height: 20),
                        GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTablet ? 4 : 2,
                            crossAxisSpacing: 15,
                            mainAxisSpacing: 15,
                            childAspectRatio: 3.0,
                          ),
                          itemCount: property.amenities!.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final amenity = property.amenities![index];
                            final IconData iconData = _getAmenityIcon(amenity);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.05),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    iconData,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      amenity,
                                      style: TextStyle(
                                        color: darkColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Agent Section
                if (property.agentContact != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                      boxShadow: boxShadow,
                    ),
                    child: Stack(
                      children: [
                        // Top gradient line
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  secondaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitleLuxury('Contact Agent'),
                              const SizedBox(height: 20),

                              // Agent profile card
                              Row(
                                children: [
                                  // Agent avatar with border
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor:
                                          primaryColor.withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        color: primaryColor,
                                        size: 40,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 20),

                                  // Agent info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          property.agentContact!.name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: darkColor,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Senior Property Consultant',
                                          style: TextStyle(
                                            color: textLightColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (property.agentContact!.agency !=
                                            null)
                                          Text(
                                            property.agentContact!.agency!,
                                            style: TextStyle(
                                              color: textLightColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 25),

                              // Contact button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _launchPhoneCall(
                                      property.agentContact!.phone),
                                  borderRadius:
                                      BorderRadius.circular(borderRadius),
                                  child: Ink(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          primaryColor,
                                          secondaryColor,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(borderRadius),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryColor.withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.phone,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Schedule a Viewing',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    '© 2025 Heaven Properties. All rights reserved.',
                    style: TextStyle(
                      color: textLightColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New helper methods for the luxury design

  // Luxury section title with gradient bar
  Widget _buildSectionTitleLuxury(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Luxury highlight card
  Widget _buildHighlightCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  theme.colorScheme.secondary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Modern header action button with hover effect
  Widget _buildHeaderActionButton(IconData icon, VoidCallback onPressed,
      {Color? color}) {
    final theme = Theme.of(context);
    final customColor = color ?? theme.colorScheme.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            color: customColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Modern action button with hover effect
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, {
    bool isActive = false,
    Color activeColor = Colors.blue,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : primaryColor,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final String lowercaseAmenity = amenity.toLowerCase();

    if (lowercaseAmenity.contains('wifi') ||
        lowercaseAmenity.contains('internet')) {
      return Icons.wifi;
    } else if (lowercaseAmenity.contains('parking') ||
        lowercaseAmenity.contains('garage')) {
      return Icons.local_parking;
    } else if (lowercaseAmenity.contains('ac') ||
        lowercaseAmenity.contains('air') ||
        lowercaseAmenity.contains('cooling')) {
      return Icons.ac_unit;
    } else if (lowercaseAmenity.contains('pool') ||
        lowercaseAmenity.contains('swimming')) {
      return Icons.pool;
    } else if (lowercaseAmenity.contains('gym') ||
        lowercaseAmenity.contains('fitness')) {
      return Icons.fitness_center;
    } else if (lowercaseAmenity.contains('kitchen') ||
        lowercaseAmenity.contains('cook')) {
      return Icons.kitchen;
    } else if (lowercaseAmenity.contains('tv') ||
        lowercaseAmenity.contains('television') ||
        lowercaseAmenity.contains('entertainment')) {
      return Icons.tv;
    } else if (lowercaseAmenity.contains('washer') ||
        lowercaseAmenity.contains('laundry') ||
        lowercaseAmenity.contains('dryer')) {
      return Icons.local_laundry_service;
    } else if (lowercaseAmenity.contains('security') ||
        lowercaseAmenity.contains('safe')) {
      return Icons.security;
    } else if (lowercaseAmenity.contains('balcony') ||
        lowercaseAmenity.contains('terrace')) {
      return Icons.balcony;
    } else if (lowercaseAmenity.contains('garden') ||
        lowercaseAmenity.contains('yard') ||
        lowercaseAmenity.contains('outdoor')) {
      return Icons.yard;
    } else if (lowercaseAmenity.contains('pet') ||
        lowercaseAmenity.contains('dog')) {
      return Icons.pets;
    } else if (lowercaseAmenity.contains('elevator') ||
        lowercaseAmenity.contains('lift')) {
      return Icons.elevator;
    } else if (lowercaseAmenity.contains('fire') ||
        lowercaseAmenity.contains('place')) {
      return Icons.fireplace;
    } else if (lowercaseAmenity.contains('heat') ||
        lowercaseAmenity.contains('furnace')) {
      return Icons.wb_sunny;
    } else {
      return Icons.star;
    }
  }

  Widget _buildFullscreenGallery() {
    final List<String> images = widget.property.images ?? [];
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _galleryTransitionController,
      builder: (context, child) {
        return Material(
          color: Colors.black.withOpacity(
            0.9 * _galleryTransitionController.value,
          ),
          child: Stack(
            children: [
              // Main gallery with swipe and pinch-to-zoom
              PhotoViewGallery.builder(
                scrollPhysics: const BouncingScrollPhysics(),
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions(
                    imageProvider: CachedNetworkImageProvider(images[index]),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained * 0.8,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    heroAttributes: PhotoViewHeroAttributes(
                        tag:
                            'detail_property_image_${widget.property.id}_$index'),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Colors.white, size: 64),
                        ),
                      );
                    },
                  );
                },
                itemCount: images.length,
                loadingBuilder: (context, event) => Center(
                  child: SizedBox(
                    width: 30.0,
                    height: 30.0,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              (event.expectedTotalBytes ?? 1),
                    ),
                  ),
                ),
                backgroundDecoration:
                    const BoxDecoration(color: Colors.transparent),
                pageController: PageController(initialPage: _currentImageIndex),
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),

              // Custom App Bar with transparent background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 12.0),
                      child: Row(
                        children: [
                          // Back button
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _showFullScreenGallery = false;
                              });
                            },
                          ),
                          const Spacer(),
                          // Image counter
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Image indicator at bottom
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentImageIndex == index ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentImageIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

              // Close button in center bottom
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _showFullScreenGallery = false;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Add notification for fullscreen gallery
class FullScreenGalleryNotification extends Notification {
  final bool isEntering;

  FullScreenGalleryNotification({required this.isEntering});
}

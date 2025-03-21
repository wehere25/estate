import 'package:flutter/material.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/widgets/favorite_button.dart';
import '/core/utils/image_utils.dart';
import '/core/utils/formatting_utils.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool isGridItem;
  final int index; // Add index for staggered animation

  const PropertyCard({
    Key? key,
    required this.property,
    this.onTap,
    this.isGridItem = false,
    this.index = 0, // Make index optional with default value
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: ModalRoute.of(context)?.animation ??
              const AlwaysStoppedAnimation(1),
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index + 1) * 0.1).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      builder: (context, child) => FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: ModalRoute.of(context)?.animation ??
                const AlwaysStoppedAnimation(1),
            curve: Interval(
              (index * 0.1).clamp(0.0, 1.0),
              ((index + 1) * 0.1).clamp(0.0, 1.0),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)?.animation ??
                  const AlwaysStoppedAnimation(1),
              curve: Interval(
                (index * 0.1).clamp(0.0, 1.0),
                ((index + 1) * 0.1).clamp(0.0, 1.0),
                curve: Curves.easeOut,
              ),
            ),
          ),
          child: child!,
        ),
      ),
      child: isGridItem ? _buildGridItem(context) : _buildListItem(context),
    );
  }

  Widget _buildGridItem(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      // Remove the outer Hero to avoid nesting
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image with Hero
                Expanded(
                  child: Hero(
                    // Use consistent tag format that won't conflict with detail screen
                    tag: 'list_property_image_${property.id}_0',
                    child: ImageUtils.loadImage(
                      url: property.images?.isNotEmpty == true
                          ? property.images!.first
                          : 'placeholder',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: isGridItem ? 140 : 180,
                    ),
                  ),
                ),
                // Property Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fix overflow by using FittedBox
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          FormattingUtils.formatIndianRupees(property.price),
                          style: TextStyle(
                            fontSize: isGridItem ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? Colors.white : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location ?? 'No Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFeatureItem(context, Icons.king_bed,
                                '${property.bedrooms}'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFeatureItem(context, Icons.bathtub,
                                '${property.bathrooms}'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFeatureItem(context, Icons.square_foot,
                                '${property.area.toInt()}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Fix FavoriteButton instantiation
            Positioned(
              top: 8,
              right: 8,
              child: FavoriteButton(property: property),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.transparent,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Property Image
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Hero(
                    // Use consistent tag format that won't conflict
                    tag: 'list_property_image_${property.id}_0',
                    child: ImageUtils.loadImage(
                      url: property.images?.isNotEmpty == true
                          ? property.images!.first
                          : 'placeholder',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: isGridItem ? 140 : 180,
                    ),
                  ),
                ),
                // Property Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDarkMode ? Colors.white : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property.location ?? 'No location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Fix price overflow with FittedBox
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            FormattingUtils.formatIndianRupees(property.price),
                            style: TextStyle(
                              fontSize: isGridItem ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // Fix feature item overflow with Expanded
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFeatureItem(context, Icons.king_bed,
                                  '${property.bedrooms}'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFeatureItem(context, Icons.bathtub,
                                  '${property.bathrooms}'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildFeatureItem(
                                  context,
                                  Icons.square_foot,
                                  '${property.area.toInt()}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Fix FavoriteButton instantiation
            Positioned(
              top: 8,
              right: 8,
              child: FavoriteButton(property: property),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min, // Make row take minimum space
      children: [
        Icon(
          icon,
          size: 16,
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
        ),
        const SizedBox(width: 2), // Reduce spacing
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis, // Handle text overflow
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}

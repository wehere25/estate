import 'package:flutter/material.dart';
import '/features/property/domain/models/property_model.dart';
import '/features/property/presentation/widgets/favorite_button.dart';
import '/core/constants/app_colors.dart'; // Fix import path
import '/core/utils/image_utils.dart'; // Fix import path

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool isGridItem;

  const PropertyCard({
    Key? key,
    required this.property,
    this.onTap,
    this.isGridItem = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('PropertyCard: Building card for property ${property.id}');
    
    if (isGridItem) {
      return _buildGridItem(context);
    }
    return _buildListItem(context);
  }

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(2)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(1)} Lac';
    } else if (price >= 1000) {
      return '₹${(price / 1000).round()}k';
    }
    return '₹${price.toInt()}';
  }

  Widget _buildGridItem(BuildContext context) {
    // Remove unused imageUrl variable
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Image
                Expanded(
                  child: ImageUtils.loadImage(
                    url: property.images?.isNotEmpty == true ? property.images!.first : 'placeholder',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: isGridItem ? 140 : 180,
                  ),
                ),
                // Property Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPrice(property.price),
                        style: TextStyle(
                          fontSize: isGridItem ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureItem(Icons.king_bed, '${property.bedrooms}'),
                          _buildFeatureItem(Icons.bathtub, '${property.bathrooms}'),
                          _buildFeatureItem(Icons.square_foot, '${property.area.toInt()}'),
                        ],
                      ),
                    ]
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
    // Remove unused imageUrl variable 
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Property Image
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ImageUtils.loadImage(
                    url: property.images?.isNotEmpty == true ? property.images!.first : 'placeholder',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: isGridItem ? 140 : 180,
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
                          style: Theme.of(context).textTheme.titleMedium,
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
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(property.price),
                          style: TextStyle(
                            fontSize: isGridItem ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightColorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildFeatureItem(Icons.king_bed, '${property.bedrooms}'),
                            const SizedBox(width: 16),
                            _buildFeatureItem(Icons.bathtub, '${property.bathrooms}'),
                            const SizedBox(width: 16),
                            _buildFeatureItem(Icons.square_foot, '${property.area.toInt()}'),
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

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/features/favorites/providers/favorites_provider.dart';
import '../../domain/models/property_model.dart';

class FavoriteButton extends StatelessWidget {
  final PropertyModel property;
  final Color? backgroundColor;
  final double size;

  const FavoriteButton({
    Key? key,
    required this.property,
    this.backgroundColor = Colors.white,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        // Add null check for provider
        final isFavorite = favoritesProvider.isFavorite(property.id);
        
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: backgroundColor,
          child: IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
              size: size * 0.6,
            ),
            onPressed: () {
              favoritesProvider.toggleFavorite(property);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite 
                        ? 'Removed from favorites' 
                        : 'Added to favorites',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

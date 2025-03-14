import 'package:flutter/material.dart';
import 'dev_utils.dart';

class ImageUtils {
  ImageUtils._(); // Private constructor

  /// Safely loads images that could be from network, file, or placeholders
  static Widget loadImage({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? errorWidget,
  }) {
    // Process the URL through DevUtils to handle Firebase Storage URLs in dev mode
    final processedUrl = DevUtils.getMockImageUrl(url);

    Widget errorPlaceholder = errorWidget ??
        Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );

    // Check if the URL starts with 'http' or 'https' for network images
    if (processedUrl.startsWith('http')) {
      return Image.network(
        processedUrl,
        fit: fit,
        width: width,
        height: height,
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
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Error loading image from $processedUrl: $error');
          return errorPlaceholder;
        },
      );
    }

    // Check for file-based URLs (with dev mode placeholders)
    else if (processedUrl.startsWith('file:/') ||
        processedUrl.startsWith('/data/')) {
      try {
        return Image.network(
          'https://via.placeholder.com/800x600?text=Local+File', // Use placeholder for file URLs
          fit: fit,
          width: width,
          height: height,
        );
      } catch (e) {
        debugPrint('Error loading file image: $e');
        return errorPlaceholder;
      }
    }

    // Fallback to a placeholder
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(child: Text('No Image')),
    );
  }

  /// Get a proper placeholder image URL based on a category or room type
  static String getPlaceholderUrl(String category) {
    // Return different placeholder images based on property type/category
    switch (category.toLowerCase()) {
      case 'apartment':
        return 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
      case 'house':
        return 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
      case 'villa':
        return 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
      case 'office':
        return 'https://images.unsplash.com/photo-1497366754035-f200968a6e72?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
      default:
        return 'https://images.unsplash.com/photo-1560184897-ae75f418493e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80';
    }
  }
}

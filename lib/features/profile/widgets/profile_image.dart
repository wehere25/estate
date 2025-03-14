
import 'package:flutter/material.dart';
import 'dart:io';
import '../../../core/utils/debug_logger.dart';

class ProfileImage extends StatelessWidget {
  final String? imagePath;
  final double radius;
  final VoidCallback? onTap;
  final Widget? badge;
  
  const ProfileImage({
    Key? key,
    this.imagePath,
    this.radius = 60,
    this.onTap,
    this.badge,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildImage(),
          if (badge != null) 
            Positioned(
              bottom: 0,
              right: 0,
              child: badge!,
            ),
        ],
      ),
    );
  }
  
  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }
    
    // Handle network image
    if (imagePath!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imagePath!),
        onBackgroundImageError: (exception, stackTrace) {
          DebugLogger.error('Failed to load network profile image', exception);
          // Error is handled automatically with CircleAvatar
        },
      );
    }
    
    // Handle file image with proper error checking
    try {
      String path = imagePath!;
      // Fix the file:// prefix issue
      if (path.startsWith('file://')) {
        path = path.replaceFirst('file://', '');
      }
      
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
          onBackgroundImageError: (exception, stackTrace) {
            DebugLogger.error('Failed to load file profile image', exception);
            // Error is handled automatically with CircleAvatar
          },
        );
      } else {
        DebugLogger.error('Profile image file does not exist: $path');
        return _buildPlaceholder();
      }
    } catch (e) {
      DebugLogger.error('Error loading profile image file', e);
      return _buildPlaceholder();
    }
  }
  
  Widget _buildPlaceholder() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: radius * 1.2,
        color: Colors.grey[600],
      ),
    );
  }
}

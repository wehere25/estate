import 'dart:io';
import '../services/storage_service.dart';
import '../utils/debug_logger.dart';

/// Service for handling image operations
/// 
/// This is a wrapper around StorageService to maintain backward compatibility
/// with existing code that uses ImageService.
/// 
/// @deprecated Use StorageService directly for new code
class ImageService {
  final StorageService _storageService;

  ImageService({StorageService? storageService})
      : _storageService = storageService ?? StorageService();

  /// Pick an image from gallery
  Future<File?> pickImage() async {
    DebugLogger.info('ImageService: Picking image from gallery');
    return await _storageService.pickImageFromGallery();
  }

  /// Take a photo with camera
  Future<File?> takePhoto() async {
    DebugLogger.info('ImageService: Taking photo with camera');
    return await _storageService.takePhoto();
  }

  /// Upload an image to Firebase Storage
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    DebugLogger.info('ImageService: Uploading image');
    return await _storageService.uploadImage(imageFile, folder: folder);
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    DebugLogger.info('ImageService: Deleting image');
    return await _storageService.deleteFileFromUrl(imageUrl);
  }
}

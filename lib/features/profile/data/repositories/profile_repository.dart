
// BEFORE:
// import '../../../services/image_service.dart';
// import '../../../utils/file_utils.dart';

// AFTER:
import 'dart:io';
import '../../../../core/services/storage_service.dart';

class ProfileRepository {
  // BEFORE:
  // final ImageService _imageService = ImageService();
  // final FileUtils _fileUtils = FileUtils();
  
  // AFTER:
  final StorageService _storageService = StorageService();
  
  // Update methods to use the consolidated service
  Future<String> uploadProfileImage(File imageFile) async {
    // BEFORE:
    // return await _imageService.uploadImage(imageFile, folder: 'profiles');
    
    // AFTER:
    return await _storageService.uploadImage(imageFile, folder: 'profiles');
  }
  
  // Other methods...
}

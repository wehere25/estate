import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../utils/debug_logger.dart';

/// Centralized storage service that handles all file and image operations
/// 
/// This service consolidates functionality for:
/// - Firebase Storage uploads/downloads
/// - Local file system operations
/// - Image picking and processing
/// - File type validation
class StorageService {
  final FirebaseStorage _firebaseStorage;
  final ImagePicker _imagePicker;
  final Uuid _uuid = const Uuid();

  /// Maximum size for image uploads (5MB)
  static const int maxImageSize = 5 * 1024 * 1024;

  /// Supported image formats
  static const List<String> supportedImageFormats = [
    'jpg', 'jpeg', 'png', 'webp', 'heic'
  ];

  /// Supported document formats
  static const List<String> supportedDocumentFormats = [
    'pdf', 'doc', 'docx', 'txt'
  ];

  /// Constructor with dependency injection for testing
  StorageService({
    FirebaseStorage? firebaseStorage,
    ImagePicker? imagePicker,
  }) : 
    _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance,
    _imagePicker = imagePicker ?? ImagePicker();

  /// Upload an image to Firebase Storage
  /// 
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      DebugLogger.info('Starting image upload');
      
      // Validate file type
      final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
      if (!supportedImageFormats.contains(extension)) {
        throw Exception('Unsupported file format. Supported formats: ${supportedImageFormats.join(', ')}');
      }
      
      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > maxImageSize) {
        throw Exception('File size exceeds the maximum allowed size of 5MB');
      }
      
      // Generate a unique filename
      final fileName = '${_uuid.v4()}.$extension';
      
      // Create the reference to the file location in Firebase Storage
      final storagePath = folder != null ? '$folder/$fileName' : 'images/$fileName';
      final ref = _firebaseStorage.ref().child(storagePath);
      
      // Upload the file
      DebugLogger.info('Uploading image to: $storagePath');
      final uploadTask = ref.putFile(imageFile);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      DebugLogger.info('Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      DebugLogger.error('Image upload failed', e);
      rethrow;
    }
  }

  /// Pick an image from the device gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      DebugLogger.error('Error picking image from gallery', e);
      rethrow;
    }
  }

  /// Take a photo using the device camera
  Future<File?> takePhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      DebugLogger.error('Error taking photo', e);
      rethrow;
    }
  }

  /// Download a file from a URL and save it to the device
  Future<File?> downloadFile(String url, {String? customFileName}) async {
    try {
      // Get the file name from the URL or use the custom one
      final fileName = customFileName ?? path.basename(url);
      
      // Get the application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      final filePath = path.join(documentsDir.path, fileName);
      
      // Download the file
      DebugLogger.info('Downloading file from: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        DebugLogger.info('File downloaded to: $filePath');
        return file;
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Error downloading file', e);
      return null;
    }
  }

  /// Upload a document or generic file to Firebase Storage
  Future<String> uploadDocument(File file, {required String folder}) async {
    try {
      DebugLogger.info('Starting document upload');
      
      // Generate a unique filename with original extension
      final extension = path.extension(file.path).toLowerCase();
      final fileName = '${_uuid.v4()}$extension';
      
      // Create the reference to the file location
      final storagePath = '$folder/$fileName';
      final ref = _firebaseStorage.ref().child(storagePath);
      
      // Upload the file
      DebugLogger.info('Uploading document to: $storagePath');
      final uploadTask = ref.putFile(file);
      
      // Wait for the upload to complete
      final snapshot = await uploadTask;
      
      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      DebugLogger.info('Document uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      DebugLogger.error('Document upload failed', e);
      rethrow;
    }
  }
  
  /// Delete a file from Firebase Storage by URL
  Future<void> deleteFileFromUrl(String url) async {
    try {
      DebugLogger.info('Attempting to delete file: $url');
      final ref = _firebaseStorage.refFromURL(url);
      await ref.delete();
      DebugLogger.info('File deleted successfully');
    } catch (e) {
      DebugLogger.error('Error deleting file', e);
      rethrow;
    }
  }
  
  /// Save a file to local storage
  Future<File> saveFileLocally(List<int> bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      DebugLogger.error('Error saving file locally', e);
      rethrow;
    }
  }
  
  /// Get a file from local storage
  Future<File?> getLocalFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = path.join(directory.path, fileName);
      final file = File(filePath);
      
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      DebugLogger.error('Error getting local file', e);
      return null;
    }
  }
  
  /// Check if a file exists in local storage
  Future<bool> fileExistsLocally(String fileName) async {
    try {
      final file = await getLocalFile(fileName);
      return file != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Delete a local file
  Future<bool> deleteLocalFile(String fileName) async {
    try {
      final file = await getLocalFile(fileName);
      if (file != null) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      DebugLogger.error('Error deleting local file', e);
      return false;
    }
  }
  
  /// Get the directory for temporary files
  Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }
  
  /// Clear all temporary files
  Future<void> clearTemporaryFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync().forEach((entity) {
          if (entity is File) {
            entity.deleteSync();
          }
        });
      }
    } catch (e) {
      DebugLogger.error('Error clearing temporary files', e);
    }
  }
}

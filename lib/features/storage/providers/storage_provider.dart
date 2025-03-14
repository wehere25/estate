import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '/core/utils/dev_utils.dart';

class StorageProvider extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String? _error;

  bool get isLoading => _isLoading;
  double get uploadProgress => _uploadProgress;
  String? get error => _error;

  /// Upload an image file to Firebase Storage with dev mode fallback
  Future<String> uploadImage(File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
    final destination = 'images/$fileName';
    return uploadFile(file, destination);
  }

  /// Upload a file to Firebase Storage with dev mode fallback
  Future<String> uploadFile(File file, String destination) async {
    _isLoading = true;
    _uploadProgress = 0;
    _error = null;
    notifyListeners();

    try {
      // Always attempt a real Firebase upload first, even in dev mode
      // Normal Firebase Storage upload
      final ref = _storage.ref().child(destination);

      // Create upload task
      final uploadTask = ref.putFile(file);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        notifyListeners();
      });

      // Wait for upload to complete
      await uploadTask.whenComplete(() => null);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();

      _isLoading = false;
      _uploadProgress = 1.0;
      notifyListeners();

      DevUtils.log('Successfully uploaded file to: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      DevUtils.log('Error uploading file: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      // Only if Firebase is completely unavailable, fall back to a local file URL in dev mode
      if (DevUtils.isDev) {
        DevUtils.log('Using local file path as fallback in dev mode');
        // Use the actual file path for local development
        // This ensures the actual uploaded image is displayed
        return 'file://${file.path}';
      }

      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String fileUrl) async {
    // Skip delete for local file URLs
    if (fileUrl.startsWith('file://')) {
      DevUtils.log('Skipping delete for local file: $fileUrl');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the file reference from the URL
      final ref = _storage.refFromURL(fileUrl);

      // Delete the file
      await ref.delete();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to delete file: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

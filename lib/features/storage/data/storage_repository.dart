import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/utils/logger.dart';

class StorageRepository {
  static const String _tag = 'StorageRepository';
  final FirebaseStorage _storage;

  StorageRepository({FirebaseStorage? storage}) 
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String?> uploadImage({
    required String path,
    required File file,
    void Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      
      final uploadTask = ref.putFile(file);
      
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      AppLogger.i(_tag, 'Successfully uploaded image to: $path');
      return downloadUrl;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to upload image', e);
      return null;
    }
  }

  Future<bool> deleteImage(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
      AppLogger.i(_tag, 'Successfully deleted image at: $path');
      return true;
    } catch (e) {
      AppLogger.e(_tag, 'Failed to delete image', e);
      return false;
    }
  }
}

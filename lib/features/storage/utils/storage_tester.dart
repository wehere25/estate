import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add import for Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/storage_provider.dart';

class StorageTester extends StatelessWidget {
  const StorageTester({Key? key}) : super(key: key);

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final provider = Provider.of<StorageProvider>(context, listen: false);
    
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;
      
      if (!context.mounted) return;  // Check mounted state after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...')),
      );
      
      final file = File(pickedFile.path);
      final downloadUrl = await provider.uploadImage(file);
      
      if (!context.mounted) return;  // Check mounted state after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload complete: $downloadUrl')),
      );
      
      // Copy URL to clipboard using proper import
      await Clipboard.setData(ClipboardData(text: downloadUrl));
      
      if (!context.mounted) return;  // Check mounted state after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL copied to clipboard')),
      );
    } catch (e) {
      if (!context.mounted) return;  // Check mounted state after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage Tester')),
      body: Consumer<StorageProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.isLoading)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('Uploading: ${(provider.uploadProgress * 100).toStringAsFixed(1)}%'),
                      LinearProgressIndicator(value: provider.uploadProgress),
                    ],
                  )
                else if (provider.error != null)
                  Text('Error: ${provider.error}', style: const TextStyle(color: Colors.red))
                else
                  const Text('Ready to upload'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : () => _pickAndUploadImage(context),
                  child: const Text('Pick and Upload Image'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

/// Helper class for Firebase Storage operations
class FirebaseStorageHelper {
  // Firebase Storage: Initialize storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String?> uploadFile({
    required File file,
    required String userId,
    required String folder,
  }) async {
    try {
      // Create a unique filename using timestamp
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final String filePath = '$folder/$userId/$fileName';
      
      // Firebase Storage: Create reference to file path
      final Reference reference = _storage.ref().child(filePath);
      // Firebase Storage: Create and start upload task
      final UploadTask uploadTask = reference.putFile(file);
      
      // Firebase Storage: Wait for upload to complete and get snapshot
      final TaskSnapshot taskSnapshot = await uploadTask;
      // Firebase Storage: Get download URL from upload reference
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      
      print('File uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  /// Deletes a file from Firebase Storage by its URL
  Future<bool> deleteFileByUrl(String fileUrl) async {
    try {
      // Firebase Storage: Create reference from existing file URL
      final Reference reference = _storage.refFromURL(fileUrl);
      // Firebase Storage: Delete file using reference
      await reference.delete();
      print('File deleted successfully: $fileUrl');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}

import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  /// Uploads an image file to Firebase Storage and returns the download URL.
  /// Returns null if upload fails.
  /// [imageFile]: The image file to upload.
  /// [fileName]: The desired name for the uploaded file.
  Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      Reference ref = _storage.ref().child('images/$fileName');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }
  
}
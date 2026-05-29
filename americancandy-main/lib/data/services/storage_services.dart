import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';

class StorageServices extends GetxController {
  static StorageServices get instance => Get.find();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// [UploadImage] - Function to upload Image to Firebase Storage
  /// [image] is the File object to upload
  /// [folderName] is the path in storage (e.g., 'category/')
  /// Returns the download URL of the uploaded image
  Future<String> uploadImage(File image, String folderName) async {
    try {
      // Generate a unique filename or use the original name
      String fileName = image.path.split(Platform.pathSeparator).last;

      // Construct the full path.
      // If folderName is 'category/', result is 'category/filename.ext'
      String path = '$folderName/$fileName';

      // Create a reference to the location
      Reference ref = _storage.ref().child(path);

      // Upload the file
      UploadTask uploadTask = ref.putFile(image);

      // Wait for the upload to complete
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;

    } catch (e) {
      // It's good practice to log the error
      print('Error uploading image: $e');
      throw 'Failed to upload image. Please try again.';
    }
  }

  /// [DeleteImage] - Function to delete Image from Firebase Storage
  /// [imageUrl] is the full download URL of the image
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Create a reference from the URL
      Reference ref = _storage.refFromURL(imageUrl);

      // Delete the file
      await ref.delete();

    } catch (e) {
      print('Error deleting image: $e');
      throw 'Something went wrong. Please try again';
    }
  }
}
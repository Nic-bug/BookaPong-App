import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<String> uploadImageToCloud({
  required String localPath,
  required String uid,
  required String collectionFolder, // Pass 'admins' or 'users'
  required String
  subFolder, // Pass 'coverImage', 'galleryImages', or 'profileImage'
}) async {
  if (localPath.isEmpty) {
    throw Exception("The provided local file path is completely empty.");
  }

  File file = File(localPath);
  if (!await file.exists()) {
    throw Exception("The target file does not exist at path: $localPath");
  }

  // 1. Create a unique filename using a timestamp to prevent duplicate cache clashes
  String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

  // 2. Point to target bucket location dynamically
  // Structure: collectionFolder/uid/subFolder/filename.jpg
  Reference storageRef = FirebaseStorage.instance
      .ref()
      .child(collectionFolder)
      .child(uid)
      .child(subFolder)
      .child(fileName);

  // 3. Execute the upload task stream
  UploadTask uploadTask = storageRef.putFile(file);
  TaskSnapshot snapshot = await uploadTask;

  // 4. Extract and return the secure live network HTTPS URL
  String downloadUrl = await snapshot.ref.getDownloadURL();
  return downloadUrl;
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registers a new Arena Administrator across Authentication and Firestore Nodes
  /// Returns the generated adminUid to act as the payment reference for ToyyibPay
  Future<String> registerAdmin({
    required String email,
    required String password,
    required String centerName,
    required String contactPerson,
    required String phone,
    required String selectedPlan,
  }) async {
    try {
      // 1. Create User credentials inside Firebase Authentication system
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final String adminUid = userCredential.user!.uid;

      // 2. Write to 'users' collection (Used by LoginPage role checking router)
      await _firestore.collection('users').doc(adminUid).set({
        'name': contactPerson,
        'email': email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Write to 'admins' collection
      await _firestore.collection('admins').doc(adminUid).set({
        'centerName': centerName,
        'email': email,
        'contactPerson': contactPerson,
        'phone': phone,

        // Subscription State Metadata - Flat Fields
        'subscriptionPlan': selectedPlan,
        'subscriptionStatus': 'pending', // System waits for ToyyibPay callback

        'addressLocation': 'Address location pending setup',
        'galleryImages': [],
        'coverImage': '',
        'rating': '5.0',
        'distance': '1.0 km',
        'role': 'admin',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      // 4. Return the UID so the payment page can fire the ToyyibPay Cloud Function
      return adminUid;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Exception inside registerAdmin: ${e.message}");
      throw Exception(e.message ?? "An authentication error occurred.");
    } catch (e) {
      debugPrint("General pipeline crash inside registerAdmin: $e");
      throw Exception(
        "Failed to sync structural admin data maps to backend collections.",
      );
    }
  }
}

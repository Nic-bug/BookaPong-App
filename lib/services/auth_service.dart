import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registers a new Arena Administrator across Authentication and Firestore Nodes
  Future<void> registerAdmin({
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
        'role': 'admin', // Marked distinctly as admin space provider
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Write to 'admins' collection (Used by AdminBookingPage & User Discovery horizontal rows)
      await _firestore.collection('admins').doc(adminUid).set({
        'centerName': centerName,
        'email': email,
        'contactPerson': contactPerson,
        'phone': phone,
        'subscriptionPlan': selectedPlan,
        'addressLocation':
            'Address location pending setup', // Placeholder to be populated in profile edit page
        'galleryImages': [],
        'coverImage': '',
        'rating': '5.0',
        'distance': '1.0 km', // Initial fallback value configuration
        'role': 'admin',
        'registeredAt': FieldValue.serverTimestamp(),
      });
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

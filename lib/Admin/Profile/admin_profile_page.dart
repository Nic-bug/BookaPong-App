import 'dart:io';
import 'package:bookapong_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookapong_app/cloud_storage_helper.dart'; // Imports your universal cloud helper tool
import 'admin_edit_profile_page.dart';

// --- LOCAL DATA STORE HOLDER ---
class CenterDataStore {
  static String centerName = "Ping Pong Arena";
  static String addressLocation = "No. 42, Sport Complex Center, KL";
  static List<String> galleryImages = [];
}

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final Color darkMaroon = const Color(0xFF8B0000);
  final Color beige = const Color(0xFFFDF8F0);
  final ImagePicker _picker = ImagePicker();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _updateFirestoreField(
    String databaseFieldKey,
    String dataValue,
  ) async {
    if (_currentUser == null) return;
    await FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .update({databaseFieldKey: dataValue});
  }

  // --- UPLOAD COVER IMAGE TO LIVE STORAGE BUCKET ---
  Future<void> _pickAvatar(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && _currentUser != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Uploading cover image to cloud..."),
            duration: Duration(seconds: 4),
          ),
        );

        // Upload through named parameters tool mapping parameters natively
        String cloudImageUrl = await uploadImageToCloud(
          localPath: image.path,
          uid: _currentUser.uid,
          collectionFolder: 'admins',
          subFolder: 'coverImage',
        );

        // Update Firestore administrative reference data block link
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(_currentUser.uid)
            .update({'coverImage': cloudImageUrl});

        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Facility cover image saved to Firebase Storage!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error uploading profile image: $e");
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text("Upload Failed! Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // --- UPLOAD GALLERY POSITION ITEMS TO STORAGE BUCKET ---
  Future<void> _addGalleryImage(List<dynamic> currentGallery) async {
    final messenger = ScaffoldMessenger.of(context);
    if (currentGallery.length >= 5) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Maximum of 5 photos allowed for the venue slot."),
        ),
      );
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && _currentUser != null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Uploading gallery image to cloud..."),
            duration: Duration(seconds: 4),
          ),
        );

        // Send asset parsing variables securely
        String cloudGalleryUrl = await uploadImageToCloud(
          localPath: image.path,
          uid: _currentUser.uid,
          collectionFolder: 'admins',
          subFolder: 'galleryImages',
        );

        List<dynamic> updatedList = List.from(currentGallery)
          ..add(cloudGalleryUrl);

        await FirebaseFirestore.instance
            .collection('admins')
            .doc(_currentUser.uid)
            .update({'galleryImages': updatedList});

        setState(() {
          CenterDataStore.galleryImages = List<String>.from(updatedList);
        });

        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Gallery image uploaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking gallery photo: $e");
      if (mounted) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text("Gallery Upload Failed! Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _removeGalleryImage(
    List<dynamic> currentGallery,
    int targetIndex,
  ) async {
    if (_currentUser == null) return;
    List<dynamic> updatedList = List.from(currentGallery)
      ..removeAt(targetIndex);

    await FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .update({'galleryImages': updatedList});

    setState(() {
      CenterDataStore.galleryImages = List<String>.from(updatedList);
    });
  }

  // --- PREVENTS IN-MEMORY LAYOUT CRASHES BY RETURNING NULL IF PATH IS DEFUNCT LOCAL FILE ---
  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('https') || kIsWeb) {
      return NetworkImage(path);
    }
    final localFile = File(path);
    return localFile.existsSync() ? FileImage(localFile) : null;
  }

  void _navigateToEditField({
    required String title,
    required String currentValue,
    required IconData icon,
    required String firestoreFieldKey,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminEditProfilePage(
          title: title,
          initialValue: currentValue,
          icon: icon,
          onSaveCallback: (newValue) async {
            await _updateFirestoreField(firestoreFieldKey, newValue);
            if (firestoreFieldKey == 'centerName') {
              CenterDataStore.centerName = newValue;
            }
            if (firestoreFieldKey == 'addressLocation') {
              CenterDataStore.addressLocation = newValue;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("No authenticated Administrator found. Login required."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: beige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Admin Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .doc(_currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error fetching records: ${snapshot.error}"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: darkMaroon));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Admin profile information entry does not exist."),
            );
          }

          var adminData = snapshot.data!.data() as Map<String, dynamic>;
          String centerName = adminData['centerName'] ?? "Not Configured";
          String email =
              adminData['email'] ?? _currentUser.email ?? "Not Configured";
          String contactPerson = adminData['contactPerson'] ?? "Not Configured";
          String phone = adminData['phone'] ?? "Not Configured";
          String addressLocation =
              adminData['addressLocation'] ?? "Not Configured";
          String? cloudCoverImage = adminData['coverImage'];
          List<dynamic> rawGallery = adminData['galleryImages'] ?? [];

          CenterDataStore.centerName = centerName;
          CenterDataStore.addressLocation = addressLocation;
          CenterDataStore.galleryImages = List<String>.from(rawGallery);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      GestureDetector(
                        onTap: () => _pickAvatar(context),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: darkMaroon,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: _getProfileImage(cloudCoverImage),
                            backgroundColor: Colors.grey.shade300,
                            child:
                                cloudCoverImage == null ||
                                    cloudCoverImage.isEmpty
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 35,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: darkMaroon,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "SUPER ADMIN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  centerName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "System Management",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                _buildSectionWrapper([
                  _buildInfoTile(
                    Icons.business,
                    "Center Name",
                    centerName,
                    darkMaroon,
                    onTap: () => _navigateToEditField(
                      title: "Center Name",
                      currentValue: centerName,
                      icon: Icons.business,
                      firestoreFieldKey: "centerName",
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(
                    Icons.email_outlined,
                    "Email Address",
                    email,
                    darkMaroon,
                    onTap: () => _navigateToEditField(
                      title: "Email Address",
                      currentValue: email,
                      icon: Icons.email_outlined,
                      firestoreFieldKey: "email",
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(
                    Icons.person_outline,
                    "Contact Person",
                    contactPerson,
                    darkMaroon,
                    onTap: () => _navigateToEditField(
                      title: "Contact Person",
                      currentValue: contactPerson,
                      icon: Icons.person_outline,
                      firestoreFieldKey: "contactPerson",
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(
                    Icons.phone_outlined,
                    "Phone Number",
                    phone,
                    darkMaroon,
                    onTap: () => _navigateToEditField(
                      title: "Phone Number",
                      currentValue: phone,
                      icon: Icons.phone_outlined,
                      firestoreFieldKey: "phone",
                    ),
                  ),
                  const Divider(height: 1, indent: 60),
                  _buildInfoTile(
                    Icons.location_on_outlined,
                    "Address Location",
                    addressLocation,
                    darkMaroon,
                    onTap: () => _navigateToEditField(
                      title: "Address Location",
                      currentValue: addressLocation,
                      icon: Icons.location_on_outlined,
                      firestoreFieldKey: "addressLocation",
                    ),
                  ),
                ]),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Center Gallery Images (${CenterDataStore.galleryImages.length}/5)",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (CenterDataStore.galleryImages.length < 5)
                        TextButton.icon(
                          onPressed: () =>
                              _addGalleryImage(CenterDataStore.galleryImages),
                          icon: const Icon(Icons.add_a_photo, size: 18),
                          label: const Text("Add"),
                          style: TextButton.styleFrom(
                            foregroundColor: darkMaroon,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: 110,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: CenterDataStore.galleryImages.isEmpty
                      ? Center(
                          child: Text(
                            "No photos attached.",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: CenterDataStore.galleryImages.length,
                          itemBuilder: (context, index) {
                            final path = CenterDataStore.galleryImages[index];
                            final imgProvider = _getProfileImage(path);
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(
                                    right: 12,
                                    top: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    image: imgProvider != null
                                        ? DecorationImage(
                                            image: imgProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeGalleryImage(
                                      CenterDataStore.galleryImages,
                                      index,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 25),
                _buildSectionWrapper([
                  _buildInfoTile(
                    Icons.logout,
                    "Logout",
                    "Sign out of session",
                    Colors.red,
                    showTrailing: false,
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AuthWrapper(), // THIS IS THE FIX
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionWrapper(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color color, {
    required VoidCallback onTap,
    bool showTrailing = true,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value.isNotEmpty ? value : "Not Configured",
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: showTrailing ? const Icon(Icons.chevron_right, size: 20) : null,
    );
  }
}

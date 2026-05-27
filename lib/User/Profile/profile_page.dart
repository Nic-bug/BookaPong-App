import 'dart:io';
import 'package:bookapong_app/User/Login%20and%20Register/login_register_page.dart';
import 'package:flutter/foundation.dart';
import 'package:bookapong_app/User/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookapong_app/cloud_storage_helper.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "Loading...";
  String email = "Loading...";
  String phone = "";
  String address = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            name = userData['name'] ?? 'No Name';
            email = userData['email'] ?? currentUser.email ?? '';
            phone = userData['phone'] ?? 'Add phone number';
            address = userData['address'] ?? 'Add address';
            isLoading = false;
          });

          if (userData['profileImage'] != null &&
              userData['profileImage'].toString().isNotEmpty) {
            UserController().updateImage(userData['profileImage']);
          }
        }
      }
    } catch (e) {
      debugPrint("Error retrieving user data: $e");
      setState(() => isLoading = false);
    }
  }

  // ==================== VERY STRONG LOGOUT ====================
  Future<void> _logout() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Logging out...")));
      }

      // 1. Sign out
      await FirebaseAuth.instance.signOut();

      // 2. Force clear entire navigation stack and go to LoginPage
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false, // This removes ALL previous screens
        );
      }
    } catch (e) {
      debugPrint("Logout error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logout failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (image != null && currentUser != null) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Uploading profile picture...")),
        );

        String cloudImageUrl = await uploadImageToCloud(
          localPath: image.path,
          uid: currentUser.uid,
          collectionFolder: 'users',
          subFolder: 'profileImage',
        );

        UserController().updateImage(cloudImageUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'profileImage': cloudImageUrl});

        if (mounted) {
          messenger.clearSnackBars();
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Profile picture updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Failed to upload image"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('https') || kIsWeb) {
      return NetworkImage(path);
    }
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  Future<void> _navigateToEditField({
    required String title,
    required String fieldKey,
    required String currentValue,
    required IconData icon,
    required Function(String) onSave,
  }) async {
    final updatedValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(
          title: title,
          fieldKey: fieldKey,
          initialValue: currentValue,
          icon: icon,
        ),
      ),
    );

    if (updatedValue != null && mounted) {
      setState(() => onSave(updatedValue));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkRed = Color(0xFF800020);
    const Color beige = Color(0xFFFDF8F0);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: beige,
        body: Center(child: CircularProgressIndicator(color: darkRed)),
      );
    }

    return Scaffold(
      backgroundColor: beige,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: darkRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _pickImage(context),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<String?>(
                            valueListenable: UserController().profileImagePath,
                            builder: (context, path, child) {
                              final provider = _getProfileImage(path);
                              return CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: provider,
                                child: provider == null
                                    ? const Icon(
                                        Icons.camera_alt,
                                        size: 40,
                                        color: Colors.white,
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: darkRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "ACTIVE EXPERT",
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
              const SizedBox(height: 20),
              Center(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSectionWrapper([
                _buildInfoTile(
                  Icons.person_outline,
                  "Name",
                  name,
                  darkRed,
                  onTap: () => _navigateToEditField(
                    title: "Name",
                    fieldKey: "name",
                    currentValue: name,
                    icon: Icons.person_outline,
                    onSave: (val) => name = val,
                  ),
                ),
                const Divider(height: 1, indent: 55),
                _buildInfoTile(
                  Icons.email_outlined,
                  "Email",
                  email,
                  darkRed,
                  showEditIcon: false,
                  onTap: null,
                ),
                const Divider(height: 1, indent: 55),
                _buildInfoTile(
                  Icons.phone_outlined,
                  "Phone",
                  phone,
                  darkRed,
                  onTap: () => _navigateToEditField(
                    title: "Phone",
                    fieldKey: "phone",
                    currentValue: phone,
                    icon: Icons.phone_outlined,
                    onSave: (val) => phone = val,
                  ),
                ),
                const Divider(height: 1, indent: 55),
                _buildInfoTile(
                  Icons.location_city_outlined,
                  "Address",
                  address,
                  darkRed,
                  onTap: () => _navigateToEditField(
                    title: "Address",
                    fieldKey: "address",
                    currentValue: address,
                    icon: Icons.location_city_outlined,
                    onSave: (val) => address = val,
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              _buildSectionWrapper([
                _buildInfoTile(
                  Icons.logout,
                  "Logout",
                  "",
                  Colors.red,
                  textColor: Colors.red,
                  showEditIcon: false,
                  onTap: _logout,
                ),
              ]),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWrapper(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color iconColor, {
    Color? textColor,
    VoidCallback? onTap,
    bool showEditIcon = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black87,
          fontSize: 15,
        ),
      ),
      subtitle: value.isNotEmpty
          ? Text(value, style: TextStyle(color: Colors.grey.shade600))
          : null,
      trailing: showEditIcon
          ? const Icon(Icons.chevron_right, color: Colors.grey)
          : null,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String title;
  final String
  fieldKey; // Points to the specific key field inside Firestore database document
  final String initialValue;
  final IconData icon;

  const EditProfilePage({
    super.key,
    required this.title,
    required this.fieldKey,
    required this.initialValue,
    required this.icon,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  final Color darkRed = const Color(0xFF800020);
  final Color beige = const Color(0xFFFDF8F0);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Perform structural updates to backend using the specific field key context
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({widget.fieldKey: _controller.text.trim()});

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Changes saved successfully!')),
          );

          // Return the clean updated text variable value context back to ProfilePage
          Navigator.pop(context, _controller.text.trim());
        }
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sync details with backend.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: darkRed),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                    ),
                    _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF800020),
                            ),
                          )
                        : TextButton(
                            onPressed: _saveData,
                            child: Text(
                              "SAVE",
                              style: TextStyle(
                                color: darkRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Update your ${widget.title.toLowerCase()} below.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _controller,
                  obscureText: widget.title == "Password",
                  cursorColor: darkRed,
                  enabled: !_isSaving,
                  decoration: InputDecoration(
                    prefixIcon: Icon(widget.icon, color: darkRed),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Enter ${widget.title}",
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: darkRed, width: 2),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Color(0xFFECECEC)),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a value'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

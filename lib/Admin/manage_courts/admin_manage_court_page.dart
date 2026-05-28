import 'package:bookapong_app/Admin/admin_drawer.dart';
import 'package:bookapong_app/Admin/manage_courts/admin_edit_slot_management.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminManageCourtPage extends StatefulWidget {
  const AdminManageCourtPage({super.key});

  @override
  State<AdminManageCourtPage> createState() => _AdminManageCourtPageState();
}

class _AdminManageCourtPageState extends State<AdminManageCourtPage> {
  static const Color brandMaroon = Color(0xFF8B0000);
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;

  void _showAddTableDialog() {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Add New Table / Court",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Table Name / Number",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        hintText: "e.g., Table 3 or VIP Court",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: brandMaroon,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_isSaving) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(color: brandMaroon),
                      ),
                    ],
                  ],
                ),
              ),
              actions: _isSaving
                  ? []
                  : [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String enteredName = nameController.text.trim();
                          if (enteredName.isEmpty) return;

                          if (_currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error: Not logged in."),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => _isSaving = true);
                          setState(() => _isSaving = true);

                          try {
                            final docRef = FirebaseFirestore.instance
                                .collection('admins')
                                .doc(_currentUser.uid)
                                .collection('courts')
                                .doc(enteredName);

                            await docRef
                                .set({
                                  'name': enteredName,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'closures': {},
                                })
                                .timeout(const Duration(seconds: 6));

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "'$enteredName' successfully sent to cloud backend.",
                                  ),
                                ),
                              );
                            }
                          } catch (e, stackTrace) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Transmission failed: $e"),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                              Navigator.pop(dialogContext);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandMaroon,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Save"),
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text("Access Denied. Admin authentication token missing."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Court",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      // INJECTED DRAWER
      drawer: const AdminDrawer(currentPage: 'Manage Courts'),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _showAddTableDialog,
                icon: const Icon(Icons.add_box_rounded, size: 22),
                label: const Text(
                  "Add New Table / Court",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandMaroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Active Tables",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admins')
                    .doc(_currentUser.uid)
                    .collection('courts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Backend Stream Error: ${snapshot.error}"),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: brandMaroon),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No courts found in your center profile.\nClick the button above to create one.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    );
                  }

                  final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
                    ..sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>?;
                      final bData = b.data() as Map<String, dynamic>?;

                      final Timestamp? aTime =
                          aData?['createdAt'] as Timestamp?;
                      final Timestamp? bTime =
                          bData?['createdAt'] as Timestamp?;

                      if (aTime == null) return -1;
                      if (bTime == null) return 1;
                      return bTime.compareTo(aTime);
                    });

                  return ListView.builder(
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      final currentDoc = sortedDocs[index];
                      final courtData =
                          currentDoc.data() as Map<String, dynamic>?;

                      final String courtName =
                          courtData != null && courtData.containsKey('name')
                          ? courtData['name']
                          : currentDoc.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.table_restaurant,
                            color: brandMaroon,
                          ),
                          title: Text(
                            courtName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            final now = DateTime.now();
                            final normalizedDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminEditSlotManagementPage(
                                      selectedDate: normalizedDate,
                                      tableName: currentDoc.id,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

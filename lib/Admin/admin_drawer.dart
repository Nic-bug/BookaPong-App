import 'dart:io';
import 'package:bookapong_app/Admin/Dashboard/admin_dashboard_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookapong_app/User/user_controller.dart';

// Ensure these point to your correct file paths!
// Adjust path if needed
import 'package:bookapong_app/Admin/Profile/admin_profile_page.dart';
import 'package:bookapong_app/Admin/access_logs/admin_access_logs_page.dart';
import 'package:bookapong_app/Admin/Bookings/admin_booking_page.dart';
import 'package:bookapong_app/Admin/manage_courts/admin_manage_court_page.dart';
import 'package:bookapong_app/Admin/Payments/admin_payment_page.dart';

class AdminDrawer extends StatelessWidget {
  final String currentPage;

  const AdminDrawer({super.key, required this.currentPage});

  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (kIsWeb) return NetworkImage(path);
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  void _showUpgradeWall(
    BuildContext context,
    String planRequired,
    String featureName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_person_rounded, color: Colors.amber.shade800),
            const SizedBox(width: 10),
            const Text("Premium Feature"),
          ],
        ),
        content: Text(
          "Access to '$featureName' requires a $planRequired Plan subscription. Upgrade your workspace tier to activate automated real-time services.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Maybe Later",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Route to your subscription/upgrade page
            },
            child: const Text(
              "Upgrade Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap, {
    bool isLocked = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isLocked ? Colors.white38 : Colors.white),
        title: Text(
          title,
          style: TextStyle(color: isLocked ? Colors.white38 : Colors.white),
        ),
        trailing: isLocked
            ? const Icon(Icons.lock_outline, color: Colors.white38, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);
    const Color darkBg = Color(0xFF212121);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Drawer(
            backgroundColor: darkBg,
            child: Center(child: CircularProgressIndicator(color: brandMaroon)),
          );
        }

        final adminData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String activePlan = adminData['subscriptionPlan'] ?? 'Standard';
        final bool supportIotAccess =
            activePlan == 'Business' || activePlan == 'Premium';

        return Drawer(
          backgroundColor: darkBg,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close drawer first
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminProfilePage(),
                    ),
                  );
                },
                child: DrawerHeader(
                  // 1. Removes default bottom gap so the image touches the edges
                  margin: EdgeInsets.zero,
                  // 2. Adds consistent internal padding for your text
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: darkBg,
                    image:
                        (adminData['coverImage'] != null &&
                            adminData['coverImage'].toString().isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(adminData['coverImage']),
                            fit: BoxFit
                                .cover, // Ensures the image fills the entire header box
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.6),
                              BlendMode.darken,
                            ),
                          )
                        : null,
                  ),
                  // 3. Forces the Column to take up the full width of the drawer
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Now it anchors to the true left edge
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          adminData['centerName'] ?? 'BookaPong',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: brandMaroon,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            adminData['role'] ?? 'Superadmin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _drawerTile(
                context,
                Icons.grid_view_rounded,
                "Dashboard",
                currentPage == "Dashboard",
                brandMaroon,
                () {
                  Navigator.pop(context);
                  if (currentPage != "Dashboard") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminDashboardPage(),
                      ),
                    );
                  }
                },
              ),

              _drawerTile(
                context,
                Icons.calendar_today,
                "Bookings",
                currentPage == "Bookings",
                brandMaroon,
                () {
                  Navigator.pop(context);
                  if (currentPage != "Bookings") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminBookingPage(),
                      ),
                    );
                  }
                },
              ),

              _drawerTile(
                context,
                Icons.sports_tennis,
                "Manage Courts",
                currentPage == "Manage Courts",
                brandMaroon,
                () {
                  Navigator.pop(context);
                  if (currentPage != "Manage Courts") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminManageCourtPage(),
                      ),
                    );
                  }
                },
              ),

              _drawerTile(
                context,
                supportIotAccess ? Icons.security : Icons.lock_outline,
                "Access Logs",
                currentPage == "Access Logs",
                brandMaroon,
                () {
                  Navigator.pop(context);
                  if (supportIotAccess) {
                    if (currentPage != "Access Logs") {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAccessLogsPage(),
                        ),
                      );
                    }
                  } else {
                    _showUpgradeWall(
                      context,
                      "Business",
                      "ESP32 Lock Integration & Access Logs",
                    );
                  }
                },
                isLocked: !supportIotAccess,
              ),

              _drawerTile(
                context,
                Icons.attach_money,
                "Payments",
                currentPage == "Payments",
                brandMaroon,
                () {
                  Navigator.pop(context);
                  if (currentPage != "Payments") {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPaymentsPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added to support the logout trigger logic natively
import 'package:bookapong_app/User/user_controller.dart';
import 'package:bookapong_app/Admin/access_logs/admin_access_logs_page.dart';
import 'package:bookapong_app/Admin/Bookings/admin_booking_page.dart';
import 'package:bookapong_app/Admin/manage_courts/admin_manage_court_page.dart';
import 'package:bookapong_app/Admin/Payments/admin_payment_page.dart';
import 'package:bookapong_app/Admin/Profile/admin_profile_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // Helper to handle File vs Web images
  ImageProvider? _getProfileImage(String? path) {
    if (path == null || path.isEmpty) return null;
    if (kIsWeb) return NetworkImage(path);
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);
    const Color darkBg = Color(0xFF212121);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Dashboard Overview",
          style: TextStyle(color: Colors.black),
        ),
      ),
      drawer: Drawer(
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
                decoration: const BoxDecoration(color: darkBg),
                child: Row(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable: UserController().profileImagePath,
                      builder: (context, path, child) {
                        final provider = _getProfileImage(path);
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 2),
                            image: provider != null
                                ? DecorationImage(
                                    image: provider,
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: provider == null
                              ? const Icon(
                                  Icons.account_circle,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : null,
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "BookaPong\nAdmin Panel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _drawerTile(
              Icons.grid_view_rounded,
              "Dashboard",
              true,
              brandMaroon,
              () {
                Navigator.pop(
                  context,
                ); // Close the drawer since we are already on dashboard
              },
            ),
            _drawerTile(
              Icons.calendar_today,
              "Bookings",
              false,
              brandMaroon,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminBookingPage(),
                  ),
                );
              },
            ),
            _drawerTile(
              Icons
                  .sports_tennis, // Changed icon from group_outlined to match courts theme beautifully
              "Manage Courts",
              false,
              brandMaroon,
              () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminManageCourtPage(),
                  ),
                );
              },
            ),
            _drawerTile(Icons.security, "Access Logs", false, brandMaroon, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminAccessLogsPage(),
                ),
              );
            }),
            _drawerTile(Icons.attach_money, "Payments", false, brandMaroon, () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPaymentsPage(),
                ),
              );
            }),
            const Spacer(),

            // ✅ Fully Implemented Logout Action Tile
            _drawerTile(Icons.logout, "Logout", false, brandMaroon, () async {
              // Close the open navigation drawer layout frame safely
              Navigator.pop(context);

              try {
                // Destroys the cloud token session string completely.
                // The main.dart StreamBuilder handles shifting the view back to LoginPage immediately.
                await FirebaseAuth.instance.signOut();
                debugPrint(
                  "✅ Admin successfully disconnected and session terminated.",
                );
              } catch (e) {
                debugPrint(
                  "❌ Failure encountered during Admin logout routine processing execution sequence: $e",
                );
              }
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatCard(
              "Total Bookings",
              "142",
              "+12% from last month",
              Icons.calendar_today,
              Colors.blue.shade100,
              Colors.blue,
            ),
            _buildStatCard(
              "Today's Occupancy",
              "85%",
              "17 of 20 slots booked",
              Icons.check_circle_outline,
              Colors.green.shade100,
              Colors.green,
            ),
            _buildStatCard(
              "Revenue (Dec)",
              "RM 3,840",
              "+18% from last month",
              Icons.attach_money,
              Colors.purple.shade100,
              Colors.purple,
            ),
            _buildStatCard(
              "Active Users",
              "68",
              "+8 new this week",
              Icons.people_outline,
              Colors.orange.shade100,
              Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              "Today's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _scheduleItem(
              "09:00 AM",
              "Table 1 • John Doe",
              "Completed",
              Colors.blue,
            ),
            _scheduleItem(
              "10:00 AM",
              "Table 2 • Jane Smith",
              "Active",
              Colors.green,
            ),
            _scheduleItem(
              "11:00 AM",
              "Table 1 • Mike Johnson",
              "Upcoming",
              Colors.grey,
            ),
            _scheduleItem(
              "02:00 PM",
              "Table 2 • Sarah Williams",
              "Upcoming",
              Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(
    IconData icon,
    String title,
    bool isSelected,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Icon(Icons.trending_up, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(sub, style: const TextStyle(color: Colors.green, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _scheduleItem(
    String time,
    String details,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7E7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 18, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  details,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

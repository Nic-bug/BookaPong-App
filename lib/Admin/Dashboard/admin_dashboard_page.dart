import 'package:bookapong_app/Admin/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

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

  String _calculatePercentage(num current, num previous) {
    if (previous == 0) {
      return current > 0 ? "+100% from last month" : "0% from last month";
    }
    double change = ((current - previous) / previous) * 100;
    String sign = change >= 0 ? "+" : "";
    return "$sign${change.toStringAsFixed(1)}% from last month";
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    final DateTime now = DateTime.now();
    final String currentMonthStr = DateFormat('MMM').format(now);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUid)
          .snapshots(),
      builder: (context, adminSnapshot) {
        if (!adminSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: brandMaroon)),
          );
        }

        final adminData =
            adminSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String activePlan = adminData['subscriptionPlan'] ?? 'Standard';
        final bool supportMarketingDashboard = activePlan == 'Premium';

        // Nested Stream for Bookings Data
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('facilityId', isEqualTo: currentUid)
              .snapshots(),
          builder: (context, bookingsSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: brandMaroon),
                ),
              );
            }

            int totalBookings = 0;
            int thisMonthBookings = 0;
            int lastMonthBookings = 0;

            int todaysBookings = 0;
            int totalDailySlots =
                20; // Adjust this capacity based on your facility limits

            double thisMonthRevenue = 0.0;
            double lastMonthRevenue = 0.0;

            Set<String> activeUsersThisWeek = {};
            List<Map<String, dynamic>> todaysScheduleList = [];

            if (bookingsSnapshot.hasData) {
              for (var doc in bookingsSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                totalBookings++;

                Timestamp? timeStamp =
                    data['startTime'] as Timestamp? ??
                    data['createdAt'] as Timestamp?;
                if (timeStamp != null) {
                  DateTime date = timeStamp.toDate();

                  bool isThisMonth =
                      date.year == now.year && date.month == now.month;
                  bool isLastMonth = (now.month == 1)
                      ? (date.year == now.year - 1 && date.month == 12)
                      : (date.year == now.year && date.month == now.month - 1);
                  bool isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  bool isThisWeek =
                      now.difference(date).inDays <= 7 &&
                      now.difference(date).inDays >= 0;

                  // Booking Increments
                  if (isThisMonth) thisMonthBookings++;
                  if (isLastMonth) lastMonthBookings++;

                  // Today's Occupancy & Schedule
                  if (isToday) {
                    todaysBookings++;
                    todaysScheduleList.add({
                      'time': DateFormat('hh:mm a').format(date),
                      'details':
                          "${data['table'] ?? 'Table Pending'} • ${data['customerName'] ?? 'Unknown'}",
                      'status': data['status'] ?? 'Confirmed',
                      'rawDate': date,
                    });
                  }

                  // Revenue (Count Active or Completed)
                  String status = (data['status'] ?? 'confirmed')
                      .toString()
                      .toLowerCase();
                  if (status == 'completed' ||
                      status == 'confirmed' ||
                      status == 'active') {
                    double amount = (data['amountPaid'] ?? 0.0) is num
                        ? (data['amountPaid'] as num).toDouble()
                        : 0.0;
                    if (isThisMonth) thisMonthRevenue += amount;
                    if (isLastMonth) lastMonthRevenue += amount;
                  }

                  // Active Platform Users (Weekly unique users)
                  if (isThisWeek) {
                    String userId =
                        data['userId']?.toString() ??
                        data['customerName']?.toString() ??
                        doc.id;
                    activeUsersThisWeek.add(userId);
                  }
                }
              }
            }

            // Calculations
            String bookingIncrementStr = _calculatePercentage(
              thisMonthBookings,
              lastMonthBookings,
            );
            String revenueIncrementStr = _calculatePercentage(
              thisMonthRevenue,
              lastMonthRevenue,
            );

            int availableSlots = (totalDailySlots - todaysBookings).clamp(
              0,
              totalDailySlots,
            );
            int occupancyRate = ((todaysBookings / totalDailySlots) * 100)
                .clamp(0, 100)
                .toInt();

            // Sort schedule by time
            todaysScheduleList.sort(
              (a, b) => (a['rawDate'] as DateTime).compareTo(
                b['rawDate'] as DateTime,
              ),
            );

            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$activePlan Tier Account",
                      style: const TextStyle(
                        color: brandMaroon,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              drawer: const AdminDrawer(currentPage: 'Dashboard'),

              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCard(
                      "Total Bookings",
                      totalBookings.toString(),
                      bookingIncrementStr,
                      Icons.calendar_today,
                      Colors.blue.shade100,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      "Today's Occupancy",
                      "$occupancyRate%",
                      "$availableSlots slots still available",
                      Icons.check_circle_outline,
                      Colors.green.shade100,
                      Colors.green,
                    ),
                    _buildStatCard(
                      "Revenue ($currentMonthStr)",
                      "RM ${thisMonthRevenue.toStringAsFixed(2)}",
                      revenueIncrementStr,
                      Icons.attach_money,
                      Colors.purple.shade100,
                      Colors.purple,
                    ),

                    Stack(
                      children: [
                        _buildStatCard(
                          "Active Platform Users",
                          activeUsersThisWeek.length.toString(),
                          "Users booked in the last 7 days",
                          Icons.people_outline,
                          Colors.orange.shade100,
                          Colors.orange,
                        ),
                        if (!supportMarketingDashboard)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: () => _showUpgradeWall(
                                context,
                                "Premium",
                                "Advanced Marketing Analytics",
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_rounded,
                                        color: Colors.amber.shade900,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Unlock with Premium Plan",
                                        style: TextStyle(
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (todaysScheduleList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            "No bookings scheduled for today.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...todaysScheduleList.map((schedule) {
                        String statusStr = schedule['status']
                            .toString()
                            .toLowerCase();
                        Color statColor = Colors.blue;
                        if (statusStr == 'completed') statColor = Colors.blue;
                        if (statusStr == 'active' || statusStr == 'confirmed')
                          statColor = Colors.green;
                        if (statusStr == 'cancelled') statColor = Colors.red;

                        return _scheduleItem(
                          schedule['time'],
                          schedule['details'],
                          statusStr.isNotEmpty
                              ? '${statusStr[0].toUpperCase()}${statusStr.substring(1)}'
                              : 'Unknown',
                          statColor,
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      },
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
              if (sub.contains('+') ||
                  sub.contains('available') ||
                  sub.contains('Users'))
                const Icon(Icons.trending_up, color: Colors.green, size: 20)
              else if (sub.contains('-'))
                const Icon(Icons.trending_down, color: Colors.red, size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            sub,
            style: TextStyle(
              color: sub.contains('-') && !sub.contains('available')
                  ? Colors.red
                  : Colors.green,
              fontSize: 12,
            ),
          ),
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

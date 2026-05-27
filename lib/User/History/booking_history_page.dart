import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookapong_app/User/Access%20Code/access_code_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final Color darkRed = const Color(0xFF800020);
  final Color beige = const Color(0xFFFDF8F0);
  final Color greyBorder = const Color(0xFFE0E0E0);

  String selectedTab = "All";
  final List<String> tabs = ["All", "Active", "Completed", "Cancelled"];

  /// Fetches all user bookings in real time. Filtering is applied locally
  /// to ensure perfect structural consistency with the Admin Dashboard.
  Query<Map<String, dynamic>> _getBaseQuery(String uid) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid);
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId =
        FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user";

    return Scaffold(
      backgroundColor: beige,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// HEADER
          SliverAppBar(
            backgroundColor: beige,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: false,
            pinned: false,
            snap: false,
            automaticallyImplyLeading: false,
            toolbarHeight: 70,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: darkRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  "History",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          /// TABS HEADER
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              height: 65,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: tabs.length,
                itemBuilder: (context, index) {
                  bool isActive = selectedTab == tabs[index];
                  return GestureDetector(
                    onTap: () => setState(() {
                      selectedTab = tabs[index];
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isActive ? darkRed : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isActive ? darkRed : greyBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// LIVE FIREBASE STREAM PIPELINE
          StreamBuilder<QuerySnapshot>(
            stream: _getBaseQuery(currentUserId).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        "Failed to load records: ${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: darkRed),
                    ),
                  ),
                );
              }

              final rawDocs = snapshot.data?.docs ?? [];
              final DateTime now = DateTime.now();
              List<DocumentSnapshot> filteredDocs = [];

              // Evaluate the status exactly how the Admin model does it
              for (var doc in rawDocs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final String baseStatus = data['status'] ?? 'confirmed';
                final Timestamp? endTimestamp = data['endTime'] as Timestamp?;

                final DateTime endTimeObj = endTimestamp != null
                    ? endTimestamp.toDate()
                    : now;

                final DateTime accessClosingTime = endTimeObj.add(
                  const Duration(minutes: 5),
                );

                String computedStatus = "Completed";
                if (baseStatus == "cancelled") {
                  computedStatus = "Cancelled";
                } else if (now.isBefore(accessClosingTime)) {
                  computedStatus = "Active";
                }

                // Filter matching tabs locally
                if (selectedTab == "All" || selectedTab == computedStatus) {
                  filteredDocs.add(doc);
                }
              }

              // Absolute chronological sorting: Newest show up first
              filteredDocs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>? ?? {};
                final bData = b.data() as Map<String, dynamic>? ?? {};

                final Timestamp aTime = aData['startTime'] ?? Timestamp.now();
                final Timestamp bTime = bData['startTime'] ?? Timestamp.now();
                return bTime.compareTo(aTime);
              });

              if (filteredDocs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        "No matching bookings found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildBookingCard(doc.id, data);
                  }, childCount: filteredDocs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(String docId, Map<String, dynamic> data) {
    final String baseStatus = data['status'] ?? 'confirmed';
    final Timestamp? endTimestamp = data['endTime'] as Timestamp?;
    final DateTime now = DateTime.now();

    final DateTime endTimeObj = endTimestamp != null
        ? endTimestamp.toDate()
        : now;

    final DateTime accessClosingTime = endTimeObj.add(
      const Duration(minutes: 5),
    );

    String calculatedDisplayStatus = "Completed";
    if (baseStatus == "cancelled") {
      calculatedDisplayStatus = "Cancelled";
    } else if (now.isBefore(accessClosingTime)) {
      calculatedDisplayStatus = "Active";
    }

    bool displayActiveActions = calculatedDisplayStatus == "Active";
    final DateTime startTimeObj = (data['startTime'] as Timestamp).toDate();

    final String formattedDate = DateFormat(
      'MMM dd, yyyy',
    ).format(startTimeObj);
    final String formattedTime =
        "${DateFormat('hh:mm a').format(startTimeObj)} - ${DateFormat('hh:mm a').format(endTimeObj)}";
    final String displayAmount =
        "RM ${data['amountPaid']?.toStringAsFixed(2) ?? '27.00'}";

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Booking ID",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    docId.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(calculatedDisplayStatus),
            ],
          ),
          const SizedBox(height: 15),
          Divider(color: greyBorder),
          const SizedBox(height: 15),
          _buildInfoRow(
            Icons.calendar_today_outlined,
            "Court & Date",
            "${data['facilityName']} • $formattedDate",
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, "Time Slot", formattedTime),
          const SizedBox(height: 15),
          Divider(color: greyBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Amount Paid",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              Text(
                displayAmount,
                style: TextStyle(
                  color: darkRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (displayActiveActions) ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccessCodePage(
                            accessCode: data['accessCode'] ?? "0000",
                            court: "${data['facilityName']} - ${data['table']}",
                            date: formattedDate,
                            time: formattedTime,
                            reference: docId.substring(0, 8).toUpperCase(),
                            bookingStartTime: startTimeObj,
                            bookingEndTime: endTimeObj,
                            bookingDocId: docId,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "View Code",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: greyBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(docId)
                          .update({'status': 'cancelled'});
                    },
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor = Colors.blue;
    if (status == "Active") badgeColor = Colors.green;
    if (status == "Cancelled") badgeColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: darkRed.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: darkRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

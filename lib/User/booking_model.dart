import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- 1. Data Model (Updated with Payment Time) ---
class Booking {
  final String id;
  final String customerName;
  final String courtNumber;
  final String date;
  final String time;
  final String slot;
  final double amountPaid;
  final String totalPrice;
  final String paymentTime; // NEW: Added field for when payment was made
  final String note;
  final String accessCode;
  final String status;
  final DateTime? rawEndTime;

  Booking({
    required this.id,
    required this.customerName,
    required this.courtNumber,
    required this.date,
    required this.time,
    required this.slot,
    required this.amountPaid,
    required this.totalPrice,
    required this.paymentTime, // NEW
    required this.note,
    required this.accessCode,
    required this.status,
    this.rawEndTime,
  });

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String formattedDate = "Pending";
    String formattedTime = "Pending";
    DateTime? endTimeObj;

    if (data['startTime'] != null && data['startTime'] is Timestamp) {
      final DateTime start = (data['startTime'] as Timestamp).toDate();
      formattedDate = DateFormat('yyyy-MM-dd').format(start);

      if (data['endTime'] != null && data['endTime'] is Timestamp) {
        endTimeObj = (data['endTime'] as Timestamp).toDate();
        formattedTime =
            "${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(endTimeObj)}";
      } else {
        formattedTime = DateFormat('hh:mm a').format(start);
      }
    }

    // --- Format "Created At" (Payment Time) ---
    String formattedPaymentTime = "Unknown";
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      final DateTime createdTime = (data['createdAt'] as Timestamp).toDate();
      // Example format: "12 May, 02:30 PM"
      formattedPaymentTime = DateFormat('dd MMM, hh:mm a').format(createdTime);
    }

    // --- Backend Status Logic ---
    final DateTime now = DateTime.now();
    final String baseStatus = (data['status'] ?? 'confirmed')
        .toString()
        .toLowerCase();

    String derivedStatus;

    if (baseStatus == 'cancelled') {
      derivedStatus = "Cancelled";
    } else if (baseStatus == 'pending') {
      derivedStatus = "Pending";
    } else if (baseStatus == 'completed') {
      derivedStatus = "Completed";
    } else if (baseStatus == 'confirmed') {
      final DateTime accessClosingTime = endTimeObj != null
          ? endTimeObj.add(const Duration(minutes: 5))
          : now;

      if (now.isBefore(accessClosingTime)) {
        derivedStatus = "Active";
      } else {
        derivedStatus = "Completed";
      }
    } else {
      derivedStatus = baseStatus.isNotEmpty
          ? '${baseStatus[0].toUpperCase()}${baseStatus.substring(1)}'
          : "Unknown";
    }

    // Parse numeric amount safely
    double rawAmount = 0.0;
    if (data['amountPaid'] != null) {
      rawAmount = (data['amountPaid'] as num).toDouble();
    }

    String rawNote = data['note']?.toString().trim() ?? "";
    if (rawNote.isEmpty || rawNote.toLowerCase() == "no requests attached.") {
      rawNote = "None";
    }

    return Booking(
      id: doc.id.toUpperCase(),
      customerName: data['customerName'] ?? data['userId'] ?? "Unknown User",
      courtNumber: data['table'] ?? "Table Pending",
      date: formattedDate,
      time: formattedTime,
      slot: data['duration'] ?? "1 Hour",
      amountPaid: rawAmount,
      totalPrice: "RM ${rawAmount.toStringAsFixed(2)}",
      paymentTime: formattedPaymentTime, // NEW: Assign the formatted time
      note: rawNote,
      accessCode: data['accessCode'] ?? "----",
      status: derivedStatus,
      rawEndTime: endTimeObj,
    );
  }
}

// --- 2. Admin Payments Page ---
class AdminPaymentsPage extends StatelessWidget {
  const AdminPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);
    final String currentAdminId =
        FirebaseAuth.instance.currentUser?.uid ?? "unknown_admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Payment Management",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Center(
            child: Text(
              "Admin\nUser",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          SizedBox(width: 10),
          Padding(
            padding: EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: brandMaroon,
              child: Text("A", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('facilityId', isEqualTo: currentAdminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandMaroon),
            );
          }

          double totalRevenue = 0.0;
          double pendingRevenue = 0.0;
          List<Booking> paymentRecords = [];

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              Booking booking = Booking.fromDoc(doc);
              paymentRecords.add(booking);

              if (booking.status == 'Active' || booking.status == 'Completed') {
                totalRevenue += booking.amountPaid;
              } else if (booking.status == 'Pending') {
                pendingRevenue += booking.amountPaid;
              }
            }
          }

          // Sort by date (newest first)
          paymentRecords.sort((a, b) => b.date.compareTo(a.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildMiniStat(
                      "Total Revenue",
                      "RM ${totalRevenue.toStringAsFixed(2)}",
                      Colors.green,
                    ),
                    const SizedBox(width: 10),
                    _buildMiniStat(
                      "Pending",
                      "RM ${pendingRevenue.toStringAsFixed(2)}",
                      Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  "Recent Transactions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Wrap DataTable inside a scrollable container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: paymentRecords.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(30.0),
                          child: Center(
                            child: Text(
                              "No transactions found.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              const Color(0xFFFDF7E7),
                            ),
                            columnSpacing: 25,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Booking ID",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Paid On",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ), // NEW
                              DataColumn(
                                label: Text(
                                  "Booking Date",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Customer",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Amount",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Status",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            rows: paymentRecords
                                .map((booking) => _buildDataRow(booking))
                                .toList(),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStat(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(Booking booking) {
    Color statusColor = Colors.blue;
    if (booking.status == "Active" || booking.status == "Completed") {
      statusColor = Colors.green;
    }
    if (booking.status == "Cancelled") statusColor = Colors.red;
    if (booking.status == "Pending") statusColor = Colors.orange;

    return DataRow(
      cells: [
        DataCell(
          Text(
            booking.id.length > 8 ? booking.id.substring(0, 8) : booking.id,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          Text(
            booking.paymentTime, // NEW: Displays formatted timestamp
            style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
          ),
        ),
        DataCell(Text(booking.date, style: const TextStyle(fontSize: 13))),
        DataCell(
          SizedBox(
            width: 100,
            child: Text(
              booking.customerName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            booking.totalPrice,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              booking.status.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'dart:math';
import 'package:bookapong_app/Admin/admin_drawer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// --- 1. Data Model ---
class Booking {
  final String id;
  final String customerName;
  final String courtNumber;
  final String date;
  final String time;
  final String slot;
  final double amountPaid;
  final String totalPrice;
  final String paymentTime;
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
    required this.paymentTime,
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

    String formattedPaymentTime = "Unknown";
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      final DateTime createdTime = (data['createdAt'] as Timestamp).toDate();
      formattedPaymentTime = DateFormat('dd MMM, hh:mm a').format(createdTime);
    }

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
      paymentTime: formattedPaymentTime,
      note: rawNote,
      accessCode: data['accessCode'] ?? "----",
      status: derivedStatus,
      rawEndTime: endTimeObj,
    );
  }
}

// --- 2. Flexible Admin Payments Page ---
class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  static const Color brandMaroon = Color(0xFF8B0000);

  String searchQuery = "";
  String selectedCategory = "Booking ID";

  final TextEditingController _searchController = TextEditingController();
  late Stream<QuerySnapshot> _bookingsStream;

  final List<String> categories = [
    "Booking ID",
    "Paid On",
    "Booking Date",
    "Customer",
    "Status",
  ];

  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(110), // Booking ID
    1: FixedColumnWidth(130), // Paid On
    2: FixedColumnWidth(110), // Booking Date
    3: FixedColumnWidth(160), // Customer Name
    4: FixedColumnWidth(100), // Amount
    5: FixedColumnWidth(110), // Status
  };

  @override
  void initState() {
    super.initState();
    final String currentAdminId =
        FirebaseAuth.instance.currentUser?.uid ?? "unknown_admin";

    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('facilityId', isEqualTo: currentAdminId)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> _applyLiveFiltering(List<Booking> incomingList) {
    incomingList.sort((a, b) => b.date.compareTo(a.date));
    if (searchQuery.isEmpty) return incomingList;

    return incomingList.where((booking) {
      String fieldToSearch = "";
      switch (selectedCategory) {
        case "Booking ID":
          fieldToSearch = booking.id;
          break;
        case "Paid On":
          fieldToSearch = booking.paymentTime;
          break;
        case "Booking Date":
          fieldToSearch = booking.date;
          break;
        case "Customer":
          fieldToSearch = booking.customerName;
          break;
        case "Status":
          fieldToSearch = booking.status;
          break;
      }
      return fieldToSearch.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        // The actions array containing the profile pic and admin text has been removed.
      ),

      // INJECTED DRAWER
      drawer: const AdminDrawer(currentPage: 'Payments'),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: brandMaroon),
              );
            }

            final parsedBookings = snapshot.data!.docs
                .map((d) => Booking.fromDoc(d))
                .toList();

            final filteredBookings = _applyLiveFiltering(parsedBookings);

            double totalRevenue = 0.0;
            double pendingRevenue = 0.0;

            for (var booking in filteredBookings) {
              if (booking.status == 'Active' || booking.status == 'Completed') {
                totalRevenue += booking.amountPaid;
              } else if (booking.status == 'Pending') {
                pendingRevenue += booking.amountPaid;
              }
            }

            return Column(
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => searchQuery = value.trim()),
                        decoration: InputDecoration(
                          hintText: "Search by $selectedCategory...",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: brandMaroon,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          items: categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) => setState(() {
                            selectedCategory = val ?? selectedCategory;
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: filteredBookings.isEmpty
                        ? const Center(
                            child: Text(
                              "No matching records found.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: SizedBox(
                              width: 750,
                              child: Column(
                                children: [
                                  Container(
                                    color: const Color(0xFFFDF7E7),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                      horizontal: 12,
                                    ),
                                    child: Table(
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      columnWidths: _columnWidths,
                                      children: [
                                        TableRow(
                                          children: [
                                            _buildHeaderCell("Booking ID"),
                                            _buildHeaderCell("Paid On"),
                                            _buildHeaderCell("Booking Date"),
                                            _buildHeaderCell("Customer"),
                                            _buildHeaderCell("Amount"),
                                            _buildHeaderCell("Status"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      physics: const BouncingScrollPhysics(),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Table(
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          columnWidths: _columnWidths,
                                          border: TableBorder(
                                            horizontalInside: BorderSide(
                                              color: Colors.grey.shade100,
                                              width: 1,
                                            ),
                                          ),
                                          children: filteredBookings.map((
                                            booking,
                                          ) {
                                            return TableRow(
                                              children: [
                                                _buildDataCell(
                                                  booking.id.substring(
                                                    0,
                                                    min(8, booking.id.length),
                                                  ),
                                                  isBold: true,
                                                ),
                                                _buildDataCell(
                                                  booking.paymentTime,
                                                  textColor: Colors.blueGrey,
                                                ),
                                                _buildDataCell(booking.date),
                                                _buildDataCell(
                                                  booking.customerName,
                                                  isBold: true,
                                                ),
                                                _buildDataCell(
                                                  booking.totalPrice,
                                                  isBold: true,
                                                ),
                                                _buildStatusBadgeCell(
                                                  booking.status,
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
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

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    bool isBold = false,
    Color textColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: textColor,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusBadgeCell(String status) {
    Color badgeColor = Colors.blue;
    if (status == "Active" || status == "Completed") badgeColor = Colors.green;
    if (status == "Cancelled") badgeColor = Colors.red;
    if (status == "Pending") badgeColor = Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
    );
  }
}

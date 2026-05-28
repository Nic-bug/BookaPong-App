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
  final String totalPrice;
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
    required this.totalPrice,
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

    final DateTime now = DateTime.now();
    final String baseStatus = data['status'] ?? 'confirmed';
    final DateTime accessClosingTime = endTimeObj != null
        ? endTimeObj.add(const Duration(minutes: 5))
        : now;

    String derivedStatus = "Completed";
    if (baseStatus == 'cancelled') {
      derivedStatus = "Cancelled";
    } else if (now.isBefore(accessClosingTime)) {
      derivedStatus = "Active";
    }

    String rawNote = data['note']?.toString().trim() ?? "";
    if (rawNote.isEmpty || rawNote.toLowerCase() == "no requests attached.") {
      rawNote = "None";
    }

    return Booking(
      id: doc.id.toUpperCase(),
      customerName: data['customerName'] ?? "Nicole Mawan",
      courtNumber: data['table'] ?? "Table Pending",
      date: formattedDate,
      time: formattedTime,
      slot: data['duration'] ?? "1 Hour",
      totalPrice: "RM ${data['amountPaid']?.toStringAsFixed(2) ?? '27.00'}",
      note: rawNote,
      accessCode: data['accessCode'] ?? "----",
      status: derivedStatus,
      rawEndTime: endTimeObj,
    );
  }
}

// --- 2. Flexible Admin Booking Page ---
class AdminBookingPage extends StatefulWidget {
  const AdminBookingPage({super.key});

  @override
  State<AdminBookingPage> createState() => _AdminBookingPageState();
}

class _AdminBookingPageState extends State<AdminBookingPage> {
  static const Color brandMaroon = Color(0xFF8B0000);

  String searchQuery = "";
  String selectedCategory = "Booking ID";

  final List<String> categories = [
    "Booking ID",
    "Customer",
    "Court",
    "Date",
    "Access Code",
  ];

  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(110), // Booking ID
    1: FixedColumnWidth(110), // Status
    2: FixedColumnWidth(140), // Customer Name
    3: FixedColumnWidth(90), // Court
    4: FixedColumnWidth(100), // Date
    5: FixedColumnWidth(160), // Time Slot
    6: FixedColumnWidth(70), // Slot duration
    7: FixedColumnWidth(80), // Price
    8: FixedColumnWidth(110), // Access Code
    9: FixedColumnWidth(220), // Note Cell allocation width
  };

  List<Booking> _applyLiveFiltering(List<Booking> incomingList) {
    incomingList.sort((a, b) => b.date.compareTo(a.date));
    if (searchQuery.isEmpty) return incomingList;

    return incomingList.where((booking) {
      String fieldToSearch = "";
      switch (selectedCategory) {
        case "Booking ID":
          fieldToSearch = booking.id;
          break;
        case "Customer":
          fieldToSearch = booking.customerName;
          break;
        case "Court":
          fieldToSearch = booking.courtNumber;
          break;
        case "Date":
          fieldToSearch = booking.date;
          break;
        case "Access Code":
          fieldToSearch = booking.accessCode;
          break;
      }
      return fieldToSearch.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String currentAdminId =
        FirebaseAuth.instance.currentUser?.uid ?? "unknown_admin";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Booking",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      // INJECTED DRAWER
      drawer: const AdminDrawer(currentPage: 'Bookings'),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: "Search by $selectedCategory...",
                      prefixIcon: const Icon(Icons.search, color: brandMaroon),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
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
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) => setState(
                        () => selectedCategory = val ?? selectedCategory,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Dynamic Table Engine ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('facilityId', isEqualTo: currentAdminId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return Center(child: Text("Error: ${snapshot.error}"));
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: brandMaroon),
                      );
                    }

                    final parsed = snapshot.data!.docs
                        .map((d) => Booking.fromDoc(d))
                        .toList();
                    final filteredBookings = _applyLiveFiltering(parsed);

                    if (filteredBookings.isEmpty) {
                      return const Center(
                        child: Text(
                          "No matching records found.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: SizedBox(
                        width: 1180,
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
                                      _buildHeaderCell("Status"),
                                      _buildHeaderCell("Customer"),
                                      _buildHeaderCell("Court"),
                                      _buildHeaderCell("Date"),
                                      _buildHeaderCell("Time Slot"),
                                      _buildHeaderCell("Slot"),
                                      _buildHeaderCell("Price"),
                                      _buildHeaderCell("Access Code"),
                                      _buildHeaderCell("Additional Note"),
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
                                        TableCellVerticalAlignment.top,
                                    columnWidths: _columnWidths,
                                    border: TableBorder(
                                      horizontalInside: BorderSide(
                                        color: Colors.grey.shade100,
                                        width: 1,
                                      ),
                                    ),
                                    children: filteredBookings.map((booking) {
                                      return TableRow(
                                        children: [
                                          _buildDataCell(
                                            booking.id.substring(
                                              0,
                                              min(8, booking.id.length),
                                            ),
                                            isBold: true,
                                          ),
                                          _buildStatusBadgeCell(booking.status),
                                          _buildDataCell(
                                            booking.customerName,
                                            isBold: true,
                                          ),
                                          _buildDataCell(booking.courtNumber),
                                          _buildDataCell(booking.date),
                                          _buildDataCell(booking.time),
                                          _buildDataCell(booking.slot),
                                          _buildDataCell(booking.totalPrice),
                                          _buildDataCell(
                                            booking.accessCode,
                                            isBold: true,
                                            textColor: brandMaroon,
                                          ),
                                          NoteCellWidget(note: booking.note),
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
                    );
                  },
                ),
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
    if (status == "Active") badgeColor = Colors.green;
    if (status == "Cancelled") badgeColor = Colors.red;

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
            status,
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

// --- 3. Isolated State Note Cell Component ---
class NoteCellWidget extends StatefulWidget {
  final String note;
  const NoteCellWidget({super.key, required this.note});

  @override
  State<NoteCellWidget> createState() => _NoteCellWidgetState();
}

class _NoteCellWidgetState extends State<NoteCellWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List<String> words = widget.note.split(RegExp(r'\s+'));
    final bool isLongNote = words.length > 3;

    String displayText = widget.note;

    if (isLongNote) {
      if (!isExpanded) {
        displayText = "${words.take(3).join(' ')}... ";
      } else {
        List<String> formattedLines = [];
        for (int i = 0; i < words.length; i += 4) {
          int end = (i + 4 < words.length) ? i + 4 : words.length;
          formattedLines.add(words.sublist(i, end).join(' '));
        }
        displayText = "${formattedLines.join('\n')} ";
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      child: isLongNote
          ? InkWell(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: Text.rich(
                    TextSpan(
                      text: displayText,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    softWrap: true,
                  ),
                ),
              ),
            )
          : Text(
              widget.note,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
    );
  }
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bookapong_app/User/Payment/payment_status_page.dart';
import 'package:bookapong_app/services/payment_navigation_store.dart';

class BookingSummaryPage extends StatefulWidget {
  final String facilityId;
  final String facilityName;
  final Map<String, String> date;
  final String time;
  final String table;
  final String slotId;

  const BookingSummaryPage({
    super.key,
    required this.facilityId,
    required this.facilityName,
    required this.date,
    required this.time,
    required this.table,
    required this.slotId,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  final TextEditingController noteController = TextEditingController();

  final Color darkRed = const Color(0xFF800020);
  final Color beige = const Color(0xFFFDF8F0);

  final double courtRental = 28.00;
  final double serviceFee = 2.00;
  double get totalAmountUI => courtRental + serviceFee;
  double get actualChargedAmount => 1.00;

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void processBookingConfirmation() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            Center(child: CircularProgressIndicator(color: darkRed)),
      );

      final String uid =
          FirebaseAuth.instance.currentUser?.uid ?? "anonymous_user";
      String customerRealName = "Nicole Mawan";

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (userDoc.exists && userDoc.data()?['name'] != null) {
          customerRealName = userDoc.data()?['name'];
        }
      } catch (e) {
        debugPrint("Failed to load user metadata: $e");
      }

      final timeParts = widget.time.split(' - ');
      final String targetDateStr = widget.date['full']!;
      final DateFormat correctParser = DateFormat("yyyy-MM-dd hh:mm a");

      final DateTime startTimeObj = correctParser.parse(
        "$targetDateStr ${timeParts[0].trim()}",
      );
      final DateTime endTimeObj = correctParser.parse(
        "$targetDateStr ${timeParts[1].trim()}",
      );
      final String generatedCode = (1000 + Random().nextInt(9000)).toString();

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 1. Prepare references
      final DocumentReference dynamicBookingRef = firestore
          .collection('bookings')
          .doc();
      final DocumentReference slotRef = firestore
          .collection('admins')
          .doc(widget.facilityId)
          .collection('courts')
          .doc(widget.table)
          .collection('slots')
          .doc(widget.slotId);

      final FirebaseFunctions functionsInstance = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      );

      final HttpsCallable callable = functionsInstance.httpsCallable(
        'requestToyyibPayLink',
        options: HttpsCallableOptions(limitedUseAppCheckToken: false),
      );

      final result = await callable.call(<String, dynamic>{
        'amount': actualChargedAmount,
        'table': widget.table,
        'dateStr': widget.date['full'],
        'timeStr': widget.time,
        'bookingId': dynamicBookingRef.id,
        'customerName': customerRealName,
      });

      final String gatewayUrl = result.data['url'];

      // 2. Perform atomic batch write operation
      WriteBatch bookingBatch = firestore.batch();

      bookingBatch.set(dynamicBookingRef, {
        'userId': uid,
        'customerName': customerRealName,
        'facilityId': widget.facilityId,
        'facilityName': widget.facilityName,
        'table': widget.table,
        'startTime': Timestamp.fromDate(startTimeObj),
        'endTime': Timestamp.fromDate(endTimeObj),
        'accessCode': generatedCode,
        'amountPaid': totalAmountUI,
        'duration': "1 Hour",
        'note': noteController.text.trim().isEmpty
            ? "No requests attached."
            : noteController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update slot availability instantly
      bookingBatch.update(slotRef, {'isAvailable': false});

      await bookingBatch.commit();

      if (!mounted) return;
      Navigator.pop(context);

      // Save to SharedPreferences BEFORE launching browser
      await PaymentNavigationStore.set(
        bookingRef: dynamicBookingRef.id,
        table: "${widget.facilityName} - ${widget.table}",
        date: "${widget.date['day']}, ${widget.date['full']}",
        time: widget.time,
        amount: "RM ${totalAmountUI.toStringAsFixed(2)}",
        accessCode: generatedCode,
        startTime: startTimeObj,
        endTime: endTimeObj,
      );
      debugPrint('📦 Store saved to SharedPreferences');

      // Launch browser
      final Uri url = Uri.parse(gatewayUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentStatusPage(
            bookingRef: dynamicBookingRef.id,
            table: "${widget.facilityName} - ${widget.table}",
            date: "${widget.date['day']}, ${widget.date['full']}",
            time: widget.time,
            amount: "RM ${totalAmountUI.toStringAsFixed(2)}",
            accessCode: generatedCode,
            startTime: startTimeObj,
            endTime: endTimeObj,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: darkRed, content: Text("System drop: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          bottom: 30,
        ),
        child: Column(
          children: [
            // Custom App Bar Row
            Row(
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
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 40.0),
                      child: Text(
                        "Booking Summary",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Venue Details Card
            buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Venue Details",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 15),
                  infoRow(
                    Icons.business,
                    "Center Name",
                    widget.facilityName,
                    darkRed,
                  ),
                  const SizedBox(height: 15),
                  infoRow(
                    Icons.location_on,
                    "Court / Table Allocation",
                    widget.table,
                    darkRed,
                  ),
                  const SizedBox(height: 15),
                  infoRow(
                    Icons.calendar_today,
                    "Date",
                    "${widget.date['day'] ?? ''}, ${widget.date['full'] ?? ''}",
                    darkRed,
                  ),
                  const SizedBox(height: 15),
                  infoRow(
                    Icons.access_time,
                    "Time Slot",
                    widget.time,
                    darkRed,
                    sub: "1 hour session",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Price Details Card
            buildCard(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Price Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  priceRow(
                    "Court rental (1 hour)",
                    "RM ${courtRental.toStringAsFixed(2)}",
                    darkRed,
                  ),
                  priceRow(
                    "Service fee",
                    "RM ${serviceFee.toStringAsFixed(2)}",
                    darkRed,
                  ),
                  const Divider(height: 30),
                  priceRow(
                    "Total Amount",
                    "RM ${totalAmountUI.toStringAsFixed(2)}",
                    darkRed,
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Additional Notes Card
            buildCard(
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Additional Notes (Optional)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: "Add any special requests...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: beige.withAlpha(128),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: processBookingConfirmation,
                child: const Text(
                  "Proceed to FPX Payment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: child,
    );
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
    Color iconColor, {
    String? sub,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget priceRow(
    String left,
    String right,
    Color totalColor, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? totalColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

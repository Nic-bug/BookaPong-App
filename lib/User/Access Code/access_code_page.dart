import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AccessCodePage extends StatefulWidget {
  final String accessCode;
  final String court;
  final String date;
  final String time;
  final String reference;
  final DateTime bookingStartTime;
  final DateTime bookingEndTime;
  final String? bookingDocId; // Optional link to document for explicit updates

  const AccessCodePage({
    super.key,
    required this.accessCode,
    required this.court,
    required this.date,
    required this.time,
    required this.reference,
    required this.bookingStartTime,
    required this.bookingEndTime,
    this.bookingDocId,
  });

  @override
  State<AccessCodePage> createState() => _AccessCodePageState();
}

class _AccessCodePageState extends State<AccessCodePage> {
  late Timer _realtimeSyncTimer;
  bool _isCodeAccessible = false;
  bool _hasUpdatedBackendCompletion = false;
  String _timeStatusMessage = "Calculating time constraints...";

  @override
  void initState() {
    super.initState();
    _evaluateAccessWindowConstraints();
    _realtimeSyncTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _evaluateAccessWindowConstraints();
    });
  }

  @override
  void dispose() {
    _realtimeSyncTimer.cancel();
    super.dispose();
  }

  void _evaluateAccessWindowConstraints() {
    final now = DateTime.now();

    // Window rule definitions
    final DateTime accessOpeningTime = widget.bookingStartTime.subtract(
      const Duration(minutes: 10),
    );
    final DateTime accessClosingTime = widget.bookingEndTime.add(
      const Duration(minutes: 5),
    );

    if (now.isBefore(accessOpeningTime)) {
      final difference = accessOpeningTime.difference(now);
      setState(() {
        _isCodeAccessible = false;
        _timeStatusMessage =
            "Unlocks in: ${difference.inMinutes}m ${difference.inSeconds % 60}s";
      });
    } else if (now.isAfter(accessClosingTime)) {
      setState(() {
        _isCodeAccessible = false;
        _timeStatusMessage = "Booking expired. Keypad code deactivated.";
      });

      // Synchronize back to database source if valid document reference exists
      if (widget.bookingDocId != null && !_hasUpdatedBackendCompletion) {
        _hasUpdatedBackendCompletion = true;
        _updateStatusToCompletedInBackend();
      }
    } else {
      final activeRemaining = accessClosingTime.difference(now);
      setState(() {
        _isCodeAccessible = true;
        _timeStatusMessage =
            "Active: Code expires in ${activeRemaining.inMinutes}m ${activeRemaining.inSeconds % 60}s";
      });
    }
  }

  Future<void> _updateStatusToCompletedInBackend() async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingDocId)
          .update({'status': 'completed'});
      debugPrint("Booking session explicit state marked completed in backend.");
    } catch (e) {
      debugPrint("Failed to automatically synchronize completed status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkRed = Color(0xFF800020);
    const Color beige = Color(0xFFFDF8F0);

    return Scaffold(
      backgroundColor: beige,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20.0,
          right: 20.0,
          bottom: 30.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Access Code",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// 1. Timer / Dynamic Windows Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isCodeAccessible ? Colors.green.shade800 : darkRed,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCodeAccessible
                            ? "Access Token Active"
                            : "Access Token Locked / Expired",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _timeStatusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            /// 2. Code Frame Container with visibility guard
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: _isCodeAccessible
                  ? Column(
                      children: [
                        const Text(
                          "Your Keypad Access Code",
                          style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.accessCode.split('').join('  '),
                              style: const TextStyle(
                                color: darkRed,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.accessCode),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Code copied to clipboard"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateTime.now().isAfter(widget.bookingEndTime)
                              ? "This booking is complete. The access window has closed."
                              : "Access code hidden until 10 mins before slot.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: "How to Use",
              child: Column(
                children: [
                  _buildStep(
                    1,
                    "Arrive at the arena at your scheduled time",
                    darkRed,
                  ),
                  _buildStep(
                    2,
                    "Locate the keypad at your assigned court",
                    darkRed,
                  ),
                  _buildStep(
                    3,
                    "Enter the 4-digit access code shown above",
                    darkRed,
                  ),
                  _buildStep(
                    4,
                    "The door will unlock; enjoy your session!",
                    darkRed,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: "Booking Details",
              child: Column(
                children: [
                  _buildDetailRow("Court", widget.court),
                  _buildDetailRow("Date", widget.date),
                  _buildDetailRow("Time", widget.time),
                  _buildDetailRow("Reference", widget.reference),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: "Important: ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                        children: [
                          TextSpan(
                            text:
                                "This access code is only valid during your booking window framework. Please arrive on time.",
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // ✅ Clean stack unwinding: pops back down to the very first route in history (HomePage)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  "Back to Home",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: themeColor,
            child: Text(
              "$number",
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:app_links/app_links.dart';
import 'package:bookapong_app/User/Access%20Code/access_code_page.dart';
import 'package:bookapong_app/User/Payment/payment_fail_page.dart';

class PaymentStatusPage extends StatefulWidget {
  final String bookingRef;
  final String table;
  final String date;
  final String time;
  final String amount;
  final String accessCode;
  final DateTime startTime;
  final DateTime endTime;

  const PaymentStatusPage({
    super.key,
    required this.bookingRef,
    required this.table,
    required this.date,
    required this.time,
    required this.amount,
    required this.accessCode,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage>
    with WidgetsBindingObserver {
  late ConfettiController _confettiController;
  bool _hasPlayedConfetti = false;
  StreamSubscription? _deepLinkSub;
  Timer? _timeoutTimer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Replace your _deepLinkSub listener with this:
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      if (uri.host == 'payment-callback' && mounted) {
        // Force a UI refresh — Firestore stream will pick up the confirmed status
        setState(() {
          _timedOut = false; // reset timeout if they came back
        });
      }
    });

    // Timeout fallback after 5 minutes
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && !_hasPlayedConfetti) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deepLinkSub?.cancel();
    _timeoutTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkRed = Color(0xFF800020);

    return Scaffold(
      backgroundColor:
          Colors.white, // Match the subscription successful background
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildWaitingState(darkRed);
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status = data['status'] ?? 'pending';

          // FAILED
          if (status == 'failed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentFailPage(
                    bookingRef: widget.bookingRef,
                    table: widget.table,
                    date: widget.date,
                    time: widget.time,
                    amount: widget.amount,
                    errorMessage:
                        data['failReason'] ??
                        "Transaction declined by card issuer.",
                  ),
                ),
              );
            });
            return const SizedBox.shrink();
          }

          // CONFIRMED
          if (status == 'confirmed') {
            if (!_hasPlayedConfetti) {
              _hasPlayedConfetti = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _confettiController.play();
              });
            }
            return _buildSuccessUI(darkRed);
          }

          // PENDING
          return _buildWaitingState(darkRed);
        },
      ),
    );
  }

  Widget _buildWaitingState(Color loaderColor) {
    if (_timedOut) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_bottom,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 20),
              const Text(
                "Still waiting...",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your payment may still be processing. Check your email or contact support if the issue persists.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: loaderColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                ),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: loaderColor, strokeWidth: 3),
            const SizedBox(height: 30),
            const Text(
              "Awaiting Payment Confirmation...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Complete your payment in the browser, then return here. Do not close this screen.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// NEW DESIGN: Formatted to match the Subscription Success card interface exactly
  Widget _buildSuccessUI(Color actionColor) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti Canvas Layer
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple,
          ],
        ),

        // Centered Content Card Architecture
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF8BC34A),
                    child: Icon(Icons.check, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Payment succeeded!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Thank you for processing your booking payment of ${widget.amount}. Your slot for ${widget.table} on ${widget.date} is confirmed.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 30),

                  // Action button styled like subscription dashboard redirection
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF2D2D2D,
                        ), // Matches dark button aesthetic
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AccessCodePage(
                              accessCode: widget.accessCode,
                              court: widget.table,
                              date: widget.date,
                              time: widget.time,
                              reference: widget.bookingRef,
                              bookingStartTime: widget.startTime,
                              bookingEndTime: widget.endTime,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        "View Access Code",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

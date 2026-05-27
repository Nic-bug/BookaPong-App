import 'package:flutter/material.dart';

class PaymentFailPage extends StatelessWidget {
  final String bookingRef;
  final String table;
  final String date;
  final String time;
  final String amount;
  final String errorMessage;

  const PaymentFailPage({
    super.key,
    required this.bookingRef,
    required this.table,
    required this.date,
    required this.time,
    required this.amount,
    this.errorMessage = "Your transaction could not be processed.",
  });

  @override
  Widget build(BuildContext context) {
    const Color darkRed = Color(0xFF800020);
    const Color errorRed = Color(0xFFD32F2F);
    const Color beige = Color(0xFFFDF8F0);

    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),
          child: Column(
            children: [
              /// FAIL ICON DESIGN
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: const BoxDecoration(
                    color: errorRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons
                        .priority_high_rounded, // Using exclamation for attention
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Payment Failed",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),

              const SizedBox(height: 35),

              /// INFO CARD (Mirrors your existing summary style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Booking Reference",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookingRef,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(),
                    ),
                    _buildRow("Court", table),
                    _buildRow("Date", date),
                    _buildRow("Time", time),
                    const SizedBox(height: 10),
                    _buildRow(
                      "Amount to Pay",
                      amount,
                      isAmount: true,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              /// TRY AGAIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    // Simply go back to the Summary page to try again
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Try Payment Again",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// BACK TO HOME BUTTON
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    "Cancel and Back to Home",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Need help? Contact support",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String left,
    String right, {
    bool isAmount = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Text(
            right,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isAmount ? 16 : 14,
              color: isAmount ? color : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

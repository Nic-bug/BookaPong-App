import 'package:flutter/material.dart';

class SubscriptionFailPage extends StatelessWidget {
  const SubscriptionFailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
                // Error Icon
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFFE57373), // Soft red
                  child: Icon(Icons.close, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Payment Failed",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Description
                const Text(
                  "Something went wrong while processing your payment. Please check your card details or try a different payment method.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Action Buttons
                Column(
                  children: [
                    // Try Again Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Go back to the payment page
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Try Again",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cancel/Go Back Text Button
                    TextButton(
                      onPressed: () {
                        // Navigate back to the dashboard or previous main screen
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text(
                        "Cancel Payment",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

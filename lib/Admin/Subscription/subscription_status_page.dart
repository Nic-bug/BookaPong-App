import 'dart:async';
import 'package:bookapong_app/Admin/Dashboard/admin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';

class SubscriptionStatusPage extends StatefulWidget {
  final String adminId;

  const SubscriptionStatusPage({super.key, required this.adminId});

  @override
  State<SubscriptionStatusPage> createState() => _SubscriptionStatusPageState();
}

class _SubscriptionStatusPageState extends State<SubscriptionStatusPage> {
  StreamSubscription? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    _deepLinkSub = AppLinks().uriLinkStream.listen((uri) {
      if (uri.host == 'payment-callback' && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admins')
            .doc(widget.adminId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildLoader(
              "Initializing platform workspace...",
              brandMaroon,
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String status = data['subscriptionStatus'] ?? 'pending';

          if (status == 'failed') {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    "Payment Dropped",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Return to Plans"),
                  ),
                ],
              ),
            );
          }

          if (status == 'active' || status == 'confirmed') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardPage(),
                ),
              );
            });
            return const SizedBox.shrink();
          }

          return _buildLoader(
            "Verifying payment transaction via FPX security gateway...",
            brandMaroon,
          );
        },
      ),
    );
  }

  Widget _buildLoader(String statusMsg, Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: color, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              statusMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              "Do not close this application window.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

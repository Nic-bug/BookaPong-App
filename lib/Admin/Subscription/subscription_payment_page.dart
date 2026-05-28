import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bookapong_app/services/auth_service.dart';
import 'subscription_status_page.dart';

class SubscriptionPaymentPage extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String centerName;
  final String email;
  final String contactPerson;
  final String phone;
  final String password;

  const SubscriptionPaymentPage({
    super.key,
    required this.plan,
    required this.centerName,
    required this.email,
    required this.contactPerson,
    required this.phone,
    required this.password,
  });

  @override
  State<SubscriptionPaymentPage> createState() =>
      _SubscriptionPaymentPageState();
}

class _SubscriptionPaymentPageState extends State<SubscriptionPaymentPage> {
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  void _processSubscriptionPayment() async {
    setState(() => _isLoading = true);

    try {
      // Extract numeric cost from tier map (e.g., "RM 99" -> 99.0)
      String cleanPrice = widget.plan['price'].toString().replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      double numericAmount = double.tryParse(cleanPrice) ?? 0.0;

      // 1. Write metadata profile matrix to Firestore
      final String adminId = await _authService.registerAdmin(
        email: widget.email,
        password: widget.password,
        centerName: widget.centerName,
        contactPerson: widget.contactPerson,
        phone: widget.phone,
        selectedPlan: widget.plan['name'],
      );

      // 2. Invoke transactional ToyyibPay bridge payload via cloud function
      final FirebaseFunctions functionsInstance = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      );

      final HttpsCallable callable = functionsInstance.httpsCallable(
        'requestToyyibPayLink',
      );
      final result = await callable.call(<String, dynamic>{
        'amount': numericAmount,
        'bookingId': adminId,
        'customerName': widget.contactPerson,
        'paymentType': 'Subscription',
        'planName': widget.plan['name'],
      });

      final String gatewayUrl = result.data['url'];

      if (!mounted) return;

      // 3. Fire up the native web browser routing environment
      final Uri url = Uri.parse(gatewayUrl);
      await launchUrl(url, mode: LaunchMode.externalApplication);

      // 4. Pivot over to real-time sync screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionStatusPage(adminId: adminId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF8B0000),
          content: Text("Gateway routing issue: $e"),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        title: const Text(
          "Plan Checkout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandMaroon))
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Order Details",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "BookaPong ${widget.plan['name']} Setup",
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              widget.plan['price'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Charged",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              widget.plan['price'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: brandMaroon,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandMaroon,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _processSubscriptionPayment,
                      child: const Text(
                        "Proceed to FPX Payment",
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
}

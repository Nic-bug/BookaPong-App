import 'package:flutter/material.dart';
import 'subscription_payment_page.dart';

class SubscriptionPlanPage extends StatefulWidget {
  final String centerName;
  final String email;
  final String contactPerson;
  final String phone;
  final String password;

  const SubscriptionPlanPage({
    super.key,
    required this.centerName,
    required this.email,
    required this.contactPerson,
    required this.phone,
    required this.password,
  });

  @override
  State<SubscriptionPlanPage> createState() => _SubscriptionPlanPageState();
}

class _SubscriptionPlanPageState extends State<SubscriptionPlanPage> {
  late PageController _pageController;
  int _currentPage = 1;

  final List<Map<String, dynamic>> plans = [
    {
      "name": "Standard",
      "price": "RM 49",
      "features": ["Up to 2 Courts", "Basic Analytics", "Email Support"],
    },
    {
      "name": "Business",
      "price": "RM 99",
      "features": [
        "Up to 5 Courts",
        "Real-time Booking",
        "Priority Support",
        "ESP32 Integration",
      ],
    },
    {
      "name": "Premium",
      "price": "RM 199",
      "features": [
        "Unlimited Courts",
        "Full IoT Dashboard",
        "Marketing Tools",
        "24/7 Support",
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    // Centering layout sets focus to the middle card ("Business Plan") by default index allocation
    _pageController = PageController(initialPage: 1, viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Text(
            "Select Your Plan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Setting up registration for \"${widget.centerName}\"",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) => setState(() => _currentPage = page),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                double scale = (_currentPage == index) ? 1.0 : 0.85;
                return _buildPlanCard(plans[index], scale);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, double scale) {
    const Color darkMaroon = Color(0xFF8B0000);

    return Transform.scale(
      scale: scale,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(
                color: darkMaroon,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  Text(
                    plan['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plan['price'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    "/month",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: plan['features'].length,
                itemBuilder: (context, fIndex) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            plan['features'][fIndex],
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkMaroon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubscriptionPaymentPage(
                          plan: plan,
                          centerName: widget.centerName,
                          email: widget.email,
                          contactPerson: widget.contactPerson,
                          phone: widget.phone,
                          password: widget.password,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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

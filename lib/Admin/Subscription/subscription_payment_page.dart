import 'package:flutter/material.dart';
import 'package:bookapong_app/services/auth_service.dart';
import 'package:bookapong_app/Admin/Subscription/subscription_successful_page.dart';
import 'subscription_fail_page.dart';

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

  // Form handling keys and validation controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _processPaymentAndRegistration() async {
    // Trigger validation matrices across inputs before executing auth pipeline
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Execute your unified Firebase registration process service abstraction
      await _authService.registerAdmin(
        email: widget.email,
        password: widget.password,
        centerName: widget.centerName,
        contactPerson: widget.contactPerson,
        phone: widget.phone,
        selectedPlan: widget.plan['name'],
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SubscriptionSuccessfulPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionFailPage()),
        );
      }
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
          "Checkout",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandMaroon))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildSummaryRow(
                            "${widget.plan['name']} Subscription",
                            widget.plan['price'],
                          ),
                          _buildSummaryRow("Processing Fee", "RM 0.00"),
                          const Divider(height: 25),
                          _buildSummaryRow(
                            "Total",
                            widget.plan['price'],
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "Payment Method",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildPaymentMethodTile(
                      "Credit/Debit Card",
                      Icons.credit_card,
                      true,
                    ),
                    _buildPaymentMethodTile(
                      "Online Banking (FPX)",
                      Icons.account_balance,
                      false,
                    ),
                    _buildPaymentMethodTile(
                      "E-Wallet",
                      Icons.account_balance_wallet,
                      false,
                    ),
                    const SizedBox(height: 25),

                    /// Card Details Section
                    const Text(
                      "Card Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildValidatedField(
                      controller: _cardHolderController,
                      label: "Cardholder Name",
                      hint: "John Doe",
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? "Name is required"
                          : null,
                    ),
                    _buildValidatedField(
                      controller: _cardNumberController,
                      label: "Card Number",
                      hint: "1234 5678 9101 1121",
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return "Card number is required";
                        if (val.trim().length < 16)
                          return "Enter a valid 16-digit card number";
                        return null;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildValidatedField(
                            controller: _expiryController,
                            label: "Expiry Date",
                            hint: "MM/YY",
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (!val.contains('/')) return "Use MM/YY";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildValidatedField(
                            controller: _cvcController,
                            label: "CVC / CVV",
                            hint: "123",
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              if (val.trim().length < 3) return "Invalid";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandMaroon,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _processPaymentAndRegistration,
                        child: Text(
                          "Confirm Payment - ${widget.plan['price']}",
                          style: const TextStyle(
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
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 15 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFF8B0000) : Colors.black87,
              ),
            ),
          ],
        ),
      );

  Widget _buildPaymentMethodTile(
    String title,
    IconData icon,
    bool isSelected,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: isSelected ? const Color(0xFF8B0000) : Colors.grey.shade200,
        width: isSelected ? 1.5 : 1,
      ),
    ),
    child: ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF8B0000) : Colors.blueGrey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF8B0000))
          : null,
    ),
  );

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
        ),
      ),
      validator: validator,
    ),
  );
}

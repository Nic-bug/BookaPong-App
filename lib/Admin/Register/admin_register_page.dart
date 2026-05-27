import 'package:flutter/material.dart';
import 'package:bookapong_app/Admin/Subscription/subscription_plan_page.dart';
import 'package:bookapong_app/User/Login%20and%20Register/login_register_page.dart';

class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});

  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _centerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _centerNameController.dispose();
    _emailController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);
    const Color darkBg = Color(0xFF2D2D2D);
    const Color darkRed = Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: darkBg,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(
                      Icons.business_center,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Partner with BookaPong",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Register your center and reach thousands of players today.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Center Name"),
                          _buildTextField(
                            _centerNameController,
                            "e.g. PingPong Pro Arena",
                          ),
                          _buildLabel("Email Address"),
                          _buildTextField(
                            _emailController,
                            "center@example.com",
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildLabel("Contact Person"),
                          _buildTextField(
                            _contactPersonController,
                            "Full Name",
                          ),
                          _buildLabel("Phone Number"),
                          _buildTextField(
                            _phoneController,
                            "+60 1x-xxxxxxx",
                            keyboardType: TextInputType.phone,
                          ),
                          _buildLabel("Password"),
                          _buildTextField(
                            _passwordController,
                            "Enter password",
                            obscureText: true,
                          ),
                          _buildLabel("Confirm Password"),
                          _buildTextField(
                            _confirmPasswordController,
                            "Re-enter password",
                            obscureText: true,
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return "Please confirm your password";
                              if (val != _passwordController.text)
                                return "Passwords do not match";
                              return null;
                            },
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandMaroon,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SubscriptionPlanPage(
                                            centerName: _centerNameController
                                                .text
                                                .trim(),
                                            email: _emailController.text.trim(),
                                            contactPerson:
                                                _contactPersonController.text
                                                    .trim(),
                                            phone: _phoneController.text.trim(),
                                            password: _passwordController.text,
                                          ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                "Proceed",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black,
      ),
    ),
  );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.black87),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFFAF9F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF8B0000), width: 1.5),
      ),
    ),
    validator:
        validator ??
        (value) =>
            (value == null || value.isEmpty) ? 'This field is required' : null,
  );
}

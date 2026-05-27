import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookapong_app/User/Forgot%20Password/forgot_password_page.dart';
import 'package:bookapong_app/Logo/pong_logo.dart';
import 'package:bookapong_app/Splash%20Screen/admin_splash_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String errorMessage = '';
  bool isLoginSelected = true;
  bool isLoading = false;

  final Color beige = const Color(0xFFFDF7E7);
  final Color red = const Color(0xFF800020);
  final Color borderColor = const Color(0xFFD1D9E6);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void submit() async {
    setState(() {
      errorMessage = '';
      isLoading = true;
    });

    final String email = emailController.text.trim();
    final String password = passwordController.text;
    final String name = nameController.text.trim();
    final String confirmPassword = confirmPasswordController.text;

    if (isLoginSelected) {
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = 'Please fill in all fields';
          isLoading = false;
        });
        return;
      }
    } else {
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        setState(() {
          errorMessage = 'Please fill in all fields';
          isLoading = false;
        });
        return;
      }
      if (password != confirmPassword) {
        setState(() {
          errorMessage = 'Passwords do not match';
          isLoading = false;
        });
        return;
      }
    }

    if (!RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email)) {
      setState(() {
        errorMessage = 'Please enter a valid email address.';
        isLoading = false;
      });
      return;
    }

    try {
      if (isLoginSelected) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': name,
              'email': email,
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
      // Navigation is handled automatically by AuthWrapper
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? 'Authentication error.';
      if (e.code == 'user-not-found')
        message = 'No user found with this email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      if (e.code == 'email-already-in-use')
        message = 'This email is already registered.';
      if (e.code == 'weak-password')
        message = 'Password should be at least 6 characters.';

      if (mounted) {
        setState(() {
          errorMessage = message;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'An unexpected error occurred.';
          isLoading = false;
        });
      }
    }
  }

  void switchMode(bool login) {
    if (isLoading) return;
    setState(() {
      isLoginSelected = login;
      errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: red))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          PongLogo(color: red),
                          const SizedBox(height: 15),
                          const Text(
                            'BookaPong',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Expanded(
                          child: _toggleButton(
                            "Login",
                            isLoginSelected,
                            () => switchMode(true),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _toggleButton(
                            "Register",
                            !isLoginSelected,
                            () => switchMode(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    if (!isLoginSelected) ...[
                      _label("Name"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration("Enter your name"),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _label("Email"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Enter your email"),
                    ),
                    const SizedBox(height: 20),
                    _label("Password"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration("Enter your password"),
                    ),
                    if (isLoginSelected) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          ),
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (!isLoginSelected) ...[
                      const SizedBox(height: 20),
                      _label("Confirm Password"),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration("Confirm your password"),
                      ),
                    ],
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isLoginSelected ? "Login" : "Create Account",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (isLoginSelected) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSplashScreen(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(
                                  text: "Interested in partnership? ",
                                ),
                                TextSpan(
                                  text: "Click here",
                                  style: TextStyle(
                                    color: red,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
  );

  Widget _toggleButton(String text, bool selected, VoidCallback onTap) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? red : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selected ? red : borderColor),
          ),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: red, width: 1.5),
      ),
    );
  }
}

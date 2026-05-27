import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bookapong_app/Logo/pong_logo.dart';
// Ensure this path matches your Admin Register page location
import 'package:bookapong_app/Admin/Register/admin_register_page.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation; // Changed to Color animation

  final Color darkBg = const Color(0xFF2D2D2D);
  final Color brandMaroon = const Color(
    0xFF8B0000,
  ); // Your Admin Register color

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 800,
      ), // Slightly slower for a smoother pulse
      vsync: this,
    )..repeat(reverse: true);

    // This creates the "blinking" effect between a muted red and the bright brand maroon
    _colorAnimation = ColorTween(
      begin: const Color(0xFF4A0000), // Very dark/muted red
      end: brandMaroon, // Your target dark red
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminRegisterPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use AnimatedBuilder to rebuild the logo with the new color on every frame
            AnimatedBuilder(
              animation: _colorAnimation,
              builder: (context, child) {
                return PongLogo(color: _colorAnimation.value ?? brandMaroon);
              },
            ),
            const SizedBox(height: 50),
            const Text(
              'BookaPong',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'ADMIN PARTNERSHIP',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

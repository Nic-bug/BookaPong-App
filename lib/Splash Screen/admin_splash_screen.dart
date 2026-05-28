import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bookapong_app/Logo/pong_logo.dart';

class AdminSplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final int durationSeconds;

  const AdminSplashScreen({
    super.key,
    this.onComplete,
    this.durationSeconds = 2,
  });

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  Timer? _timer;

  final Color darkBg = const Color(0xFF2D2D2D);
  final Color brandMaroon = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFF4A0000),
      end: brandMaroon,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.onComplete != null) {
      _timer = Timer(Duration(seconds: widget.durationSeconds), () {
        if (mounted) widget.onComplete!();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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

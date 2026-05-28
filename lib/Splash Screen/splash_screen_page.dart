import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bookapong_app/Logo/pong_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final int durationSeconds;

  const SplashScreen({super.key, this.onComplete, this.durationSeconds = 2});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
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
      backgroundColor: const Color(0xFF8B0000),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _animation,
              child: const PongLogo(color: Colors.white),
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
              'Smart Reservation System',
              style: TextStyle(
                fontSize: 15,
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

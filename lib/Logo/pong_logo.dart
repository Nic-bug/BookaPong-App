import 'package:flutter/material.dart';

class PongLogo extends StatelessWidget {
  final Color color;

  /// ✅ ADD THIS

  const PongLogo({
    super.key,
    this.color = Colors.white,

    /// default (safe)
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// PADDLE HANDLE
          Positioned(
            left: 52,
            bottom: 20,
            child: Container(
              width: 16,
              height: 70,
              decoration: BoxDecoration(
                color: color,

                /// ✅ USE VARIABLE
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
            ),
          ),

          /// PADDLE HEAD
          Positioned(
            top: 25,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: color,

                /// ✅ USE VARIABLE
                shape: BoxShape.circle,
              ),
            ),
          ),

          /// BALL
          Positioned(
            top: 18,
            left: 70,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,

                /// ✅ USE VARIABLE
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:async';
import '../../views/auth-elaf/start_screen.dart';
 // We'll create this next

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to StartScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StartScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191834), // Dark Navy
      body: Stack(
        children: [
          // Logo with gradient in the center
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF604F8E), // Purple center
                    const Color(0xFF191834), // Dark Navy edge
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
          // Waves image at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/waves.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
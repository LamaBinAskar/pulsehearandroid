import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sign_in_screen.dart'; 
import 'sign_up_screen.dart'; 

class StartScreen extends StatelessWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191834), // Dark Navy
      body: Stack(
        children: [
          // Waves image at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer( // تمت إضافة هذا السطر لحل المشكلة
              child: Image.asset(
                'assets/images/waves.png', 
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Logo at the top center
                Image.asset(
                  'assets/images/logo.png', 
                  width: 200,
                  height: 200,
                ),
                const Spacer(),
                // Buttons at the bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F4D78), // Dark Purple
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.sarala(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFEFF0F7), // White
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF0F7), // White
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.sarala(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4F4D78), // Dark Purple
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
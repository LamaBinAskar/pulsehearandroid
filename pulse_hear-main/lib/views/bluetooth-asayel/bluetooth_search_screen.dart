import 'package:flutter/material.dart';

class PairWristbandScreen extends StatefulWidget {
  const PairWristbandScreen({super.key});

  @override
  State<PairWristbandScreen> createState() => _PairWristbandScreenState();
}

class _PairWristbandScreenState extends State<PairWristbandScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Animation controller for glow & pulse effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    // Dispose animation controller to free resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191834),
      extendBodyBehindAppBar: true,

      // Transparent AppBar with back button
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Stack(
        children: [
          // 1. Decorative purple background circles at the bottom
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5A597D).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -150,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5A597D).withOpacity(0.6),
              ),
            ),
          ),

          // 2. Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // Bluetooth icon with glowing pulse animation
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            // Glow effect around the Bluetooth icon
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF5A6CFF)
                                    .withOpacity(0.4 * (1 - _controller.value)),
                                blurRadius: 60,
                                spreadRadius: 20 * _controller.value,
                              ),
                            ],

                            // Pulsing outer ring
                            border: Border.all(
                              color: Colors.white
                                  .withOpacity(1 - _controller.value),
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.bluetooth,
                              size: 120,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Instruction text
                  const Text(
                    'Turn on your Bluetooth connection setting and make sure your Wristband is close to your phone',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.5,
                      
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Pair wristband button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 34, 34, 60),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 15,
                    ),
                    onPressed: () {
                      // TODO: Implement wristband pairing logic
                    },
                    child: const Text(
                      'Pair Wristband',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
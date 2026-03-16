import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_hear/services/ble_audio_service.dart';

class DashboardScreen extends StatefulWidget {
  final BleAudioService service;
  const DashboardScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceChanged);
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF4),
      body: Column(
        children: [
          // 1. Header Section
          Container(
            width: double.infinity,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF1D1B3F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/smallwaves.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 260,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          // 2. Connection Status Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/bluetooth');
              },
              borderRadius: BorderRadius.circular(40),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 63, 61, 91),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: const Color.fromARGB(255, 16, 16, 40),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Image.asset('assets/images/watch.png',
                            width: 110, height: 110),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.white70, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.power_settings_new,
                              color: Colors.white, size: 20),
                        )
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            widget.service.isConnected
                                ? 'Connected (${widget.service.deviceName})'
                                : 'Not Connected',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Your Wristband is ready to alert you',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (!widget.service.isConnected) {
                                widget.service.connectToESP32('PulseHear_v30');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white24),
                              ),
                            ),
                            child: Text(
                              widget.service.isConnected
                                  ? 'Connected'
                                  : 'Connect Wristband',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 3. Last Detection Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 19),
            child: _buildDetectionCard(),
          ),
          const SizedBox(height: 16),
          // 4. Features Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: GridView.count(
                padding: const EdgeInsets.only(top: 0),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildIconCard(
                    'Sound Library',
                    'assets/images/sound_library.png',
                    () => Navigator.pushNamed(context, '/sounds'),
                  ),
                  _buildIconCard(
                    'Keywords',
                    'assets/images/keyword-2 1.png',
                    () => Navigator.pushNamed(context, '/keywords'),
                  ),
                  _buildIconCard(
                    'Speech-To-Text',
                    'assets/images/speech_to_text.png',
                    () => debugPrint("Navigate to Speech-To-Text"),
                  ),
                  _buildIconCard(
                    'Text-To-Speech',
                    'assets/images/text_to_speech.png',
                    () => debugPrint("Navigate to Text-To-Speech"),
                  ),
                  _buildIconCard(
                    'Modes',
                    'assets/images/modes.png',
                    () => debugPrint("Navigate to Modes"),
                  ),
                ],
              ),
            ),
          ),
          // 5. Nav Bar
          Container(
            height: 75,
            margin: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1D1B3F),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.white, size: 28),
                  onPressed: () => debugPrint("Home tapped"),
                ),
                IconButton(
                  icon: const Icon(Icons.contact_phone_rounded,
                      color: Colors.white54, size: 28),
                  onPressed: () => debugPrint("Contacts tapped"),
                ),
                IconButton(
                  icon: const Icon(Icons.settings,
                      color: Colors.white54, size: 28),
                  onPressed: () => debugPrint("Settings tapped"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionCard() {
    final label = widget.service.lastDetectedLabel;
    final isProcessing = widget.service.isProcessing;

    Color cardColor;
    Color textColor = Colors.white;
    String displayText;
    IconData icon;

    if (isProcessing) {
      cardColor   = const Color(0xFF3A3A6A);
      displayText = 'Analyzing sound...';
      icon        = Icons.graphic_eq;
    } else if (label.isEmpty) {
      cardColor   = const Color(0xFF3A3A6A);
      displayText = 'Listening for sounds...';
      icon        = Icons.hearing;
    } else if (label.toUpperCase().contains('FIRE')) {
      cardColor   = const Color(0xFFD32F2F);
      displayText = label;
      icon        = Icons.local_fire_department;
    } else if (label.toUpperCase().contains('BABY')) {
      cardColor   = const Color(0xFFF57C00);
      displayText = label;
      icon        = Icons.child_care;
    } else if (label.toUpperCase().contains('MIXED')) {
      cardColor   = const Color(0xFFF57C00);
      displayText = label;
      icon        = Icons.warning_amber_rounded;
    } else {
      cardColor   = const Color(0xFF1565C0);
      displayText = label;
      icon        = Icons.volume_up;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Detection',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isProcessing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconCard(String title, String imagePath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color.fromARGB(255, 175, 175, 215),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 60, height: 60),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

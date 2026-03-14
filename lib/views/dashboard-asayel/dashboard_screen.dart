import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pulse_hear/views/bluetooth-asayel/bluetooth_search_screen.dart';
import 'package:pulse_hear/views/soundlibrary-asayel/sound_library_screen.dart';
import 'package:pulse_hear/services/ble_audio_service.dart';

class DashboardScreen extends StatefulWidget {
  final BleAudioService service;
  const DashboardScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
                      color: Colors.black.withOpacity(0.3),
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
                                widget.service.connectToESP32('XIAO_ESP32S3');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Colors.white24),
                              ),
                            ),
                            child: Text(
                              widget.service.isConnected ? 'Connected' : 'Connect Wristband',
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
          const SizedBox(height: 20),
          // 3. Features Grid
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
                    () => print("Navigate to Speech-To-Text"),
                  ),
                  _buildIconCard(
                    'Text-To-Speech',
                    'assets/images/text_to_speech.png',
                    () => print("Navigate to Text-To-Speech"),
                  ),
                  _buildIconCard(
                    'Modes',
                    'assets/images/modes.png',
                    () => print("Navigate to Modes"),
                  ),
                ],
              ),
            ),
          ),
          // 4. Nav Bar
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
                  icon:
                      const Icon(Icons.home, color: Colors.white, size: 28),
                  onPressed: () => print("Home tapped"),
                ),
                IconButton(
                  icon: const Icon(Icons.contact_phone_rounded,
                      color: Colors.white54, size: 28),
                  onPressed: () => print("Contacts tapped"),
                ),
                IconButton(
                  icon: const Icon(Icons.settings,
                      color: Colors.white54, size: 28),
                  onPressed: () => print("Settings tapped"),
                ),
              ],
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
              color: Colors.black.withOpacity(0.08),
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

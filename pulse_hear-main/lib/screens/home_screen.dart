import 'package:flutter/material.dart';
import '../services/ble_audio_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleAudioService _service = BleAudioService();
  String _status = 'جاهز للاستماع...';
  String _lastDetection = '';

  @override
  void initState() {
    super.initState();
    // تحديث الواجهة عند تغيير الـ service
    _service.addListener(_updateUI);
  }

  void _updateUI() {
    setState(() {
      _status = _service.isListening ? 'يستمع...' : 'جاهز';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PulseHear'),
        backgroundColor: Color(0xFF71A39E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hearing_outlined,
              size: 120,
              color: Color(0xFF005352),
            ),
            SizedBox(height: 30),
            Text(
              _status,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              _lastDetection.isEmpty ? 'انتظر إشارة من السوار' : _lastDetection,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await _service.onDeviceSignal('adhan_detected');
                setState(() {
                  _lastDetection = 'تم تحليل الصوت بـ YAMNet!';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF005352),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text('اختبار YAMNet (أذان)'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

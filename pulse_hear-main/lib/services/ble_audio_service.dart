import 'package:flutter/material.dart';
import 'yamnet_classifier.dart';

class BleAudioService extends ChangeNotifier {
  final YamnetClassifier yamnet = YamnetClassifier();
  bool isConnected = false;
  String deviceName = '';
  double batteryLevel = 100.0;
  bool isListening = false;

  BleAudioService() {
    init();
  }

  Future<void> init() async {
    await yamnet.init();
    print('✅ BLE Audio Service + YAMNet initialized');
  }

  // ربط مع ESP32S3
  Future<void> connectToESP32(String espName) async {
    isConnected = true;
    deviceName = espName;
    notifyListeners();
    print('🔗 Connected to $espName');
  }

  // استقبال إشارة من السوار
  Future<void> onDeviceSignal(String signal) async {
    print('📡 Received signal: $signal');

    switch (signal) {
      case 'adhan_detected':
      case 'need_deep_analysis':
        await analyzeCurrentAudio();
        break;
      case 'battery_update':
      // تحديث البطارية
        notifyListeners();
        break;
    }
  }

  Future<void> analyzeCurrentAudio() async {
    isListening = true;
    notifyListeners();

    // dummy audio buffer (لاحقًا من just_audio)
    final pcmBytes = Uint8List(31200);

    final result = yamnet.classify(pcmBytes);

    print('🧠 YAMNet: ${result['label']} (${result['confidence']})');

    if (result['label'].toString().toLowerCase().contains('prayer') ||
        result['confidence'] > 0.7) {
      triggerAdhanAlert();
    }

    isListening = false;
    notifyListeners();
  }

  void triggerAdhanAlert() {
    print('🕌 أذان مُكتشف! إشعار + اهتزاز');
    // هنا: local notification + vibration
  }

  void disconnect() {
    isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    yamnet.dispose();
    super.dispose();
  }
}

// ble_audio_service.dart
// PulseHear v29 - iOS Compatible
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'bluetooth_service.dart';
import 'yamnet_classifier.dart';

class BleAudioService extends ChangeNotifier {
  final BluetoothService bleService;
  final YamnetClassifier _yamnet = YamnetClassifier();
  final AudioRecorder _recorder = AudioRecorder();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool isListening = false;
  String lastYamnetLabel = '';
  String lastRecognizedText = '';
  bool _speechInitialized = false;

  List<String> keywords = [
    'ساعدني',
    'نجدة',
    'حريق',
    'ماء',
    'خطر',
    'help',
    'fire',
  ];

    BleAudioService({required this.bleService}) {
          _init();
  }

  // Getters for dashboard_screen.dart compatibility
  bool get isConnected => bleService.isConnected;
  String get deviceName => bleService.deviceName;
  Future<void> connectToESP32(String name) async {
    await bleService.startScan();
    notifyListeners();
  }

  Future<void> _init() async {
    await _yamnet.init();
    await _initNotifications();
    await _initSpeechToText();
    bleService.onSignalReceived = handleBleSignal;
    // Auto-connect to ESP32 on app start — keeps retrying until connected
    bleService.autoConnect();
    debugPrint('[BleAudioService] Initialized');
  }

  Future<void> _initNotifications() async {
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('[Notification] Tapped: ${details.payload}');
      },
    );

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
        debugPrint('[Notification] Android permission requested');
      }
    }

    // طلب إذن الإشعارات على iOS
    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> _initSpeechToText() async {
    try {
      _speechInitialized = await _speechToText.initialize(
        onStatus: (status) => debugPrint('[SpeechToText] Status: $status'),
        onError: (error) => debugPrint('[SpeechToText] Error: $error'),
      );
      if (_speechInitialized) {
        debugPrint('[SpeechToText] Initialized successfully');
      }
    } catch (e) {
      debugPrint('[SpeechToText] Init error: $e');
    }
  }

  Future<void> handleBleSignal(String signal) async {
    debugPrint('[BleAudioService] Signal: $signal');
    switch (signal.toUpperCase()) {
      case 'FIRE':
        await _sendNotification(
          title: '🔥 تحذير حريق!',
          body: 'تم اكتشاف صوت جرس الحريق',
          id: 1,
        );
        break;
      case 'BABY':
        await _sendNotification(
          title: '👶 بكاء طفل!',
          body: 'تم اكتشاف بكاء طفل',
          id: 2,
        );
        break;
      case 'ATHAN':
        await _sendNotification(
          title: '🕌 أذان!',
          body: 'حان وقت الصلاة',
          id: 3,
        );
        break;
      case 'BG':
      case 'BACKGROUND':
        await _analyzeWithYamnet();
        break;
      default:
        await _sendNotification(
          title: '🔔 صوت مخصص!',
          body: 'تم اكتشاف: $signal',
          id: 4,
        );
    }
  }

  Future<void> _analyzeWithYamnet() async {
    if (isListening) return;
    if (!await _recorder.hasPermission()) {
      debugPrint('[BleAudioService] No mic permission');
      return;
    }
    isListening = true;
    notifyListeners();
    try {
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      final List<int> audioBytes = [];
      StreamSubscription? sub;
      sub = stream.listen((chunk) {
        audioBytes.addAll(chunk);
        if (audioBytes.length >= 31200) {
          sub?.cancel();
          _recorder.stop();
          _classifyAudio(
              Uint8List.fromList(audioBytes.take(31200).toList()));
        }
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (isListening) {
          sub?.cancel();
          _recorder.stop();
          if (audioBytes.isNotEmpty) {
            _classifyAudio(Uint8List.fromList(audioBytes));
          }
        }
      });
    } catch (e) {
      debugPrint('[BleAudioService] Record error: $e');
      isListening = false;
      notifyListeners();
    }
  }

  void _classifyAudio(Uint8List audioBytes) async {
    try {
      final result = _yamnet.classify(audioBytes);
      final label = result['label'] as String;
      final confidence = (result['confidence'] as num).toDouble();
      debugPrint('[YAMNet] $label ($confidence)');
      lastYamnetLabel = label;
      bleService.lastDetectedLabel = label;
      notifyListeners();
      if (confidence > 0.4 && _isHumanSound(label)) {
        await _recognizeSpeechForKeywords();
      } else if (confidence > 0.4 && label.isNotEmpty) {
        _sendYamnetNotification(label, confidence);
      }
    } catch (e) {
      debugPrint('[BleAudioService] Classify error: $e');
    } finally {
      isListening = false;
      notifyListeners();
    }
  }

  bool _isHumanSound(String label) {
    final humanLabels = [
      'SPEECH', 'CONVERSATION', 'NARRATION', 'SPEECH_SYNTHESIZER',
      'CHILD_SPEECH', 'MALE_SPEECH', 'FEMALE_SPEECH',
      'VOCAL', 'VOICE', 'SHOUT', 'SCREAM', 'CRY', 'YELL',
    ];
    return humanLabels.any((h) => label.toUpperCase().contains(h));
  }

  Future<void> _recognizeSpeechForKeywords() async {
    if (!_speechInitialized) return;
    try {
      await _speechToText.listen(
        onResult: (result) {
          lastRecognizedText = result.recognizedWords;
          debugPrint('[SpeechToText] Recognized: $lastRecognizedText');
          _checkForKeywords(lastRecognizedText);
        },
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 3),
        pauseFor: const Duration(seconds: 2),
      );
      Future.delayed(const Duration(seconds: 5), () {
        if (_speechToText.isListening) {
          _speechToText.stop();
        }
      });
    } catch (e) {
      debugPrint('[SpeechToText] Recognition error: $e');
    }
  }

  void _checkForKeywords(String text) {
    final lowerText = text.toLowerCase();
    for (String keyword in keywords) {
      if (lowerText.contains(keyword.toLowerCase())) {
        debugPrint('[Keywords] Match found: $keyword');
        _sendKeywordNotification(keyword, text);
        break;
      }
    }
  }

  Future<void> _sendKeywordNotification(
      String keyword, String fullText) async {
    await _sendNotification(
      title: '🚨 كلمة مفتاحية: $keyword',
      body: 'تم اكتشاف: "$fullText"',
      id: 20,
    );
  }

  Future<void> _sendYamnetNotification(
      String label, double confidence) async {
    final Map<String, Map<String, String>> labels = {
      'SIREN': {'title': '🚨 صفارة!', 'body': 'سمعت سيارة طوارئ أو إسعاف'},
      'ALARM': {'title': '⏰ جرس تنبيه!', 'body': 'تم اكتشاف جرس تنبيه'},
      'DOG': {'title': '🐕 نباح كلب!', 'body': 'هناك كلب بالقرب'},
      'DOORBELL': {'title': '🔔 جرس الباب!', 'body': 'شخص يدق الباب'},
      'MUSIC': {'title': '🎵 موسيقى', 'body': 'تم كشف موسيقى بالقرب'},
    };
    final info = labels[label.toUpperCase()];
    if (info != null) {
      await _sendNotification(
        title: info['title']!,
        body: '${info['body']!} (${(confidence * 100).toStringAsFixed(0)}%)',
        id: 10,
      );
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pulsehear_channel',
      'PulseHear Alerts',
      channelDescription: 'Sound detection alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  void addKeyword(String keyword) {
    if (!keywords.contains(keyword)) {
      keywords.add(keyword);
      bleService.sendKeyword(keyword);
      notifyListeners();
    }
  }

  void removeKeyword(String keyword) {
    keywords.remove(keyword);
    notifyListeners();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _yamnet.dispose();
    _speechToText.cancel();
    super.dispose();
  }
}

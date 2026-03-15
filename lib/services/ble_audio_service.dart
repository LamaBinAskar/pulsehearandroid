// ble_audio_service.dart
// PulseHear v30 - Receives audio from ESP32, runs YAMNet, sends result back
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_service.dart';
import 'yamnet_classifier.dart';

class BleAudioService extends ChangeNotifier {
  final BluetoothService bleService;
  final YamnetClassifier _yamnet = YamnetClassifier();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool   isProcessing     = false;
  String lastYamnetLabel  = '';
  String lastDetectedLabel = '';

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

    // Called when ESP32 sends a text signal (not used for FIRE/BABY anymore,
    // but kept in case ESP32 sends connection-status messages)
    bleService.onSignalReceived = _handleTextSignal;

    // Called when ESP32 streams audio bytes for YAMNet classification
    bleService.onAudioReceived = _handleAudioFromESP32;

    bleService.autoConnect();
    debugPrint('[BleAudioService] Initialized');
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

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

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ── Handle text signals from ESP32 (BLE connected status etc.) ──
  Future<void> _handleTextSignal(String signal) async {
    debugPrint('[BleAudioService] Signal: $signal');
    // ESP32 may send "CONNECTED" or similar — show phone notification
    if (signal.toUpperCase() == 'CONNECTED') {
      await _sendNotification(
        title: '🔗 PulseHear متصل',
        body: 'تم الاتصال بالجهاز ${bleService.deviceName}',
        id: 99,
      );
    }
  }

  // ── Receive raw audio from ESP32, classify with YAMNet ──────────
  Future<void> _handleAudioFromESP32(Uint8List audioBytes) async {
    if (isProcessing) {
      debugPrint('[BleAudioService] Still processing — skipping');
      return;
    }

    debugPrint('[BleAudioService] Received ${audioBytes.length} bytes from ESP32 — classifying...');
    isProcessing = true;
    notifyListeners();

    try {
      final result    = _yamnet.classify(audioBytes);
      final label     = result['label'] as String;
      final confidence = (result['confidence'] as num).toDouble();

      debugPrint('[YAMNet] $label (${(confidence * 100).toStringAsFixed(0)}%)');

      lastYamnetLabel   = label;
      lastDetectedLabel = label;
      bleService.lastDetectedLabel = label;
      notifyListeners();

      // Send result back to ESP32 so it can display on OLED
      final displayLabel = _friendlyLabel(label);
      await bleService.sendResult(displayLabel);

      // Also show notification on phone
      if (confidence > 0.35) {
        await _sendYamnetNotification(displayLabel, confidence);
      }
    } catch (e) {
      debugPrint('[BleAudioService] YAMNet error: $e');
      await bleService.sendResult('UNKNOWN');
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }

  // ── Convert YAMNet label to friendly short text for OLED ────────
  String _friendlyLabel(String label) {
    const map = {
      'SIREN':              'SIREN',
      'CIVIL_DEFENSE_SIREN':'SIREN',
      'AMBULANCE':          'AMBULANCE',
      'POLICE_CAR':         'POLICE',
      'ALARM':              'ALARM',
      'SMOKE_ALARM':        'SMOKE ALARM',
      'FIRE_ALARM':         'FIRE ALARM',
      'DOG':                'DOG BARK',
      'BARK':               'DOG BARK',
      'DOORBELL':           'DOORBELL',
      'KNOCK':              'KNOCK',
      'TELEPHONE':          'PHONE RING',
      'TELEPHONE_BELL_RINGING': 'PHONE RING',
      'MUSIC':              'MUSIC',
      'SPEECH':             'SPEECH',
      'SCREAM':             'SCREAM',
      'BABY_CRY':           'BABY CRY',
      'CRY':                'CRY',
    };
    return map[label.toUpperCase()] ?? label;
  }

  // ── Notification for YAMNet result ───────────────────────────────
  Future<void> _sendYamnetNotification(String label, double confidence) async {
    final Map<String, Map<String, String>> labels = {
      'SIREN':      {'title': '🚨 صفارة!',        'body': 'سمعت سيارة طوارئ أو إسعاف'},
      'AMBULANCE':  {'title': '🚑 إسعاف!',         'body': 'سيارة إسعاف بالقرب'},
      'POLICE':     {'title': '🚔 شرطة!',          'body': 'سيارة شرطة بالقرب'},
      'ALARM':      {'title': '⏰ جرس تنبيه!',     'body': 'تم اكتشاف جرس تنبيه'},
      'SMOKE ALARM':{'title': '💨 إنذار دخان!',    'body': 'تم اكتشاف إنذار دخان'},
      'FIRE ALARM': {'title': '🔥 إنذار حريق!',    'body': 'تم اكتشاف إنذار حريق'},
      'DOG BARK':   {'title': '🐕 نباح كلب!',      'body': 'هناك كلب بالقرب'},
      'DOORBELL':   {'title': '🔔 جرس الباب!',     'body': 'شخص يدق الباب'},
      'KNOCK':      {'title': '🚪 طرق باب!',       'body': 'شخص يطرق الباب'},
      'PHONE RING': {'title': '📞 هاتف يرن!',      'body': 'هاتف يرن بالقرب'},
      'MUSIC':      {'title': '🎵 موسيقى',         'body': 'تم كشف موسيقى بالقرب'},
      'SCREAM':     {'title': '😱 صراخ!',          'body': 'تم سماع صوت صراخ'},
      'BABY CRY':   {'title': '👶 بكاء طفل!',      'body': 'تم اكتشاف بكاء طفل'},
    };

    final info = labels[label];
    final title = info?['title'] ?? '🔊 صوت مكتشف';
    final body  = info != null
        ? '${info['body']!} (${(confidence * 100).toStringAsFixed(0)}%)'
        : '$label (${(confidence * 100).toStringAsFixed(0)}%)';

    await _sendNotification(title: title, body: body, id: 10);
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

  // ── Keywords (kept for future use) ───────────────────────────────
  List<String> get keywords => bleService.keywords;

  void addKeyword(String keyword) {
    bleService.sendKeyword(keyword);
    notifyListeners();
  }

  void removeKeyword(String keyword) {
    bleService.keywords.remove(keyword);
    notifyListeners();
  }

  @override
  void dispose() {
    _yamnet.dispose();
    super.dispose();
  }
}

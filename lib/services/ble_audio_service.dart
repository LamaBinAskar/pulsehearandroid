// ble_audio_service.dart
// PulseHear v30 - Receives audio from ESP32, runs YAMNet, sends result back
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_service.dart';
import 'yamnet_classifier.dart';
import 'websocket_server.dart';
import 'sound_library_service.dart';
import 'vosk_keyword_service.dart';

class BleAudioService extends ChangeNotifier {
  final BluetoothService bleService;
  final SoundLibraryService soundLibrary;
  final VoskKeywordService? voskService;
  final YamnetClassifier _yamnet = YamnetClassifier();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final WebSocketBroadcastServer _wsServer = WebSocketBroadcastServer();

  bool   isProcessing      = false;
  String lastYamnetLabel   = '';
  String lastDetectedLabel = '';

  // Detection history — last 10 events, newest first
  final List<Map<String, String>> detectionHistory = [];

  void _addHistory(String label, String source) {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}:${now.second.toString().padLeft(2,'0')}';
    detectionHistory.insert(0, {'label': label, 'source': source, 'time': time});
    if (detectionHistory.length > 10) detectionHistory.removeLast();
  }

  // Call this from dashboard test button to verify UI works
  void simulateDetection(String label) {
    lastDetectedLabel = label;
    _addHistory(label, 'TEST');
    notifyListeners();
  }

  BleAudioService({
    required this.bleService,
    required this.soundLibrary,
    this.voskService,
  }) {
    // Forward any BluetoothService state change (connect / disconnect / scanning)
    // to this service's own listeners so the dashboard rebuilds automatically.
    bleService.addListener(notifyListeners);
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
    // Set callbacks first — before any await — so BLE signals are never missed
    // even if a later init step (YAMNet, notifications, permissions) throws.
    bleService.onSignalReceived = _handleTextSignal;
    bleService.onAudioReceived  = _handleAudioFromESP32;

    try {
      await _yamnet.init();
    } catch (e) {
      debugPrint('[BleAudioService] YAMNet init failed: $e');
    }

    try {
      await _initNotifications();
    } catch (e) {
      debugPrint('[BleAudioService] Notifications init failed: $e');
    }

    try {
      await _requestBlePermissions();
    } catch (e) {
      debugPrint('[BleAudioService] BLE permission request failed: $e');
    }

    await _wsServer.start();
    debugPrint('[BleAudioService] Initialized — WS at ws://${_wsServer.localIp}:${WebSocketBroadcastServer.port}');
  }

  Future<void> _requestBlePermissions() async {
    if (!Platform.isAndroid) return;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    statuses.forEach((perm, status) {
      debugPrint('[Perm] $perm: $status');
    });
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

  // ── Handle text signals from ESP32 ──────────────────────────────
  Future<void> _handleTextSignal(String signal) async {
    debugPrint('[BleAudioService] Signal: $signal');
    switch (signal.toUpperCase()) {
      case 'CONNECTED':
        await _sendNotification(
          title: 'PulseHear متصل',
          body: 'تم الاتصال بالجهاز ${bleService.deviceName}',
          id: 99,
        );
        break;
      case 'FIRE':
        lastDetectedLabel = 'FIRE ALARM';
        bleService.lastDetectedLabel = 'FIRE ALARM';
        _addHistory('FIRE ALARM', 'ESP32');
        notifyListeners();
        _wsServer.broadcast('FIRE ALARM', 1.0);
        await _sendNotification(
          title: 'إنذار حريق!',
          body: 'تم اكتشاف إنذار حريق بواسطة الجهاز',
          id: 11,
        );
        break;
      case 'BABY':
        lastDetectedLabel = 'BABY CRYING';
        bleService.lastDetectedLabel = 'BABY CRYING';
        _addHistory('BABY CRYING', 'ESP32');
        notifyListeners();
        _wsServer.broadcast('BABY CRYING', 1.0);
        await _sendNotification(
          title: 'بكاء طفل!',
          body: 'تم اكتشاف بكاء طفل بواسطة الجهاز',
          id: 12,
        );
        break;
      case 'MIXED':
        lastDetectedLabel = 'MIXED ALARM';
        bleService.lastDetectedLabel = 'MIXED ALARM';
        _addHistory('MIXED ALARM', 'ESP32');
        notifyListeners();
        _wsServer.broadcast('MIXED ALARM', 1.0);
        await _sendNotification(
          title: '⚠️ إنذار مختلط!',
          body: 'تم اكتشاف صوت إنذار غير محدد — تحقق من المكان',
          id: 13,
        );
        break;
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

    // Also pipe audio to Vosk for keyword detection (runs in parallel)
    voskService?.feedAudio(audioBytes);

    try {
      final result    = _yamnet.classify(audioBytes);
      final label     = result['label'] as String;
      final confidence = (result['confidence'] as num).toDouble();

      debugPrint('[YAMNet] $label (${(confidence * 100).toStringAsFixed(0)}%)');

      lastYamnetLabel   = label;
      lastDetectedLabel = label;
      bleService.lastDetectedLabel = label;
      _addHistory(label, 'YAMNet');
      notifyListeners();

      // Send result back to ESP32 so it can display on OLED
      final displayLabel = _friendlyLabel(label);

      if (!soundLibrary.isLabelEnabled(displayLabel)) {
        debugPrint('[BleAudioService] Sound "$displayLabel" is disabled in library — skipping');
        return;
      }

      await bleService.sendResult(displayLabel);

      // Broadcast to web dashboard
      _wsServer.broadcast(displayLabel, confidence);

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
  // Note: FIRE ALARM and BABY CRY are handled by ESP32 directly (BLE signals).
  // This map only covers background/environment sounds classified by YAMNet.
  String _friendlyLabel(String label) {
    const map = {
      'SIREN':                  'SIREN',
      'CIVIL_DEFENSE_SIREN':    'SIREN',
      'AMBULANCE':              'AMBULANCE',
      'POLICE_CAR':             'POLICE',
      'DOG':                    'DOG BARK',
      'BARK':                   'DOG BARK',
      'DOORBELL':               'DOORBELL',
      'KNOCK':                  'KNOCK',
      'TELEPHONE':              'PHONE RING',
      'TELEPHONE_BELL_RINGING': 'PHONE RING',
      'MUSIC':                  'MUSIC',
      'SPEECH':                 'SPEECH',
      'SCREAM':                 'SCREAM',
      'SHOUT':                  'SHOUT',
      'LAUGHTER':               'LAUGHTER',
    };
    return map[label.toUpperCase()] ?? label;
  }

  // ── Notification for YAMNet result ───────────────────────────────
  // Fire alarm and baby cry are NOT here — handled by ESP32 BLE signals.
  Future<void> _sendYamnetNotification(String label, double confidence) async {
    final Map<String, Map<String, String>> labels = {
      'SIREN':      {'title': 'صفارة!',        'body': 'سمعت سيارة طوارئ أو إسعاف'},
      'AMBULANCE':  {'title': 'إسعاف!',         'body': 'سيارة إسعاف بالقرب'},
      'POLICE':     {'title': 'شرطة!',          'body': 'سيارة شرطة بالقرب'},
      'DOG BARK':   {'title': 'نباح كلب!',      'body': 'هناك كلب بالقرب'},
      'DOORBELL':   {'title': 'جرس الباب!',     'body': 'شخص يدق الباب'},
      'KNOCK':      {'title': 'طرق باب!',       'body': 'شخص يطرق الباب'},
      'PHONE RING': {'title': 'هاتف يرن!',      'body': 'هاتف يرن بالقرب'},
      'MUSIC':      {'title': 'موسيقى',         'body': 'تم كشف موسيقى بالقرب'},
      'SCREAM':     {'title': 'صراخ!',          'body': 'تم سماع صوت صراخ'},
      'SHOUT':      {'title': 'صياح!',          'body': 'تم سماع صوت صياح'},
      'LAUGHTER':   {'title': 'ضحك',            'body': 'تم سماع صوت ضحك'},
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

  Future<void> sendKeywordAlert(String keyword) async {
    await bleService.sendKeywordAlert(keyword);
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
    bleService.removeListener(notifyListeners);
    _wsServer.stop();
    _yamnet.dispose();
    super.dispose();
  }
}

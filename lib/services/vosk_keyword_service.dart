// vosk_keyword_service.dart
// PulseHear — offline Arabic keyword detection via Vosk native Android channel.
// Audio comes from INMP441 mic streamed over BLE (raw 16 kHz, 16-bit, mono PCM).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class VoskKeywordService extends ChangeNotifier {
  static const _channel = MethodChannel('pulsehear/vosk');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _keywords = [];
  bool isListening = false;
  bool _initialized = false;
  String lastDetected = '';

  /// Called when a keyword is detected — wired to BLE sendKeywordAlert.
  Function(String keyword)? onKeywordDetected;

  List<Map<String, dynamic>> get keywords => List.unmodifiable(_keywords);

  // ── Init: load Vosk model on Android (extracted from assets on first run) ─
  Future<void> init() async {
    await _initNotifications();
    try {
      final result = await _channel.invokeMethod<String>('init');
      _initialized = (result == 'ok');
      debugPrint('[Vosk] Init result: $result');
    } on PlatformException catch (e) {
      debugPrint('[Vosk] Init error: ${e.message}');
    }
  }

  Future<void> _initNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
  }

  // ── Update keyword list from KeywordsScreen ──────────────────────
  void setKeywords(List<Map<String, dynamic>> kws) {
    _keywords = List.from(kws);
    isListening = _initialized && _keywords.isNotEmpty;
    notifyListeners();
  }

  // ── Feed raw PCM from BLE (16 kHz, 16-bit, mono) into Vosk ──────
  Future<void> feedAudio(Uint8List pcmBytes) async {
    if (!_initialized || _keywords.isEmpty) return;

    try {
      final jsonStr = await _channel.invokeMethod<String>(
        'acceptWaveform',
        pcmBytes,
      );
      if (jsonStr == null || jsonStr.isEmpty) return;

      final decoded = json.decode(jsonStr) as Map<String, dynamic>;
      final text =
          (decoded['text'] ?? decoded['partial'] ?? '') as String;

      if (text.isNotEmpty) {
        debugPrint('[Vosk] Heard: $text');
        _checkKeywords(text);
      }
    } on PlatformException catch (e) {
      debugPrint('[Vosk] feedAudio error: ${e.message}');
    }
  }

  void _checkKeywords(String text) {
    final lower = text.toLowerCase();
    for (final kw in _keywords) {
      if (!(kw['isActive'] as bool)) continue;
      final word = (kw['word'] as String).toLowerCase();
      if (lower.contains(word)) {
        debugPrint('[Vosk] KEYWORD MATCH: ${kw['word']}');
        lastDetected = kw['word'];
        onKeywordDetected?.call(kw['word']);
        _sendNotification(kw['word']);
        notifyListeners();
        break;
      }
    }
  }

  Future<void> _sendNotification(String keyword) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'pulsehear_keywords',
        'PulseHear Keywords',
        channelDescription: 'Keyword detection alerts',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
    );
    await _notifications.show(
        20, '🔑 Keyword Detected', '"$keyword" was heard nearby', details);
  }

  void stopListening() {
    isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _channel.invokeMethod('dispose').ignore();
    super.dispose();
  }
}

// bluetooth_service.dart
// PulseHear v30 - Audio streaming from ESP32 to phone
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp show BluetoothService;

class BluetoothService extends ChangeNotifier {
  // UUIDs — must match Arduino exactly
  static const String SERVICE_UUID      = '12345678-1234-1234-1234-123456789abc';
  static const String CHAR_SIGNAL_UUID  = 'abcd1234-1234-1234-1234-abcdef123456';
  static const String CHAR_KEYWORD_UUID = 'abcd5678-1234-1234-1234-abcdef123456';
  static const String CHAR_AUDIO_UUID   = 'abcd9999-1234-1234-1234-abcdef123456';
  static const String DEVICE_NAME       = 'PulseHear_v30';

  BluetoothDevice?         _device;
  BluetoothCharacteristic? _signalChar;
  BluetoothCharacteristic? _keywordChar;
  BluetoothCharacteristic? _audioChar;
  StreamSubscription?      _scanSub;
  StreamSubscription?      _notifySub;
  StreamSubscription?      _audioNotifySub;
  StreamSubscription?      _connectionSub;
  Timer?                   _reconnectTimer;

  bool   isConnected = false;
  bool   isScanning  = false;
  String deviceName  = '';
  String lastDetectedLabel = '';
  List<String> keywords   = [];

  // Audio streaming state
  final List<int> _audioBuffer = [];
  int _expectedAudioBytes = 0;
  bool _receivingAudio = false;

  // Callbacks
  Function(String signal)?      onSignalReceived;
  Function(Uint8List audioBytes)? onAudioReceived;

  // ── Auto-connect ─────────────────────────────────────────────
  void autoConnect() {
    debugPrint('[BLE] Auto-connect started');
    _tryConnect();
  }

  void _tryConnect() {
    if (isConnected || isScanning) return;
    debugPrint('[BLE] Scanning for $DEVICE_NAME...');
    startScan();
  }

  // ── Start BLE scan ───────────────────────────────────────────
  Future<void> startScan() async {
    if (isScanning) return;
    isScanning = true;
    notifyListeners();

    try {
      await _scanSub?.cancel();

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 20),
        withNames: [DEVICE_NAME],
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (r.device.platformName == DEVICE_NAME) {
            FlutterBluePlus.stopScan();
            _connectToDevice(r.device);
            break;
          }
        }
      });

      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && !isConnected) {
          isScanning = false;
          notifyListeners();
          debugPrint('[BLE] Scan ended — retrying in 5s');
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
        }
      });
    } catch (e) {
      debugPrint('[BLE] Scan error: $e');
      isScanning = false;
      notifyListeners();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
    }
  }

  // ── Connect to device ────────────────────────────────────────
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));

      // Negotiate larger MTU for audio streaming (512 bytes)
      await device.requestMtu(512);

      _device    = device;
      deviceName = device.platformName;
      isConnected = true;
      isScanning  = false;
      notifyListeners();
      debugPrint('[BLE] Connected to $deviceName ✓');

      await _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('[BLE] Connection lost — reconnecting in 3s');
          _signalChar  = null;
          _keywordChar = null;
          _audioChar   = null;
          isConnected  = false;
          deviceName   = '';
          _receivingAudio = false;
          _audioBuffer.clear();
          notifyListeners();
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 3), _tryConnect);
        }
      });

      await _discoverServices();
    } catch (e) {
      debugPrint('[BLE] Connect error: $e');
      isConnected = false;
      isScanning  = false;
      notifyListeners();
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
    }
  }

  // ── Discover services and characteristics ────────────────────
  Future<void> _discoverServices() async {
    if (_device == null) return;
    try {
      List<fbp.BluetoothService> services = await _device!.discoverServices();
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            final uuid = char.uuid.toString().toLowerCase();
            if (uuid == CHAR_SIGNAL_UUID.toLowerCase()) {
              _signalChar = char;
              await _subscribeToSignals();
            } else if (uuid == CHAR_KEYWORD_UUID.toLowerCase()) {
              _keywordChar = char;
            } else if (uuid == CHAR_AUDIO_UUID.toLowerCase()) {
              _audioChar = char;
              await _subscribeToAudio();
            }
          }
        }
      }
      debugPrint('[BLE] Services discovered — ready');
    } catch (e) {
      debugPrint('[BLE] Service discovery error: $e');
    }
  }

  // ── Subscribe to signal notifications ───────────────────────
  Future<void> _subscribeToSignals() async {
    if (_signalChar == null) return;
    try {
      await _signalChar!.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = _signalChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final signal = String.fromCharCodes(value).trim();
        debugPrint('[BLE] Signal: $signal');
        onSignalReceived?.call(signal);
      });
    } catch (e) {
      debugPrint('[BLE] Signal notify error: $e');
    }
  }

  // ── Subscribe to audio stream notifications ──────────────────
  Future<void> _subscribeToAudio() async {
    if (_audioChar == null) return;
    try {
      await _audioChar!.setNotifyValue(true);
      await _audioNotifySub?.cancel();
      _audioNotifySub = _audioChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        _handleAudioChunk(value);
      });
      debugPrint('[BLE] Audio stream subscribed');
    } catch (e) {
      debugPrint('[BLE] Audio notify error: $e');
    }
  }

  // ── Handle incoming audio chunks from ESP32 ──────────────────
  void _handleAudioChunk(List<int> chunk) {
    // Check if it's a control message (text)
    // Control messages are short ASCII strings
    if (chunk.length < 64) {
      final text = String.fromCharCodes(chunk).trim();

      if (text.startsWith('AUDIO_START:')) {
        final parts = text.split(':');
        _expectedAudioBytes = int.tryParse(parts[1]) ?? 0;
        _audioBuffer.clear();
        _receivingAudio = true;
        debugPrint('[BLE] Audio START — expecting $_expectedAudioBytes bytes');
        return;
      }

      if (text == 'AUDIO_END') {
        _receivingAudio = false;
        debugPrint('[BLE] Audio END — received ${_audioBuffer.length} bytes');
        if (_audioBuffer.isNotEmpty) {
          onAudioReceived?.call(Uint8List.fromList(_audioBuffer));
        }
        _audioBuffer.clear();
        return;
      }
    }

    // It's a raw audio data chunk
    if (_receivingAudio) {
      _audioBuffer.addAll(chunk);
      debugPrint('[BLE] Audio chunk: ${chunk.length} bytes (total: ${_audioBuffer.length}/$_expectedAudioBytes)');
    }
  }

  // ── Send result back to ESP32 ────────────────────────────────
  Future<void> sendResult(String result) async {
    if (_keywordChar == null || !isConnected) {
      debugPrint('[BLE] Cannot send result — not connected');
      return;
    }
    try {
      final msg = 'RESULT:$result';
      final bytes = Uint8List.fromList(msg.codeUnits);
      await _keywordChar!.write(bytes, withoutResponse: false);
      debugPrint('[BLE] Sent result: $msg');
    } catch (e) {
      debugPrint('[BLE] Send result error: $e');
    }
  }

  // ── Send keyword to ESP32 ────────────────────────────────────
  Future<void> sendKeyword(String keyword) async {
    if (_keywordChar == null || !isConnected) {
      debugPrint('[BLE] Cannot send keyword — not connected');
      return;
    }
    try {
      final bytes = Uint8List.fromList(keyword.codeUnits);
      await _keywordChar!.write(bytes, withoutResponse: false);
      debugPrint('[BLE] Sent keyword: $keyword');
      if (!keywords.contains(keyword)) {
        keywords.add(keyword);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BLE] Send keyword error: $e');
    }
  }

  // ── Manual disconnect ────────────────────────────────────────
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _notifySub?.cancel();
    await _audioNotifySub?.cancel();
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    await _device?.disconnect();
    _device      = null;
    _signalChar  = null;
    _keywordChar = null;
    _audioChar   = null;
    isConnected  = false;
    isScanning   = false;
    deviceName   = '';
    notifyListeners();
    debugPrint('[BLE] Manually disconnected');
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    super.dispose();
  }
}

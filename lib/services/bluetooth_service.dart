// bluetooth_service.dart
// PulseHear v27 - BLE Service with auto-reconnect
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
  static const String DEVICE_NAME       = 'PulseHear_v27';

  BluetoothDevice?         _device;
  BluetoothCharacteristic? _signalChar;
  BluetoothCharacteristic? _keywordChar;
  StreamSubscription?      _scanSub;
  StreamSubscription?      _notifySub;
  StreamSubscription?      _connectionSub;
  Timer?                   _reconnectTimer;

  bool   isConnected = false;
  bool   isScanning  = false;
  String deviceName  = '';
  String lastDetectedLabel = '';
  List<String> keywords   = [];

  // Callback when ESP32 sends a signal
  Function(String signal)? onSignalReceived;

  // ── Auto-connect: called once at app start ──────────────────
  // Keeps trying until connected, then auto-reconnects on drop
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

      // If scan finishes without finding device, retry after 5s
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
      // Retry after 5 seconds
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
    }
  }

  // ── Connect to found device ──────────────────────────────────
  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 15));
      _device    = device;
      deviceName = device.platformName;
      isConnected = true;
      isScanning  = false;
      notifyListeners();
      debugPrint('[BLE] Connected to $deviceName ✓');

      // Listen for disconnection and auto-reconnect
      await _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          debugPrint('[BLE] Connection lost — reconnecting in 3s');
          _signalChar  = null;
          _keywordChar = null;
          isConnected  = false;
          deviceName   = '';
          notifyListeners();
          // Auto reconnect
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
      // Retry after 5 seconds
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _tryConnect);
    }
  }

  // ── Discover BLE services and characteristics ────────────────
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
            }
          }
        }
      }
      debugPrint('[BLE] Services discovered — ready to receive signals');
    } catch (e) {
      debugPrint('[BLE] Service discovery error: $e');
    }
  }

  // ── Subscribe to notifications from ESP32 ───────────────────
  Future<void> _subscribeToSignals() async {
    if (_signalChar == null) return;
    try {
      await _signalChar!.setNotifyValue(true);
      await _notifySub?.cancel();
      _notifySub = _signalChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final signal = String.fromCharCodes(value).trim();
        debugPrint('[BLE] Signal received: $signal');
        _handleSignal(signal);
      });
    } catch (e) {
      debugPrint('[BLE] Notify error: $e');
    }
  }

  // ── Handle incoming signal from ESP32 ───────────────────────
  void _handleSignal(String signal) {
    switch (signal.toUpperCase()) {
      case 'FIRE':
        lastDetectedLabel = 'FIRE';
        notifyListeners();
        onSignalReceived?.call('FIRE');
        break;
      case 'BABY':
        lastDetectedLabel = 'BABY';
        notifyListeners();
        onSignalReceived?.call('BABY');
        break;
      case 'ATHAN':
        lastDetectedLabel = 'ATHAN';
        notifyListeners();
        onSignalReceived?.call('ATHAN');
        break;
      case 'BG':
      case 'BACKGROUND':
        // ESP32 detected background → phone runs YAMNet to identify
        // secondary sounds (car horn, doorbell, etc.)
        onSignalReceived?.call('BG');
        break;
      default:
        if (keywords.contains(signal)) {
          lastDetectedLabel = signal;
          notifyListeners();
          onSignalReceived?.call(signal);
        }
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
    await _scanSub?.cancel();
    await _connectionSub?.cancel();
    await _device?.disconnect();
    _device      = null;
    _signalChar  = null;
    _keywordChar = null;
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

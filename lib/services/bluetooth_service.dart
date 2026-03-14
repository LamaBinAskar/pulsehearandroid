// bluetooth_service.dart
// PulseHear v27 - BLE Service
// يتصل بـ ESP32S3 XIAO Sense عبر BLE
// يستقبل إشارات: FIRE, BABY, ATHAN, BG
// BG = يشغّل YAMNet على الهاتف

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' hide BluetoothService;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp show BluetoothService;

class BluetoothService extends ChangeNotifier {
  // UUIDs - نفس اللي في Arduino
  static const String SERVICE_UUID = '12345678-1234-1234-1234-123456789abc';
  static const String CHAR_SIGNAL_UUID = 'abcd1234-1234-1234-1234-abcdef123456';
  static const String CHAR_KEYWORD_UUID = 'abcd5678-1234-1234-1234-abcdef123456';
  static const String DEVICE_NAME = 'PulseHear_v27';

  BluetoothDevice? _device;
  BluetoothCharacteristic? _signalChar;
  BluetoothCharacteristic? _keywordChar;
  StreamSubscription? _scanSub;
  StreamSubscription? _notifySub;

  bool isConnected = false;
  bool isScanning = false;
  String deviceName = '';
  String lastDetectedLabel = '';
  double batteryLevel = 100.0;
  List<String> keywords = [];

  // callback عند استقبال إشارة من ESP32
  Function(String signal)? onSignalReceived;

  // بدء البحث عن الجهاز
  Future<void> startScan() async {
    if (isScanning) return;
    isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
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
    } catch (e) {
      print('[BLE] Scan error: $e');
      isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _device = device;
      deviceName = device.platformName;
      isConnected = true;
      isScanning = false;
      notifyListeners();
      print('[BLE] Connected to $deviceName');
      await _discoverServices();
    } catch (e) {
      print('[BLE] Connect error: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  Future<void> _discoverServices() async {
    if (_device == null) return;
    try {
      List<fbp.BluetoothService> services = await _device!.discoverServices();
      for (fbp.BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (BluetoothCharacteristic char in service.characteristics) {
            String charUuid = char.uuid.toString().toLowerCase();
            if (charUuid == CHAR_SIGNAL_UUID.toLowerCase()) {
              _signalChar = char;
              await _subscribeToSignals();
            } else if (charUuid == CHAR_KEYWORD_UUID.toLowerCase()) {
              _keywordChar = char;
            }
          }
        }
      }
      print('[BLE] Services discovered');
    } catch (e) {
      print('[BLE] Service discovery error: $e');
    }
  }

  Future<void> _subscribeToSignals() async {
    if (_signalChar == null) return;
    try {
      await _signalChar!.setNotifyValue(true);
      _notifySub = _signalChar!.lastValueStream.listen((value) {
        if (value.isEmpty) return;
        final signal = String.fromCharCodes(value).trim();
        print('[BLE] Signal received: $signal');
        _handleSignal(signal);
      });
    } catch (e) {
      print('[BLE] Notify error: $e');
    }
  }

  void _handleSignal(String signal) {
    // إشارات من ESP32 TinyML
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
        // يشغّل YAMNet على الهاتف
        onSignalReceived?.call('BG');
        break;
      default:
        // keyword مخصص
        if (keywords.contains(signal)) {
          lastDetectedLabel = signal;
          notifyListeners();
          onSignalReceived?.call(signal);
        }
    }
  }

  // إرسال keyword إلى ESP32
  Future<void> sendKeyword(String keyword) async {
    if (_keywordChar == null || !isConnected) {
      print('[BLE] Not connected or no keyword char');
      return;
    }
    try {
      final bytes = Uint8List.fromList(keyword.codeUnits);
      await _keywordChar!.write(bytes, withoutResponse: false);
      print('[BLE] Sent keyword: $keyword');
      if (!keywords.contains(keyword)) {
        keywords.add(keyword);
        notifyListeners();
      }
    } catch (e) {
      print('[BLE] Send keyword error: $e');
    }
  }

  // قطع الاتصال
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _scanSub?.cancel();
    await _device?.disconnect();
    _device = null;
    _signalChar = null;
    _keywordChar = null;
    isConnected = false;
    deviceName = '';
    notifyListeners();
    print('[BLE] Disconnected');
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    isScanning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}


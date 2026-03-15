// websocket_server.dart
// Runs a local WebSocket server on port 8765.
// The web dashboard connects to ws://[phone-wifi-ip]:8765
// and receives every detection as JSON in real time.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class WebSocketBroadcastServer {
  static const int port = 8765;

  HttpServer?        _server;
  final List<WebSocket> _clients = [];
  String _localIp = '';

  String get localIp => _localIp;
  int    get clientCount => _clients.length;

  // ── Start the server ─────────────────────────────────────
  Future<void> start() async {
    try {
      _localIp = await _getLocalIp();

      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('[WS] Server started — connect at ws://$_localIp:$port');

      _server!.listen((HttpRequest request) async {
        if (!WebSocketTransformer.isUpgradeRequest(request)) {
          request.response
            ..statusCode = HttpStatus.ok
            ..write('PulseHear WS server')
            ..close();
          return;
        }

        final ws = await WebSocketTransformer.upgrade(request);
        _clients.add(ws);
        debugPrint('[WS] Dashboard connected  (${_clients.length} client(s))');

        ws.listen(
          null,
          onDone: () {
            _clients.remove(ws);
            debugPrint('[WS] Dashboard disconnected (${_clients.length} client(s))');
          },
          onError: (_) {
            _clients.remove(ws);
          },
          cancelOnError: true,
        );
      });
    } catch (e) {
      debugPrint('[WS] Could not start server: $e');
    }
  }

  // ── Broadcast a detection to all connected dashboards ────
  void broadcast(String label, double confidence) {
    if (_clients.isEmpty) return;
    final msg = jsonEncode({
      'label':      label,
      'confidence': confidence,
      'timestamp':  DateTime.now().toIso8601String(),
    });
    for (final ws in List<WebSocket>.from(_clients)) {
      try {
        ws.add(msg);
      } catch (_) {
        _clients.remove(ws);
      }
    }
    debugPrint('[WS] Broadcast → $label (${(confidence * 100).toStringAsFixed(0)}%)');
  }

  // ── Stop ──────────────────────────────────────────────────
  void stop() {
    for (final ws in List<WebSocket>.from(_clients)) {
      try { ws.close(); } catch (_) {}
    }
    _clients.clear();
    _server?.close(force: true);
    _server = null;
  }

  // ── Get the phone's WiFi IP ───────────────────────────────
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        // Prefer wlan (WiFi) over other interfaces
        if (iface.name.toLowerCase().contains('wlan') ||
            iface.name.toLowerCase().contains('wifi') ||
            iface.name.toLowerCase().contains('en')) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback) return addr.address;
          }
        }
      }
      // Fallback: first non-loopback address found
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return 'unknown';
  }
}

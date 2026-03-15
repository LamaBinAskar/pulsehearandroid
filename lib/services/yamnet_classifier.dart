import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class YamnetClassifier {
  static const _modelPath = 'assets/models/yamnet.tflite';
  static const _frameLength = 15600; // 0.96 ثانية

  late final Interpreter _interpreter;

  // YAMNet only classifies BACKGROUND sounds here.
  // Fire alarm and baby crying are detected directly by the ESP32 (Edge Impulse)
  // and arrive as BLE signals "FIRE"/"BABY"/"MIXED" — NOT via this audio stream.
  final Map<int, String> importantLabels = {
    // ── Speech / Human voice ─────────────────
    0:   'SPEECH',
    6:   'SHOUT',
    11:  'SCREAM',
    13:  'LAUGHTER',
    // ── Music ────────────────────────────────
    137: 'MUSIC',
    // ── Animals ──────────────────────────────
    74:  'DOG',
    75:  'BARK',
    // ── Emergency sirens ─────────────────────
    388: 'SIREN',
    389: 'CIVIL_DEFENSE_SIREN',
    390: 'AMBULANCE',
    392: 'POLICE_CAR',
    // ── Home sounds ──────────────────────────
    461: 'DOORBELL',
    465: 'KNOCK',
    // ── Phone ────────────────────────────────
    418: 'TELEPHONE',
    419: 'TELEPHONE_BELL_RINGING',
  };

  Future<void> init() async {
    // تحميل المودل
    // تحميل المودل
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    debugPrint('[YAMNet] Model loaded successfully');
  }

  // تجهيز الـ 15600 عينة من buffer الصوت
  Float32List prepareInput(Uint8List pcmBytes) {
    final nSamples = pcmBytes.lengthInBytes ~/ 2; // 16-bit PCM
    final samples = Float32List(_frameLength);

    for (int i = 0; i < samples.length; i++) {
      if (i < nSamples) {
        final offset = i * 2;
        int s = (pcmBytes[offset + 1] << 8) | pcmBytes[offset];
        if (s >= 32768) s -= 65536; // sign-extend to signed int16
        samples[i] = (s / 32768.0).clamp(-1.0, 1.0);
      } else {
        samples[i] = 0.0;
      }
    }

    return samples;
  }

  // Run YAMNet on one audio frame
  Map<String, dynamic> classify(Uint8List pcmBytes) {
    final input = prepareInput(pcmBytes);

    final inputs = [input.reshape([_frameLength])];
    final outputs = List.filled(521, 0.0).reshape([1, 521]);
    _interpreter.run(inputs, outputs);

    // Search only among the important class indices.
    // This way we always return a meaningful label even when
    // the global winner is an unimportant class.
    double maxScore = 0;
    int    maxIndex = -1;
    for (final entry in importantLabels.entries) {
      final score = outputs[0][entry.key].toDouble();
      if (score > maxScore) {
        maxScore = score;
        maxIndex = entry.key;
      }
    }

    final label = maxIndex >= 0
        ? (importantLabels[maxIndex] ?? 'BACKGROUND')
        : 'BACKGROUND';

    return {
      'label':      label,
      'confidence': maxScore,
      'index':      maxIndex,
    };
  }

  void dispose() {
    _interpreter.close();
  }
}

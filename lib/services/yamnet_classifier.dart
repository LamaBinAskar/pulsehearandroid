import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

class YamnetClassifier {
  static const _modelPath = 'assets/models/yamnet.tflite';
  static const _sampleRate = 16000;
  static const _frameLength = 15600; // 0.96 ثانية

  late final Interpreter _interpreter;

  // YAMNet labels - أهم 521 تصنيف من AudioSet
  // نستخدم فقط التصنيفات البشرية المهمة
  final Map<int, String> importantLabels = {
    0: 'SPEECH',
    1: 'MALE_SPEECH',
    2: 'FEMALE_SPEECH',
    3: 'CHILD_SPEECH',
    4: 'CONVERSATION',
    5: 'NARRATION',
    6: 'BABBLING',
    7: 'SHOUT',
    8: 'SCREAM',
    9: 'YELL',
    10: 'LAUGHTER',
    11: 'CRY',
    12: 'BABY_CRY',
    13: 'WHIMPER',
    14: 'MUSIC',
    15: 'MUSICAL_INSTRUMENT',
    23: 'DOG',
    24: 'BARK',
    38: 'SIREN',
    39: 'CIVIL_DEFENSE_SIREN',
    40: 'AMBULANCE',
    41: 'POLICE_CAR',
    65: 'ALARM',
    66: 'SMOKE_ALARM',
    67: 'FIRE_ALARM',
    85: 'DOORBELL',
    86: 'KNOCK',
    108: 'TELEPHONE',
    109: 'TELEPHONE_BELL_RINGING',
  };

  Future<void> init() async {
    // تحميل المودل
    // تحميل المودل
    final options = InterpreterOptions();
    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);
    print('[YAMNet] Model loaded successfully');
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

  // تصنيف إطار واحد
  Map<String, dynamic> classify(Uint8List pcmBytes) {
    final input = prepareInput(pcmBytes);

    // 1D Float32List بحجم 15600
    final inputShape = [_frameLength];
    final inputs = [input.reshape(inputShape)];

    // Output: [1, 521] scores
    final outputs = List.filled(521, 0.0).reshape([1, 521]);

    _interpreter.run(inputs, outputs);

    // البحث عن أعلى score
    double maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < 521; i++) {
      final score = outputs[0][i].toDouble();
      if (score > maxScore) {
        maxScore = score;
        maxIndex = i;
      }
    }

    // الحصول على التصنيف
    final label = importantLabels[maxIndex] ?? 'BACKGROUND_$maxIndex';
    final confidence = maxScore;

    return {
      'label': label,
      'confidence': confidence,
      'index': maxIndex,
    };
  }

  void dispose() {
    _interpreter.close();
  }
}

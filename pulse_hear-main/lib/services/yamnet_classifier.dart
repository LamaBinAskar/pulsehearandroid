import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class YamnetClassifier {
  static const _modelPath = 'assets/models/yamnet.tflite';
  static const _sampleRate = 16000;
  static const _frameLength = 15600; // 0.96 ثانية

  late final Interpreter _interpreter;
  final List<String> labels = List.filled(521, 'unknown'); // 521 label

  Future<void> init() async {
    // تحميل المودل
    final gpuDelegateV2 = GpuDelegateV2(
      options: GpuDelegateOptionsV2(
        allowPrecisionLoss: true,
        inferencePriority1: TfLiteInferencePriority.min,
        inferencePriority2: TfLiteInferencePriority.min,
        inferencePriority3: TfLiteInferencePriority.min,
        inferencePriority4: TfLiteInferencePriority.min,
      ),
    );

    final options = InterpreterOptions()
      ..addDelegate(gpuDelegateV2);

    _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

    // تحميل الـ labels (إذا عندك ملف labels_yamnet.txt)
    // readLabels('labels_yamnet.txt');
  }

  // تجهيز الـ 15600 عينة من buffer الصوت
  Float32List prepareInput(Uint8List pcmBytes) {
    final nSamples = pcmBytes.lengthInBytes ~/ 2; // 16-bit PCM
    final samples = Float32List(_frameLength);

    for (int i = 0; i < samples.length; i++) {
      if (i < nSamples) {
        final offset = i * 2;
        final s = (pcmBytes[offset + 1] << 8) | pcmBytes[offset];
        samples[i] = (s / 32768.0).clamp(-1.0, 1.0);
      } else {
        samples[i] = 0.0;
      }
    }

    return samples;
  }

  // تصنيف إطار واحد
  Map<String, double> classify(Uint8List pcmBytes) {
    final input = prepareInput(pcmBytes); // 1D Float32List بحجم 15600
    final inputShape = [_frameLength];

    final inputs = [input.reshape(inputShape)];

    final outputs = List.filled(1, 0.0).reshape([1, 521]);

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

    final label = labels[maxIndex];
    final confidence = maxScore;

    return {
      'label': label,
      'confidence': confidence,
    };
  }

  // تحميل الـ labels (إذا تبي)
  Future<void> readLabels(String fileName) async {
    final raw = await rootBundle.loadString('assets/labels/$fileName');
    final lines = raw.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (i < 521) {
        labels[i] = lines[i].trim();
      }
    }
  }

  void dispose() {
    _interpreter.close();
  }
}

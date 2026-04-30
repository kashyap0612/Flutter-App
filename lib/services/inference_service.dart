import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/inference_result.dart';
import 'label_service.dart';

class InferenceService {
  Interpreter? _interpreter;
  late final List<String> _labels;
  final LabelService _labelService;

  InferenceService({LabelService? labelService})
      : _labelService = labelService ?? LabelService();

  Future<void> init() async {
    _interpreter ??= await Interpreter.fromAsset(
      'assets/models/crop_disease_model.tflite',
      options: InterpreterOptions()..threads = 2,
    );
    _labels = await _labelService.loadLabels();
  }

  Future<InferenceResult> runInference(String imagePath) async {
    if (_interpreter == null) {
      await init();
    }

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    final resized = _preprocessImage(
      imagePath,
      width: inputTensor.shape[1],
      height: inputTensor.shape[2],
      isFloat: inputTensor.type == TfLiteType.float32,
    );

    final outputShape = outputTensor.shape;
    final output = List.generate(
      outputShape[0],
      (_) => List.filled(outputShape[1], 0.0),
    );

    _interpreter!.run(resized, output);

    final probabilities = output.first;
    final topPreds = _topK(probabilities, k: 3);

    final best = topPreds.first;
    final label = _labels[best['index'] as int];

    return InferenceResult(
      label: label,
      cropType: _labelService.extractCropType(label),
      confidence: best['score'] as double,
      topPredictions: topPreds
          .map((entry) => {
                'label': _labels[entry['index'] as int],
                'confidence': entry['score'],
              })
          .toList(),
    );
  }

  List<dynamic> _preprocessImage(
    String imagePath, {
    required int width,
    required int height,
    required bool isFloat,
  }) {
    final bytes = File(imagePath).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Invalid image selected. Could not decode image bytes.');
    }

    final resized = img.copyResize(decoded, width: width, height: height);

    if (isFloat) {
      return [
        List.generate(
          height,
          (y) => List.generate(
            width,
            (x) {
              final pixel = resized.getPixel(x, y);
              return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
            },
          ),
        ),
      ];
    }

    return [
      List.generate(
        height,
        (y) => List.generate(
          width,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
        ),
      ),
    ];
  }

  List<Map<String, dynamic>> _topK(List<double> probs, {int k = 3}) {
    final indexed = probs.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return indexed
        .take(k)
        .map((e) => {'index': e.key, 'score': e.value})
        .toList();
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

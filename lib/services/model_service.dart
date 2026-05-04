import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelService {
  ModelService._();

  static final ModelService instance = ModelService._();

  Interpreter? _leafInterpreter;
  Interpreter? _diseaseInterpreter;
  List<String> _leafLabels = const [];
  List<String> _diseaseLabels = const [];

  bool get isInitialized =>
      _leafInterpreter != null && _diseaseInterpreter != null;

  List<String> get leafLabels => _leafLabels;
  List<String> get diseaseLabels => _diseaseLabels;

  Future<void> init() async {
    if (isInitialized) return;

    final options = InterpreterOptions()..threads = 2;

    _leafInterpreter = await Interpreter.fromAsset(
      'assets/models/leaf_detection.tflite',
      options: options,
    );
    _diseaseInterpreter = await Interpreter.fromAsset(
      'assets/models/disease_classification.tflite',
      options: options,
    );

    _leafLabels = await _loadLabels('assets/labels/leaf_labels.txt');
    _diseaseLabels = await _loadLabels('assets/labels/disease_labels.txt');
  }

  Future<List<String>> _loadLabels(String path) async {
    final text = await rootBundle.loadString(path);
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  Tensor get leafInputTensor => _leafInterpreter!.getInputTensor(0);
  Tensor get diseaseInputTensor => _diseaseInterpreter!.getInputTensor(0);

  List<double> runLeaf(Uint8List inputBytes) {
    final output = List.filled(2, 0).reshape([1, 2]);
    _leafInterpreter!.run(inputBytes.reshape([1, inputBytes.length]), output);
    return (output[0] as List).map((e) => (e as num).toDouble()).toList();
  }

  List<double> runDisease(Uint8List inputBytes, int classCount) {
    final output = List.filled(classCount, 0).reshape([1, classCount]);
    _diseaseInterpreter!
        .run(inputBytes.reshape([1, inputBytes.length]), output);
    return (output[0] as List).map((e) => (e as num).toDouble()).toList();
  }

  void dispose() {
    _leafInterpreter?.close();
    _diseaseInterpreter?.close();
    _leafInterpreter = null;
    _diseaseInterpreter = null;
  }
}

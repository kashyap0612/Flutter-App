import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/inference_result.dart';
import 'model_service.dart';
import 'storage_service.dart';

class InferenceService {
  InferenceService({
    required ModelService modelService,
    required StorageService storageService,
    this.leafThreshold = 0.5,
    this.diseaseThreshold = 0.0,
  })  : _modelService = modelService,
        _storageService = storageService;

  final ModelService _modelService;
  final StorageService _storageService;
  final double leafThreshold;
  final double diseaseThreshold;

  Future<InferenceResult> runPipeline(File imageFile) async {
    await _modelService.init();

    final savedImagePathFuture = _storageService.saveImage(imageFile);

    final leafSize = _modelService.leafInputTensor.shape[1];
    final leafBytes = await compute(
      _preprocessImage,
      _PreprocessRequest(path: imageFile.path, size: leafSize),
    );

    final leafOutput = _modelService.runLeaf(leafBytes);
    final leafMax = _argMax(leafOutput);
    final leafConfidence = leafOutput[leafMax];
    final leafLabel = _labelAt(_modelService.leafLabels, leafMax);
    final isLeaf = leafLabel.toLowerCase().contains('leaf')
        ? !leafLabel.toLowerCase().contains('non') &&
            !leafLabel.toLowerCase().contains('no')
        : leafMax == 1;

    final savedImagePath = await savedImagePathFuture;

    if (!isLeaf || leafConfidence < leafThreshold) {
      return InferenceResult(
        isLeaf: false,
        leafLabel: leafLabel,
        leafConfidence: leafConfidence,
        savedImagePath: savedImagePath,
      );
    }

    final diseaseSize = _modelService.diseaseInputTensor.shape[1];
    final diseaseBytes = await compute(
      _preprocessImage,
      _PreprocessRequest(path: imageFile.path, size: diseaseSize),
    );

    final diseaseOutput =
        _modelService.runDisease(diseaseBytes, _modelService.diseaseLabels.length);
    final diseaseMax = _argMax(diseaseOutput);
    final diseaseConfidence = diseaseOutput[diseaseMax];

    return InferenceResult(
      isLeaf: true,
      leafLabel: leafLabel,
      leafConfidence: leafConfidence,
      diseaseLabel: diseaseConfidence >= diseaseThreshold
          ? _labelAt(_modelService.diseaseLabels, diseaseMax)
          : 'Low confidence',
      diseaseConfidence: diseaseConfidence,
      savedImagePath: savedImagePath,
    );
  }

  static int _argMax(List<double> values) {
    var maxIndex = 0;
    var maxValue = values[0];
    for (var i = 1; i < values.length; i++) {
      if (values[i] > maxValue) {
        maxValue = values[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  static String _labelAt(List<String> labels, int index) {
    if (index < 0 || index >= labels.length) {
      return 'Unknown';
    }
    return labels[index];
  }
}

class _PreprocessRequest {
  const _PreprocessRequest({required this.path, required this.size});

  final String path;
  final int size;
}

Uint8List _preprocessImage(_PreprocessRequest request) {
  final bytes = File(request.path).readAsBytesSync();
  final original = img.decodeImage(bytes);
  if (original == null) {
    throw Exception('Unable to decode image');
  }

  final resized = img.copyResize(original, width: request.size, height: request.size);
  final buffer = Uint8List(request.size * request.size * 3);

  var i = 0;
  for (var y = 0; y < request.size; y++) {
    for (var x = 0; x < request.size; x++) {
      final pixel = resized.getPixel(x, y);
      buffer[i++] = pixel.r.toInt();
      buffer[i++] = pixel.g.toInt();
      buffer[i++] = pixel.b.toInt();
    }
  }

  return buffer;
}

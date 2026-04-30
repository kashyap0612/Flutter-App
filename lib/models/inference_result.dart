class InferenceResult {
  final String label;
  final String cropType;
  final double confidence;
  final List<Map<String, dynamic>> topPredictions;

  const InferenceResult({
    required this.label,
    required this.cropType,
    required this.confidence,
    required this.topPredictions,
  });
}

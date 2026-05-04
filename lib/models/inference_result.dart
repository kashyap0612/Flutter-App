class InferenceResult {
  const InferenceResult({
    required this.isLeaf,
    required this.leafLabel,
    required this.leafConfidence,
    this.diseaseLabel,
    this.diseaseConfidence,
    required this.savedImagePath,
  });

  final bool isLeaf;
  final String leafLabel;
  final double leafConfidence;
  final String? diseaseLabel;
  final double? diseaseConfidence;
  final String savedImagePath;
}

import 'package:flutter/services.dart' show rootBundle;

class LabelService {
  Future<List<String>> loadLabels() async {
    final content = await rootBundle.loadString('assets/labels/disease_labels.txt');
    return content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String extractCropType(String diseaseLabel) {
    if (diseaseLabel.toLowerCase().contains('healthy')) {
      return diseaseLabel.split('___').first.replaceAll('_', ' ');
    }
    final parts = diseaseLabel.split('___');
    return parts.isNotEmpty ? parts.first.replaceAll('_', ' ') : 'Unknown';
  }
}

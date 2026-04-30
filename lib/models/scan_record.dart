import 'dart:convert';

class ScanRecord {
  static const boxName = 'scan_history';

  final String id;
  final String imagePath;
  final String prediction;
  final double confidence;
  final DateTime timestamp;
  final String cropType;
  final List<Map<String, dynamic>> topPredictions;

  const ScanRecord({
    required this.id,
    required this.imagePath,
    required this.prediction,
    required this.confidence,
    required this.timestamp,
    required this.cropType,
    required this.topPredictions,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'prediction': prediction,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
        'cropType': cropType,
        'topPredictions': topPredictions,
      };

  factory ScanRecord.fromMap(Map<dynamic, dynamic> map) {
    final rawTopPredictions = map['topPredictions'] as List<dynamic>? ?? const [];
    return ScanRecord(
      id: map['id'] as String,
      imagePath: map['imagePath'] as String,
      prediction: map['prediction'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
      cropType: map['cropType'] as String? ?? 'Unknown',
      topPredictions: rawTopPredictions
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  String toJson() => jsonEncode(toMap());
}

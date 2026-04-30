import 'dart:io';

import 'package:flutter/material.dart';

import '../models/inference_result.dart';
import '../models/scan_record.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class ResultScreen extends StatefulWidget {
  final File imageFile;
  final InferenceResult result;

  const ResultScreen({super.key, required this.imageFile, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();

  Future<ScanRecord> _recordFromResult() async {
    final savedPath = await _storage.persistImage(widget.imageFile);
    return ScanRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: savedPath,
      prediction: widget.result.label,
      confidence: widget.result.confidence,
      timestamp: DateTime.now(),
      cropType: widget.result.cropType,
      topPredictions: widget.result.topPredictions,
    );
  }

  Future<void> _saveRecord() async {
    final record = await _recordFromResult();
    await _storage.saveRecord(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record saved locally.')));
  }

  Future<void> _uploadRecord() async {
    try {
      final record = await _recordFromResult();
      await _apiService.uploadScan(record);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload successful.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Result')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(widget.imageFile, height: 220, fit: BoxFit.cover)),
          const SizedBox(height: 16),
          Text(widget.result.label, style: Theme.of(context).textTheme.headlineSmall),
          Text('Confidence: ${Formatters.percent(widget.result.confidence)}'),
          Text('Crop Type: ${widget.result.cropType}'),
          Text('Timestamp: ${Formatters.dateTime(DateTime.now())}'),
          const SizedBox(height: 12),
          const Text('Top Predictions', style: TextStyle(fontWeight: FontWeight.bold)),
          ...widget.result.topPredictions.map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e['label']}'),
              trailing: Text(Formatters.percent((e['confidence'] as num).toDouble())),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _saveRecord, child: const Text('Save Record')),
          ElevatedButton(onPressed: _uploadRecord, child: const Text('Upload to Server')),
          OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Scan Another')),
        ],
      ),
    );
  }
}

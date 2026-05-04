import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inference_result.dart';
import '../services/inference_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.inferenceService});

  final InferenceService inferenceService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  File? _imageFile;
  InferenceResult? _result;
  String? _error;
  bool _isRunning = false;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 95);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _result = null;
      _error = null;
    });
  }

  Future<void> _runInference() async {
    final file = _imageFile;
    if (file == null) return;

    setState(() {
      _isRunning = true;
      _result = null;
      _error = null;
    });

    try {
      final result = await widget.inferenceService.runPipeline(file);
      setState(() {
        _result = result;
      });
    } catch (_) {
      setState(() {
        _error = 'Inference failed. Please try another image.';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('Leaf Disease Inference')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _imageFile == null
                  ? const Center(child: Text('Select or capture an image'))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isRunning || _imageFile == null ? null : _runInference,
              child: const Text('Run Inference'),
            ),
            const SizedBox(height: 20),
            if (_isRunning) const Center(child: CircularProgressIndicator()),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            if (result != null) _ResultView(result: result),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({required this.result});

  final InferenceResult result;

  @override
  Widget build(BuildContext context) {
    if (!result.isLeaf) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No leaf detected. Please upload a valid leaf image.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Leaf model output: ${result.leafLabel}'),
          Text('Confidence: ${(result.leafConfidence * 100).toStringAsFixed(2)}%'),
          Text('Saved image: ${result.savedImagePath}'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Leaf detected: ${result.leafLabel}'),
        Text('Leaf confidence: ${(result.leafConfidence * 100).toStringAsFixed(2)}%'),
        const SizedBox(height: 8),
        Text('Disease: ${result.diseaseLabel ?? 'Unknown'}'),
        Text(
          'Disease confidence: ${((result.diseaseConfidence ?? 0) * 100).toStringAsFixed(2)}%',
        ),
        const SizedBox(height: 8),
        Text('Saved image: ${result.savedImagePath}'),
      ],
    );
  }
}

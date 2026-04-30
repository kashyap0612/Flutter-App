import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/inference_service.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final InferenceService _inferenceService = InferenceService();
  bool _loading = false;

  Future<void> _handleImage(ImageSource source) async {
    final granted = await _requestPermission(source);
    if (!granted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final result = await _inferenceService.runInference(picked.path);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ResultScreen(imageFile: File(picked.path), result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Disease Detector')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 88, color: Color(0xFF2E7D32)),
              const SizedBox(height: 12),
              const Text('AI Crop Disease Detection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_loading) const CircularProgressIndicator(),
              if (!_loading) ...[
                ElevatedButton.icon(
                  onPressed: () => _handleImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Image'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload from Gallery'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                  icon: const Icon(Icons.history),
                  label: const Text('History'),
                ),
              ],
              const SizedBox(height: 24),
              const Text('Built for offline-first crop diagnosis and scalable backend integration.'),
            ],
          ),
        ),
      ),
    );
  }
}

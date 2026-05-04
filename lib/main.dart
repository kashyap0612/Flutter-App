import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/inference_service.dart';
import 'services/model_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final modelService = ModelService.instance;
  final storageService = StorageService();
  final inferenceService = InferenceService(
    modelService: modelService,
    storageService: storageService,
  );

  runApp(MyApp(inferenceService: inferenceService));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.inferenceService});

  final InferenceService inferenceService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaf Disease Inference',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: HomeScreen(inferenceService: inferenceService),
    );
  }
}

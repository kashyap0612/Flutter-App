import 'dart:io';

import 'package:dio/dio.dart';

import '../models/scan_record.dart';

class ApiService {
  final Dio _dio;
  final String baseUrl;

  ApiService({
    Dio? dio,
    this.baseUrl = 'https://example.com/api/v1',
  }) : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  Future<void> uploadScan(ScanRecord record) async {
    final data = FormData.fromMap({
      'image': await MultipartFile.fromFile(record.imagePath,
          filename: record.imagePath.split('/').last),
      'prediction': record.prediction,
      'confidence': record.confidence,
      'timestamp': record.timestamp.toIso8601String(),
      'cropType': record.cropType,
    });

    try {
      await _dio.post('$baseUrl/scans/upload', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? e.message ?? 'Upload failed');
    } on SocketException {
      throw Exception('No internet connection. Please retry later.');
    }
  }
}

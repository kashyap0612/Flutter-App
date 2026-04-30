import 'dart:io';

import 'package:flutter/material.dart';

import '../models/scan_record.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();

  @override
  Widget build(BuildContext context) {
    final records = _storage.allRecords();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: records.isEmpty
          ? const Center(child: Text('No scans yet.'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Dismissible(
                  key: ValueKey(record.id),
                  background: Container(color: Colors.redAccent),
                  onDismissed: (_) async {
                    await _storage.deleteRecord(record.id, record.imagePath);
                    setState(() {});
                  },
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(record.imagePath), width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    title: Text(record.prediction),
                    subtitle: Text(Formatters.dateTime(record.timestamp)),
                    trailing: Text(Formatters.percent(record.confidence)),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(record.prediction),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.file(File(record.imagePath), height: 140),
                            Text('Crop: ${record.cropType}'),
                            Text('Confidence: ${Formatters.percent(record.confidence)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

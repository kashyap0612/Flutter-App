import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/scan_record.dart';

class StorageService {
  final Box _box = Hive.box(ScanRecord.boxName);

  Future<String> persistImage(File source) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final copied = await source.copy(targetPath);
    return copied.path;
  }

  Future<void> saveRecord(ScanRecord record) async {
    await _box.put(record.id, record.toMap());
  }

  List<ScanRecord> allRecords() {
    return _box.values
        .map((v) => ScanRecord.fromMap(Map<dynamic, dynamic>.from(v as Map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> deleteRecord(String id, String imagePath) async {
    await _box.delete(id);
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

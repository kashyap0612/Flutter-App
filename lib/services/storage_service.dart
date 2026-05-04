import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageService {
  Future<String> saveImage(File imageFile) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final inferenceDir = Directory(p.join(baseDir.path, 'inference_images'));

    if (!await inferenceDir.exists()) {
      await inferenceDir.create(recursive: true);
    }

    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}_${now.millisecond.toString().padLeft(3, '0')}';
    final fileName = 'leaf_$timestamp.jpg';
    final targetPath = p.join(inferenceDir.path, fileName);

    await imageFile.copy(targetPath);
    return targetPath;
  }
}

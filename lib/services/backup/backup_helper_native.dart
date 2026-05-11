import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Native implementation for backup file operations.
class BackupFileHelper {
  static Future<File> saveStringToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  static Future<List<File>> listBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    return files
        .whereType<File>()
        .where((file) => file.path.contains('wealthlens_backup_'))
        .toList();
  }

  static Future<void> deleteFile(Object file) async {
    if (file is File) {
      await file.delete();
    }
  }

  static Future<String> getFileInfo(Object file) async {
    if (file is File) {
      final stat = await file.stat();
      final sizeInKB = stat.size / 1024;
      return '${file.path.split('/').last}\n'
          'Size: ${sizeInKB.toStringAsFixed(2)} KB\n'
          'Modified: ${stat.modified.toLocal()}';
    }
    return 'Unknown file';
  }

  static Future<String> readFileAsString(Object file) async {
    if (file is File) {
      return await file.readAsString();
    }
    return '';
  }
}

import 'dart:io';
import 'dart:typed_data';

/// Native implementation for reading files.
class FileHelper {
  static Future<Uint8List?> readAsBytes(String path) async {
    return await File(path).readAsBytes();
  }
}

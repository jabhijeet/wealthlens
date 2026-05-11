/// Stub for backup file operations on web.
class BackupFileHelper {
  static Future<Object> saveStringToFile(
    String content,
    String fileName,
  ) async {
    // On web, we could trigger a download, but for now we just return the content as a string
    // to satisfy the return type.
    return content;
  }

  static Future<List<Object>> listBackupFiles() async {
    return [];
  }

  static Future<void> deleteFile(Object file) async {}

  static Future<String> getFileInfo(Object file) async {
    return 'Web Backup (Storage in browser)';
  }

  static Future<String> readFileAsString(Object file) async {
    if (file is String) return file;
    return '';
  }
}

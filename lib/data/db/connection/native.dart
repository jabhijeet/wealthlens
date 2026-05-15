import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'wealthlens.db');

    // Get encryption key from secure storage
    const secureStorage = FlutterSecureStorage();
    var key = await secureStorage.read(key: 'db_encryption_key');
    if (key == null) {
      // Generate a new key
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Url.encode(keyBytes);
      await secureStorage.write(key: 'db_encryption_key', value: key);
    }

    // key is base64url-encoded (chars: A-Za-z0-9-_=) — safe for string interpolation.
    return NativeDatabase.createBackgroundConnection(
      File(dbPath),
      isolateSetup: () async {
        if (Platform.isAndroid) {
          await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
          open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
        }
      },
      setup: (rawDb) {
        rawDb
          ..execute("PRAGMA key = '$key'")
          ..execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}

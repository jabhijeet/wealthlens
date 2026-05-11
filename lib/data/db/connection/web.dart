import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import '../../../services/logging/logger_service.dart';

QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: 'wealthlens_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        logger.w(
          '[WealthLens] Web DB using ${result.chosenImplementation}, '
          'missing features: ${result.missingFeatures}. '
          'For full performance (SharedArrayBuffer), serve with COOP/COEP headers.',
        );
      }

      return result.resolvedExecutor;
    }),
  );
}

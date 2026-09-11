import 'package:drift/drift.dart';

import 'database_factory_native.dart'
    if (dart.library.html) 'database_factory_web.dart';

/// Creates a platform-appropriate database executor.
///
/// On native platforms (Android, iOS, Windows, macOS, Linux), this opens
/// an on-disk SQLite database file in the application documents directory.
///
/// On web, this creates a browser-based database using sql.js (data is
/// stored in IndexedDB or localStorage and persists across page reloads).
Future<QueryExecutor> createDatabaseExecutor() {
  return createPlatformDatabaseExecutor();
}

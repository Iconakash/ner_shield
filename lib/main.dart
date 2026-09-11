import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/sync/sync_queue_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phase 1/2 — open the persistent sync-queue database at app boot and
  // override the default in-memory backend with the on-disk file. The
  // override is honoured by every provider that watches
  // [syncQueueDatabaseProvider] — sync queue, drafts, media.
  final db = await SyncQueueDatabase.openInApplicationDocuments();
  runApp(
    ProviderScope(
      overrides: [
        syncQueueDatabaseProvider.overrideWithValue(db),
      ],
      child: const NerShieldApp(),
    ),
  );
}

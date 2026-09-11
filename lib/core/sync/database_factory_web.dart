import 'package:drift/drift.dart';
import 'package:drift/web.dart';

Future<QueryExecutor> createPlatformDatabaseExecutor() async {
  final db = WebDatabase(
    'ner_shield_sync_queue',
    logStatements: false,
  );
  return db;
}

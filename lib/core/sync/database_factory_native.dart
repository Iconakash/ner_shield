import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<QueryExecutor> createPlatformDatabaseExecutor() async {
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'ner_shield_sync_queue.sqlite');
  return NativeDatabase(File(dbPath));
}

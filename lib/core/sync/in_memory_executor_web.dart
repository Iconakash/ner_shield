import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Creates an in-memory database executor for tests (web platform).
QueryExecutor createInMemoryExecutor() {
  return WebDatabase('ner_shield_test');
}

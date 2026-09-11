import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Creates an in-memory database executor for tests (native platforms).
QueryExecutor createInMemoryExecutor() {
  return NativeDatabase.memory();
}

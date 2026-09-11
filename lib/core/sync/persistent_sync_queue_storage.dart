import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/sync_queue_entry.dart';
import 'sync_queue.dart';
import 'sync_queue_database.dart';

/// Drift-backed implementation of [SyncQueueStorage].
///
/// Survives the app process being killed (Phase 1 acceptance criterion:
/// queued operations must NOT disappear on restart). Keeps the
/// [SyncQueueStorage] contract unchanged so existing callers don't refactor.
class PersistentSyncQueueStorage implements SyncQueueStorage {
  PersistentSyncQueueStorage(this._db);

  final SyncQueueDatabase _db;

  @override
  Future<List<SyncQueueEntry>> loadAll() async {
    final rows = await (_db.select(_db.syncQueueRows)).get();
    return rows.map(_toEntry).toList(growable: false);
  }

  @override
  Future<void> saveAll(List<SyncQueueEntry> entries) async {
    await _db.transaction(() async {
      await _db.delete(_db.syncQueueRows).go();
      for (final entry in entries) {
        await _db.into(_db.syncQueueRows).insert(
              _toRow(entry),
              mode: InsertMode.insertOrReplace,
            );
      }
    });
  }

  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _db.delete(_db.syncQueueRows).go();
      await _db.delete(_db.syncAttemptRows).go();
    });
  }

  // -- mapping --------------------------------------------------------------

  SyncQueueRowsCompanion _toRow(SyncQueueEntry entry) {
    return SyncQueueRowsCompanion.insert(
      clientOpId: entry.clientOpId,
      opType: entry.opType,
      entityType: Value(entry.entityType),
      entityId: Value(entry.entityId),
      payloadJson: jsonEncode(entry.payload),
      status: entry.status.name,
      attempts: Value(entry.attempts),
      priority: Value(entry.priority),
      lastError: Value(entry.lastError),
      lastAttemptAt: Value(entry.lastAttemptAt),
      nextRetryAt: Value(entry.nextRetryAt),
      createdAt: entry.createdAt ?? DateTime.now().toUtc().toIso8601String(),
      resourceId: Value(entry.resourceId),
      dependencyClientOpId: Value(entry.dependencyClientOpId),
    );
  }

  SyncQueueEntry _toEntry(SyncQueueRow row) {
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(row.payloadJson);
      payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
    } catch (_) {
      payload = const <String, dynamic>{};
    }
    return SyncQueueEntry(
      clientOpId: row.clientOpId,
      opType: row.opType,
      payload: payload,
      status: _parseStatus(row.status),
      attempts: row.attempts,
      lastError: row.lastError,
      lastAttemptAt: row.lastAttemptAt,
      createdAt: row.createdAt,
      resourceId: row.resourceId,
      entityType: row.entityType,
      entityId: row.entityId,
      priority: row.priority,
      nextRetryAt: row.nextRetryAt,
      dependencyClientOpId: row.dependencyClientOpId,
    );
  }

  SyncQueueStatus _parseStatus(String raw) {
    for (final s in SyncQueueStatus.values) {
      if (s.name == raw) return s;
    }
    // Defensive: an unknown status from an older schema falls back to
    // pending — never silently drops data.
    return SyncQueueStatus.pending;
  }
}
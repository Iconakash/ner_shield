// Phase 1 â€” Persistent offline sync queue test matrix
// (master prompt Â§1.7). All tests run against an in-memory Drift
// database so they execute in `flutter test` without device/emulator.

import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/core/sync/persistent_sync_queue_storage.dart';
import 'package:ner_shield/core/sync/sync_queue.dart';
import 'package:ner_shield/core/sync/sync_queue_database.dart';
import 'package:ner_shield/models/sync_queue_entry.dart';

SyncQueueEntry _entry(
  String id, {
  SyncQueueStatus status = SyncQueueStatus.pending,
  int priority = 0,
  String? nextRetryAt,
}) {
  return SyncQueueEntry(
    clientOpId: id,
    opType: 'FIELD_REPORT',
    payload: {'incident_type': 'FLOOD', 'client_op_id': id},
    status: status,
    createdAt: DateTime.now().toUtc().toIso8601String(),
    priority: priority,
    nextRetryAt: nextRetryAt,
  );
}

void main() {
  group('Phase 1 â€” persistent sync queue lifecycle', () {
    late SyncQueueDatabase db;
    late SyncQueue queue;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      queue = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await queue.ensureLoaded();
    });

    tearDown(() async {
      await queue.dispose();
      await db.close();
    });

    test('1. create queue item â€” survives across storage reload', () async {
      await queue.enqueue(_entry('op-1'));
      final reloaded = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await reloaded.ensureLoaded();
      expect(reloaded.entries, hasLength(1));
      expect(reloaded.entries.single.clientOpId, 'op-1');
    });

    test('2+4. close/restart app simulation â€” queue survives', () async {
      await queue.enqueue(_entry('op-1'));
      await queue.enqueue(_entry('op-2'));
      await queue.dispose();
      final fresh = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await fresh.ensureLoaded();
      expect(fresh.entries.map((e) => e.clientOpId),
          containsAll(['op-1', 'op-2']));
    });

    test('3. reopen queue â€” loadAll returns persisted rows', () async {
      await queue.enqueue(_entry('op-a'));
      final r = await (db.select(db.syncQueueRows)).get();
      expect(r, hasLength(1));
      expect(r.single.clientOpId, 'op-a');
    });

    test('5. network unavailable â€” offline status, not flushed', () async {
      await queue.enqueue(_entry('op-net', status: SyncQueueStatus.offline));
      final flushed = queue.flushable(
        connectivityClass: 'OFFLINE',
        allowedTypes: const {'FIELD_REPORT'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed, isEmpty);
    });

    test('6+7. network restored â€” offline entry transitions & is flushable',
        () async {
      await queue.enqueue(_entry('op-net', status: SyncQueueStatus.offline));
      await queue.markStatus(
        clientOpId: 'op-net',
        status: SyncQueueStatus.pending,
      );
      final flushed = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'FIELD_REPORT'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed.map((e) => e.clientOpId), ['op-net']);
    });

    test('8. retry â€” transient error applies exponential backoff', () async {
      await queue.enqueue(_entry('op-retry'));
      await queue.markStatus(
        clientOpId: 'op-retry',
        status: SyncQueueStatus.failed,
        error: _FakeException('NetworkException'),
        lastError: 'connection reset',
      );
      final updated = queue.entries.single;
      expect(updated.status, SyncQueueStatus.failed);
      expect(updated.attempts, 1);
      expect(updated.nextRetryAt, isNotNull);
      final t = DateTime.parse(updated.nextRetryAt!);
      expect(t.isAfter(DateTime.now().toUtc()), isTrue);
      expect(computeBackoff(1).inSeconds, greaterThanOrEqualTo(2));
    });

    test('9. duplicate operation â€” same client_op_id collapses', () async {
      await queue.enqueue(_entry('op-dup'));
      await queue.enqueue(_entry('op-dup'));
      final rows = await (db.select(db.syncQueueRows)).get();
      expect(rows, hasLength(1));
    });

    test('10. permanent failure â€” validation error â†’ failed, no retry timer',
        () async {
      await queue.enqueue(_entry('op-bad'));
      await queue.markStatus(
        clientOpId: 'op-bad',
        status: SyncQueueStatus.pending,
        error: _FakeException('ValidationException'),
        lastError: 'severity invalid',
      );
      final updated = queue.entries.single;
      expect(updated.status, SyncQueueStatus.failed);
      expect(updated.nextRetryAt, isNull);
      expect(queue.failedCount, 1);
    });

    test('11. conflict â€” preserved locally with conflict status', () async {
      await queue.enqueue(_entry('op-conflict'));
      await queue.markStatus(
        clientOpId: 'op-conflict',
        status: SyncQueueStatus.pending,
        error: _FakeException('ConflictException'),
        lastError: 'duplicate incident',
        resourceId: 'srv-1',
      );
      final updated = queue.entries.single;
      expect(updated.status, SyncQueueStatus.conflict);
      expect(updated.resourceId, 'srv-1');
      expect(queue.entries, hasLength(1));
      expect(queue.attentionCount, 1);
    });

    test('12. successful removal â€” remove clears the row', () async {
      await queue.enqueue(_entry('op-ok'));
      await queue.markStatus(
        clientOpId: 'op-ok',
        status: SyncQueueStatus.synced,
        resourceId: 'srv-99',
      );
      await queue.remove('op-ok');
      final rows = await (db.select(db.syncQueueRows)).get();
      expect(rows, isEmpty);
      expect(queue.syncedCount, 0);
      expect(queue.pendingCount, 0);
    });
  });
  group('Phase 1 â€” sync queue summary surfaces', () {
    late SyncQueueDatabase db;
    late SyncQueue queue;

    setUp(() async {
      db = SyncQueueDatabase.memory();
      queue = SyncQueue(storage: PersistentSyncQueueStorage(db));
      await queue.ensureLoaded();
    });

    tearDown(() async {
      await queue.dispose();
      await db.close();
    });

    test('uploading + attention counters reflect current state', () async {
      await queue.enqueue(_entry('p1', status: SyncQueueStatus.pending));
      await queue.enqueue(_entry('s1', status: SyncQueueStatus.syncing));
      await queue.enqueue(_entry('c1', status: SyncQueueStatus.conflict));
      await queue.enqueue(_entry('d1', status: SyncQueueStatus.synced));
      expect(queue.uploadingCount, 1);
      expect(queue.attentionCount, 1);
      expect(queue.syncedCount, 1);
    });

    test('priority + nextRetryAt gating inside flushable()', () async {
      final future = DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String();
      await queue.enqueue(_entry('p-low', priority: 0));
      await queue.enqueue(_entry('p-high', priority: 100));
      await queue.enqueue(_entry('p-blocked', nextRetryAt: future));
      final flushed = queue.flushable(
        connectivityClass: 'GOOD',
        allowedTypes: const {'FIELD_REPORT'},
        maxOps: 10,
        allowMedia: true,
      );
      expect(flushed.map((e) => e.clientOpId), ['p-high', 'p-low']);
    });
  });

  group('Phase 1 â€” error classification', () {
    test('classifyError routes the canonical exception types', () {
      expect(classifyError(_FakeException('NetworkException')),
          SyncErrorClass.transient);
      expect(classifyError(_FakeException('ValidationException')),
          SyncErrorClass.validation);
      expect(classifyError(_FakeException('UnauthenticatedException')),
          SyncErrorClass.auth);
      expect(classifyError(_FakeException('ConflictException')),
          SyncErrorClass.conflict);
      expect(classifyError(_FakeException('RateLimitedException')),
          SyncErrorClass.transient);
      expect(classifyError(_FakeException('ServerException')),
          SyncErrorClass.transient);
      expect(classifyError(_FakeException('SomethingElse')),
          SyncErrorClass.permanent);
    });

    test('classifyError honours a `code` field on the exception', () {
      expect(classifyError(_CodedException(code: 'NETWORK')),
          SyncErrorClass.transient);
      expect(classifyError(_CodedException(code: 'CONFLICT')),
          SyncErrorClass.conflict);
      expect(classifyError(_CodedException(code: 'UNAUTHENTICATED')),
          SyncErrorClass.auth);
    });
  });
}

class _FakeException implements Exception {
  _FakeException(this.fakeName);
  final String fakeName;
  String get name => fakeName;
  @override
  String toString() => 'Fake($fakeName)';
}

class _CodedException implements Exception {
  _CodedException({required this.code});
  final String code;
  @override
  String toString() => 'Coded($code)';
}

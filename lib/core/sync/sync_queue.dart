import 'dart:async';
import 'dart:math';

import '../../models/sync_queue_entry.dart';

/// Storage abstraction for the sync queue.
///
/// The default in-memory implementation is appropriate for tests and for
/// the transient pre-Drift period. Production code wires the Drift-backed
/// [PersistentSyncQueueStorage] (see lib/core/sync/persistent_sync_queue_storage.dart)
/// so the queue survives process termination.
abstract class SyncQueueStorage {
  Future<void> saveAll(List<SyncQueueEntry> entries);
  Future<List<SyncQueueEntry>> loadAll();
  Future<void> clear();
}

/// Plain in-memory storage. Survives controller rebuilds because the queue
/// manager owns a single instance via Riverpod. Used in unit tests.
class InMemorySyncQueueStorage implements SyncQueueStorage {
  final List<SyncQueueEntry> _entries = [];
  bool _loaded = false;
  bool get isLoaded => _loaded;

  @override
  Future<List<SyncQueueEntry>> loadAll() async {
    _loaded = true;
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> saveAll(List<SyncQueueEntry> entries) async {
    _entries
      ..clear()
      ..addAll(entries);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

/// Thread-safe (single isolate) sync queue manager.
///
/// Exposes a state stream the UI can watch and `flushable()` to pick what
/// to send. The queue itself never claims success — every transition is
/// logged in [history] so a field officer can see the lifecycle.
///
/// Phase 1 additions:
///   * `nextRetryAt` gating inside `flushable()`
///   * `conflict` status + `needsAttention` helpers (model layer)
///   * error classification + exponential backoff helpers
class SyncQueue {
  SyncQueue({SyncQueueStorage? storage})
      : _storage = storage ?? InMemorySyncQueueStorage();

  final SyncQueueStorage _storage;

  final List<SyncQueueEntry> _entries = [];
  final List<SyncAttempt> _history = [];
  final StreamController<List<SyncQueueEntry>> _controller =
      StreamController<List<SyncQueueEntry>>.broadcast();

  bool _initialized = false;

  /// One-shot stream of queue snapshots; emit on every mutation.
  Stream<List<SyncQueueEntry>> get stream => _controller.stream;

  /// Snapshot of current entries (read-only).
  List<SyncQueueEntry> get entries => List.unmodifiable(_entries);

  /// Snapshot of historical attempts (newest first).
  List<SyncAttempt> get history => List.unmodifiable(_history.reversed);

  int get pendingCount => _entries
      .where((e) =>
          e.status == SyncQueueStatus.pending ||
          e.status == SyncQueueStatus.failed ||
          e.status == SyncQueueStatus.offline ||
          e.status == SyncQueueStatus.syncing)
      .length;

  int get syncedCount =>
      _entries.where((e) => e.status == SyncQueueStatus.synced).length;

  int get failedCount =>
      _entries.where((e) => e.status == SyncQueueStatus.failed).length;

  /// Phase 1 — entries the user must resolve manually (CONFLICT + permanent
  /// FAILED).
  int get attentionCount =>
      _entries.where((e) => e.needsAttention).length;

  /// Phase 1 — entries currently uploading.
  int get uploadingCount =>
      _entries.where((e) => e.status == SyncQueueStatus.syncing).length;

  /// Phase 1 — wall-clock instant of the most recent successful flush.
  /// Null if no entry has ever reached `synced`.
  DateTime? get lastSyncedAt {
    DateTime? latest;
    for (final e in _entries) {
      if (e.status != SyncQueueStatus.synced) continue;
      final at = e.lastAttemptAt;
      if (at == null) continue;
      final t = DateTime.tryParse(at);
      if (t == null) continue;
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  /// Phase 1 — wall-clock instant of the most recent failure.
  DateTime? get lastFailedAt {
    DateTime? latest;
    for (final e in _entries) {
      if (e.status != SyncQueueStatus.failed &&
          e.status != SyncQueueStatus.conflict) {
        continue;
      }
      final at = e.lastAttemptAt;
      if (at == null) continue;
      final t = DateTime.tryParse(at);
      if (t == null) continue;
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  /// Lazy load from storage; idempotent.
  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    final loaded = await _storage.loadAll();
    _entries
      ..clear()
      ..addAll(loaded);
    _emit();
  }

  /// Adds an entry to the queue and persists it.
  Future<void> enqueue(SyncQueueEntry entry) async {
    await ensureLoaded();
    _entries.add(entry);
    await _persist();
    _emit();
  }

  /// Updates one entry's status (and optional metadata) in-place.
  ///
  /// When [error] is supplied, the entry is classified via [classifyError]
  /// to decide whether the next attempt should be retried (transient) or
  /// marked as a permanent failure / conflict.
  Future<void> markStatus({
    required String clientOpId,
    required SyncQueueStatus status,
    String? lastError,
    Object? error,
    String? resourceId,
    Duration? retryAfter,
  }) async {
    await ensureLoaded();
    final idx = _entries.indexWhere((e) => e.clientOpId == clientOpId);
    if (idx < 0) return;
    final current = _entries[idx];
    final classification = error != null ? classifyError(error) : null;
    final finalStatus = classification == null
        ? status
        : _statusFromClassification(status, classification);
    final nextRetryAt = _computeNextRetryAt(
      classification: classification,
      retryAfter: retryAfter,
      attempts: current.attempts,
    );
    final updated = current.copyWith(
      status: finalStatus,
      lastError: lastError ?? current.lastError,
      resourceId: resourceId ?? current.resourceId,
      lastAttemptAt: DateTime.now().toUtc().toIso8601String(),
      attempts: finalStatus == SyncQueueStatus.syncing
          ? current.attempts
          : current.attempts + 1,
      nextRetryAt: nextRetryAt,
    );
    _entries[idx] = updated;
    _history.add(
      SyncAttempt(
        clientOpId: clientOpId,
        attempt: updated.attempts,
        at: updated.lastAttemptAt!,
        outcome: finalStatus.name,
        reason: lastError,
        resourceId: resourceId,
      ),
    );
    await _persist();
    _emit();
  }

  /// Removes a successfully-synced entry from the queue.
  Future<void> remove(String clientOpId) async {
    await ensureLoaded();
    _entries.removeWhere((e) => e.clientOpId == clientOpId);
    await _persist();
    _emit();
  }

  /// Returns entries that should be flushed given a connectivity class
  /// (per docs/offline-strategy.md §Sync). Honours `nextRetryAt` and
  /// sorts by priority desc, then createdAt asc.
  ///
  /// Phase 2 — also gates on `dependencyClientOpId`: an op whose parent is
  /// still in the queue OR whose parent has no `resourceId` yet (server id)
  /// is NOT flushable. This is how MEDIA_UPLOAD ops wait for their parent
  /// FIELD_REPORT to succeed before they attempt an upload.
  List<SyncQueueEntry> flushable({
    required String connectivityClass,
    required Set<String> allowedTypes,
    required int maxOps,
    required bool allowMedia,
  }) {
    if (connectivityClass == 'OFFLINE') return const [];
    final now = DateTime.now().toUtc();
    // Index of known terminal op outcomes for fast dependency lookup.
    final knownTerminal = <String, String>{
      for (final e in _entries)
        if (e.status == SyncQueueStatus.synced ||
            e.status == SyncQueueStatus.conflict)
          e.clientOpId: e.status.name,
    };
    final list = _entries
        .where((e) => e.isFlushable)
        .where((e) => allowedTypes.contains(e.opType))
        .where((e) {
          final nr = e.nextRetryAt;
          if (nr == null) return true;
          final t = DateTime.tryParse(nr);
          if (t == null) return true;
          return !t.isAfter(now);
        })
        .where((e) {
          // Phase 2 dependency gating — see [dependencyClientOpId] docs.
          final dep = e.dependencyClientOpId;
          if (dep == null) return true;
          return knownTerminal[dep] == SyncQueueStatus.synced.name;
        })
        .where((e) {
          if (!allowMedia && e.opType == 'MEDIA_UPLOAD') return false;
          return true;
        })
        .toList()
      ..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        if (p != 0) return p;
        final aCreated = DateTime.tryParse(a.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bCreated = DateTime.tryParse(b.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aCreated.compareTo(bCreated);
      });
    return list.take(maxOps).toList();
  }

  /// Releases the underlying stream. Call only at app shutdown.
  Future<void> dispose() async {
    await _controller.close();
  }

  Future<void> _persist() async {
    await _storage.saveAll(List.unmodifiable(_entries));
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_entries));
    }
  }

  SyncQueueStatus _statusFromClassification(
    SyncQueueStatus requested,
    SyncErrorClass classification,
  ) {
    switch (classification) {
      case SyncErrorClass.transient:
        return requested == SyncQueueStatus.syncing
            ? SyncQueueStatus.failed
            : requested;
      case SyncErrorClass.validation:
        return SyncQueueStatus.failed;
      case SyncErrorClass.auth:
        return requested;
      case SyncErrorClass.conflict:
        return SyncQueueStatus.conflict;
      case SyncErrorClass.permanent:
        return SyncQueueStatus.failed;
    }
  }

  String? _computeNextRetryAt({
    required SyncErrorClass? classification,
    required Duration? retryAfter,
    required int attempts,
  }) {
    if (classification == null || retryAfter != null) {
      if (retryAfter == null) return null;
      return DateTime.now().toUtc().add(retryAfter).toIso8601String();
    }
    if (classification == SyncErrorClass.auth ||
        classification == SyncErrorClass.permanent ||
        classification == SyncErrorClass.validation) {
      return null;
    }
    final backoff = computeBackoff(attempts);
    return DateTime.now().toUtc().add(backoff).toIso8601String();
  }
}

// ----------------------------------------------------------------- retry policy

/// Classification of an error encountered while attempting to flush an op.
///
/// Drives whether the entry should be retried automatically, surfaced for
/// user resolution, or marked as permanently failed.
enum SyncErrorClass {
  /// Transient — retry with backoff. Network timeout, 5xx.
  transient,
  /// Validation failure — retry will not help. Surface as a permanent
  /// failure so the user can fix the payload.
  validation,
  /// Auth failure — do not blindly retry. Wait for session restore.
  auth,
  /// Server returned CONFLICT. Preserve local data; user must resolve.
  conflict,
  /// Anything else — treat as permanent.
  permanent,
}

/// Classify an exception thrown by the sync layer. Uses duck-typing so the
/// policy has no compile-time dependency on the exception types in
/// `lib/core/errors/*`. Keeps the policy testable in isolation.
///
/// Recognises:
///   1. `error.runtimeType.toString()` matching the canonical class name
///      (the production path: real `NetworkException` etc.)
///   2. a `name` getter returning the canonical class name (used by tests
///      that want to assert the policy without importing real exceptions)
///   3. a `code` getter matching one of the canonical error codes
SyncErrorClass classifyError(Object error) {
  final name = error.runtimeType.toString();
  final declaredName = _nameOf(error);
  bool matches(String n) => n == name || n == declaredName;
  final code = _codeOf(error);

  if (matches('NetworkException') || code == 'NETWORK') {
    return SyncErrorClass.transient;
  }
  if (matches('ValidationException') || code == 'VALIDATION_ERROR') {
    return SyncErrorClass.validation;
  }
  if (matches('UnauthenticatedException') || code == 'UNAUTHENTICATED') {
    return SyncErrorClass.auth;
  }
  if (matches('ConflictException') || code == 'CONFLICT') {
    return SyncErrorClass.conflict;
  }
  if (matches('RateLimitedException') || code == 'RATE_LIMITED') {
    return SyncErrorClass.transient;
  }
  if (matches('ServerException') || code == 'INTERNAL') {
    return SyncErrorClass.transient;
  }
  return SyncErrorClass.permanent;
}

dynamic _codeOf(Object error) {
  try {
    final dyn = error as dynamic;
    return dyn.code;
  } catch (_) {
    return null;
  }
}

String? _nameOf(Object error) {
  try {
    final dyn = error as dynamic;
    final n = dyn.name;
    return n is String ? n : null;
  } catch (_) {
    return null;
  }
}

/// Exponential backoff with a sane upper bound.
///
/// `attempts` is the number of attempts already made (so the FIRST retry
/// uses `attempts=1` → ~2s). Capped at 5 minutes; jittered deterministically
/// by the attempts count to avoid thundering-herd reconnects.
Duration computeBackoff(int attempts, {Random? rng}) {
  const cap = Duration(minutes: 5);
  final base = 1 << min(8, attempts); // 2,4,8,16,32,64,128,256 seconds
  final jitter = (rng ?? Random(attempts)).nextInt(base ~/ 2 + 1);
  final seconds = base + jitter;
  return Duration(seconds: seconds) > cap ? cap : Duration(seconds: seconds);
}
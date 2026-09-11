import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_queue_entry.freezed.dart';
part 'sync_queue_entry.g.dart';

/// One queued offline operation awaiting flush to the backend.
///
/// The queue mirrors the `/sync/push` op shape (client_op_id + op_type +
/// payload) plus lifecycle metadata surfaced in the UI (status, attempts,
/// last_error, last_attempt_at, created_at).
///
/// Phase 1 — extends the entry with retry + dependency metadata so the
/// queue can survive process termination (persistent storage) and apply a
/// deterministic backoff + dependency-aware flush policy. All new fields
/// are optional/defaulted so older callers and stored rows remain valid.
///
/// Lifecycle (master prompt §27):
///   PENDING → SYNCING → (SYNCED | FAILED | OFFLINE | CONFLICT)
/// and back to PENDING for retry. A local save NEVER claims server success.
@freezed
sealed class SyncQueueEntry with _$SyncQueueEntry {
  const SyncQueueEntry._();

  const factory SyncQueueEntry({
    required String clientOpId,
    required String opType,
    required Map<String, dynamic> payload,
    required SyncQueueStatus status,
    @Default(0) int attempts,
    String? lastError,
    String? lastAttemptAt,
    String? createdAt,
    String? resourceId,
    // -------- Phase 1 additions --------
    /// Logical entity kind ("FIELD_REPORT", "MEDIA", "GPS_PING", ...).
    /// Lets the UI/flush policy reason about the queue without parsing
    /// opType. Optional so existing call-sites are not broken.
    String? entityType,
    /// Server-side ID of the entity once the server has acknowledged it
    /// (different from [resourceId] which records the op-result id).
    String? entityId,
    /// Higher = should flush first. 0 is the default; 100 = critical
    /// (e.g. CRITICAL_FIELD_REPORT).
    @Default(0) int priority,
    /// ISO-8601 wall-clock instant when this entry becomes eligible for
    /// the next flush attempt. NULL = ready now.
    String? nextRetryAt,
    /// client_op_id of the op that must succeed BEFORE this one. Used to
    /// attach a media op to its parent field-report submission, etc.
    String? dependencyClientOpId,
  }) = _SyncQueueEntry;

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) =>
      _$SyncQueueEntryFromJson(json);

  /// True when this entry can still be flushed (PENDING/SYNCING/FAILED).
  bool get isFlushable =>
      status == SyncQueueStatus.pending ||
      status == SyncQueueStatus.failed ||
      status == SyncQueueStatus.syncing;

  /// True when the entry has reached a terminal success state.
  bool get isSynced => status == SyncQueueStatus.synced;

  /// True when the entry is in a terminal non-success state that the
  /// user must resolve manually (CONFLICT or a permanent FAILED).
  bool get needsAttention =>
      status == SyncQueueStatus.conflict || status == SyncQueueStatus.failed;

  /// True when the entry has reached any terminal state (success or
  /// unrecoverable failure).
  bool get isTerminal =>
      status == SyncQueueStatus.synced ||
      status == SyncQueueStatus.conflict;
}

enum SyncQueueStatus {
  pending,
  syncing,
  synced,
  failed,
  offline,
  /// Phase 1 — server returned CONFLICT for this op. Local data is
  /// preserved; the user must resolve the conflict manually.
  conflict,
}

/// One historical record of a sync attempt. Surfaced in the UI for audit.
@freezed
sealed class SyncAttempt with _$SyncAttempt {
  const factory SyncAttempt({
    required String clientOpId,
    required int attempt,
    required String at,
    required String outcome,
    String? reason,
    String? resourceId,
  }) = _SyncAttempt;

  factory SyncAttempt.fromJson(Map<String, dynamic> json) =>
      _$SyncAttemptFromJson(json);
}
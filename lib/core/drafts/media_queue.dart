import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/field_report.dart';
import '../sync/sync_queue_database.dart';

/// Phase 2 — registers [DraftMediaRef] rows for the upload worker and lets
/// it look them up again after an app restart. The actual upload bytes
/// remain on the device under [DraftMediaRef.localPath]; this class only
/// persists the metadata so the queue + worker know what to upload.
class MediaQueue {
  MediaQueue(this._db);

  final SyncQueueDatabase _db;
  static const _uuid = Uuid();

  /// Register a media ref attached to a draft. Returns the persisted row.
  Future<void> enqueue(DraftMediaRef ref, String clientDraftId) async {
    final row = DraftMediaRowsCompanion.insert(
      clientRefId: ref.clientRefId,
      clientDraftId: clientDraftId,
      localPath: ref.localPath,
      contentType: Value(ref.contentType),
      sizeBytes: Value(ref.sizeBytes),
      sha256: Value(ref.sha256),
      capturedAt: Value(ref.capturedAt ??
          DateTime.now().toUtc().toIso8601String()),
      state: const Value('QUEUED'),
    );
    await _db.into(_db.draftMediaRows).insertOnConflictUpdate(row);
  }

  /// All media refs attached to a draft (any state).
  Future<List<DraftMediaRow>> forDraft(String clientDraftId) {
    return (_db.select(_db.draftMediaRows)
          ..where((t) => t.clientDraftId.equals(clientDraftId)))
        .get();
  }

  /// All media refs in QUEUED state across all drafts.
  Future<List<DraftMediaRow>> queued() {
    return (_db.select(_db.draftMediaRows)
          ..where((t) => t.state.equals('QUEUED')))
        .get();
  }

  Future<void> markUploading(String clientRefId) async {
    await (_db.update(_db.draftMediaRows)
          ..where((t) => t.clientRefId.equals(clientRefId)))
        .write(const DraftMediaRowsCompanion(state: Value('UPLOADING')));
  }

  Future<void> markUploaded(String clientRefId, String serverMediaId) async {
    await (_db.update(_db.draftMediaRows)
          ..where((t) => t.clientRefId.equals(clientRefId)))
        .write(DraftMediaRowsCompanion(
      state: const Value('UPLOADED'),
      serverMediaId: Value(serverMediaId),
    ));
  }

  Future<void> markFailed(String clientRefId) async {
    await (_db.update(_db.draftMediaRows)
          ..where((t) => t.clientRefId.equals(clientRefId)))
        .write(const DraftMediaRowsCompanion(state: Value('FAILED')));
  }

  /// Purge every media ref for a draft (called once the parent
  /// FIELD_REPORT + all uploads complete).
  Future<void> purgeDraft(String clientDraftId) async {
    await (_db.delete(_db.draftMediaRows)
          ..where((t) => t.clientDraftId.equals(clientDraftId)))
        .go();
  }

  /// Allocate a new client_ref_id (uuid v4) for a fresh media attachment.
  String newRefId() => _uuid.v4();
}
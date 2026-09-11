import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/field_report.dart';
import '../sync/sync_queue_database.dart';

/// Persistent draft storage (Phase 2).
///
/// Mirrors the drift-backed sync-queue layer so the wizard can survive an
/// app kill. Soft-deletes by default so a ref to a draft can be resurrected
/// if the user undoes the discard action.
class DraftRepository {
  DraftRepository(this._db);

  final SyncQueueDatabase _db;

  /// Persists (inserts or updates) one draft.
  Future<void> save(FieldReportDraft draft) async {
    final payload = jsonEncode({
      ...draft.toJson(),
      'mediaRefs': draft.mediaRefs.map((r) => r.toJson()).toList(),
    });
    await _db.into(_db.draftRows).insertOnConflictUpdate(
      DraftRowsCompanion.insert(
        clientDraftId: draft.clientDraftId,
        payloadJson: payload,
        updatedAt: draft.updatedAt ?? DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  /// All live drafts (not soft-deleted), newest first.
  Future<List<FieldReportDraft>> loadAll() async {
    final query = _db.select(_db.draftRows)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await query.get();
    return rows.map(_toDraft).toList(growable: false);
  }

  /// One draft by id (null if missing or soft-deleted).
  Future<FieldReportDraft?> loadById(String clientDraftId) async {
    final row = await (_db.select(_db.draftRows)
          ..where((t) => t.clientDraftId.equals(clientDraftId)
              & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDraft(row);
  }

  /// Soft-delete (sets `deleted_at`); the row stays in storage for audit.
  Future<void> delete(String clientDraftId) async {
    await (_db.update(_db.draftRows)
          ..where((t) => t.clientDraftId.equals(clientDraftId)))
        .write(DraftRowsCompanion(
      deletedAt: Value(DateTime.now().toUtc().toIso8601String()),
    ));
  }

  /// Hard-delete (used after a draft's parent FIELD_REPORT op reaches
  /// `synced` and all media refs have uploaded).
  Future<void> purge(String clientDraftId) async {
    await (_db.delete(_db.draftRows)
          ..where((t) => t.clientDraftId.equals(clientDraftId)))
        .go();
  }

  FieldReportDraft _toDraft(DraftRow row) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      // Defensive: corrupt row → drop it.
      json = const <String, dynamic>{};
    }
    final refs = (json['mediaRefs'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(DraftMediaRef.fromJson)
            .toList() ??
        const <DraftMediaRef>[];
    final cleaned = Map<String, dynamic>.from(json)..remove('mediaRefs');
    return FieldReportDraft.fromJson({
      ...cleaned,
      'mediaRefs': refs.map((r) => r.toJson()).toList(),
    });
  }
}
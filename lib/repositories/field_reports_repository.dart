import 'package:uuid/uuid.dart';

import '../core/drafts/draft_repository.dart';
import '../core/errors/app_exception.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/cache_first.dart';
import '../models/field_report.dart';
import '../models/sync_models.dart';
import '../models/sync_queue_entry.dart';
import '../services/field_reports_service.dart';

/// Field intel repository — combines network reads, cache-first freshness,
/// and offline draft enqueueing through the sync queue.
///
/// Contract (docs/offline-strategy.md §3):
/// - Reads return [CachedResult] so the UI can render freshness.
/// - Writes (create) go to the network when online; if the network is
///   unavailable or the call fails with a transient error, the draft is
///   queued for later delivery via `/sync/push`.
/// - Validation queue reads require `VERIFY_INCIDENT` server-side; 403s
///   surface to the UI as authorization explanations, never retry loops.
class FieldReportsRepository {
  /// Builds the production repository — wired against the shared Drift DB.
  factory FieldReportsRepository.fromService({
    required FieldReportsService svc,
    required DraftRepository draftRepo,
  }) {
    return FieldReportsRepository._(svc, draftRepo);
  }

  /// Backwards-compatible constructor used by existing tests (no drafts).
  FieldReportsRepository(this._svc, {this.drafts})
      : _mine = CacheFirst(TtlCache(ttl: const Duration(seconds: 30))),
        _queue = CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  FieldReportsRepository._(
    this._svc,
    this.drafts,
  )  : _mine = CacheFirst(TtlCache(ttl: const Duration(seconds: 30))),
        _queue = CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  final FieldReportsService _svc;
  final DraftRepository? drafts;
  final CacheFirst<List<FieldReport>> _mine;
  final CacheFirst<List<FieldReport>> _queue;
  static const _uuid = Uuid();

  /// Reports I authored (current officer). Cached briefly.
  Future<CachedResult<List<FieldReport>>> mine() =>
      _mine.run('mine', fetch: _svc.mine);

  /// Verification queue (VALIDATE_INCIDENT gated server-side).
  Future<CachedResult<List<FieldReport>>> queue() =>
      _queue.run('queue', fetch: _svc.queue);

  /// One report incl. confidence + media.
  Future<FieldReport> detail(String id) => _svc.detail(id);

  /// Submit a draft. Returns the live server-side report on success, or
  /// enqueues a [SyncQueueEntry] and returns a queued marker when the
  /// network is unreachable / validation rejects. Never silently loses data.
  Future<SubmitResult> submit(FieldReportDraft draft) async {
    try {
      final report = await _svc.create(
        incidentType: draft.incidentType!,
        severity: draft.severity!,
        lon: draft.lon!,
        lat: draft.lat!,
        description: draft.description,
        stateCode: draft.stateCode,
        districtCode: draft.districtCode,
        segmentId: draft.segmentId,
        roadCode: draft.roadCode,
        locationName: draft.locationName,
      );
      _mine.invalidateAll();
      return SubmitResult.live(report);
    } on NetworkException catch (e) {
      // Genuine offline: queue locally.
      AppLogger.instance.warn('submit queued (network): ${e.message}');
      final entry = _toQueueEntry(draft, status: SyncQueueStatus.offline);
      return SubmitResult.queued(entry);
    } on ValidationException catch (e) {
      // Server-side validation refused. Retryable; queue for later.
      AppLogger.instance.warn('submit queued (validation): ${e.message}');
      final entry = _toQueueEntry(
        draft,
        status: SyncQueueStatus.pending,
        lastError: e.message,
      );
      return SubmitResult.queued(entry);
    } catch (e, s) {
      AppLogger.instance.error('submit failed', e, s);
      rethrow;
    }
  }

  /// Verifies (or rejects) a report from the queue.
  Future<FieldReport> validate(
    String id, {
    required String decision,
    String? reason,
  }) async {
    final report = await _svc.validate(id, decision: decision, reason: reason);
    _queue.invalidateAll();
    return report;
  }

  /// Lists media for one report.
  Future<List<FieldReportMedia>> listMedia(String reportId) =>
      _svc.listMedia(reportId);

  /// Uploads one media file. Caller is responsible for retry handling
  /// (this returns errors raw; the queue wraps it).
  Future<FieldReportMedia> uploadMedia({
    required String reportId,
    required String localPath,
    String? contentType,
  }) => _svc.uploadMedia(
    reportId: reportId,
    localPath: localPath,
    contentType: contentType,
  );

    /// Reporter trust ledger.
  Future<Map<String, dynamic>> reporterTrust(String reporterId) =>
      _svc.reporterTrust(reporterId);

  /// Public cache invalidation — used by the reconnection reconciler
  /// when pull deltas indicate field reports changed server-side.
  void invalidateAll() {
    _mine.invalidateAll();
    _queue.invalidateAll();
  }

  /// Pushes the given entries via `/sync/push`. Returns the server response
  /// verbatim so callers can update queue status per-op.
  Future<SyncPushResponse> pushBatch({
    required String connectivity,
    required List<SyncQueueEntry> entries,
  }) {
    final ops = entries
        .map(
          (e) => SyncPushOp(
            clientOpId: e.clientOpId,
            opType: e.opType,
            payload: e.payload,
          ),
        )
        .toList();
    return _svc.pushOps(connectivity: connectivity, ops: ops);
  }

  /// Builds the queue entry payload for a draft — single source of truth for
  /// the FIELD_REPORT op shape (master prompt §27).
  static SyncQueueEntry _toQueueEntry(
    FieldReportDraft draft, {
    required SyncQueueStatus status,
    String? lastError,
    String? clientOpId,
  }) {
    final id = clientOpId ?? _uuid.v4();
    return SyncQueueEntry(
      clientOpId: id,
      opType: 'FIELD_REPORT',
      entityType: 'FIELD_REPORT',
      status: status,
      createdAt: DateTime.now().toIso8601String(),
      payload: {
        'incident_type': draft.incidentType,
        'severity': draft.severity,
        'lon': draft.lon,
        'lat': draft.lat,
        if (draft.description != null) 'description': draft.description,
        if (draft.stateCode != null) 'state_code': draft.stateCode,
        if (draft.districtCode != null) 'district_code': draft.districtCode,
        if (draft.segmentId != null) 'segment_id': draft.segmentId,
        if (draft.roadCode != null) 'road_code': draft.roadCode,
        if (draft.locationName != null) 'location_name': draft.locationName,
        'media_local_paths': draft.mediaPaths,
      },
      lastError: lastError,
    );
  }

  /// Phase 2 — builds the FIELD_REPORT op + one MEDIA_UPLOAD op per
  /// attached media ref. All media ops carry `dependencyClientOpId`
  /// pointing at the parent FIELD_REPORT op so the flush worker only
  /// uploads them after the server has acknowledged the parent.
  static ({SyncQueueEntry parent, List<SyncQueueEntry> media})
      buildQueueOpsForDraft(FieldReportDraft draft) {
    final parent = _toQueueEntry(draft, status: SyncQueueStatus.pending);
    final media = <SyncQueueEntry>[];
    for (final ref in draft.mediaRefs) {
      media.add(
        SyncQueueEntry(
          clientOpId: ref.clientRefId,
          opType: 'MEDIA_UPLOAD',
          entityType: 'MEDIA',
          status: SyncQueueStatus.pending,
          createdAt: DateTime.now().toIso8601String(),
          dependencyClientOpId: parent.clientOpId,
          payload: {
            'local_path': ref.localPath,
            if (ref.contentType != null) 'content_type': ref.contentType,
            if (ref.sizeBytes != null) 'size_bytes': ref.sizeBytes,
            if (ref.sha256 != null) 'sha256': ref.sha256,
          },
        ),
      );
    }
    return (parent: parent, media: media);
  }

  /// Builds a new draft shell for the wizard.
  static FieldReportDraft emptyDraft() => FieldReportDraft(
    clientDraftId: _uuid.v4(),
    createdAt: DateTime.now().toIso8601String(),
    updatedAt: DateTime.now().toIso8601String(),
  );
}

/// Result of [FieldReportsRepository.submit].
sealed class SubmitResult {
  const SubmitResult();

  /// Server accepted the report.
  const factory SubmitResult.live(FieldReport report) = SubmitLive;

  /// Network/server refused the call — the draft is queued for later.
  const factory SubmitResult.queued(SyncQueueEntry entry) = SubmitQueued;
}

class SubmitLive extends SubmitResult {
  const SubmitLive(this.report);
  final FieldReport report;
}

class SubmitQueued extends SubmitResult {
  const SubmitQueued(this.entry);
  final SyncQueueEntry entry;
}

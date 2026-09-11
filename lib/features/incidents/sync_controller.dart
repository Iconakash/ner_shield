import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/connectivity/connectivity_manager.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../core/sync/sync_queue.dart';
import '../../models/field_report.dart';
import '../../models/sync_models.dart';
import '../../models/sync_queue_entry.dart';

// Singleton syncQueueProvider is defined in app/providers.dart so that
// other providers (e.g. gpsPingBeaconProvider) can wire it without
// creating a dependency on features/incidents.

/// Phase 2 — current persisted drafts stream (UI badge + reports screen).
final draftsStreamProvider = StreamProvider<List<FieldReportDraft>>((ref) {
  final repo = ref.watch(draftRepositoryProvider);
  final controller = StreamController<List<FieldReportDraft>>.broadcast();
  Future<void>.microtask(() async {
    try {
      controller.add(await repo.loadAll());
    } catch (e, s) {
      AppLogger.instance.error('drafts load failed', e, s);
    }
  });
  // Hook into the queue stream so we re-load whenever a queued FIELD_REPORT
  // reaches `synced` (draft may now be safely purged). The simplest
  // approach: refresh on every queue stream event.
  final sub = ref.read(syncQueueProvider).stream.listen((_) async {
    try {
      if (!controller.isClosed) controller.add(await repo.loadAll());
    } catch (e, s) {
      AppLogger.instance.error('drafts reload failed', e, s);
    }
  });
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  return controller.stream;
});

/// Streamed snapshot of the queue (subscribers see every mutation).
final syncQueueEntriesProvider = StreamProvider<List<SyncQueueEntry>>((ref) {
  final queue = ref.watch(syncQueueProvider);
  final controller = StreamController<List<SyncQueueEntry>>.broadcast();
  // Eager-load persisted entries, then forward stream.
  Future<void>.microtask(() async {
    await queue.ensureLoaded();
    if (!controller.isClosed) {
      controller.add(queue.entries);
    }
  });
  final sub = queue.stream.listen(controller.add);
  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });
  return controller.stream;
});

/// Pulled-from-cache snapshot for synchronous access (UI badges etc.).
final syncQueueSnapshotProvider = Provider<List<SyncQueueEntry>>((ref) {
  final async = ref.watch(syncQueueEntriesProvider);
  return async.valueOrNull ?? const [];
});

/// Sync flush controller — owns the policy-driven batch flush against
/// `/sync/push`. Backed by [SyncQueue] + connectivity class + sync policy.
class SyncFlushController {
  SyncFlushController(this._ref);
  final Ref _ref;

  bool _flushing = false;

  bool get isFlushing => _flushing;

  /// Pushes every flushable entry from the queue to `/sync/push`, applying
  /// the verdict per-op. Idempotent under retry: server dedupes by
  /// `client_op_id` (docs/offline-strategy.md).
  Future<SyncFlushResult> flush() async {
    if (_flushing) {
      return const SyncFlushResult(skipped: 0, accepted: 0, rejected: 0);
    }
    _flushing = true;
    try {
      final queue = _ref.read(syncQueueProvider);
      await queue.ensureLoaded();
      final connectivity = _ref.read(connectivityClassProvider);
      final policy = await _safeFetchPolicy();
      final classPolicy = policy?.policy?[connectivity];
      final allowedTypes = (classPolicy?.allowedTypes ?? const <String>[])
          .toSet();
      final maxOps = classPolicy?.maxOps ?? 0;
      final allowMedia = classPolicy?.allowPhotos ?? false;

      if (connectivity == 'OFFLINE' || maxOps == 0) {
        return const SyncFlushResult(skipped: 0, accepted: 0, rejected: 0);
      }

      final entries = queue.flushable(
        connectivityClass: connectivity,
        allowedTypes: allowedTypes,
        maxOps: maxOps,
        allowMedia: allowMedia,
      );
      if (entries.isEmpty) {
        return const SyncFlushResult(skipped: 0, accepted: 0, rejected: 0);
      }

      // Mark each as SYNCING for UI feedback.
      for (final e in entries) {
        await queue.markStatus(
          clientOpId: e.clientOpId,
          status: SyncQueueStatus.syncing,
        );
      }

      final repo = _ref.read(fieldReportsRepositoryProvider);
      final response = await repo.pushBatch(
        connectivity: connectivity,
        entries: entries,
      );
      int accepted = 0;
      int rejected = 0;
      for (final result in response.results ?? const <SyncOpResult>[]) {
        await queue.markStatus(
          clientOpId: result.clientOpId,
          status: _statusFor(result.status),
          lastError: result.reason,
          resourceId: result.resourceId,
        );
        if (result.status == 'ACCEPTED' || result.status == 'DUPLICATE') {
          accepted++;
          await queue.remove(result.clientOpId);
        } else {
          rejected++;
        }
      }
      // Anything we didn't get a verdict for: leave in SYNCING (next flush).
      // Phase 2 — once a FIELD_REPORT has a resourceId, fire its media
      // uploads. The media flush is best-effort: any failure is
      // captured into the queue entry's lastError by the media upload
      // worker (below).
      await _flushMediaForAcceptedParents(entries, response);
      return SyncFlushResult(
        skipped: entries.length - (accepted + rejected),
        accepted: accepted,
        rejected: rejected,
      );
    } catch (e, s) {
      AppLogger.instance.error('flush failed', e, s);
      rethrow;
    } finally {
      _flushing = false;
    }
  }

  /// Phase 2 — after `/sync/push` returns ACCEPTED for a FIELD_REPORT
  /// op, locate any MEDIA_UPLOAD ops that depended on it and attempt
  /// the multipart upload to `/field/reports/{id}/media`. Success →
  /// `synced` + remove. Failure → re-classify per the policy.
  Future<void> _flushMediaForAcceptedParents(
    List<SyncQueueEntry> attempted,
    SyncPushResponse response,
  ) async {
    final accepted = <String, String>{};
    for (final r in response.results ?? const <SyncOpResult>[]) {
      if ((r.status == 'ACCEPTED' || r.status == 'DUPLICATE') &&
          r.resourceId != null) {
        accepted[r.clientOpId] = r.resourceId!;
      }
    }
    if (accepted.isEmpty) return;
    final queue = _ref.read(syncQueueProvider);
    final media = _ref.read(mediaQueueProvider);
    final repo = _ref.read(fieldReportsRepositoryProvider);
    for (final entry in attempted) {
      final parentId = accepted[entry.clientOpId];
      if (parentId == null) continue;
      // Find the media refs attached to this draft via the local DB.
      final refs = await media.forDraft(entry.clientOpId);
      for (final ref in refs) {
        if (ref.state == 'UPLOADED') continue;
        await media.markUploading(ref.clientRefId);
        try {
          final uploaded = await repo.uploadMedia(
            reportId: parentId,
            localPath: ref.localPath,
            contentType: ref.contentType,
          );
          await media.markUploaded(ref.clientRefId, uploaded.id);
          // Mark the queue entry synced + remove it.
          await queue.markStatus(
            clientOpId: ref.clientRefId,
            status: SyncQueueStatus.syncing,
          );
          await queue.markStatus(
            clientOpId: ref.clientRefId,
            status: SyncQueueStatus.synced,
            resourceId: uploaded.id,
          );
          await queue.remove(ref.clientRefId);
        } catch (e) {
          AppLogger.instance.warn(
            'media upload failed for ${ref.clientRefId}: $e',
          );
          await media.markFailed(ref.clientRefId);
          await queue.markStatus(
            clientOpId: ref.clientRefId,
            status: SyncQueueStatus.syncing,
          );
          await queue.markStatus(
            clientOpId: ref.clientRefId,
            status: SyncQueueStatus.failed,
            error: e,
            lastError: e.toString(),
          );
        }
      }
    }
  }

  Future<SyncPolicy?> _safeFetchPolicy() async {
    try {
      return await _ref.read(syncServiceProvider).policy();
    } on AppException catch (e) {
      AppLogger.instance.warn('sync policy fetch failed: ${e.code}');
      return SyncPolicy.defaults();
    }
  }

  SyncQueueStatus _statusFor(String verdict) {
    switch (verdict) {
      case 'ACCEPTED':
      case 'DUPLICATE':
        return SyncQueueStatus.synced;
      case 'CONFLICT':
        // Phase 1 — server says this op collided with existing state.
        // Local data is preserved; user must resolve.
        return SyncQueueStatus.conflict;
      case 'REJECTED':
      case 'FAILED':
        return SyncQueueStatus.failed;
      case 'DEFERRED':
        return SyncQueueStatus.pending;
      default:
        return SyncQueueStatus.failed;
    }
  }
}

final syncFlushControllerProvider = Provider<SyncFlushController>(
  (ref) => SyncFlushController(ref),
);

/// Auto-sync trigger: kicks a flush whenever connectivity transitions
/// from OFFLINE → anything else. Wired as a side-effecting Riverpod
/// provider so the app boot picks it up automatically.
///
/// Phase 1 — replaces the previous "manual-only" sync trigger with the
/// required automatic-on-reconnect behavior (master prompt §1.4).
final autoSyncOnReconnectProvider = Provider<void>((ref) {
  ref.listen<String>(connectivityClassProvider, (prev, next) {
    if (prev == 'OFFLINE' && next != 'OFFLINE') {
      // fire-and-forget; flush controller is idempotent under re-entry
      // (its own _flushing guard).
      // ignore: discarded_futures
      ref.read(syncFlushControllerProvider).flush();
    }
  });
});

class SyncFlushResult {
  const SyncFlushResult({
    required this.skipped,
    required this.accepted,
    required this.rejected,
  });
  final int skipped;
  final int accepted;
  final int rejected;
  int get total => skipped + accepted + rejected;
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/connectivity/connectivity_manager.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../features/incidents/sync_controller.dart';
import '../auth/auth_controller.dart';

import '../../features/realtime/realtime_controller.dart';
import '../../models/sync_models.dart';
import '../../services/sync_service.dart';


/// Phase 11 — Reconnection reconciliation orchestrator.
///
/// Combines the offline queue, push/flush, pull cache-refresh, cache
/// invalidation, and SSE resume into a single safe reconnection sequence
/// (master prompt §11):
///
///   1. Upload pending operations (→ /sync/push)
///   2. Receive server acknowledgments
///   3. Apply per-op verdicts (synced / failed / conflict)
///   4. Pull scoped cache delta (→ /sync/pull)
///   5. Invalidate stale cache for affected entities
///   6. Refresh risk (→ /risk/latest)
///   7. Refresh route (online plan re-requested)
///   8. Refresh decision cards
///   9. Resume realtime SSE
///
/// The reconciler never overwrites local state blindly — server state is
/// applied as cache invalidation, and the next read fetches fresh data.
/// Network failures in non-critical steps (pull, risk, route) are logged
/// and skipped; the critical push step fails fast so conflicts surface.
class ReconnectionReconciler {
  ReconnectionReconciler(this._ref);

  final Ref _ref;

  /// Guard against overlapping reconciliation runs (e.g. app resume fires
  /// at the same time as a connectivity transition).
  bool _running = false;

  /// Last successful reconciliation instant — exposed for telemetry.
  DateTime? lastCompletedAt;

  /// Public entry point — called automatically on reconnect and on manual
  /// "Sync Now". Returns true if the full sequence completed without a
  /// critical error (push succeeded), false if a critical step failed.
  Future<bool> reconcile() async {
    if (_running) {
      AppLogger.instance.info('reconcile skipped: already in progress');
      return false;
    }
    _running = true;
    try {
      AppLogger.instance.info('reconciliation starting');

      // Step 1+2+3: Upload pending ops and apply ACKs.
      await _uploadPending();

      // Step 4+5: Pull cache delta + invalidate affected entity caches.
      await _pullAndInvalidate();

      // Step 6: Refresh risk state (writes through to offline snapshot).
      await _refreshRisk();

      // Step 7: Refresh route state (re-request live plan if one was in use).
      await _refreshRoute();

      // Step 8: Refresh decision cards (re-run decision fetch).
      await _refreshDecisions();

      // Step 9: Resume SSE.
      _resumeRealtime();

      lastCompletedAt = DateTime.now().toUtc();
      AppLogger.instance.info('reconciliation complete');
      return true;
    } catch (e, s) {
      AppLogger.instance.error('reconciliation failed', e, s);
      return false;
    } finally {
      _running = false;
    }
  }

  // ----------------------------------------------------------------- step 1-3

  /// Steps 1-3: flush the queue, receive ACKs, apply verdicts.
  ///
  /// The flush controller handles the full push cycle internally:
  /// it queries the queue for flushable entries, POSTs them to
  /// `/sync/push`, and applies per-op verdicts (synced / failed /
  /// conflict) back to the queue. Any conflict or permanent failure
  /// surfaces here as a thrown [AppException], which is rethrown so the
  /// caller can surface it to the user.
  Future<void> _uploadPending() async {
    final flushController = _ref.read(syncFlushControllerProvider);
    final result = await flushController.flush();
    AppLogger.instance.info(
      'push complete: accepted=${result.accepted} '
      'rejected=${result.rejected} skipped=${result.skipped}',
    );
  }

  // ----------------------------------------------------------------- step 4-5

  /// Steps 4-5: pull scoped cache delta, invalidate stale caches.
  Future<void> _pullAndInvalidate() async {
    final syncService = _ref.read(syncServiceProvider);

    // Don't attempt pull if still offline — the queue flush above is the
    // only thing that makes sense in a purely offline reconnect.
    final connectivity = _ref.read(connectivityClassProvider);
    if (connectivity == 'OFFLINE') {
      AppLogger.instance.info('pull skipped: still offline');
      return;
    }

    int cursor = 0;
    bool hasMore = true;
    int guard = 0;
    // Pull loop: apply deltas + advance cursor until the server says
    // nextCursor <= cursor (no more changes) or we hit the safety cap.
    while (hasMore && guard < 10) {
      final response = await _safePull(syncService, cursor);
      if (response == null) return;

      await _applyDeltas(response.deltas ?? const []);
      final newCursor = response.nextCursor;
      if (newCursor <= cursor) {
        hasMore = false;
      } else {
        cursor = newCursor;
      }
      guard++;
    }
  }

  /// Apply each delta to the appropriate repository cache. The server
  /// tells us what changed; the client invalidates the local cache so the
  /// next read fetches fresh data (cache-first, not cache-blind).
  Future<void> _applyDeltas(List<SyncPullDelta> deltas) async {
    for (final d in deltas) {
      try {
        switch (d.entityType) {
          case 'ALERT':
            _ref.read(alertsRepositoryProvider).invalidateAll();
            break;
          case 'SHIPMENT':
            _ref.read(shipmentsRepositoryProvider).invalidateAll();
            break;
          case 'RISK':
            _ref.read(riskRepositoryProvider).invalidateLatest();
            break;
          case 'INCIDENT':
          case 'FIELD_REPORT':
            _ref.read(fieldReportsRepositoryProvider).invalidateAll();
            break;
          case 'COMMAND':
            _ref.read(commandRepositoryProvider)
              ..invalidateSummary()
              ..invalidateLayers();
            break;
          default:
            // Unknown entity types are ignored — forward-compatible.
            AppLogger.instance.warn('unknown pull delta type: ${d.entityType}');
        }
      } catch (e) {
        // Cache invalidation must never stop reconciliation.
        AppLogger.instance.warn('cache invalidation failed for ${d.entityType}: $e');
      }
    }
  }

  // ----------------------------------------------------------------- step 6-8

  /// Step 6: force a fresh risk fetch so the offline snapshot is updated.
  Future<void> _refreshRisk() async {
    try {
      final repo = _ref.read(riskRepositoryProvider);
      repo.invalidateLatest();
      await repo.latest();
    } catch (e) {
      // Risk refresh failure is non-critical — the offline snapshot
      // remains valid until the next successful fetch.
      AppLogger.instance.warn('risk refresh failed: $e');
    }
  }

  /// Step 7: refresh the offline route graph snapshot.
  /// Throws if offline routing isn't configured — caught by the caller.
  Future<void> _refreshRoute() async {
    try {
      final repo = _ref.read(routingRepositoryProvider);
      await repo.refreshSnapshot();
    } catch (e) {
      // Route refresh failure is non-critical — the persisted snapshot
      // from the last successful refresh remains available offline.
      AppLogger.instance.warn('route refresh failed: $e');
    }
  }

  /// Step 8: refresh command / decision summary caches.
  Future<void> _refreshDecisions() async {
    try {
      final repo = _ref.read(commandRepositoryProvider);
      repo
        ..invalidateSummary()
        ..invalidateLayers();
      await repo.summary();
    } catch (e) {
      // Decision card refresh is non-critical — stale cached values
      // are still shown until the next successful refresh.
      AppLogger.instance.warn('decision refresh failed: $e');
    }
  }

  // ----------------------------------------------------------------- step 9

  /// Step 9: resume the SSE stream if it was disconnected.
  /// Calls reconnectNow() on the shared client — the method is idempotent;
  /// if the stream is already connected it simply closes and re-establishes
  /// the transport so the server sends the latest events.
  void _resumeRealtime() {
    try {
      final client = _ref.read(sseClientProvider);
      unawaited(client.reconnectNow());
    } catch (e) {
      // SSE resume is best-effort — the client's internal retry timer
      // will re-establish the connection on its own.
      AppLogger.instance.warn('sse resume failed: $e');
    }
  }

  // ------------------------------------------------------------------ helpers

  /// Pull one page of deltas from the server, swallowing network errors
  /// so a flaky pull doesn't abort reconciliation after the critical push
  /// has already succeeded.
  Future<SyncPullResponse?> _safePull(
    SyncService service,
    int cursor,
  ) async {
    try {
      return await service.pull(cursor: cursor);
    } on AppException catch (e) {
      AppLogger.instance.warn('pull failed (cursor=$cursor): ${e.code}');
      return null;
    } catch (e) {
      AppLogger.instance.warn('pull error (cursor=$cursor): $e');
      return null;
    }
  }
}

// ------------------------------------------------------------------ wiring

/// Shared reconciler instance so the app (connectivity transitions,
/// app-resume events, and any manual "Sync Now" action) drive the same
/// safe sequence. The internal `_running` guard makes overlapping
/// invocations a no-op.
final reconnectionReconcilerProvider = Provider<ReconnectionReconciler>(
  (ref) => ReconnectionReconciler(ref),
);

/// Phase 11 — reconciliation coordinator. Mounted once at app boot (read
/// from `NerShieldApp.initState`) so its triggers are active for the whole
/// app lifetime. Riverpod listeners are lazy: a provider only runs when
/// something reads it, hence this explicit mount point.
///
/// Triggers:
///   * connectivity OFFLINE → online: full reconcile sequence.
///   * session restored (auth controller signals readiness): reconcile so
///     a fresh login resynchronises cache + realtime.
///   * app resumed from background (`onAppResumed`): flush queue and
///     refresh caches (master prompt §1.4).
class ReconciliationCoordinator {
  ReconciliationCoordinator(this._ref) {
    _sub = _ref.listen<String>(connectivityClassProvider, (prev, next) {
      if (prev == 'OFFLINE' && next != 'OFFLINE') {
        // Fire-and-forget; reconcile() is guarded against re-entry.
        // ignore: discarded_futures
        unawaited(_ref.read(reconnectionReconcilerProvider).reconcile());
      }
    });

    // Session restored: when a live session appears (login or cold-start
    // restore), run the sequence so the freshly authenticated device
    // resynchronises cache + realtime.
    _authSub = _ref.listen<bool>(isAuthenticatedProvider, (prev, next) {
      final wasSignedIn = prev ?? false;
      final isSignedIn = next;
      if (!wasSignedIn && isSignedIn) {
        // ignore: discarded_futures
        unawaited(_ref.read(reconnectionReconcilerProvider).reconcile());
      }
    });
  }

  final Ref _ref;
  ProviderSubscription<String>? _sub;
  ProviderSubscription<bool>? _authSub;

  /// Called by the app shell on `AppLifecycleState.resumed`.
  Future<void> onAppResumed() async {
    // Only reconcile if we actually believe we're online — offline resume
    // just means the local caches keep serving.
    if (_ref.read(connectivityClassProvider) != 'OFFLINE') {
      await _ref.read(reconnectionReconcilerProvider).reconcile();
    }
  }

  void dispose() {
    _sub?.close();
    _authSub?.close();
  }
}

final reconciliationCoordinatorProvider = Provider<ReconciliationCoordinator>(
  (ref) {
    final coordinator = ReconciliationCoordinator(ref);
    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);

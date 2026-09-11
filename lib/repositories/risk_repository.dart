import '../core/errors/app_exception.dart';
import '../core/risk/offline_risk.dart';
import '../core/risk/offline_risk_store.dart';
import '../core/storage/cache_first.dart';
import '../models/risk_item.dart';
import '../services/risk_service.dart';

/// Risk prediction reads with caching. The backend engine stays the only
/// source of scores/labels/explanations (master prompt §32).
///
/// Phase 6 — every successful fetch is written through to the persistent
/// offline snapshot; on a network failure the last synchronised snapshot is
/// served with an explicit stale/degraded label. The snapshot survives app
/// restart (master prompt §6.1-6.2).
class RiskRepository {
  RiskRepository(
    this._svc, {
    this._offlineStore,
  })  : _latest = CacheFirst(TtlCache(ttl: const Duration(seconds: 60))),
        _explain = CacheFirst(TtlCache(ttl: const Duration(minutes: 2)));

  final RiskService _svc;
  final OfflineRiskStore? _offlineStore;
  final CacheFirst<List<RiskPrediction>> _latest;
  final CacheFirst<RiskExplain> _explain;

  /// Latest prediction per segment, optionally narrowed to one district.
  ///
  /// Serves a fresh cache hit without a network call; on a connectivity
  /// failure falls back to the persisted offline snapshot (last-known data,
  /// always tagged `fromCache: true` with its sync instant). Non-network
  /// failures propagate immediately — stale data never masks a real error.
  Future<CachedResult<List<RiskPrediction>>> latest({String? districtCode}) async {
    try {
      return await _latest.run(
        'latest:${districtCode ?? 'all'}',
        fetch: () async {
          final value = await _svc.latest(districtCode: districtCode);
          // Phase 6 — write-through persistence (survives app restart).
          await _persistSnapshot(value, districtCode);
          return value;
        },
      );
    } on NetworkException {
      final stored = await _loadOffline(districtCode);
      if (stored != null) {
        return CachedResult(
          stored.predictions,
          fromCache: true,
          cachedAt: stored.fetchedAt,
        );
      }
      rethrow;
    }
  }

  /// WHY card for one segment.
  Future<CachedResult<RiskExplain>> explain(String segmentId) =>
      _explain.run('explain:$segmentId', fetch: () => _svc.explain(segmentId));

  /// Phase 6 — the persisted last-known risk with explicit freshness
  /// metadata (for the degraded banner). Null when never synchronised.
  Future<OfflineRiskResult?> offlineSnapshot({
    String? districtCode,
    Duration staleAfter = defaultRiskStaleAfter,
    DateTime? now,
  }) async {
    final store = _offlineStore;
    if (store == null) return null;
    return store.load(staleAfter: staleAfter, now: now);
  }

  void invalidateLatest() => _latest.invalidateAll();

  Future<void> _persistSnapshot(
    List<RiskPrediction> value,
    String? districtCode,
  ) async {
    final store = _offlineStore;
    if (store == null) return;
    try {
      await store.save(
        value,
        districtCode: districtCode,
        fetchedAt: DateTime.now().toUtc(),
      );
    } catch (e) {
      // A persistence failure must never break a live read.
    }
  }

  Future<OfflineRiskResult?> _loadOffline(String? districtCode) async {
    final store = _offlineStore;
    if (store == null) return null;
    try {
      return await store.load();
    } catch (_) {
      return null;
    }
  }
}
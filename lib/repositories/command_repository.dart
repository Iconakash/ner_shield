import '../core/storage/cache_first.dart';
import '../models/command_summary.dart';
import '../models/geojson.dart';
import '../services/command_service.dart';

/// Command Center reads: short-lived caching of the KPI summary and live map
/// layers. Everything is RLS-scoped server-side — no client-side filtering.
class CommandRepository {
  CommandRepository(this._svc)
      : _summary = CacheFirst(
          TtlCache(ttl: const Duration(seconds: 30)),
        ),
        _layers = CacheFirst(TtlCache(ttl: const Duration(seconds: 60)));

  final CommandService _svc;
  final CacheFirst<CommandSummary> _summary;
  final CacheFirst<GeoJsonFeatureCollection> _layers;

  /// The frozen six KPI tiles (30s cache, stale fallback when offline).
  Future<CachedResult<CommandSummary>> summary() =>
      _summary.run('summary', fetch: _svc.summary);

  /// One live map layer (`high-risk-roads` | `disruptions` | `shipments` |
  /// `weather`) as GeoJSON (60s cache, stale fallback when offline).
  Future<CachedResult<GeoJsonFeatureCollection>> layer(String name) =>
      _layers.run('layer:$name', fetch: () => _svc.layer(name));

  void invalidateSummary() => _summary.invalidate('summary');

  void invalidateLayers() => _layers.invalidateAll();
}
import '../core/storage/cache_first.dart';
import '../models/geojson.dart';
import '../services/gis_service.dart';

/// GIS reads with cache-first freshness semantics
/// (docs/offline-strategy.md §cache — every result carries freshness data).
///
/// TTL tiers:
///  - base geography (states/districts): 30 min — quasi-static reference data
///  - static infrastructure (roads/railways/waterways/facilities): 10 min
///  - live accessibility segments: 60 s
///  - locate lookups: 5 min (keyed to an ~11 m grid)
class GisRepository {
  GisRepository(this._svc)
      : _states = CacheFirst(TtlCache(ttl: const Duration(minutes: 30))),
        _districts = CacheFirst(TtlCache(ttl: const Duration(minutes: 30))),
        _roads = CacheFirst(TtlCache(ttl: const Duration(minutes: 10))),
        _railways = CacheFirst(TtlCache(ttl: const Duration(minutes: 10))),
        _waterways = CacheFirst(TtlCache(ttl: const Duration(minutes: 10))),
        _facilities = CacheFirst(TtlCache(ttl: const Duration(minutes: 10))),
        _segments = CacheFirst(TtlCache(ttl: const Duration(seconds: 60))),
        _locate = CacheFirst(TtlCache(ttl: const Duration(minutes: 5)));

  final GisService _svc;
  final CacheFirst<GeoJsonFeatureCollection> _states;
  final CacheFirst<GeoJsonFeatureCollection> _districts;
  final CacheFirst<GeoJsonFeatureCollection> _roads;
  final CacheFirst<GeoJsonFeatureCollection> _railways;
  final CacheFirst<GeoJsonFeatureCollection> _waterways;
  final CacheFirst<GeoJsonFeatureCollection> _facilities;
  final CacheFirst<GeoJsonFeatureCollection> _segments;
  final CacheFirst<LocateResult> _locate;

  Future<CachedResult<GeoJsonFeatureCollection>> states() =>
      _states.run('states', fetch: _svc.states);

  Future<CachedResult<GeoJsonFeatureCollection>> districts({
    String? stateCode,
  }) =>
      _districts.run(
        'districts:$stateCode',
        fetch: () => _svc.districts(stateCode: stateCode),
      );

  Future<CachedResult<LocateResult>> locate({
    required double lon,
    required double lat,
  }) =>
      _locate.run(
        'locate:${lat.toStringAsFixed(4)}:${lon.toStringAsFixed(4)}',
        fetch: () => _svc.locate(lon: lon, lat: lat),
      );

  Future<CachedResult<GeoJsonFeatureCollection>> roads({
    String? stateCode,
    String? districtCode,
  }) =>
      _roads.run(
        'roads:$stateCode:$districtCode',
        fetch: () => _svc.roads(stateCode: stateCode, districtCode: districtCode),
      );

  Future<CachedResult<GeoJsonFeatureCollection>> segments({
    String? districtCode,
    String? status,
  }) =>
      _segments.run(
        'segments:$districtCode:$status',
        fetch: () => _svc.segments(districtCode: districtCode, status: status),
      );

  Future<CachedResult<GeoJsonFeatureCollection>> facilities({
    String? facilityType,
    String? stateCode,
  }) =>
      _facilities.run(
        'facilities:$facilityType:$stateCode',
        fetch: () => _svc.facilities(
          facilityType: facilityType,
          stateCode: stateCode,
        ),
      );

  Future<CachedResult<GeoJsonFeatureCollection>> railways() =>
      _railways.run('railways', fetch: _svc.railways);

  Future<CachedResult<GeoJsonFeatureCollection>> waterways() =>
      _waterways.run('waterways', fetch: _svc.waterways);

  /// Manual refresh (map toolbar): drop everything so the next read
  /// re-fetches instead of serving the TTL cache.
  void invalidateAll() {
    _states.invalidateAll();
    _districts.invalidateAll();
    _roads.invalidateAll();
    _railways.invalidateAll();
    _waterways.invalidateAll();
    _facilities.invalidateAll();
    _segments.invalidateAll();
    _locate.invalidateAll();
  }
}

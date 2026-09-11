import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../models/geojson.dart';

/// Interprets raw GeoJSON geometry into flutter_map shapes.
///
/// `lib/models/geojson.dart` deliberately keeps `geometry` raw — this is the
/// Phase 8 map-engine half of that contract: Point / MultiPoint /
/// LineString / MultiLineString / Polygon / MultiPolygon, lon-lat order.
/// Malformed coordinates are skipped, never thrown (tolerant like the model).
abstract final class GeoJsonGeometry {
  /// Coordinate rings for drawing:
  ///  - Point / MultiPoint → one single-coordinate ring per point
  ///  - LineString / MultiLineString → one ring per line
  ///  - Polygon → the outline ring only (holes are not drawn)
  ///  - MultiPolygon → the outline ring of each polygon
  static List<List<LatLng>> rings(GeoJsonFeature feature) {
    final coords = feature.coordinates;
    switch (feature.geometryType) {
      case 'Point':
        final p = _coord(coords);
        return p == null ? const [] : [
          [p],
        ];
      case 'MultiPoint':
      case 'LineString':
        final ring = _ring(coords);
        return ring.isEmpty ? const [] : [ring];
      case 'MultiLineString':
        return _ringList(coords);
      case 'Polygon':
        final rings = _ringList(coords);
        return rings.isEmpty ? const [] : [rings.first];
      case 'MultiPolygon':
        return [
          for (final polygon in _listOf(coords))
            ..._outlineOf(polygon),
        ];
      default:
        return const [];
    }
  }

  /// A representative anchor point (first/mean coordinate) for marker
  /// placement, hit-testing and the detail sheet subtitle.
  static LatLng? anchor(GeoJsonFeature feature) {
    final all = [
      for (final ring in rings(feature)) ...ring,
    ];
    if (all.isEmpty) return null;
    if (all.length == 1) return all.first;
    var lat = 0.0;
    var lon = 0.0;
    for (final p in all) {
      lat += p.latitude;
      lon += p.longitude;
    }
    return LatLng(lat / all.length, lon / all.length);
  }

  static List<List<LatLng>> _ringList(Object? raw) {
    final out = <List<LatLng>>[];
    for (final item in _listOf(raw)) {
      final ring = _ring(item);
      if (ring.isNotEmpty) out.add(ring);
    }
    return out;
  }

  static List<List<LatLng>> _outlineOf(Object? polygonRings) {
    final rings = _ringList(polygonRings);
    return rings.isEmpty ? const [] : [rings.first];
  }

  static List<dynamic> _listOf(Object? raw) =>
      raw is List ? raw : const [];

  static List<LatLng> _ring(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final c in raw)
        if (_coord(c) != null) _coord(c)!,
    ];
  }

  static LatLng? _coord(Object? raw) {
    if (raw is! List || raw.length < 2) return null;
    final lonRaw = raw[0];
    final latRaw = raw[1];
    if (lonRaw is! num || latRaw is! num) return null;
    return LatLng(latRaw.toDouble(), lonRaw.toDouble());
  }
}

/// Great-circle / planar distance helpers for map hit-testing.
abstract final class GeoDistance {
  /// Haversine distance in meters.
  static double meters(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final s = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * r * math.asin(math.sqrt(s));
  }

  /// Distance in meters from [p] to the closest point on the [a]–[b]
  /// segment, using a local equirectangular projection (adequate at the
  /// district scales the map operates on).
  static double metersToSegment(LatLng p, LatLng a, LatLng b) {
    const r = 6371000.0;
    // Project (a, b, p) into a common local plane in meters.
    final cosLat = math.cos(_rad(p.latitude));
    double mx(LatLng q) => _rad(q.longitude - p.longitude) * r * cosLat;
    double my(LatLng q) => _rad(q.latitude - p.latitude) * r;

    final ax = mx(a);
    final ay = my(a);
    final bx = mx(b);
    final by = my(b);

    final dx = bx - ax;
    final dy = by - ay;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return math.sqrt(ax * ax + ay * ay);

    // a is at the origin in the local frame, so the projection parameter is
    // simply the dot of (a, b) with the unit direction along (a, b) — i.e.
    // the signed distance from a to the foot, divided by |a − b|.
    var t = (-ax * dx - ay * dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    return math.sqrt(cx * cx + cy * cy);
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}

/// Picks the feature the user tapped: the closest feature (by its ring
/// vertices and segments) within a pixel-derived threshold.
abstract final class FeaturePicker {
  /// The nearest feature within [thresholdMeters], with its distance —
  /// null when nothing is within reach.
  static ({GeoJsonFeature feature, double distance})? nearest(
    Iterable<GeoJsonFeature> features,
    LatLng point, {
    required double thresholdMeters,
  }) {
    GeoJsonFeature? best;
    var bestDist = thresholdMeters;
    for (final f in features) {
      final d = _distance(f, point);
      if (d != null && d < bestDist) {
        bestDist = d;
        best = f;
      }
    }
    if (best == null) return null;
    return (feature: best, distance: bestDist);
  }

  static double? _distance(GeoJsonFeature feature, LatLng point) {
    double? best;
    for (final ring in GeoJsonGeometry.rings(feature)) {
      if (ring.isEmpty) continue;
      if (ring.length == 1) {
        final d = GeoDistance.meters(ring.first, point);
        if (best == null || d < best) best = d;
        continue;
      }
      for (var i = 0; i < ring.length - 1; i++) {
        final d = GeoDistance.metersToSegment(point, ring[i], ring[i + 1]);
        if (best == null || d < best) best = d;
      }
    }
    return best;
  }
}

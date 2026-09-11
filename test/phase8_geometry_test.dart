import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ner_shield/features/maps/geojson_adapter.dart';
import 'package:ner_shield/models/geojson.dart';

GeoJsonFeature _feat(String type, Object coordinates,
    [Map<String, dynamic>? props]) {
  return GeoJsonFeature(
    type: 'Feature',
    geometry: {'type': type, 'coordinates': coordinates},
    properties: props ?? const {},
  );
}

void main() {
  group('GeoJsonGeometry.rings', () {
    test('Point → one single-coordinate ring', () {
      final f = _feat('Point', [10.0, 20.0]);
      expect(GeoJsonGeometry.rings(f), [
        [const LatLng(20.0, 10.0)],
      ]);
    });

    test('LineString → one ring of the line', () {
      final f = _feat(
          'LineString',
          [
            [10.0, 20.0],
            [11.0, 21.0],
            [12.0, 22.0],
          ]);
      final rings = GeoJsonGeometry.rings(f);
      expect(rings.length, 1);
      expect(rings.first.length, 3);
      expect(rings.first.first.latitude, 20.0);
      expect(rings.first.first.longitude, 10.0);
      expect(rings.first.last.longitude, 12.0);
    });

    test('MultiLineString → one ring per line', () {
      final f = _feat('MultiLineString', [
        [
          [10.0, 20.0],
          [11.0, 21.0],
        ],
        [
          [30.0, 40.0],
          [31.0, 41.0],
        ],
      ]);
      final rings = GeoJsonGeometry.rings(f);
      expect(rings.length, 2);
      expect(rings[0].first.latitude, 20.0);
      expect(rings[1].first.longitude, 30.0);
    });

    test('Polygon → outline only (first ring)', () {
      final f = _feat('Polygon', [
        [
          [0.0, 0.0],
          [10.0, 0.0],
          [10.0, 10.0],
          [0.0, 10.0],
          [0.0, 0.0],
        ],
        // hole — must be ignored
        [
          [2.0, 2.0],
          [3.0, 2.0],
          [3.0, 3.0],
          [2.0, 3.0],
          [2.0, 2.0],
        ],
      ]);
      final rings = GeoJsonGeometry.rings(f);
      expect(rings.length, 1);
      expect(rings.first.length, 5);
    });

    test('MultiPolygon → one outline ring per polygon', () {
      final f = _feat('MultiPolygon', [
        [
          [
            [0.0, 0.0],
            [1.0, 0.0],
            [1.0, 1.0],
            [0.0, 0.0],
          ],
        ],
        [
          [
            [5.0, 5.0],
            [6.0, 5.0],
            [6.0, 6.0],
            [5.0, 5.0],
          ],
        ],
      ]);
      final rings = GeoJsonGeometry.rings(f);
      expect(rings.length, 2);
      expect(rings[0].first.longitude, 0.0);
      expect(rings[1].first.longitude, 5.0);
    });

    test('malformed coordinates are skipped, never thrown', () {
      final f = _feat('LineString', [
        [10.0, 20.0],
        ['bogus', 'values'],
        [11.0, 21.0],
      ]);
      final rings = GeoJsonGeometry.rings(f);
      expect(rings.length, 1);
      expect(rings.first.length, 2);
    });

    test('unknown geometry type returns no rings', () {
      final f = _feat('GeometryCollection', []);
      expect(GeoJsonGeometry.rings(f), isEmpty);
    });
  });

  group('GeoJsonGeometry.anchor', () {
    test('single-point feature returns that point', () {
      final f = _feat('Point', [10.0, 20.0]);
      expect(GeoJsonGeometry.anchor(f), const LatLng(20.0, 10.0));
    });

    test('multi-point feature returns the centroid (mean)', () {
      final f = _feat('MultiPoint', [
        [0.0, 0.0],
        [10.0, 10.0],
      ]);
      expect(GeoJsonGeometry.anchor(f), const LatLng(5.0, 5.0));
    });

    test('returns null for features with no rings', () {
      final f = _feat('Point', []);
      expect(GeoJsonGeometry.anchor(f), isNull);
    });
  });

  group('GeoDistance.metersToSegment', () {
    test('perpendicular foot of the midpoint', () {
      // Line along the equator from lon=0 to lon=1; tap is 1° due north
      // of the midpoint → ~111 km.
      const a = LatLng(0.0, 0.0);
      const b = LatLng(0.0, 1.0);
      const p = LatLng(1.0, 0.5);
      final d = GeoDistance.metersToSegment(p, a, b);
      expect(d, closeTo(111_000, 2_000));
    });

    test('projects onto endpoint when closer', () {
      const a = LatLng(0.0, 0.0);
      const b = LatLng(1.0, 0.0);
      // 0.05° past the end of the segment (~ 5.5 km). The foot clamps to b.
      const p = LatLng(1.05, 0.0);
      final d = GeoDistance.metersToSegment(p, a, b);
      expect(d, closeTo(5_500, 500));
    });
  });

  group('FeaturePicker.nearest', () {
    test('returns the closest feature within the threshold', () {
      // GeoJSON coordinates are [lon, lat]; near the equator 0.1° ≈ 11 km,
      // so 0.5° between the tap and the [0.5, 0.5] point is ~62 km.
      final features = [
        _feat('Point', [10.0, 20.0]),
        _feat('Point', [0.5, 0.5]),
        _feat('Point', [50.0, 50.0]),
      ];
      const tap = LatLng(0.4, 0.4);
      final hit = FeaturePicker.nearest(
        features,
        tap,
        thresholdMeters: 100_000,
      );
      expect(hit, isNotNull);
      expect(hit!.feature.coordinates, [0.5, 0.5]);
    });

    test('returns null when nothing is within the threshold', () {
      final features = [
        _feat('Point', [10.0, 20.0]),
        _feat('Point', [50.0, 50.0]),
      ];
      const tap = LatLng(0.0, 0.0);
      expect(
        FeaturePicker.nearest(features, tap, thresholdMeters: 1000),
        isNull,
      );
    });

    test('picks the closest ring vertex / segment for LineString', () {
      // GeoJSON ordering: [[lon, lat], ...]. The first line runs along the
      // equator from lon=0 to lon=10 — the tap at lat=0.0001, lon=5.0 sits
      // about 11 m north of the midpoint.
      final features = [
        _feat('LineString', [
          [0.0, 0.0],
          [10.0, 0.0],
        ]),
        _feat('LineString', [
          [50.0, 50.0],
          [51.0, 51.0],
        ]),
      ];
      const tap = LatLng(0.0001, 5.0);
      final hit = FeaturePicker.nearest(
        features,
        tap,
        thresholdMeters: 1_000_000,
      );
      expect(hit, isNotNull);
      expect(hit!.feature.geometryType, 'LineString');
      // The first ring sits right under the tap.
      expect(hit.distance, lessThan(50));
    });
  });
}

import 'package:dio/dio.dart';

import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/models/cached_result.dart';
import 'package:ner_shield/models/geojson.dart';
import 'package:ner_shield/repositories/command_repository.dart';
import 'package:ner_shield/repositories/gis_repository.dart';
import 'package:ner_shield/services/command_service.dart';
import 'package:ner_shield/services/gis_service.dart';

/// Test fixtures shared with the map-screen widget tests.
GeoJsonFeature testSegment(String id, String status) {
  return GeoJsonFeature(
    type: 'Feature',
    id: id,
    geometry: {
      'type': 'LineString',
      'coordinates': [
        [91.70, 26.10],
        [91.80, 26.20],
      ],
    },
    properties: {
      'segment_id': id,
      'name': 'Segment $id',
      'status': status,
      'updated_at': '2026-08-31T09:00:00+00:00',
    },
  );
}

GeoJsonFeature testPointFeat(String id, double lon, double lat, String name) {
  return GeoJsonFeature(
    type: 'Feature',
    id: id,
    geometry: {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    properties: {
      'name': name,
      'type': 'facility',
    },
  );
}

class TestGisRepo extends GisRepository {
  TestGisRepo() : super(GisService(Dio(BaseOptions(baseUrl: 'http://t'))));

  CachedResult<GeoJsonFeatureCollection> get segmentsResult => CachedResult(
        GeoJsonFeatureCollection(
          type: 'FeatureCollection',
          features: [
            testSegment('A', 'OPEN'),
            testSegment('B', 'CLOSED'),
          ],
        ),
        fromCache: false,
        cachedAt: DateTime(2026, 8, 31, 10),
      );

  CachedResult<GeoJsonFeatureCollection> get facilitiesResult => CachedResult(
        GeoJsonFeatureCollection(
          type: 'FeatureCollection',
          features: [
            testPointFeat('hub-1', 91.74, 26.14, 'Hub One'),
          ],
        ),
        fromCache: false,
        cachedAt: DateTime(2026, 8, 31, 10),
      );

  @override
  Future<CachedResult<GeoJsonFeatureCollection>> segments({
    String? districtCode,
    String? status,
  }) async =>
      segmentsResult;

  @override
  Future<CachedResult<GeoJsonFeatureCollection>> facilities({
    String? facilityType,
    String? stateCode,
    double? nearLon,
    double? nearLat,
    double? radiusM,
  }) async =>
      facilitiesResult;

  @override
  Future<CachedResult<LocateResult>> locate({
    required double lon,
    required double lat,
  }) async {
    return CachedResult(
      const LocateResult(
        stateCode: 'AS',
        districtCode: 'KAMRUP',
        operation: 'OK',
      ),
      fromCache: false,
      cachedAt: DateTime(2026, 8, 31, 10),
    );
  }
}

class TestEmptyRepo extends GisRepository {
  TestEmptyRepo() : super(GisService(Dio(BaseOptions(baseUrl: 'http://t'))));

  @override
  Future<CachedResult<GeoJsonFeatureCollection>> segments({
    String? districtCode,
    String? status,
  }) async {
    return CachedResult(
      const GeoJsonFeatureCollection(
        type: 'FeatureCollection',
        features: [],
      ),
      fromCache: true,
      cachedAt: DateTime(2026, 8, 31, 10),
    );
  }
}

class TestThrowingRepo extends GisRepository {
  TestThrowingRepo() : super(GisService(Dio(BaseOptions(baseUrl: 'http://t'))));

  @override
  Future<CachedResult<GeoJsonFeatureCollection>> segments({
    String? districtCode,
    String? status,
  }) async {
    throw const NetworkException('Cannot reach the server.');
  }
}

class TestCommandRepo extends CommandRepository {
  TestCommandRepo()
      : super(CommandService(Dio(BaseOptions(baseUrl: 'http://t'))));

  @override
  Future<CachedResult<GeoJsonFeatureCollection>> layer(String name) async {
    return CachedResult(
      const GeoJsonFeatureCollection(
        type: 'FeatureCollection',
        features: [],
      ),
      fromCache: false,
      cachedAt: DateTime(2026, 8, 31, 10),
    );
  }
}

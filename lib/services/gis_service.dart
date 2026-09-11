import 'package:dio/dio.dart';

import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/geojson.dart';

/// GIS base-geography reads (reference `backend/app/gis/router.py`).
///
/// All routes are read-only and RLS-scoped server-side — the client never
/// narrows geography itself. List endpoints return GeoJSON
/// `FeatureCollection`s; `/gis/locate` returns a small lookup object.
///
/// NOTE: `GET /gis/summary` exists in the backend but its aggregate response
/// shape is not captured in docs/api-contract-map.md, so it is deliberately
/// NOT parsed here (no invented shapes — master prompt §8/§63).
class GisService {
  GisService(this._dio);

  final Dio _dio;

  /// GET /gis/states — NER state boundaries.
  Future<GeoJsonFeatureCollection> states() => _collection('/gis/states');

  /// GET /gis/districts?state_code= — district polygons incl. centroid props.
  Future<GeoJsonFeatureCollection> districts({String? stateCode}) =>
      _collection('/gis/districts', {
        if (stateCode != null && stateCode.isNotEmpty) 'state_code': stateCode,
      });

  /// GET /gis/locate?lon=&lat= — a point → {state_code, district_code,
  /// operation}. Used by map search and long-press inspection.
  Future<LocateResult> locate({required double lon, required double lat}) async {
    try {
      final res = await _dio.get<Object?>(
        '/gis/locate',
        queryParameters: {'lon': lon, 'lat': lat},
      );
      return LocateResult.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /gis/roads?state_code=&district_code= — road network lines.
  Future<GeoJsonFeatureCollection> roads({
    String? stateCode,
    String? districtCode,
  }) =>
      _collection('/gis/roads', {
        if (stateCode != null && stateCode.isNotEmpty)
          'state_code': stateCode,
        if (districtCode != null && districtCode.isNotEmpty)
          'district_code': districtCode,
      });

  /// GET /gis/segments?district_code=&status= — road accessibility segments
  /// ([status]: OPEN | PARTIAL | CLOSED).
  Future<GeoJsonFeatureCollection> segments({
    String? districtCode,
    String? status,
  }) =>
      _collection('/gis/segments', {
        if (districtCode != null && districtCode.isNotEmpty)
          'district_code': districtCode,
        if (status != null && status.isNotEmpty) 'status': status,
      });

  /// GET /gis/facilities?facility_type=&state_code=&near_lon=&near_lat=&radius_m=
  Future<GeoJsonFeatureCollection> facilities({
    String? facilityType,
    String? stateCode,
    double? nearLon,
    double? nearLat,
    double? radiusM,
  }) {
    final q = <String, dynamic>{};
    if (facilityType != null && facilityType.isNotEmpty) {
      q['facility_type'] = facilityType;
    }
    if (stateCode != null && stateCode.isNotEmpty) q['state_code'] = stateCode;
    if (nearLon != null) q['near_lon'] = nearLon;
    if (nearLat != null) q['near_lat'] = nearLat;
    if (radiusM != null) q['radius_m'] = radiusM;
    return _collection('/gis/facilities', q);
  }

  /// GET /gis/railways — railway lines.
  Future<GeoJsonFeatureCollection> railways() => _collection('/gis/railways');

  /// GET /gis/waterways — river/waterway lines.
  Future<GeoJsonFeatureCollection> waterways() => _collection('/gis/waterways');

  Future<GeoJsonFeatureCollection> _collection(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    try {
      final res = await _dio.get<Object?>(path, queryParameters: query);
      return GeoJsonFeatureCollection.fromJson(requireJsonObject(res));
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}

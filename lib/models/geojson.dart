/// Minimal, tolerant GeoJSON model for backend FeatureCollections
/// (`/gis/*`, `/command/layers/*`). Geometry is kept raw — the map engine
/// (Phase 8) interprets `Point`, `LineString`, `MultiLineString`, `Polygon`.
class GeoJsonFeatureCollection {
  const GeoJsonFeatureCollection({required this.type, required this.features});

  final String type;
  final List<GeoJsonFeature> features;

  factory GeoJsonFeatureCollection.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeatureCollection(
      type: (json['type'] as String?) ?? 'FeatureCollection',
      features: ((json['features'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GeoJsonFeature.fromJson)
          .toList(),
    );
  }

  bool get isEmpty => features.isEmpty;
}

class GeoJsonFeature {
  const GeoJsonFeature({
    required this.type,
    required this.geometry,
    required this.properties,
    this.id,
  });

  final String type;
  final Map<String, dynamic> geometry;
  final Map<String, dynamic> properties;
  final Object? id;

  factory GeoJsonFeature.fromJson(Map<String, dynamic> json) {
    return GeoJsonFeature(
      type: (json['type'] as String?) ?? 'Feature',
      geometry: _asMap(json['geometry']),
      properties: _asMap(json['properties']),
      id: json['id'],
    );
  }

  String? get geometryType => geometry['type'] as String?;
  dynamic get coordinates => geometry['coordinates'];

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry('$k', v));
    }
    return const {};
  }
}

/// `GET /gis/locate?lon=&lat=` — `{state_code, district_code, operation}`.
class LocateResult {
  const LocateResult({
    required this.stateCode,
    this.districtCode,
    this.operation,
  });

  final String stateCode;
  final String? districtCode;
  final String? operation;

  factory LocateResult.fromJson(Map<String, dynamic> json) => LocateResult(
        stateCode: (json['state_code'] as String?) ?? '',
        districtCode: json['district_code'] as String?,
        operation: json['operation'] as String?,
      );
}
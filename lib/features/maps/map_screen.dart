import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/maps/offline_tile_provider.dart';
import '../../core/utils/time_format.dart';
import '../../models/geojson.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'feature_detail_sheet.dart';
import 'geojson_adapter.dart';
import 'map_controller.dart' as maps;
import 'map_layers.dart';
import 'map_toolbar.dart';
import 'offline_map_banner.dart';

/// Operational GIS map (Phase 8): OSM raster tiles via the configured
/// tile URL, backend-scoped overlays (`/gis/*` + `/command/layers/*`),
/// layer toggles, coordinate search + long-press locate, and a detail
/// bottom sheet for every feature (docs/ui-ux-plan.md §6, T11).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _map = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _mapReady = false;

  /// Initial camera: the North Eastern Region (rough centroid).
  static const LatLng _initialCenter = LatLng(25.7, 93.0);
  static const double _initialZoom = 5.5;
  static const String _userAgent = 'in.gov.mdoner.nershield';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(maps.mapControllerProvider.notifier).loadEnabled();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maps.mapControllerProvider);
    final config = ref.watch(appConfigProvider);
    final tileFetcher = ref.watch(offlineTileFetcherProvider);

    // Follow the locate pin: when a new point is looked up, move the camera.
    ref.listen<maps.MapState>(maps.mapControllerProvider, (prev, next) {
      final point = next.locatePoint;
      if (point != null && point != prev?.locatePoint && _mapReady) {
        _map.move(point, 12);
      }
    });

    return Column(
      children: [
        MapToolbar(searchController: _searchController),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  minZoom: 4,
                  maxZoom: 17,
                  onMapReady: () => _mapReady = true,
                  onTap: _onMapTap,
                  onLongPress: (_, latLng) => ref
                      .read(maps.mapControllerProvider.notifier)
                      .locateAt(latLng),
                ),
                children: [
                  TileLayer(
                    urlTemplate: config.outboundTileUrl,
                    tileProvider: OfflineTileProvider(
                      fetcher: tileFetcher,
                      urlTemplate: config.outboundTileUrl,
                    ),
                    userAgentPackageName: _userAgent,
                    maxNativeZoom: 19,
                  ),
                  ..._overlayLayers(state),
                  if (state.locatePoint != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          key: const ValueKey('locate-pin'),
                          point: state.locatePoint!,
                          width: 36,
                          height: 36,
                          alignment: Alignment.bottomCenter,
                          child: const Icon(
                            Icons.location_on,
                            size: 34,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () {}, // license requires named attribution
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: OfflineMapBanner(),
              ),
              if (_anyServedFromCache(state))
                Positioned(
                  top: 52,
                  left: 8,
                  right: 8,
                  child: OfflineBanner(lastSyncedLabel: _staleLabel(state)),
                ),
              const Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: LocateCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }


  // ------------------------------------------------------------- overlays

  /// Builds polygon/polyline/marker layers from every enabled, loaded layer.
  /// Features are rendered by their ACTUAL geometry type (tolerant: a layer
  /// flagged `point` still draws whatever the backend really returns).
  List<Widget> _overlayLayers(maps.MapState state) {
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    final selected = state.selected;

    for (final spec in kMapLayers) {
      final layer = state.layers[spec.id];
      if (layer == null || !layer.enabled) continue;
      final fc = layer.data.valueOrNull?.value;
      if (fc == null) continue;

      for (var i = 0; i < fc.features.length; i++) {
        final feature = fc.features[i];
        final rings = GeoJsonGeometry.rings(feature);
        final isSel = selected != null &&
            selected.layerId == spec.id &&
            identical(selected.feature, feature);

        for (var r = 0; r < rings.length; r++) {
          final ring = rings[r];
          if (ring.isEmpty) continue;
          final featureKey = '${spec.id}:$i:${rings.length > 1 ? r : 0}';

          final isPoint = ring.length == 1 &&
              (feature.geometryType == 'Point' ||
                  feature.geometryType == 'MultiPoint');
          if (isPoint) {
            markers.add(
              _pointMarker(spec, feature, featureKey, ring.first, isSel),
            );
          } else {
            final color = _featureColor(spec, feature);
            final isArea = spec.kind == MapGeometryKind.polygon ||
                feature.geometryType == 'Polygon' ||
                feature.geometryType == 'MultiPolygon';
            if (isArea) {
              polygons.add(
                Polygon(
                  points: ring,
                  color: color.withValues(alpha: 0.14),
                  borderStrokeWidth: isSel ? 3 : 1.6,
                  borderColor: color,
                  hitValue: featureKey,
                ),
              );
            } else {
              polylines.add(
                Polyline(
                  points: ring,
                  strokeWidth: spec.id == 'segments' ? 4 : 2.5,
                  color: color.withValues(alpha: isSel ? 1.0 : 0.9),
                  hitValue: featureKey,
                ),
              );
            }
          }
        }
      }
    }

    return [
      if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
      if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
      if (markers.isNotEmpty) MarkerLayer(markers: markers),
    ];
  }

  Marker _pointMarker(
    MapLayerSpec spec,
    GeoJsonFeature feature,
    String featureKey,
    LatLng point,
    bool isSel,
  ) {
    return Marker(
      key: ValueKey('feature-marker-$featureKey'),
      point: point,
      width: 34,
      height: 34,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(spec, feature),
        child: _MarkerBadge(
          icon: spec.icon,
          color: spec.color,
          highlighted: isSel,
        ),
      ),
    );
  }

  /// Road-status layers get the vocabulary color per feature; everything
  /// else keeps its catalog color.
  static Color _featureColor(MapLayerSpec spec, GeoJsonFeature feature) {
    if (spec.id != 'segments') return spec.color;
    for (final key in const ['status', 'road_status', 'acc_classification']) {
      final v = feature.properties[key];
      if (v is String && v.trim().isNotEmpty) {
        return RoadStatusVisuals.of(v).$3;
      }
    }
    return spec.color;
  }


  void _openDetail(MapLayerSpec spec, GeoJsonFeature feature) {
    ref
        .read(maps.mapControllerProvider.notifier)
        .select(maps.SelectedFeature(layerId: spec.id, feature: feature));
    showFeatureDetail(context, layerLabel: spec.label, feature: feature)
        .whenComplete(() {
      if (mounted) {
        ref.read(maps.mapControllerProvider.notifier).select(null);
      }
    });
  }

  /// Tap on empty map space: pick the closest feature within a ~28 px
  /// hit-radius across every enabled, loaded layer; open its detail sheet.
  void _onMapTap(TapPosition _, LatLng latLng) {
    final state = ref.read(maps.mapControllerProvider);
    final zoom = _mapReady ? _map.camera.zoom : _initialZoom;
    final metersPerPixel = 156543.03392 *
        math.cos(latLng.latitudeInRad) /
        math.pow(2, zoom).toDouble();
    var threshold = metersPerPixel * 28;

    maps.SelectedFeature? best;
    for (final spec in kMapLayers) {
      final layer = state.layers[spec.id];
      if (layer == null || !layer.enabled) continue;
      final fc = layer.data.valueOrNull?.value;
      if (fc == null) continue;
      final hit = FeaturePicker.nearest(
        fc.features,
        latLng,
        thresholdMeters: threshold,
      );
      if (hit != null) {
        best = maps.SelectedFeature(layerId: spec.id, feature: hit.feature);
        threshold = hit.distance; // only a closer hit can win now
      }
    }
    if (best != null) {
      _openDetail(_specOf(best.layerId), best.feature);
    }
  }

  MapLayerSpec _specOf(String id) {
    for (final s in kMapLayers) {
      if (s.id == id) return s;
    }
    throw StateError('Unknown map layer id: $id');
  }

  // ------------------------------------------------------------ stale data

  static bool _anyServedFromCache(maps.MapState state) {
    for (final spec in kMapLayers) {
      final layer = state.layers[spec.id];
      if (layer == null || !layer.enabled) continue;
      final result = layer.data.valueOrNull;
      if (result != null && result.servedFromCache) return true;
    }
    return false;
  }

  static String? _staleLabel(maps.MapState state) {
    DateTime? latest;
    for (final spec in kMapLayers) {
      final layer = state.layers[spec.id];
      if (layer == null || !layer.enabled) continue;
      final result = layer.data.valueOrNull;
      if (result == null || !result.servedFromCache) continue;
      final at = result.cachedAt;
      if (at != null && (latest == null || at.isAfter(latest))) latest = at;
    }
    if (latest == null) return null;
    return 'Updated ${TimeFormat.clock(latest.toIso8601String())}.';
  }
}

/// Circular marker badge with icon + color (never color alone — the icon
/// carries the meaning; the detail sheet carries labels).
class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({
    required this.icon,
    required this.color,
    required this.highlighted,
  });

  final IconData icon;
  final Color color;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: highlighted ? 3 : 2,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

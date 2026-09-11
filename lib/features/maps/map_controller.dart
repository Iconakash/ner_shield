import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../models/cached_result.dart';
import '../../models/geojson.dart';
import 'map_layers.dart';

/// Per-layer UI state: visibility + loaded data (or in-flight/error).
class MapLayerState {
  const MapLayerState({
    this.enabled = false,
    this.data = const AsyncValue.loading(),
  });

  final bool enabled;
  final AsyncValue<CachedResult<GeoJsonFeatureCollection>> data;

  bool get isLoading => enabled && data.isLoading;
  bool get hasError => enabled && data.hasError;
  bool get isLoadedAndEmpty =>
      enabled && (data.valueOrNull?.value.isEmpty ?? false);

  MapLayerState copyWith({
    bool? enabled,
    AsyncValue<CachedResult<GeoJsonFeatureCollection>>? data,
  }) {
    return MapLayerState(
      enabled: enabled ?? this.enabled,
      data: data ?? this.data,
    );
  }
}

/// The feature the detail sheet is bound to.
class SelectedFeature {
  const SelectedFeature({required this.layerId, required this.feature});

  final String layerId;
  final GeoJsonFeature feature;
}

/// Whole-map UI state (pure data — the repositories own fetching, the
/// backend owns scoping; nothing is computed client-side).
class MapState {
  const MapState({
    this.layers = const {},
    this.locate = const AsyncValue.loading(),
    this.locatePoint,
    this.selected,
  });

  final Map<String, MapLayerState> layers;

  /// Last `/gis/locate` lookup (search or long-press), tagged with freshness.
  final AsyncValue<CachedResult<LocateResult>> locate;

  /// Where the locate pin sits (set as soon as a lookup starts).
  final LatLng? locatePoint;
  final SelectedFeature? selected;

  MapState copyWith({
    Map<String, MapLayerState>? layers,
    AsyncValue<CachedResult<LocateResult>>? locate,
    LatLng? locatePoint,
    SelectedFeature? selected,
    bool clearLocatePoint = false,
    bool clearSelected = false,
  }) {
    return MapState(
      layers: layers ?? this.layers,
      locate: locate ?? this.locate,
      locatePoint: clearLocatePoint ? null : (locatePoint ?? this.locatePoint),
      selected: clearSelected ? null : (selected ?? this.selected),
    );
  }
}

final mapControllerProvider =
    NotifierProvider<MapController, MapState>(MapController.new);

/// Map screen controller: layer toggling/loading over the cache-first GIS +
/// command repositories, coordinate search and long-press locate.
class MapController extends Notifier<MapState> {
  @override
  MapState build() {
    return MapState(
      layers: {
        for (final spec in kMapLayers)
          spec.id: MapLayerState(enabled: spec.defaultOn),
      },
    );
  }

  /// Loads every enabled-but-unloaded layer. Called by the screen on first
  /// build (kept explicit instead of a hidden build side effect so tests can
  /// drive it deterministically).
  Future<void> loadEnabled() async {
    for (final spec in kMapLayers) {
      final layer = state.layers[spec.id];
      if (layer != null && layer.enabled && layer.data.valueOrNull == null) {
        await reload(spec.id);
      }
    }
  }

  /// Toggles a layer; enabling (re)loads it through the cache-first
  /// repository, so fresh TTL data is served without hitting the network.
  Future<void> toggle(String id) async {
    final current = state.layers[id];
    if (current == null) return;
    final enabling = !current.enabled;
    state = state.copyWith(
      layers: {
        ...state.layers,
        id: current.copyWith(enabled: enabling),
      },
      clearSelected: !enabling && state.selected?.layerId == id,
    );
    if (enabling) {
      await reload(id);
    }
  }

  /// (Re)fetches one layer; errors land in the layer's AsyncValue and are
  /// surfaced inline by the toolbar.
  Future<void> reload(String id) async {
    final spec = _spec(id);
    if (spec == null) return;
    _patchLayer(id, (l) => l.copyWith(data: const AsyncValue.loading()));
    try {
      final result = await _fetch(spec);
      _patchLayer(id, (l) => l.copyWith(data: AsyncValue.data(result)));
    } catch (e, st) {
      _patchLayer(id, (l) => l.copyWith(data: AsyncValue.error(e, st)));
    }
  }

  /// Refresh all enabled layers (toolbar button): drop caches first so the
  /// reads actually re-fetch.
  Future<void> refreshAll() async {
    ref.read(gisRepositoryProvider).invalidateAll();
    ref.read(commandRepositoryProvider).invalidateLayers();
    for (final spec in kMapLayers) {
      if (state.layers[spec.id]?.enabled ?? false) {
        await reload(spec.id);
      }
    }
  }

  /// Coordinate search: "lat, lon" → `/gis/locate` + camera pin.
  Future<void> search(String raw) async {
    final point = parseCoordinates(raw);
    if (point == null) {
      state = state.copyWith(
        locate: AsyncValue.error(
          const ValidationException(
            'Enter coordinates as "lat, lon" — for example: 26.15, 91.80',
          ),
          StackTrace.current,
        ),
      );
      return;
    }
    await locateAt(point);
  }

  /// Long-press / search locate: pins the point and resolves it against the
  /// backend's geography service.
  Future<void> locateAt(LatLng point) async {
    state = state.copyWith(
      locatePoint: point,
      locate: const AsyncValue.loading(),
    );
    try {
      final result = await ref
          .read(gisRepositoryProvider)
          .locate(lon: point.longitude, lat: point.latitude);
      state = state.copyWith(locate: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(locate: AsyncValue.error(e, st));
    }
  }

  void clearLocate() {
    state = state.copyWith(clearLocatePoint: true);
  }

  void select(SelectedFeature? selection) {
    state = state.copyWith(
      selected: selection,
      clearSelected: selection == null,
    );
  }

  // ----------------------------------------------------------------- helpers

  MapLayerSpec? _spec(String id) =>
      kMapLayers.where((s) => s.id == id).firstOrNull;

  void _patchLayer(String id, MapLayerState Function(MapLayerState) patch) {
    final current = state.layers[id];
    if (current == null) return;
    state = state.copyWith(layers: {...state.layers, id: patch(current)});
  }

  Future<CachedResult<GeoJsonFeatureCollection>> _fetch(MapLayerSpec spec) {
    final gisRepo = ref.read(gisRepositoryProvider);
    final commandRepo = ref.read(commandRepositoryProvider);
    switch (spec.gisEndpoint) {
      case GisEndpoint.segments:
        return gisRepo.segments();
      case GisEndpoint.roads:
        return gisRepo.roads();
      case GisEndpoint.districts:
        return gisRepo.districts();
      case GisEndpoint.facilities:
        return gisRepo.facilities();
      case GisEndpoint.railways:
        return gisRepo.railways();
      case GisEndpoint.waterways:
        return gisRepo.waterways();
      case null:
        return commandRepo.layer(spec.commandLayer!);
    }
  }

  /// Parses free-text coordinates: "26.15, 91.80", "26.15 91.80",
  /// "26.15;91.80". Returns null for anything not a valid lat/lon pair.
  static LatLng? parseCoordinates(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[,;]'), ' ');
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return LatLng(lat, lon);
  }
}

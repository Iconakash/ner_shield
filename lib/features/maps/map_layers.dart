import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// How a layer's features are expected to be presented. Features are still
/// rendered by their actual geometry type (see [geojson_adapter.dart]) — this
/// only steers defaults like stroke width vs. marker badges.
enum MapGeometryKind { point, line, polygon }

/// Which repository method feeds a layer.
enum GisEndpoint { segments, roads, districts, facilities, railways, waterways }

/// One toggleable map overlay (docs/api-contract-map.md §GIS + §Command
/// Center; UI plan §6 — layer toggles, search, detail bottom sheet).
class MapLayerSpec {
  const MapLayerSpec({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.kind,
    required this.defaultOn,
    this.gisEndpoint,
    this.commandLayer,
  }) : assert(
          (gisEndpoint == null) != (commandLayer == null),
          'a layer must have exactly one source (GIS endpoint or command layer)',
        );

  /// Stable id (state keys, test keys).
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final MapGeometryKind kind;
  final bool defaultOn;

  /// `/gis/*` source, when the layer is served by the GIS service.
  final GisEndpoint? gisEndpoint;

  /// `/command/layers/{name}` source, when served by the command service.
  final String? commandLayer;
}

/// The frozen overlay catalog. Order = toolbar order; `segments` (the core
/// operational layer) and command `high-risk-roads` are the awareness
/// defaults; reference infrastructure layers stay opt-in to keep the map
/// readable (master prompt §24 — never display every layer simultaneously).
const List<MapLayerSpec> kMapLayers = [
  MapLayerSpec(
    id: 'segments',
    label: 'Road status',
    icon: Icons.route,
    color: AppColors.infoBlue,
    kind: MapGeometryKind.line,
    defaultOn: true,
    gisEndpoint: GisEndpoint.segments,
  ),
  MapLayerSpec(
    id: 'high_risk_roads',
    label: 'High-risk roads',
    icon: Icons.dangerous,
    color: AppColors.dangerRed,
    kind: MapGeometryKind.line,
    defaultOn: false,
    commandLayer: 'high-risk-roads',
  ),
  MapLayerSpec(
    id: 'disruptions',
    label: 'Disruptions',
    icon: Icons.crisis_alert,
    color: AppColors.emergency,
    kind: MapGeometryKind.point,
    defaultOn: false,
    commandLayer: 'disruptions',
  ),
  MapLayerSpec(
    id: 'shipments',
    label: 'Shipments',
    icon: Icons.local_shipping,
    color: AppColors.infoBlue,
    kind: MapGeometryKind.point,
    defaultOn: false,
    commandLayer: 'shipments',
  ),
  MapLayerSpec(
    id: 'weather',
    label: 'Weather',
    icon: Icons.thunderstorm,
    color: Color(0xFF6750A4),
    kind: MapGeometryKind.polygon,
    defaultOn: false,
    commandLayer: 'weather',
  ),
  MapLayerSpec(
    id: 'districts',
    label: 'Districts',
    icon: Icons.map_outlined,
    color: AppColors.primary,
    kind: MapGeometryKind.polygon,
    defaultOn: false,
    gisEndpoint: GisEndpoint.districts,
  ),
  MapLayerSpec(
    id: 'roads',
    label: 'Roads',
    icon: Icons.add_road,
    color: AppColors.unknownGray,
    kind: MapGeometryKind.line,
    defaultOn: false,
    gisEndpoint: GisEndpoint.roads,
  ),
  MapLayerSpec(
    id: 'facilities',
    label: 'Facilities',
    icon: Icons.local_hospital_outlined,
    color: AppColors.okGreen,
    kind: MapGeometryKind.point,
    defaultOn: false,
    gisEndpoint: GisEndpoint.facilities,
  ),
  MapLayerSpec(
    id: 'railways',
    label: 'Railways',
    icon: Icons.train_outlined,
    color: AppColors.unknownGray,
    kind: MapGeometryKind.line,
    defaultOn: false,
    gisEndpoint: GisEndpoint.railways,
  ),
  MapLayerSpec(
    id: 'waterways',
    label: 'Waterways',
    icon: Icons.water,
    color: AppColors.infoBlue,
    kind: MapGeometryKind.line,
    defaultOn: false,
    gisEndpoint: GisEndpoint.waterways,
  ),
];

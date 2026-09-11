import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/time_format.dart';
import '../../models/geojson.dart';
import '../../shared/widgets/status_chip.dart';
import 'geojson_adapter.dart';

/// Bottom sheet with a feature's properties (road segment, disruption,
/// shipment… — docs/ui-ux-plan.md §6 "detail bottom sheet", §interaction
/// "bottom sheets for map details").
///
/// Presentation rules:
///  - status/severity vocabulary always renders as label + icon + color
///    (never color alone);
///  - backend DEMO/SIMULATED markers are surfaced, never stripped
///    (docs/ui-ux-plan.md §no-mock-data);
///  - properties are shown verbatim from the backend payload — nothing is
///    invented client-side.
Future<void> showFeatureDetail(
  BuildContext context, {
  required String layerLabel,
  required GeoJsonFeature feature,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    builder: (_) => FeatureDetailSheet(layerLabel: layerLabel, feature: feature),
  );
}

class FeatureDetailSheet extends StatelessWidget {
  const FeatureDetailSheet({
    super.key,
    required this.layerLabel,
    required this.feature,
  });

  final String layerLabel;
  final GeoJsonFeature feature;

  /// Title candidate keys, in priority order (tolerant — the backend uses
  /// different property names per layer).
  static const _titleKeys = [
    'name',
    'title',
    'code',
    'segment_id',
    'segment_code',
    'road_name',
    'road_code',
    'district_name',
    'facility_name',
    'facility_code',
    'shipment_code',
    'operation',
    'id',
  ];

  static const _roadStatusKeys = ['status', 'road_status', 'acc_classification'];
  static const _severityKeys = [
    'severity',
    'risk_level',
    'overall_label',
    'alert_level',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final props = feature.properties;
    final title = '${_pick(props, _titleKeys) ?? 'Unnamed feature'}';
    final status = _statusChip(props);
    final anchor = GeoJsonGeometry.anchor(feature);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                ?status,
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                StatusChip(
                  label: layerLabel,
                  icon: Icons.layers,
                  color: theme.colorScheme.primary,
                  dense: true,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _geometryLabel(anchor),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_isDemo(props)) ...[
              const SizedBox(height: 12),
              const _DemoBadge(),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in props.entries)
                    if (_showProperty(entry.key, entry.value))
                      _PropertyRow(label: entry.key, value: entry.value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _geometryLabel(LatLng? anchor) {
    final type = (feature.geometryType ?? 'geometry').replaceAll('_', ' ');
    if (anchor == null) return type;
    return '$type · ${anchor.latitude.toStringAsFixed(4)}, '
        '${anchor.longitude.toStringAsFixed(4)}';
  }

  static Object? _pick(Map<String, dynamic> props, List<String> keys) {
    for (final k in keys) {
      final v = props[k];
      if (v != null && '$v'.trim().isNotEmpty) return v;
    }
    return null;
  }

  static StatusChip? _statusChip(Map<String, dynamic> props) {
    for (final k in _severityKeys) {
      final v = props[k];
      if (v is String && v.trim().isNotEmpty) {
        return SeverityVisuals.chip(v);
      }
    }
    for (final k in _roadStatusKeys) {
      final v = props[k];
      if (v is String && v.trim().isNotEmpty) {
        return RoadStatusVisuals.chip(v);
      }
    }
    return null;
  }

  /// Server-side DEMO/SIMULATED labels must reach the user verbatim.
  static bool _isDemo(Map<String, dynamic> props) {
    for (final entry in props.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (key == 'simulated' || key == 'demo' || key == 'data_mode') {
        if (value == true) return true;
      }
      if (value is String) {
        final upper = value.toUpperCase();
        if (upper.contains('SIMULATED') || upper.contains('DEMO')) return true;
      }
    }
    return false;
  }

  static bool _showProperty(String key, Object? value) {
    if (value == null || key == 'geometry' || key == 'type') return false;
    // Already rendered as the title / status / severity chip — don't repeat.
    if (_titleKeys.contains(key)) return false;
    if (_roadStatusKeys.contains(key)) return false;
    if (_severityKeys.contains(key)) return false;
    return true;
  }
}


class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF9A6A00).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFF9A6A00).withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.science_outlined, size: 15, color: Color(0xFF9A6A00)),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'DEMO / SIMULATED — not live operational data',
              style: TextStyle(
                color: Color(0xFF9A6A00),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              _humanize(label),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(
            child: Text(
              _format(value),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static String _humanize(String key) {
    final cleaned = key.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return key;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  static String _format(Object? value) {
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return '$value';
    final s = '$value'.trim();
    final asDate = DateTime.tryParse(s);
    if (asDate != null && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
      return TimeFormat.full(s);
    }
    return s;
  }
}

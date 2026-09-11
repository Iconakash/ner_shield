import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../shared/widgets/status_chip.dart';
import '../../theme/app_theme.dart';
import 'map_controller.dart';
import 'map_layers.dart';

/// Map toolbar: coordinate search, layer toggle chips, segment-status legend
/// and per-layer inline status (loading handled by chip spinners, errors by
/// retry rows, empties by scope notes — docs/ui-ux-plan.md §states).
class MapToolbar extends ConsumerWidget {
  const MapToolbar({super.key, required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapControllerProvider);
    final controller = ref.read(mapControllerProvider.notifier);
    final theme = Theme.of(context);

    return Material(
      elevation: 1,
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search coordinates (lat, lon)',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onSubmitted: (v) => controller.search(v),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh layers',
                    onPressed: () => controller.refreshAll(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    for (final spec in kMapLayers)
                      _LayerChip(
                        spec: spec,
                        state: state.layers[spec.id] ??
                            const MapLayerState(enabled: false),
                        onToggle: () => controller.toggle(spec.id),
                      ),
                  ],
                ),
              ),
            ),
            _SegmentLegend(state: state),
            ...[
              for (final spec in kMapLayers)
                _LayerStatusRow(spec: spec, state: state.layers[spec.id]),
            ],
          ],
        ),
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.spec,
    required this.state,
    required this.onToggle,
  });

  final MapLayerSpec spec;
  final MapLayerState state;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final loading = state.isLoading;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        key: ValueKey('layer-chip-${spec.id}'),
        selected: state.enabled,
        onSelected: (_) => onToggle(),
        avatar: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(spec.icon, size: 16, color: spec.color),
        label: Text(spec.label),
      ),
    );
  }
}

/// Non-color-only legend for the status vocabulary of the road-status layer
/// (docs/ui-ux-plan.md §accessibility).
class _SegmentLegend extends StatelessWidget {
  const _SegmentLegend({required this.state});

  final MapState state;

  @override
  Widget build(BuildContext context) {
    final segments = state.layers['segments'];
    if (segments == null || !segments.enabled) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          RoadStatusVisuals.chip('OPEN'),
          RoadStatusVisuals.chip('PARTIAL'),
          RoadStatusVisuals.chip('CLOSED'),
        ],
      ),
    );
  }
}

/// Inline per-layer state: load failure + retry, and "loaded but empty in
/// your scope" notes (never a silent blank map).
class _LayerStatusRow extends ConsumerWidget {
  const _LayerStatusRow({required this.spec, required this.state});

  final MapLayerSpec spec;
  final MapLayerState? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final layer = state;
    if (layer == null || !layer.enabled) return const SizedBox.shrink();

    final error = layer.data.error;
    if (error != null) {
      final message =
          error is AppException ? error.message : 'Could not load this layer.';
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${spec.label} layer failed — $message',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              key: ValueKey('layer-retry-${spec.id}'),
              onPressed: () => ref
                  .read(mapControllerProvider.notifier)
                  .reload(spec.id),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (layer.isLoadedAndEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: theme.colorScheme.outline),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${spec.label}: no features in your scope.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Result of a `/gis/locate` lookup (search or long-press): the resolved
/// state/district/operation for the pinned point, with close action.
class LocateCard extends ConsumerWidget {
  const LocateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapControllerProvider);
    if (state.locatePoint == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.emergency),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Location lookup',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  const SizedBox(height: 2),
                  state.locate.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                    error: (e, _) => Text(
                      e is AppException ? e.message : 'Lookup failed.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    data: (result) {
                      final r = result.value;
                      final parts = [
                        r.stateCode,
                        if (r.districtCode != null) r.districtCode!,
                        if (r.operation != null) r.operation!,
                      ];
                      return Text(
                        parts.isEmpty
                            ? 'Outside mapped geography.'
                            : parts.join(' · '),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                  if (state.locate.valueOrNull?.servedFromCache ?? false)
                    Text(
                      'Cached result.',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Clear location',
              onPressed: () =>
                  ref.read(mapControllerProvider.notifier).clearLocate(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}


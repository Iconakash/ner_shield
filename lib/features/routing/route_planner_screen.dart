import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/routing_plan.dart';
import 'route_planner_controller.dart';

/// Route planner (Phase 10): plans a route through the backend engine
/// (`POST /routing/plan`) with alternatives, ETA, distance and aggregate
/// risk rendered straight from the response — nothing is computed or
/// invented client-side (master prompt §29, §32).
class RoutePlannerScreen extends ConsumerWidget {
  const RoutePlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(routePlannerProvider);
    final controller = ref.read(routePlannerProvider.notifier);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Plan a route', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'The routing engine ranks alternatives by current road state, '
          'incidents and risk. Rank 1 is the engine recommendation.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _EndpointFields(state: state),
        const SizedBox(height: 12),
        _ModeSelector(state: state),
        const SizedBox(height: 12),
        _OptionControls(state: state),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.planning ? null : controller.plan,
          icon: const Icon(Icons.alt_route_outlined),
          label: const Text('Plan route'),
        ),
        const SizedBox(height: 12),
        if (state.lastError != null) ...[
          _InlineError(message: state.lastError!),
          const SizedBox(height: 12),
        ],
        if (state.offlineNotice != null) ...[
          _NoticeBanner(
            message: state.offlineNotice!,
            icon: Icons.cloud_off_outlined,
            background: theme.colorScheme.secondaryContainer,
            foreground: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(height: 8),
        ],
        if (state.staleNotice != null) ...[
          _NoticeBanner(
            message: state.staleNotice!,
            icon: Icons.history_outlined,
            background: theme.colorScheme.errorContainer,
            foreground: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 8),
        ],
        if (state.planning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!state.planning && !state.hasResult && state.lastError == null)
          _EmptyPlanning(),
        if (state.hasResult) ...[
          const SizedBox(height: 8),
          for (var i = 0; i < state.result!.length; i++)
            _RouteCard(
              route: state.result![i],
              selected: i == state.selectedIndex,
              onTap: () => controller.select(i),
            ),
        ],
      ],
    );
  }
}

class _EndpointFields extends ConsumerWidget {
  const _EndpointFields({required this.state});

  final PlannerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(routePlannerProvider.notifier);
    return Column(
      children: [
        TextFormField(
          initialValue: state.originText,
          decoration: const InputDecoration(
            labelText: 'Origin',
            hintText: 'Facility code or "longitude, latitude"',
            prefixIcon: Icon(Icons.trip_origin),
          ),
          onChanged: controller.setOrigin,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Divider()),
            IconButton(
              tooltip: 'Swap origin and destination',
              onPressed: controller.swap,
              icon: const Icon(Icons.swap_vert),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        TextFormField(
          initialValue: state.destinationText,
          decoration: const InputDecoration(
            labelText: 'Destination',
            hintText: 'Facility code or "longitude, latitude"',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          onChanged: controller.setDestination,
        ),
      ],
    );
  }
}

class _ModeSelector extends ConsumerWidget {
  const _ModeSelector({required this.state});

  final PlannerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(routePlannerProvider.notifier);
    if (state.modes.isEmpty) {
      return const SizedBox.shrink();
    }
    return DropdownButtonFormField<String>(
      initialValue: state.modeId,
      hint: const Text('Backend default'),
      decoration: const InputDecoration(
        labelText: 'Mode',
        prefixIcon: Icon(Icons.route_outlined),
      ),
      items: [
        for (final m in state.modes)
          DropdownMenuItem(value: m.id, child: Text(m.description)),
      ],
      onChanged: (v) => controller.setMode(v),
    );
  }
}

class _OptionControls extends ConsumerWidget {
  const _OptionControls({required this.state});

  final PlannerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(routePlannerProvider.notifier);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alternatives to request (k = ${state.k})',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 1, label: Text('1')),
            ButtonSegment(value: 2, label: Text('2')),
            ButtonSegment(value: 3, label: Text('3')),
          ],
          selected: {state.k.clamp(1, 3)},
          onSelectionChanged: (s) => controller.setK(s.first),
        ),
        const SizedBox(height: 8),
        Text(
          'Risk aversion: ${state.riskAversion.toStringAsFixed(2)} '
          '(0 = engine default weighting)',
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: state.riskAversion,
          min: 0,
          max: 1,
          divisions: 10,
          label: state.riskAversion.toStringAsFixed(2),
          onChanged: controller.setRiskAversion,
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPlanning extends StatelessWidget {
  const _EmptyPlanning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.alt_route_outlined,
            size: 44,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter an origin and destination, then plan the route.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final PlannedRoute route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eta = route.totalEtaMinutes;
    final dist = route.totalDistanceKm;
    final risk = route.aggregateRisk;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: route.isRecommended
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${route.rank}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: route.isRecommended
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    route.isRecommended ? 'Recommended' : 'Alternative',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${route.riskDisplay}${risk == null ? '' : ' · ${risk.toStringAsFixed(2)}'}',
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  Text(
                    'ETA ${eta == null ? '—' : '${eta.toStringAsFixed(0)} min'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    'Distance ${dist == null ? '—' : '${dist.toStringAsFixed(1)} km'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${route.segmentCount} segments',
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (route.mode != null)
                    Text(
                      'Mode ${route.mode}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
              if (route.narrative != null && route.narrative!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(route.narrative!, style: theme.textTheme.bodySmall),
              ],
              if (selected && route.segments.isNotEmpty) ...[
                const Divider(height: 20),
                for (final seg in route.segments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.more_vert, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _segmentLine(seg),
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Renders only server-provided segment fields — never synthesises values.
  String _segmentLine(Map<String, dynamic> seg) {
    final parts = <String>[];
    for (final key in const [
      'segment_id',
      'id',
      'road_code',
      'status',
      'distance_km',
      'eta_minutes',
      'risk',
    ]) {
      final v = seg[key];
      if (v == null) continue;
      parts.add('$key: $v');
    }
    return parts.isEmpty ? 'segment' : parts.join(' · ');
  }
}

/// Phase 5 — prominent, non-color-only notice for offline/stale plans
/// (icon + text; never color alone, master prompt §34).
class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({
    required this.message,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_format.dart';
import '../../models/cached_result.dart';
import '../../models/command_summary.dart';
import '../../shared/widgets/screen_states.dart';
import 'dashboard_controller.dart';

/// Command overview — the backend's six actionable KPI tiles (FR-C16.1).
///
/// Deliberately NOT a vanity dashboard: the source mandate freezes the tile
/// list, so the screen renders exactly what `GET /command/summary` returns,
/// each tile answering "do I need to act right now, and where?".
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    return state.when(
      loading: () => const LoadingView(label: 'Loading command summary…'),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
      ),
      data: (result) => _DashboardContent(
        result: result,
        onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.result, required this.onRefresh});

  final CachedResult<CommandSummary> result;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final summary = result.value;
    final text = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (result.servedFromCache)
            OfflineBanner(
              lastSyncedLabel: summary.generatedAt != null
                  ? 'Generated ${TimeFormat.clock(summary.generatedAt)}.'
                  : null,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Command overview',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              StaleLabel(
                label: summary.generatedAt != null
                    ? 'Generated ${TimeFormat.clock(summary.generatedAt)}'
                    : (result.servedFromCache ? 'Cached copy' : 'Live'),
              ),
            ],
          ),
          Text(
            'Counts are scoped to your assigned geography.',
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxis = constraints.maxWidth >= 640 ? 3 : 2;
              return GridView.count(
                crossAxisCount: crossAxis,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: [
                  for (final kpi in summary.kpis) _KpiTile(kpi: kpi),
                ],
              );
            },
          ),
          if (summary.actionCount == 0) ...[
            const SizedBox(height: 12),
            EmptyView(
              title: 'Nothing needs your attention',
              message:
                  'All six operational indicators are currently at zero for '
                  'your scope. Pull to refresh.',
              icon: Icons.verified_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

/// One frozen KPI tile: icon + label + count (never color alone).
class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.kpi});

  final CommandKpi kpi;

  static (IconData, Color) _visuals(String id) => switch (id) {
        'critical_alerts' => (Icons.crisis_alert, const Color(0xFFBA1A1A)),
        'high_risk_roads' => (Icons.dangerous, const Color(0xFFB54008)),
        'active_shipments' => (Icons.local_shipping, const Color(0xFF00639C)),
        'critical_shipments' => (
          Icons.medical_services_outlined,
          const Color(0xFFB54008)
        ),
        'supply_risk_districts' => (
          Icons.storefront,
          const Color(0xFF9A6A00)
        ),
        'predicted_disruptions' => (
          Icons.insights,
          const Color(0xFF6750A4)
        ),
        _ => (Icons.circle_outlined, const Color(0xFF5E5E66)),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visuals(kpi.id);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final urgent = kpi.count > 0 &&
        (kpi.id == 'critical_alerts' ||
            kpi.id == 'high_risk_roads' ||
            kpi.id == 'critical_shipments');

    return Semantics(
      label: '${kpi.description}: ${kpi.count}',
      child: Card(
        elevation: 0,
        color: urgent ? color.withValues(alpha: 0.08) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color:
                urgent ? color.withValues(alpha: 0.45) : scheme.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const Spacer(),
                  Text(
                    '${kpi.count}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kpi.count > 0 ? color : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  kpi.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
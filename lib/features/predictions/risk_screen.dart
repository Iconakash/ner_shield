import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/risk/offline_risk.dart';
import '../../core/utils/time_format.dart';
import '../../models/risk_item.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'risk_controller.dart';

/// Disruption predictions (master prompt §32). The backend risk engine is
/// the only source of scores, labels, factors and narratives — this screen
/// renders them verbatim, with model metadata always visible. No client-side
/// ML, no derived values.
class RiskScreen extends ConsumerWidget {
  const RiskScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riskLatestProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Disruption predictions',
                  style: theme.textTheme.titleMedium),
              Text(
                'AI output from the backend risk engine — never computed on '
                'this device.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const LoadingView(label: 'Loading predictions…'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(riskLatestProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = result.value;
              final offline = ref.watch(offlineRiskSnapshotProvider).valueOrNull;
              if (list.isEmpty) {
                return const EmptyView(
                  title: 'No predictions published',
                  message:
                      'The risk engine has not published predictions for your '
                      'scope yet. Rows appear here once the next model run '
                      'completes.',
                  icon: Icons.insights,
                );
              }
              return Column(
                children: [
                  if (offline != null && offline.stale && result.servedFromCache)
                    _OfflineRiskBanner(result: offline),
                  if (result.servedFromCache)
                    _StaleRow(onRetry: () {
                      // ignore: cascade_invocations
                      ref.read(riskLatestProvider.notifier).refresh();
                    }),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(riskLatestProvider.notifier).refresh(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _RiskCard(
                          prediction: list[i],
                          onWhy: () => _openWhy(context, list[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openWhy(BuildContext context, RiskPrediction p) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WhySheet(segmentId: p.segmentId),
    );
  }
}

/// Cached-data banner (stale copy while offline) — master prompt §42.
class _StaleRow extends StatelessWidget {
  const _StaleRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing the last synced copy — retry for live data.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Phase 6 — explicit degraded-risk banner. Shown only with cached/offline
/// data; never claims the snapshot is live (§6.2). Discloses feature
/// freshness, confidence and the last sync instant.
class _OfflineRiskBanner extends StatelessWidget {
  const _OfflineRiskBanner({required this.result});

  final OfflineRiskResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freshness = switch (result.featureFreshness) {
      RiskFreshness.live => 'live',
      RiskFreshness.recent => 'recent',
      RiskFreshness.stale => 'stale',
    };
    final title = result.stale
        ? 'OFFLINE RISK — STALE'
        : 'OFFLINE RISK — last synchronised';
    final body = 'Shown from the last synchronised server snapshot. '
        'Feature freshness: $freshness · confidence: '
        '${(result.confidence * 100).round()}% · synced '
        '${TimeFormat.full(result.fetchedAt.toIso8601String())}.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Icon(Icons.warning, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                Text(body, style: theme.textTheme.bodySmall),
                for (final reason in result.degradedReasons)
                  Text(reason, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One prediction row. Renders the backend's label, score, horizons, summary
/// and model metadata verbatim (master prompt §32) — severity uses label +
/// icon + colour, never colour alone.
class _RiskCard extends StatelessWidget {
  const _RiskCard({required this.prediction, required this.onWhy});

  final RiskPrediction prediction;
  final VoidCallback onWhy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = prediction.overallLabel ?? 'UNKNOWN';
    final horizons = <String, double?>{
      '6h': prediction.risk6h,
      '12h': prediction.risk12h,
      '24h': prediction.risk24h,
      '72h': prediction.risk72h,
    }..removeWhere((_, v) => v == null);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: prediction.isActionable
              ? theme.colorScheme.error
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      prediction.roadCode,
                      prediction.districtName ?? prediction.districtCode,
                    ].nonNulls.join(' · '),
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _labelChip(label),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Segment ${prediction.segmentId}',
              style: theme.textTheme.labelSmall,
            ),
            if (prediction.summarySentence != null) ...[
              const SizedBox(height: 8),
              Text(prediction.summarySentence!,
                  style: theme.textTheme.bodySmall),
            ],
            if (horizons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in horizons.entries)
                    Text(
                      '${e.key}: ${e.value}',
                      style: theme.textTheme.labelSmall,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.model_training,
                    size: 13, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      prediction.mode,
                      prediction.modelName,
                      prediction.modelVersion,
                      'as of ${TimeFormat.clock(prediction.computedAt)}',
                    ].nonNulls.join(' · '),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onWhy,
                  icon: const Icon(Icons.psychology_alt_outlined, size: 16),
                  label: const Text('WHY'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Presentation mapping for backend labels — SeverityVisuals does not
  /// cover MEDIUM/LOW, so the full vocabulary lives here (label + icon +
  /// colour; §34 non-colour-only rule).
  Widget _labelChip(String label) {
    final (color, icon) = switch (label) {
      'CRITICAL' => (const Color(0xFFBA1A1A), Icons.error_outline),
      'HIGH' => (const Color(0xFF9A3B00), Icons.warning_amber_outlined),
      'MEDIUM' => (const Color(0xFF9A6A00), Icons.info_outline),
      'LOW' => (const Color(0xFF1E7A3C), Icons.check_circle_outline),
      _ => (const Color(0xFF5E5E66), Icons.help_outline),
    };
    return StatusChip(label: label, icon: icon, color: color, dense: true);
  }
}

/// WHY card for one prediction (`GET /risk/{segment_id}/explain`).
/// Renders the backend narrative + signed factor contributions verbatim —
/// the client never recomputes risk (master prompt §32).
class _WhySheet extends ConsumerWidget {
  const _WhySheet({required this.segmentId});

  final String segmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(riskExplainProvider(segmentId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why this risk?', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Segment $segmentId', style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Column(
                children: [
                  Text(
                    'Could not load the explanation for this segment.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        ref.invalidate(riskExplainProvider(segmentId)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
              data: (cached) {
                final explain = cached.value;
                final factors = explain.factors ?? const <RiskFactor>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cached.fromCache)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Cached result — may be slightly stale.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ),
                    if (explain.narrative != null &&
                        explain.narrative!.isNotEmpty)
                      Text(explain.narrative!,
                          style: theme.textTheme.bodyMedium),
                    if (explain.baseValue != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Base model value: ${explain.baseValue!.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                    if (factors.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('Contributing factors',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      for (final f in factors)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  f.label ?? f.feature,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '${f.feature}'
                                '${(f.contribution ?? 0) >= 0 ? ' +' : ' -'}'
                                '${(f.contribution ?? 0).abs().toStringAsFixed(2)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

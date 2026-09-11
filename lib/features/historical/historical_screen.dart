import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/historical_event.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'historical_controller.dart';

class HistoricalScreen extends ConsumerWidget {
  const HistoricalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historicalEventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Historical validation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Text(
            'Server-published historical events for this scope. Accuracy '
            'metrics are always tagged with their data quality.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const LoadingView(label: 'Loading events...'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(historicalEventsProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = result.value;
              if (list.isEmpty) {
                return const EmptyView(
                  title: 'No historical events',
                  message: 'The server has not published any events for your scope yet.',
                  icon: Icons.history,
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(historicalEventsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _HistoricalCard(event: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoricalCard extends StatelessWidget {
  const _HistoricalCard({required this.event});
  final HistoricalEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go('/shell/historical/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title ?? 'Untitled event',
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DataQualityChip(quality: event.dataQuality),
                ],
              ),
              const SizedBox(height: 4),
              if ((event.description ?? '').isNotEmpty)
                Text(
                  event.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (event.eventType != null)
                    StatusChip(
                      label: event.eventType!,
                      icon: Icons.label_outline,
                      color: theme.colorScheme.secondary,
                      dense: true,
                    ),
                  if (event.occurredAt != null)
                    StatusChip(
                      label: event.occurredAt!,
                      icon: Icons.schedule,
                      color: theme.colorScheme.outline,
                      dense: true,
                    ),
                  if (event.datasetVersion != null)
                    StatusChip(
                      label: 'dataset ${event.datasetVersion!}',
                      icon: Icons.dataset_outlined,
                      color: theme.colorScheme.outline,
                      dense: true,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataQualityChip extends StatelessWidget {
  const DataQualityChip({super.key, required this.quality});
  final String? quality;

  @override
  Widget build(BuildContext context) {
    final q = (quality ?? 'NO_DATASET').toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    final color = switch (q) {
      'MEASURED' => const Color(0xFF1E8E3E),
      'SAMPLE' => const Color(0xFFD18B00),
      'SIMULATED' => const Color(0xFFC5221F),
      _ => scheme.outline,
    };
    return StatusChip(
      label: q,
      icon: Icons.verified_outlined,
      color: color,
      dense: true,
    );
  }
}

class HistoricalDetailScreen extends ConsumerWidget {
  const HistoricalDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(historicalEventDetailProvider(eventId));
    final validation = ref.watch(historicalValidationProvider(eventId));
    return Scaffold(
      appBar: AppBar(title: const Text('Historical event')),
      body: detail.when(
        loading: () => const LoadingView(label: 'Loading event...'),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(historicalEventDetailProvider(eventId)),
        ),
        data: (result) {
          final event = result.value;
          final theme = Theme.of(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(event.title ?? 'Untitled event',
                  style: theme.textTheme.titleLarge),
              if ((event.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(event.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  DataQualityChip(quality: event.dataQuality),
                  if (event.eventType != null)
                    StatusChip(
                      label: event.eventType!,
                      icon: Icons.label_outline,
                      color: theme.colorScheme.secondary,
                      dense: true,
                    ),
                  if (event.occurredAt != null)
                    StatusChip(
                      label: event.occurredAt!,
                      icon: Icons.schedule,
                      color: theme.colorScheme.outline,
                      dense: true,
                    ),
                  if (event.observationCount != null)
                    StatusChip(
                      label: '${event.observationCount} obs',
                      icon: Icons.list_alt_outlined,
                      color: theme.colorScheme.outline,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Latest validation run',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              validation.when(
                loading: () => const LoadingView(label: 'Loading run...'),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(historicalValidationProvider(eventId)),
                ),
                data: (vResult) {
                  final run = vResult.value;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${run.modelName ?? "model"} - ${run.modelVersion ?? "unknown version"}',
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          if (run.datasetVersion != null)
                            Text('Dataset: ${run.datasetVersion}',
                                style: theme.textTheme.bodySmall),
                          if (run.ranAt != null)
                            Text('Ran: ${run.ranAt}',
                                style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          if ((run.metrics ?? <String, dynamic>{}).isNotEmpty)
                            ...run.metrics!.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${e.key}: ${e.value}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

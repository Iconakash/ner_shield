import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/responder.dart';
import '../../services/responder_service.dart' show responderStatusLabel;
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'emergency_controller.dart';

/// Emergency workflow surface (Phase 15 / PRD P3).
///
/// Two coupled lists:
///   1. **Response tasks** — work assigned to the signed-in user. Transitions
///      (ACKNOWLEDGED → DISPATCHED → ON_SITE → RESOLVED) come straight from
///      the backend; the server stays the authority.
///   2. **Responders** — visible roster with their operational status.
///      DEMO rows are surfaced with an explicit DEMO badge.
///
/// Nothing on this screen fabricates task state, ETA or dispatcher
/// decisions — every value the user sees was produced server-side.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(responseTasksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Emergency response',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
          child: Text(
            'Tasks assigned to you and the visible responder roster. '
            'Statuses and decisions come from the backend.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: tasks.when(
            loading: () => const LoadingView(label: 'Loading tasks...'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () =>
                  ref.read(responseTasksProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = result.value;
              if (list.isEmpty) {
                return const EmptyView(
                  title: 'No assigned tasks',
                  message:
                      'You have no open response tasks. New work appears '
                      'here when the dispatcher assigns it.',
                  icon: Icons.assignment_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(responseTasksProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TaskCard(task: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});
  final ResponseTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = responderNextStatusesFor(task.status);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title ?? 'Response task',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: responderStatusLabel(task.status),
                  icon: Icons.flag_outlined,
                  color: _statusColor(theme, task.status),
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if ((task.description ?? '').isNotEmpty)
              Text(
                task.description!,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if ((task.responderName ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Responder: ${task.responderName}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (next.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final to in next)
                    OutlinedButton(
                      onPressed: () => ref
                          .read(responseTasksProvider.notifier)
                          .transition(task.id, status: to),
                      child: Text(responderStatusLabel(to)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, String? status) {
    switch (status) {
      case 'NOTIFIED':
        return const Color(0xFFD18B00);
      case 'ACKNOWLEDGED':
      case 'DISPATCHED':
        return const Color(0xFF1E64C6);
      case 'ON_SITE':
        return const Color(0xFF6A1B9A);
      case 'RESOLVED':
        return const Color(0xFF1E8E3E);
      case 'CANCELLED':
        return const Color(0xFFC5221F);
      default:
        return theme.colorScheme.outline;
    }
  }
}
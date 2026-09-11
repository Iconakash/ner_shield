import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'tasks_controller.dart';

/// Action Center tasks (Phase 16).
///
/// The task lifecycle is fully server-authoritative: every status visible
/// here was produced by `POST /tasks/{id}/transition`. The buttons offered
/// are derived from `kTaskStatusTransitions`; the backend is still the
/// source of truth and rejects invalid transitions with 409 (surface
/// verbatim — no local retry loops).
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myTasksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            'Action Center',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Text(
            'Tasks assigned to you. Status changes go through the backend; '
            'your local view refreshes from the server response.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: state.when(
            loading: () => const LoadingView(label: 'Loading tasks...'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(myTasksProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = result.value;
              if (list.isEmpty) {
                return const EmptyView(
                  title: 'No assigned tasks',
                  message:
                      'The dispatcher has not assigned any tasks to you yet.',
                  icon: Icons.task_alt_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(myTasksProvider.notifier).refresh(),
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
  final TaskItem task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final next = taskNextStatusesFor(task.status);
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
                    task.title ?? 'Task',
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(
                  label: task.priority ?? 'MEDIUM',
                  icon: Icons.flag_outlined,
                  color: _priorityColor(theme, task.priority),
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                StatusChip(
                  label: task.status ?? 'NEW',
                  icon: Icons.sync,
                  color: theme.colorScheme.primary,
                  dense: true,
                ),
                if (task.sourceType != null)
                  StatusChip(
                    label: 'from ${task.sourceType!}',
                    icon: Icons.source_outlined,
                    color: theme.colorScheme.outline,
                    dense: true,
                  ),
              ],
            ),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final to in next)
                    OutlinedButton(
                      onPressed: () => ref
                          .read(myTasksProvider.notifier)
                          .transition(task.id, toStatus: to),
                      child: Text(to.replaceAll('_', ' ').toLowerCase()),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _priorityColor(ThemeData theme, String? priority) {
    switch (priority) {
      case 'CRITICAL':
        return const Color(0xFFC5221F);
      case 'HIGH':
        return const Color(0xFFD18B00);
      case 'LOW':
        return const Color(0xFF1E8E3E);
      default:
        return theme.colorScheme.secondary;
    }
  }
}
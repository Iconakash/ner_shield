import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_format.dart';
import '../../models/field_report.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'incidents_controller.dart';
import 'report_wizard_screen.dart';
import 'sync_controller.dart';

/// Field reports / incidents inbox — the field officer's primary screen.
///
///  Three states are surfaced (master prompt §42):
///   - Live server data with freshness (cached timestamp when served stale)
///   - Empty list (no reports authored yet)
///   - Error / permission denied (server 403 = no VERIFY_INCIDENT)
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReportsProvider);
    final queue = ref.watch(syncQueueSnapshotProvider);

    return Stack(
      children: [
        Column(
          children: [
            _ReportsToolbar(
              queueCount: queue.length,
              onSync: () => ref.read(syncFlushControllerProvider).flush(),
              onRefresh: () => ref.read(myReportsProvider.notifier).refresh(),
            ),
            Expanded(
              child: state.when(
                loading: () =>
                    const LoadingView(label: 'Loading your reports…'),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.read(myReportsProvider.notifier).refresh(),
                ),
                data: (result) {
                  final list = result.value;
                  if (list.isEmpty) {
                    return EmptyView(
                      title: 'No field reports yet',
                      message:
                          'Tap the report button to capture an incident from '
                          'the field. Drafts created offline are queued '
                          'locally and synced as soon as connectivity '
                          'returns.',
                      icon: Icons.campaign_outlined,
                      actionLabel: 'Create report',
                      onAction: () => _openWizard(context, ref),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(myReportsProvider.notifier).refresh(),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ReportRow(report: list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'reports-create-fab',
            onPressed: () => _openWizard(context, ref),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Report incident'),
          ),
        ),
      ],
    );
  }

  /// Opens the capture wizard and refreshes the inbox on return — the draft
  /// may have gone live (server accepted) or been queued for later sync.
  Future<void> _openWizard(BuildContext context, WidgetRef ref) async {
    final reports = ref.read(myReportsProvider.notifier);
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ReportWizardScreen()));
    await reports.refresh();
  }
}

class _ReportsToolbar extends StatelessWidget {
  const _ReportsToolbar({
    required this.queueCount,
    required this.onSync,
    required this.onRefresh,
  });

  final int queueCount;
  final Future<void> Function() onSync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(
              'Field reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 8),
            if (queueCount > 0)
              StatusPill(count: queueCount)
            else
              const SizedBox.shrink(),
            const Spacer(),
            IconButton(
              tooltip: 'Sync queued reports',
              onPressed: onSync,
              icon: const Icon(Icons.cloud_sync_outlined),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});
  final FieldReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.campaign_outlined),
        title: Row(
          children: [
            Expanded(
              child: Text(
                report.displayTitle.isEmpty
                    ? 'Untitled incident'
                    : report.displayTitle,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            if (report.severity != null) SeverityVisuals.chip(report.severity!),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              report.description ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.locationName ??
                        (report.districtCode != null
                            ? '${report.stateCode ?? ''} · ${report.districtCode}'
                            : (report.stateCode ?? 'Unknown location')),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (report.reportedAt != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    TimeFormat.clock(report.reportedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
            if (report.status != null) ...[
              const SizedBox(height: 6),
              _StatusChip(status: report.status!),
            ],
          ],
        ),
        onTap: () {},
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'RECEIVED' || 'UNDER_REVIEW' => const Color(0xFF9A6A00),
      'VALIDATED' || 'IN_ACTION' => const Color(0xFF1E7A3C),
      'REJECTED' => const Color(0xFFBA1A1A),
      'RESOLVED' || 'CLOSED' => const Color(0xFF5E5E66),
      _ => const Color(0xFF00639C),
    };
    return StatusChip(
      label: status.replaceAll('_', ' '),
      icon: Icons.flag_outlined,
      color: color,
      dense: true,
    );
  }
}

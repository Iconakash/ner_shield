import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_format.dart';
import '../../models/alert.dart';
import '../../models/cached_result.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'alerts_controller.dart';

/// Alert inbox — RLS/role-scoped `GET /alerts/inbox` (master prompt §34).
/// Severity is communicated with label + icon + colour (never colour alone),
/// and only backend-authorised actions (acknowledge/resolve) are offered —
/// the server 403s anything else and its message surfaces verbatim.
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key, this.focusId});

  /// Deep-link focus: when present, the matching alert's detail sheet
  /// auto-opens once its row is available (e.g. `?focus=<alert_id>` from a
  /// notification tap).
  final String? focusId;

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String? _focusId;
  bool _focusHandled = false;

  @override
  void initState() {
    super.initState();
    _focusId = widget.focusId;
    if (_focusId != null) {
      ref.listenManual<AsyncValue<CachedResult<List<Alert>>>>(
        alertsInboxProvider,
        (previous, next) {
          if (next.valueOrNull != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenFocus());
          }
        },
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenFocus());
    }
  }

  @override
  void didUpdateWidget(AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusId != oldWidget.focusId) {
      _focusId = widget.focusId;
      _focusHandled = false;
      if (_focusId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenFocus());
      }
    }
  }

  /// Auto-opens the focused alert's detail sheet once its row is present.
  Future<void> _maybeOpenFocus() async {
    if (_focusHandled || !mounted || _focusId == null) return;
    final value = ref.read(alertsInboxProvider).valueOrNull;
    if (value == null) return;
    for (final a in value.value) {
      if (a.id == _focusId) {
        _focusHandled = true;
        await _openDetail(context, a);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertsInboxProvider);
    final action = ref.watch(alertActionProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Alert inbox', style: theme.textTheme.titleMedium),
              ),
              IconButton(
                tooltip: 'Notification preferences',
                onPressed: () => _openPrefs(context),
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        ),
        if (action.error != null)
          _InlineBanner(text: action.error!, isError: true),
        Expanded(
          child: state.when(
            loading: () => const LoadingView(label: 'Loading alerts…'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(alertsInboxProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = result.value;
              if (list.isEmpty) {
                return const EmptyView(
                  title: 'No alerts in your scope',
                  message:
                      'Alerts raised for your role and geography appear here. '
                      'The list refreshes whenever the backend publishes a '
                      'new alert.',
                  icon: Icons.notifications_none,
                );
              }
              final openCount = list.where((a) => a.isOpen).length;
              return Column(
                children: [
                  if (result.servedFromCache)
                    _StaleRow(onRetry: () {
                      // ignore: cascade_invocations
                      ref.read(alertsInboxProvider.notifier).refresh();
                    }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '$openCount open of ${list.length}',
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () =>
                          ref.read(alertsInboxProvider.notifier).refresh(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _AlertCard(
                          alert: list[i],
                          busy: action.busyId == list[i].id,
                          onOpen: () => _openDetail(context, list[i]),
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

  Future<void> _openDetail(BuildContext context, Alert alert) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AlertDetailSheet(alert: alert),
    );
  }

  Future<void> _openPrefs(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _PrefsSheet(),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : const Color(0xFF1E7A3C);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.busy, required this.onOpen});

  final Alert alert;
  final bool busy;
  final VoidCallback onOpen;

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: busy ? null : onOpen,
        leading: SeverityVisuals.chip(alert.level ?? 'INFO'),
        title: Text(
          alert.displayTitle,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (alert.message != null)
              Text(
                alert.message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (alert.status != null) ...[
                  StatusChip(
                    label: alert.status!.replaceAll('_', ' '),
                    icon: Icons.flag_outlined,
                    color: alert.isOpen
                        ? const Color(0xFFBA1A1A)
                        : const Color(0xFF5E5E66),
                    dense: true,
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.place_outlined,
                    size: 13, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      alert.stateCode,
                      alert.districtCode,
                    ].nonNulls.join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  TimeFormat.clock(alert.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ],
        ),
        trailing: busy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// Detail + actions for one alert. Restricted actions (acknowledge/resolve)
/// are always offered; the backend remains the authorization authority and
/// any 403 surfaces verbatim (master prompt §22, §34).
class _AlertDetailSheet extends ConsumerWidget {
  const _AlertDetailSheet({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final action = ref.watch(alertActionProvider);
    final body = alert.localizedMessage ?? alert.message;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.displayTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (alert.level != null) SeverityVisuals.chip(alert.level!),
              ],
            ),
            if (alert.emergencyInstruction != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.health_and_safety_outlined,
                        size: 18, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alert.emergencyInstruction!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (body != null && body.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(body, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            _MetaRow(label: 'Status', value: alert.status ?? 'UNKNOWN'),
            if (alert.alertType != null)
              _MetaRow(label: 'Type', value: alert.alertType!),
            if (alert.districtCode != null)
              _MetaRow(label: 'District', value: alert.districtCode!),
            if (alert.currentRole != null)
              _MetaRow(label: 'Held by', value: alert.currentRole!),
            if (alert.createdAt != null)
              _MetaRow(
                  label: 'Created', value: TimeFormat.clock(alert.createdAt)),
            if (action.error != null) ...[
              const SizedBox(height: 10),
              Text(
                action.error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            _ResolveControls(alert: alert),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Acknowledge/resolve controls for the detail sheet. Only the role currently
/// holding the alert may act — the backend 403s anything else and its message
/// surfaces verbatim via [AlertActionState.error].
class _ResolveControls extends ConsumerWidget {
  const _ResolveControls({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = ref.watch(alertActionProvider);
    final busy = action.busyId == alert.id;
    final theme = Theme.of(context);

    if (!alert.isOpen) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline,
              size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This alert is closed (${alert.status ?? 'UNKNOWN'}).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final ok = await ref
                        .read(alertActionProvider.notifier)
                        .acknowledge(alert.id);
                    if (ok && context.mounted) Navigator.of(context).pop();
                  },
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.how_to_reg_outlined),
            label: const Text('Acknowledge'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final note = await _askForNote(context);
                    if (note == null) return;
                    if (!context.mounted) return;
                    final ok = await ref
                        .read(alertActionProvider.notifier)
                        .resolve(alert.id, note: note.isEmpty ? null : note);
                    if (ok && context.mounted) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.task_alt_outlined),
            label: const Text('Resolve'),
          ),
        ),
      ],
    );
  }

  /// Optional resolution note (backend `/alerts/{id}/resolve` accepts `note`).
  Future<String?> _askForNote(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resolve alert'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          maxLength: 500,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Resolution note (optional)',
            hintText: 'What closed this alert?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}

/// Notification preferences sheet — reads/writes the real
/// `/notifications/preferences` contract. A failed toggle reverts (the
/// controller keeps previous state) and the sheet says so — a local-only
/// toggle would mislead the user about what will actually be delivered.
class _PrefsSheet extends ConsumerWidget {
  const _PrefsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: prefs.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SizedBox(
            height: 220,
            child: ErrorView(
              error: e,
              onRetry: () => ref.invalidate(notificationPrefsProvider),
            ),
          ),
          data: (p) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notification preferences',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Delivered by the backend according to your role and scope.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              if (p.channels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No channels are configured for your account yet.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                for (final entry in p.channels.entries)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(_channelLabel(entry.key)),
                    subtitle: Text(entry.key, style: theme.textTheme.bodySmall),
                    value: entry.value,
                    onChanged: (v) async {
                      final ok = await ref
                          .read(notificationPrefsProvider.notifier)
                          .setChannel(entry.key, enabled: v);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The server rejected that change — reverting.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
              const Divider(height: 24),
              Text('Minimum severity', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in kMinSeverityChoices)
                    ChoiceChip(
                      label: Text(s),
                      selected: p.minSeverity == s,
                      onSelected: (_) async {
                        final ok = await ref
                            .read(notificationPrefsProvider.notifier)
                            .setMinSeverity(s);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'The server rejected that change — reverting.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _channelLabel(String id) => switch (id) {
        'EMAIL' => 'Email',
        'SMS' => 'SMS',
        'WEB_PUSH' => 'Push notifications',
        _ => id.replaceAll('_', ' ').toLowerCase(),
      };
}

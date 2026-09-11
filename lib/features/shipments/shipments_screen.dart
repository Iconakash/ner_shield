import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/time_format.dart';
import '../../models/shipment.dart';
import '../../models/cached_result.dart';
import '../../shared/widgets/screen_states.dart';
import '../../shared/widgets/status_chip.dart';
import 'shipments_controller.dart';

/// Logistics inbox — RLS-scoped shipments over `GET /shipments` (master
/// prompt §30). The detail sheet offers only backend-supported lifecycle
/// transitions; the server stays the authority for authorization/conflict
/// rules (403/409 messages surface verbatim). Nothing here fabricates state.
class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key, this.focusId});

  /// Deep-link focus: when present, the matching shipment's detail sheet
  /// auto-opens once its row is available (e.g. `?focus=<shipment_id>` from a
  /// notification tap).
  final String? focusId;

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

enum _ShipmentFilter { all, active, critical }

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  _ShipmentFilter _filter = _ShipmentFilter.all;
  String? _focusId;
  bool _focusHandled = false;

  @override
  void initState() {
    super.initState();
    _focusId = widget.focusId;
    if (_focusId != null) {
      ref.listenManual<AsyncValue<CachedResult<List<Shipment>>>>(
        shipmentsProvider,
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
  void didUpdateWidget(ShipmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusId != oldWidget.focusId) {
      _focusId = widget.focusId;
      _focusHandled = false;
      if (_focusId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOpenFocus());
      }
    }
  }

  /// Auto-opens the focused shipment's detail sheet once its row is present.
  Future<void> _maybeOpenFocus() async {
    if (_focusHandled || !mounted || _focusId == null) return;
    final value = ref.read(shipmentsProvider).valueOrNull;
    if (value == null) return;
    for (final s in value.value) {
      if (s.id == _focusId) {
        _focusHandled = true;
        await _openDetail(context, s);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shipmentsProvider);
    return Column(
      children: [
        _FilterBar(
          current: _filter,
          onSelect: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: state.when(
            loading: () => const LoadingView(label: 'Loading shipments…'),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.read(shipmentsProvider.notifier).refresh(),
            ),
            data: (result) {
              final list = _apply(result.value);
              if (list.isEmpty) {
                return EmptyView(
                  title: _filter == _ShipmentFilter.all
                      ? 'No shipments in your scope'
                      : 'No matching shipments',
                  message: _filter == _ShipmentFilter.all
                      ? 'Shipments visible to your role and geography appear '
                          'here. Pull to refresh once logistics teams assign '
                          'cargo.'
                      : 'Try a different filter — the list only contains rows '
                          'the backend returned for your scope.',
                  icon: Icons.local_shipping_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(shipmentsProvider.notifier).refresh(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ShipmentCard(
                    shipment: list[i],
                    onOpen: () => _openDetail(context, list[i]),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Shipment> _apply(List<Shipment> rows) {
    switch (_filter) {
      case _ShipmentFilter.all:
        return rows;
      case _ShipmentFilter.active:
        return rows.where((s) => s.isActive).toList();
      case _ShipmentFilter.critical:
        return rows.where((s) => s.isCritical).toList();
    }
  }

  Future<void> _openDetail(BuildContext context, Shipment shipment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ShipmentDetailSheet(shipment: shipment),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onSelect});

  final _ShipmentFilter current;
  final ValueChanged<_ShipmentFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          FilterChip(
            selected: current == _ShipmentFilter.all,
            label: const Text('All'),
            onSelected: (_) => onSelect(_ShipmentFilter.all),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: current == _ShipmentFilter.active,
            label: const Text('Active'),
            onSelected: (_) => onSelect(_ShipmentFilter.active),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: current == _ShipmentFilter.critical,
            label: const Text('Critical'),
            onSelected: (_) => onSelect(_ShipmentFilter.critical),
          ),
        ],
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onOpen});

  final Shipment shipment;
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      shipment.title ?? shipment.code ?? 'Shipment',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (shipment.priority != null)
                    _PriorityChip(label: shipment.priority!),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (shipment.status != null) ...[
                    _StatusChip(status: shipment.status!),
                    const SizedBox(width: 8),
                  ],
                  if (shipment.commodity != null)
                    Expanded(
                      child: Text(
                        shipment.commodity!.replaceAll('_', ' '),
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.outbound,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shipment.originName ?? 'Unknown origin',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shipment.destName ??
                          shipment.destDistrict ??
                          'Unknown destination',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (shipment.vehicleCode != null) ...[
                    Icon(Icons.local_shipping_outlined,
                        size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(shipment.vehicleCode!,
                        style: theme.textTheme.labelSmall),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  if (shipment.etaAt != null)
                    Text(
                      'ETA ${TimeFormat.clock(shipment.etaAt)}',
                      style: theme.textTheme.labelSmall,
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

/// Detail + lifecycle actions for one shipment (master prompt §30). The ETA
/// card shows the backend-calculated value only; transition buttons are
/// limited to [nextStatusesFor] and the server stays the authority — its
/// 403/409 messages surface verbatim.
class _ShipmentDetailSheet extends ConsumerWidget {
  const _ShipmentDetailSheet({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final action = ref.watch(shipmentActionProvider);
    final etaAsync = ref.watch(shipmentEtaProvider(shipment.id));
    final nexts = nextStatusesFor(shipment.status);
    final busy = action.busyId == shipment.id;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            shipment.title ?? shipment.code ?? 'Shipment',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (shipment.priority != null)
                _PriorityChip(label: shipment.priority!),
              if (shipment.status != null) _StatusChip(status: shipment.status!),
            ],
          ),
          const SizedBox(height: 12),
          _kv(context, Icons.inventory_2_outlined, 'Commodity',
              shipment.commodity?.replaceAll('_', ' ') ?? '—'),
          _kv(context, Icons.outbound, 'Origin', shipment.originName ?? '—'),
          _kv(context, Icons.place_outlined, 'Destination',
              [shipment.destName, shipment.destDistrict, shipment.destState]
                  .nonNulls
                  .join(' · ')),
          _kv(context, Icons.local_shipping_outlined, 'Vehicle',
              shipment.vehicleCode ?? '—'),
          _kv(context, Icons.schedule, 'Planned ETA',
              shipment.etaAt == null ? '—' : TimeFormat.clock(shipment.etaAt)),
          const SizedBox(height: 12),
          // Backend-calculated ETA (GET /shipments/{id}/eta) — shown verbatim,
          // with its own loading/error state. Never fabricated client-side.
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text('Live ETA (routing engine)',
                  style: theme.textTheme.labelLarge),
              subtitle: etaAsync.when(
                loading: () => const Text('Calculating…'),
                error: (e, _) => Text(
                  'Unavailable — the routing engine could not be reached.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                data: (eta) => Text(
                  '${eta.etaMinutes} min · as of ${TimeFormat.clock(eta.calculatedAt)}',
                ),
              ),
            ),
          ),
          if (action.error != null) ...[
            const SizedBox(height: 8),
            Text(
              action.error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (nexts.isNotEmpty || shipment.status == 'IN_TRANSIT') ...[
            const SizedBox(height: 12),
            Text('Actions', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (shipment.status == 'IN_TRANSIT')
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(shipmentActionProvider.notifier)
                            .confirmDelivery(shipment.id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm delivery'),
                  ),
                for (final n in nexts)
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(shipmentActionProvider.notifier)
                            .updateStatus(shipment.id, newStatus: n),
                    child: Text(
                      'Mark ${n.replaceAll('_', ' ').toLowerCase()}',
                    ),
                  ),
                if (busy)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Priority chip — presentation-level mapping for shipment priorities
/// (backend vocabulary includes values like NORMAL that [SeverityVisuals]
/// does not cover). Label + icon + colour, never colour alone.
class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (label) {
      'CRITICAL' => (const Color(0xFFBA1A1A), Icons.error_outline),
      'HIGH' => (const Color(0xFF9A6A00), Icons.warning_amber_outlined),
      'MEDIUM' => (const Color(0xFF00639C), Icons.info_outline),
      _ => (const Color(0xFF5E5E66), Icons.radio_button_unchecked),
    };
    return StatusChip(label: label, icon: icon, color: color, dense: true);
  }
}

/// Shipment lifecycle chip (backend status vocabulary).
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'IN_TRANSIT' => (const Color(0xFF00639C), Icons.local_shipping_outlined),
      'DELIVERED' => (const Color(0xFF1E7A3C), Icons.check_circle_outline),
      'DELAYED' => (const Color(0xFFBA1A1A), Icons.schedule_outlined),
      'PENDING' || 'PREPARING' || 'ASSIGNED' => (
        const Color(0xFF9A6A00),
        Icons.hourglass_top_outlined
      ),
      'CANCELLED' => (const Color(0xFF5E5E66), Icons.cancel_outlined),
      _ => (const Color(0xFF00639C), Icons.help_outline),
    };
    return StatusChip(
      label: status.replaceAll('_', ' '),
      icon: icon,
      color: color,
      dense: true,
    );
  }
}


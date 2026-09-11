import '../core/storage/cache_first.dart';
import '../models/shipment.dart';
import '../services/shipments_service.dart';

/// Logistics reads + lifecycle actions.
///
/// ETA is computed per request server-side (route + live road state) and is
/// NOT cached; the shipment list is cached briefly and invalidated after any
/// status mutation.
class ShipmentsRepository {
  ShipmentsRepository(this._svc)
      : _list = CacheFirst(TtlCache(ttl: const Duration(seconds: 30)));

  final ShipmentsService _svc;
  final CacheFirst<List<Shipment>> _list;

  /// RLS-scoped shipment list, server-ordered by priority.
  Future<CachedResult<List<Shipment>>> list() =>
      _list.run('shipments', fetch: _svc.list);

  /// Backend-calculated ETA for one shipment (never cached).
  Future<ShipmentEta> eta(String shipmentId) => _svc.eta(shipmentId);

  Future<void> updateStatus(
    String shipmentId, {
    required String newStatus,
    String? note,
  }) async {
    await _svc.updateStatus(shipmentId, newStatus: newStatus, note: note);
    _list.invalidateAll();
  }

  Future<void> confirmDelivery(String shipmentId) async {
    await _svc.confirmDelivery(shipmentId);
    _list.invalidateAll();
  }

  /// Public cache invalidation — used by the reconnection reconciler
  /// when pull deltas indicate the shipment list changed server-side.
  void invalidateAll() => _list.invalidateAll();
}

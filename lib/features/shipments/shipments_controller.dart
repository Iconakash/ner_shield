import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/app_logger.dart';
import '../../models/cached_result.dart';
import '../../models/shipment.dart';

/// Shipments list — cache-first reads (30s TTL) over `GET /shipments`.
/// RLS scopes every row server-side; the client renders what it receives.
final shipmentsProvider = AsyncNotifierProvider<ShipmentsController,
    CachedResult<List<Shipment>>>(ShipmentsController.new);

class ShipmentsController
    extends AsyncNotifier<CachedResult<List<Shipment>>> {
  @override
  Future<CachedResult<List<Shipment>>> build() {
    return ref.watch(shipmentsRepositoryProvider).list();
  }

  /// Pull-to-refresh — explicit loading state (house pattern).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(shipmentsRepositoryProvider).list(),
    );
  }

  /// Silent refetch after a mutation — keeps the current list visible
  /// (the repository has already invalidated its cache).
  Future<void> reloadAfterAction() async {
    state = await AsyncValue.guard(
      () => ref.read(shipmentsRepositoryProvider).list(),
    );
  }
}

/// Backend-calculated ETA for one shipment (`GET /shipments/{id}/eta`).
/// Computed per request server-side — never cached beyond the
/// autoDispose lifetime of the provider.
final shipmentEtaProvider = FutureProvider.autoDispose
    .family<ShipmentEta, String>((ref, shipmentId) {
  return ref.watch(shipmentsRepositoryProvider).eta(shipmentId);
});

/// Lifecycle transitions the UI offers per current status. The backend
/// remains the authority — invalid requests surface its 409/403 message
/// verbatim (master prompt §30: never fabricate logistics state).
const kShipmentTransitions = <String, List<String>>{
  'VEHICLE_ASSIGNED': ['ROUTE_ASSIGNED', 'CANCELLED'],
  'ROUTE_ASSIGNED': ['IN_TRANSIT', 'CANCELLED'],
  'IN_TRANSIT': ['DELIVERED', 'CANCELLED'],
};

List<String> nextStatusesFor(String? status) =>
    kShipmentTransitions[status] ?? const [];

/// In-flight mutation feedback for the shipments screen.
class ShipmentActionState {
  const ShipmentActionState({this.busyId, this.message, this.error});

  final String? busyId;
  final String? message;
  final String? error;

  ShipmentActionState copyWith({
    String? busyId,
    String? message,
    String? error,
    bool clearBusy = false,
    bool clearMessage = false,
    bool clearError = false,
  }) {
    return ShipmentActionState(
      busyId: clearBusy ? null : (busyId ?? this.busyId),
      message: clearMessage ? null : (message ?? this.message),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final shipmentActionProvider =
    NotifierProvider<ShipmentActionController, ShipmentActionState>(
      ShipmentActionController.new,
    );

class ShipmentActionController extends Notifier<ShipmentActionState> {
  @override
  ShipmentActionState build() => const ShipmentActionState();

  Future<bool> updateStatus(
    String id, {
    required String newStatus,
    String? note,
  }) async {
    state = state.copyWith(busyId: id, clearMessage: true, clearError: true);
    try {
      await ref
          .read(shipmentsRepositoryProvider)
          .updateStatus(id, newStatus: newStatus, note: note);
      state = state.copyWith(
        clearBusy: true,
        message: 'Status updated to ${newStatus.replaceAll('_', ' ')}',
      );
      await ref.read(shipmentsProvider.notifier).reloadAfterAction();
      return true;
    } catch (e, s) {
      // Backend authorization/conflict messages surface verbatim (§43).
      final message = e is AppException
          ? e.message
          : 'Could not update the shipment status. Please try again.';
      state = state.copyWith(clearBusy: true, error: message);
      AppLogger.instance.error('shipment status update failed', e, s);
      return false;
    }
  }

  Future<bool> confirmDelivery(String id) async {
    state = state.copyWith(busyId: id, clearMessage: true, clearError: true);
    try {
      await ref.read(shipmentsRepositoryProvider).confirmDelivery(id);
      state = state.copyWith(clearBusy: true, message: 'Delivery confirmed');
      await ref.read(shipmentsProvider.notifier).reloadAfterAction();
      return true;
    } catch (e, s) {
      final message = e is AppException
          ? e.message
          : 'Could not confirm delivery. Please try again.';
      state = state.copyWith(clearBusy: true, error: message);
      AppLogger.instance.error('shipment delivery confirmation failed', e, s);
      return false;
    }
  }
}
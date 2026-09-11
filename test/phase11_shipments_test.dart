import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/core/storage/cache_first.dart';
import 'package:ner_shield/features/shipments/shipments_controller.dart';
import 'package:ner_shield/models/shipment.dart';
import 'package:ner_shield/services/shipments_service.dart';

class FakeShipmentsService implements ShipmentsService {
  FakeShipmentsService({
    this.listResult,
    this.failOn = const <String>{},
  });

  List<Shipment>? listResult;
  Set<String> failOn;
  int updateCalls = 0;
  int confirmCalls = 0;
  String? lastNewStatus;

  @override
  Future<List<Shipment>> list() async {
    if (failOn.contains('list')) throw const NetworkException('offline');
    return listResult ?? const <Shipment>[];
  }

  @override
  Future<ShipmentEta> eta(String shipmentId) async {
    return ShipmentEta(
      id: shipmentId,
      etaMinutes: 45,
      calculatedAt: '2026-09-03T00:00:00Z',
    );
  }

  @override
  Future<void> updateStatus(
    String shipmentId, {
    required String newStatus,
    String? note,
  }) async {
    updateCalls += 1;
    lastNewStatus = newStatus;
    if (failOn.contains('updateStatus')) {
      throw const ForbiddenException('Permission denied');
    }
  }

  @override
  Future<void> confirmDelivery(String shipmentId) async {
    confirmCalls += 1;
    if (failOn.contains('confirmDelivery')) {
      throw const NetworkException('confirm failed');
    }
  }
}
List<Shipment> _sampleList() => const <Shipment>[
      Shipment(
        id: 's-1',
        code: 'S-1',
        title: 'Medicine A',
        commodity: 'MEDICINE',
        priority: 'CRITICAL',
        status: 'IN_TRANSIT',
        originName: 'Guwahati',
        destName: 'Imphal',
        vehicleCode: 'VEH-01',
      ),
      Shipment(
        id: 's-2',
        code: 'S-2',
        title: 'Wheat',
        commodity: 'FOOD_GRAIN',
        priority: 'NORMAL',
        status: 'DELIVERED',
        originName: 'Guwahati',
        destName: 'Shillong',
        vehicleCode: 'VEH-02',
      ),
    ];

void main() {
  group('Shipments service + repository (T12)', () {
    test('list parses the RLS-scoped shipment payload', () async {
      final fake = FakeShipmentsService(listResult: _sampleList());
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      final result =
          await container.read(shipmentsRepositoryProvider).list();
      expect(result.value, hasLength(2));
      expect(result.value.first.isCritical, isTrue);
      expect(result.value.last.isActive, isFalse);
    });

    test('list failure surfaces a typed AppException', () async {
      final fake = FakeShipmentsService(failOn: {'list'});
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      expect(
        () => container.read(shipmentsRepositoryProvider).list(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('eta returns a typed model from the service', () async {
      final fake = FakeShipmentsService();
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      final eta =
          await container.read(shipmentsRepositoryProvider).eta('s-1');
      expect(eta.id, 's-1');
      expect(eta.etaMinutes, 45);
    });
  });

  group('ShipmentsController', () {
    test('refresh exposes loading then data', () async {
      final fake = FakeShipmentsService(listResult: _sampleList());
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      await container.read(shipmentsProvider.future);
      expect(container.read(shipmentsProvider).value?.value, hasLength(2));
      await container.read(shipmentsProvider.notifier).refresh();
      expect(container.read(shipmentsProvider).value?.value, hasLength(2));
    });
  });

  group('ShipmentActionController (lifecycle)', () {
    test('updateStatus success forwards to the service', () async {
      final fake = FakeShipmentsService();
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      final ok = await container
          .read(shipmentActionProvider.notifier)
          .updateStatus('s-1', newStatus: 'IN_TRANSIT');
      expect(ok, isTrue);
      expect(fake.updateCalls, 1);
      expect(fake.lastNewStatus, 'IN_TRANSIT');
    });

    test('confirmDelivery surfaces backend errors', () async {
      final fake = FakeShipmentsService(failOn: {'confirmDelivery'});
      final container = ProviderContainer(
        overrides: [
          shipmentsServiceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);
      final ok = await container
          .read(shipmentActionProvider.notifier)
          .confirmDelivery('s-1');
      expect(ok, isFalse);
      expect(fake.confirmCalls, 1);
    });
  });

  group('kShipmentTransitions', () {
    test('lists only valid next statuses', () {
      expect(nextStatusesFor('VEHICLE_ASSIGNED'),
          containsAll(<String>['ROUTE_ASSIGNED', 'CANCELLED']));
      expect(nextStatusesFor('ROUTE_ASSIGNED'),
          containsAll(<String>['IN_TRANSIT', 'CANCELLED']));
      expect(nextStatusesFor('DELIVERED'), isEmpty);
      expect(nextStatusesFor(null), isEmpty);
    });
  });

  group('CachedResult', () {
    test('exposes stale fallback without refetching', () {
      const r = CachedResult<int>(42, fromCache: true);
      expect(r.value, 42);
      expect(r.servedFromCache, isTrue);
    });
  });
}
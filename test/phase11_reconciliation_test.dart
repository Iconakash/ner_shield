import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/models/sync_models.dart';
import 'package:ner_shield/services/sync_service.dart';

/// Phase 11 — reconnection reconciliation mapping.
///
/// The backend `GET /sync/pull` contract is grouped lists
/// (`backend/app/sync/service.py::pull_changes`):
///   {cursor, alerts[], shipments[], validated_incidents[], pulled_at_cursor}
/// `SyncService.pull` normalizes that envelope into typed deltas the
/// reconciler can route to the correct repository cache, and never
/// claims pagination the server doesn't provide.
void main() {
  group('syncPullResponseFromBody', () {
    test('maps alerts/shipments/validated incidents to typed deltas', () {
      final response = syncPullResponseFromBody(
        {
          'cursor': 0,
          'alerts': [
            {'id': 'a-1', 'level': 'HIGH', 'status': 'ACTIVE'},
          ],
          'shipments': [
            {'id': 's-1', 'code': 'SH-1', 'status': 'IN_TRANSIT'},
          ],
          'validated_incidents': [
            {'id': 'r-1', 'code': 'FR-TEST', 'severity': 'HIGH'},
          ],
          'pulled_at_cursor': 7,
        },
        cursor: 0,
      );

      final deltas = response.deltas ?? const <SyncPullDelta>[];
      expect(deltas, hasLength(3));

      final alert = deltas.firstWhere((d) => d.entityType == 'ALERT');
      expect(alert.entityId, 'a-1');
      expect(alert.action, 'UPSERT');
      expect(alert.payload?['level'], 'HIGH');

      final shipment = deltas.firstWhere((d) => d.entityType == 'SHIPMENT');
      expect(shipment.entityId, 's-1');
      expect(shipment.payload?['code'], 'SH-1');

      final incident = deltas.firstWhere((d) => d.entityType == 'INCIDENT');
      expect(incident.entityId, 'r-1');
      expect(incident.payload?['severity'], 'HIGH');

      // Single-page contract: nextCursor never exceeds the served cursor.
      expect(response.cursor, 7);
      expect(response.nextCursor, 7);
    });

    test('empty groups produce an empty delta list', () {
      final response = syncPullResponseFromBody(
        {
          'cursor': 0,
          'alerts': <Object?>[],
          'shipments': <Object?>[],
          'validated_incidents': <Object?>[],
          'pulled_at_cursor': 0,
        },
        cursor: 0,
      );
      expect(response.deltas, isEmpty);
      expect(response.nextCursor, 0);
    });

    test('missing groups are tolerated as no changes', () {
      final response = syncPullResponseFromBody({'cursor': 3}, cursor: 3);
      expect(response.deltas, isEmpty);
      expect(response.cursor, 3);

      // Non-list garbage is tolerated exactly like an absent key — the
      // backend's shape is fixed, but a defensive client never crashes on it.
      final garbage = syncPullResponseFromBody(
        {'alerts': 'not-a-list', 'pulled_at_cursor': 9},
        cursor: 9,
      );
      expect(garbage.deltas, isEmpty);
    });

    test('rows without an id are still carried for category-level invalidation',
        () {
      final response = syncPullResponseFromBody(
        {
          'alerts': [
            {'level': 'CRITICAL', 'status': 'ESCALATED'},
          ],
          'pulled_at_cursor': 0,
        },
        cursor: 0,
      );
      final deltas = response.deltas ?? const <SyncPullDelta>[];
      expect(deltas, hasLength(1));
      expect(deltas.single.entityId, isEmpty);
      expect(deltas.single.payload?['status'], 'ESCALATED');
    });

    test('cursor falls back to the request cursor when pulled_at_cursor absent',
        () {
      final response = syncPullResponseFromBody(
        {'alerts': <Object?>[], 'shipments': <Object?>[]},
        cursor: 42,
      );
      expect(response.cursor, 42);
      expect(response.nextCursor, 42);
    });
  });
}
import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../core/network/api_responses.dart';
import '../models/sync_models.dart';

/// Progressive sync endpoints (reference `backend/app/sync/router.py`).
class SyncService {
  SyncService(this._dio);

  final Dio _dio;

  /// POST /sync/devices — idempotent device registration.
  Future<void> registerDevice(String deviceCode) async {
    try {
      final res = await _dio.post<Object?>(
        '/sync/devices',
        data: {'device_code': deviceCode},
      );
      requireJsonObject(res);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /sync/policy — server-authoritative progressive-sync limits.
  Future<SyncPolicy> policy() async {
    try {
      final res = await _dio.get<Object?>('/sync/policy');
      final body = requireJsonObject(res);
      try {
        return SyncPolicy.fromJson(body);
      } on TypeError {
        throw const ParsingException('Sync policy was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// GET /sync/pull — scoped cache refresh for cache invalidation.
  ///
  /// The backend returns grouped lists (`{cursor, alerts, shipments,
  /// validated_incidents, pulled_at_cursor}` — verified in
  /// `backend/tests/test_sync_integration.py` / `app/sync/service.py`).
  /// Those are normalized into typed [SyncPullDelta] rows (ALERT / SHIPMENT /
  /// INCIDENT) so the reconciler can route each to the correct repository
  /// cache. `nextCursor == cursor` because the backend serves one page per
  /// call — there is no cursor-based pagination to follow.
  Future<SyncPullResponse> pull({required int cursor}) async {
    try {
      final res = await _dio.get<Object?>(
        '/sync/pull',
        queryParameters: {'cursor': cursor},
      );
      final body = requireJsonObject(res);
      return syncPullResponseFromBody(body, cursor: cursor);
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }

  /// POST /sync/push — batched offline operations with per-op verdicts.
  Future<SyncPushResponse> push({
    required String connectivity,
    required List<SyncPushOp> ops,
    String? deviceCode,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/sync/push',
        data: {
          if (deviceCode != null && deviceCode.isNotEmpty)
            'device_code': deviceCode,
          'connectivity': connectivity,
          'ops': ops.map((o) => o.toJson()).toList(),
        },
      );
      final body = requireJsonObject(res);
      try {
        return SyncPushResponse.fromJson(body);
      } on TypeError {
        throw const ParsingException('Sync push response was malformed.');
      }
    } on DioException catch (e) {
      throw ErrorMapper.from(e);
    }
  }
}

/// Normalize the backend `/sync/pull` envelope into the typed
/// [SyncPullResponse] the reconnection reconciler consumes.
///
/// Extracted as a pure top-level function so the mapping is testable without
/// an HTTP stack. The backend contract (verified against
/// `backend/app/sync/service.py::pull_changes` and the integration tests) is:
///
/// ```json
/// {"cursor": 0, "alerts": [...], "shipments": [...],
///  "validated_incidents": [...], "pulled_at_cursor": 0}
/// ```
///
/// Each grouped row becomes an upsert delta for its entity type; a row
/// without an `id` is still included (cache invalidation keyed by category
/// should happen even if an id is absent).
SyncPullResponse syncPullResponseFromBody(
  Map<String, dynamic> body, {
  required int cursor,
}) {
  final pulledAt = _toInt(body['pulled_at_cursor']) ?? cursor;

  final alerts = _rowsOf(body['alerts']);
  final shipments = _rowsOf(body['shipments']);
  final incidents = _rowsOf(body['validated_incidents']);

  final deltas = <SyncPullDelta>[
    for (final row in alerts)
      SyncPullDelta(
        entityType: 'ALERT',
        entityId: _rowId(row),
        action: 'UPSERT',
        payload: row,
      ),
    for (final row in shipments)
      SyncPullDelta(
        entityType: 'SHIPMENT',
        entityId: _rowId(row),
        action: 'UPSERT',
        payload: row,
      ),
    for (final row in incidents)
      SyncPullDelta(
        entityType: 'INCIDENT',
        entityId: _rowId(row),
        action: 'UPSERT',
        payload: row,
      ),
  ];

  return SyncPullResponse(
    cursor: pulledAt,
    // Single-page contract: the server sends one snapshot per call, so
    // `nextCursor == cursor` signals "no further pages" to the reconciler.
    nextCursor: pulledAt,
    deltas: deltas,
  );
}

List<Map<String, dynamic>> _rowsOf(Object? raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().toList(growable: false);
}

String _rowId(Map<String, dynamic> row) {
  final id = row['id'];
  return id is String && id.isNotEmpty ? id : '';
}

int? _toInt(Object? value) => value is num ? value.toInt() : null;
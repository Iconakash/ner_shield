import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_models.freezed.dart';
part 'sync_models.g.dart';

/// `GET /sync/policy` — `{connectivity_classes: [...], policy: {...}}`
/// (reference `backend/app/sync/service.py`).
@freezed
sealed class SyncPolicy with _$SyncPolicy {
  const factory SyncPolicy({
    List<String>? connectivityClasses,
    Map<String, SyncPolicyClass>? policy,
  }) = _SyncPolicy;

  factory SyncPolicy.fromJson(Map<String, dynamic> json) =>
      _$SyncPolicyFromJson(json);

  /// Mirrors the backend `DEFAULT_SYNC_POLICY` (server serves the authoritative
  /// copy via `/sync/policy`; this is only the offline fallback).
  factory SyncPolicy.defaults() => const SyncPolicy(
        connectivityClasses: [
          'EXCELLENT',
          'GOOD',
          'WEAK',
          'VERY_WEAK',
          'OFFLINE',
        ],
        policy: {
          'EXCELLENT': SyncPolicyClass(
            maxOps: 100,
            allowPhotos: true,
            allowedTypes: ['FIELD_REPORT', 'GPS_PING'],
            gpsBeaconS: 30,
          ),
          'GOOD': SyncPolicyClass(
            maxOps: 50,
            allowPhotos: true,
            allowedTypes: ['FIELD_REPORT', 'GPS_PING'],
            gpsBeaconS: 60,
          ),
          'WEAK': SyncPolicyClass(
            maxOps: 20,
            allowPhotos: false,
            allowedTypes: ['FIELD_REPORT', 'GPS_PING'],
            gpsBeaconS: 180,
          ),
          'VERY_WEAK': SyncPolicyClass(
            maxOps: 5,
            allowPhotos: false,
            allowedTypes: ['GPS_PING', 'CRITICAL_FIELD_REPORT'],
            gpsBeaconS: 600,
          ),
          'OFFLINE': SyncPolicyClass(
            maxOps: 0,
            allowPhotos: false,
            allowedTypes: [],
            gpsBeaconS: null,
          ),
        },
      );
}

/// Per-connectivity-class progressive-sync limits.
@freezed
sealed class SyncPolicyClass with _$SyncPolicyClass {
  const factory SyncPolicyClass({
    @Default(0) int maxOps,
    @Default(false) bool allowPhotos,
    List<String>? allowedTypes,
    int? gpsBeaconS,
  }) = _SyncPolicyClass;

  factory SyncPolicyClass.fromJson(Map<String, dynamic> json) =>
      _$SyncPolicyClassFromJson(json);
}

/// One batched operation sent to `POST /sync/push`.
@freezed
sealed class SyncPushOp with _$SyncPushOp {
  const factory SyncPushOp({
    required String clientOpId,
    required String opType,
    Map<String, dynamic>? payload,
  }) = _SyncPushOp;

  factory SyncPushOp.fromJson(Map<String, dynamic> json) =>
      _$SyncPushOpFromJson(json);
}

/// One per-op verdict from `POST /sync/push`.
@freezed
sealed class SyncOpResult with _$SyncOpResult {
  const factory SyncOpResult({
    required String clientOpId,
    required String status,
    String? reason,
    String? resourceId,
  }) = _SyncOpResult;

  factory SyncOpResult.fromJson(Map<String, dynamic> json) =>
      _$SyncOpResultFromJson(json);
}

/// `POST /sync/push` response.
@freezed
sealed class SyncPushResponse with _$SyncPushResponse {
  const factory SyncPushResponse({
    List<SyncOpResult>? results,
    @Default(0) int accepted,
    @Default(0) int total,
  }) = _SyncPushResponse;

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncPushResponseFromJson(json);
}

/// One typed delta row from `GET /sync/pull`.
@freezed
sealed class SyncPullDelta with _$SyncPullDelta {
  const factory SyncPullDelta({
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic>? payload,
  }) = _SyncPullDelta;

  factory SyncPullDelta.fromJson(Map<String, dynamic> json) =>
      _$SyncPullDeltaFromJson(json);
}

/// `GET /sync/pull?cursor=N` response — the cache-refresh delta envelope.
/// `nextCursor` returns a new cursor for subsequent fetches; deltas carry
/// RLS-scoped changes (alerts, shipments, incidents) that the reconciler
/// routes to the appropriate repository cache for invalidation + refresh.
@freezed
sealed class SyncPullResponse with _$SyncPullResponse {
  const factory SyncPullResponse({
    @Default(0) int cursor,
    @Default(0) int nextCursor,
    List<SyncPullDelta>? deltas,
  }) = _SyncPullResponse;

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncPullResponseFromJson(json);
}
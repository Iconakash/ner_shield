// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncPolicy _$SyncPolicyFromJson(Map<String, dynamic> json) => _SyncPolicy(
  connectivityClasses: (json['connectivity_classes'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  policy: (json['policy'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, SyncPolicyClass.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$SyncPolicyToJson(_SyncPolicy instance) =>
    <String, dynamic>{
      'connectivity_classes': instance.connectivityClasses,
      'policy': instance.policy,
    };

_SyncPolicyClass _$SyncPolicyClassFromJson(Map<String, dynamic> json) =>
    _SyncPolicyClass(
      maxOps: (json['max_ops'] as num?)?.toInt() ?? 0,
      allowPhotos: json['allow_photos'] as bool? ?? false,
      allowedTypes: (json['allowed_types'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      gpsBeaconS: (json['gps_beacon_s'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SyncPolicyClassToJson(_SyncPolicyClass instance) =>
    <String, dynamic>{
      'max_ops': instance.maxOps,
      'allow_photos': instance.allowPhotos,
      'allowed_types': instance.allowedTypes,
      'gps_beacon_s': instance.gpsBeaconS,
    };

_SyncPushOp _$SyncPushOpFromJson(Map<String, dynamic> json) => _SyncPushOp(
  clientOpId: json['client_op_id'] as String,
  opType: json['op_type'] as String,
  payload: json['payload'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$SyncPushOpToJson(_SyncPushOp instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'op_type': instance.opType,
      'payload': instance.payload,
    };

_SyncOpResult _$SyncOpResultFromJson(Map<String, dynamic> json) =>
    _SyncOpResult(
      clientOpId: json['client_op_id'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      resourceId: json['resource_id'] as String?,
    );

Map<String, dynamic> _$SyncOpResultToJson(_SyncOpResult instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'status': instance.status,
      'reason': instance.reason,
      'resource_id': instance.resourceId,
    };

_SyncPushResponse _$SyncPushResponseFromJson(Map<String, dynamic> json) =>
    _SyncPushResponse(
      results: (json['results'] as List<dynamic>?)
          ?.map((e) => SyncOpResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SyncPushResponseToJson(_SyncPushResponse instance) =>
    <String, dynamic>{
      'results': instance.results,
      'accepted': instance.accepted,
      'total': instance.total,
    };

_SyncPullDelta _$SyncPullDeltaFromJson(Map<String, dynamic> json) =>
    _SyncPullDelta(
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SyncPullDeltaToJson(_SyncPullDelta instance) =>
    <String, dynamic>{
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'action': instance.action,
      'payload': instance.payload,
    };

_SyncPullResponse _$SyncPullResponseFromJson(Map<String, dynamic> json) =>
    _SyncPullResponse(
      cursor: (json['cursor'] as num?)?.toInt() ?? 0,
      nextCursor: (json['next_cursor'] as num?)?.toInt() ?? 0,
      deltas: (json['deltas'] as List<dynamic>?)
          ?.map((e) => SyncPullDelta.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SyncPullResponseToJson(_SyncPullResponse instance) =>
    <String, dynamic>{
      'cursor': instance.cursor,
      'next_cursor': instance.nextCursor,
      'deltas': instance.deltas,
    };

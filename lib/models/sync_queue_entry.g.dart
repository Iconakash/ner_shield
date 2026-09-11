// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncQueueEntry _$SyncQueueEntryFromJson(Map<String, dynamic> json) =>
    _SyncQueueEntry(
      clientOpId: json['client_op_id'] as String,
      opType: json['op_type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      status: $enumDecode(_$SyncQueueStatusEnumMap, json['status']),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['last_error'] as String?,
      lastAttemptAt: json['last_attempt_at'] as String?,
      createdAt: json['created_at'] as String?,
      resourceId: json['resource_id'] as String?,
      entityType: json['entity_type'] as String?,
      entityId: json['entity_id'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      nextRetryAt: json['next_retry_at'] as String?,
      dependencyClientOpId: json['dependency_client_op_id'] as String?,
    );

Map<String, dynamic> _$SyncQueueEntryToJson(_SyncQueueEntry instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'op_type': instance.opType,
      'payload': instance.payload,
      'status': _$SyncQueueStatusEnumMap[instance.status]!,
      'attempts': instance.attempts,
      'last_error': instance.lastError,
      'last_attempt_at': instance.lastAttemptAt,
      'created_at': instance.createdAt,
      'resource_id': instance.resourceId,
      'entity_type': instance.entityType,
      'entity_id': instance.entityId,
      'priority': instance.priority,
      'next_retry_at': instance.nextRetryAt,
      'dependency_client_op_id': instance.dependencyClientOpId,
    };

const _$SyncQueueStatusEnumMap = {
  SyncQueueStatus.pending: 'pending',
  SyncQueueStatus.syncing: 'syncing',
  SyncQueueStatus.synced: 'synced',
  SyncQueueStatus.failed: 'failed',
  SyncQueueStatus.offline: 'offline',
  SyncQueueStatus.conflict: 'conflict',
};

_SyncAttempt _$SyncAttemptFromJson(Map<String, dynamic> json) => _SyncAttempt(
  clientOpId: json['client_op_id'] as String,
  attempt: (json['attempt'] as num).toInt(),
  at: json['at'] as String,
  outcome: json['outcome'] as String,
  reason: json['reason'] as String?,
  resourceId: json['resource_id'] as String?,
);

Map<String, dynamic> _$SyncAttemptToJson(_SyncAttempt instance) =>
    <String, dynamic>{
      'client_op_id': instance.clientOpId,
      'attempt': instance.attempt,
      'at': instance.at,
      'outcome': instance.outcome,
      'reason': instance.reason,
      'resource_id': instance.resourceId,
    };

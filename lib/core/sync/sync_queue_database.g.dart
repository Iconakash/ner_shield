// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_database.dart';

// ignore_for_file: type=lint
class $SyncQueueRowsTable extends SyncQueueRows
    with TableInfo<$SyncQueueRowsTable, SyncQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
    'op_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<String> lastAttemptAt = GeneratedColumn<String>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<String> nextRetryAt = GeneratedColumn<String>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dependencyClientOpIdMeta =
      const VerificationMeta('dependencyClientOpId');
  @override
  late final GeneratedColumn<String> dependencyClientOpId =
      GeneratedColumn<String>(
        'dependency_client_op_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    clientOpId,
    opType,
    entityType,
    entityId,
    payloadJson,
    status,
    attempts,
    priority,
    lastError,
    lastAttemptAt,
    nextRetryAt,
    createdAt,
    resourceId,
    dependencyClientOpId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('op_type')) {
      context.handle(
        _opTypeMeta,
        opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    }
    if (data.containsKey('dependency_client_op_id')) {
      context.handle(
        _dependencyClientOpIdMeta,
        dependencyClientOpId.isAcceptableOrUnknown(
          data['dependency_client_op_id']!,
          _dependencyClientOpIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOpId};
  @override
  SyncQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueRow(
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      opType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      ),
      dependencyClientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_client_op_id'],
      ),
    );
  }

  @override
  $SyncQueueRowsTable createAlias(String alias) {
    return $SyncQueueRowsTable(attachedDatabase, alias);
  }
}

class SyncQueueRow extends DataClass implements Insertable<SyncQueueRow> {
  final String clientOpId;
  final String opType;
  final String? entityType;
  final String? entityId;
  final String payloadJson;
  final String status;
  final int attempts;
  final int priority;
  final String? lastError;
  final String? lastAttemptAt;
  final String? nextRetryAt;
  final String createdAt;
  final String? resourceId;
  final String? dependencyClientOpId;
  const SyncQueueRow({
    required this.clientOpId,
    required this.opType,
    this.entityType,
    this.entityId,
    required this.payloadJson,
    required this.status,
    required this.attempts,
    required this.priority,
    this.lastError,
    this.lastAttemptAt,
    this.nextRetryAt,
    required this.createdAt,
    this.resourceId,
    this.dependencyClientOpId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_op_id'] = Variable<String>(clientOpId);
    map['op_type'] = Variable<String>(opType);
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<String>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<String>(nextRetryAt);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    if (!nullToAbsent || dependencyClientOpId != null) {
      map['dependency_client_op_id'] = Variable<String>(dependencyClientOpId);
    }
    return map;
  }

  SyncQueueRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueRowsCompanion(
      clientOpId: Value(clientOpId),
      opType: Value(opType),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attempts: Value(attempts),
      priority: Value(priority),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
      dependencyClientOpId: dependencyClientOpId == null && nullToAbsent
          ? const Value.absent()
          : Value(dependencyClientOpId),
    );
  }

  factory SyncQueueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueRow(
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      opType: serializer.fromJson<String>(json['opType']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      priority: serializer.fromJson<int>(json['priority']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<String?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<String?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
      dependencyClientOpId: serializer.fromJson<String?>(
        json['dependencyClientOpId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOpId': serializer.toJson<String>(clientOpId),
      'opType': serializer.toJson<String>(opType),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'priority': serializer.toJson<int>(priority),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<String?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<String?>(nextRetryAt),
      'createdAt': serializer.toJson<String>(createdAt),
      'resourceId': serializer.toJson<String?>(resourceId),
      'dependencyClientOpId': serializer.toJson<String?>(dependencyClientOpId),
    };
  }

  SyncQueueRow copyWith({
    String? clientOpId,
    String? opType,
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
    String? payloadJson,
    String? status,
    int? attempts,
    int? priority,
    Value<String?> lastError = const Value.absent(),
    Value<String?> lastAttemptAt = const Value.absent(),
    Value<String?> nextRetryAt = const Value.absent(),
    String? createdAt,
    Value<String?> resourceId = const Value.absent(),
    Value<String?> dependencyClientOpId = const Value.absent(),
  }) => SyncQueueRow(
    clientOpId: clientOpId ?? this.clientOpId,
    opType: opType ?? this.opType,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    priority: priority ?? this.priority,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
    resourceId: resourceId.present ? resourceId.value : this.resourceId,
    dependencyClientOpId: dependencyClientOpId.present
        ? dependencyClientOpId.value
        : this.dependencyClientOpId,
  );
  SyncQueueRow copyWithCompanion(SyncQueueRowsCompanion data) {
    return SyncQueueRow(
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      opType: data.opType.present ? data.opType.value : this.opType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      priority: data.priority.present ? data.priority.value : this.priority,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
      dependencyClientOpId: data.dependencyClientOpId.present
          ? data.dependencyClientOpId.value
          : this.dependencyClientOpId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRow(')
          ..write('clientOpId: $clientOpId, ')
          ..write('opType: $opType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('priority: $priority, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('resourceId: $resourceId, ')
          ..write('dependencyClientOpId: $dependencyClientOpId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientOpId,
    opType,
    entityType,
    entityId,
    payloadJson,
    status,
    attempts,
    priority,
    lastError,
    lastAttemptAt,
    nextRetryAt,
    createdAt,
    resourceId,
    dependencyClientOpId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueRow &&
          other.clientOpId == this.clientOpId &&
          other.opType == this.opType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.priority == this.priority &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt &&
          other.resourceId == this.resourceId &&
          other.dependencyClientOpId == this.dependencyClientOpId);
}

class SyncQueueRowsCompanion extends UpdateCompanion<SyncQueueRow> {
  final Value<String> clientOpId;
  final Value<String> opType;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int> priority;
  final Value<String?> lastError;
  final Value<String?> lastAttemptAt;
  final Value<String?> nextRetryAt;
  final Value<String> createdAt;
  final Value<String?> resourceId;
  final Value<String?> dependencyClientOpId;
  final Value<int> rowid;
  const SyncQueueRowsCompanion({
    this.clientOpId = const Value.absent(),
    this.opType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.resourceId = const Value.absent(),
    this.dependencyClientOpId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueRowsCompanion.insert({
    required String clientOpId,
    required String opType,
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    required String payloadJson,
    required String status,
    this.attempts = const Value.absent(),
    this.priority = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required String createdAt,
    this.resourceId = const Value.absent(),
    this.dependencyClientOpId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientOpId = Value(clientOpId),
       opType = Value(opType),
       payloadJson = Value(payloadJson),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueRow> custom({
    Expression<String>? clientOpId,
    Expression<String>? opType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? priority,
    Expression<String>? lastError,
    Expression<String>? lastAttemptAt,
    Expression<String>? nextRetryAt,
    Expression<String>? createdAt,
    Expression<String>? resourceId,
    Expression<String>? dependencyClientOpId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (opType != null) 'op_type': opType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (priority != null) 'priority': priority,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
      if (resourceId != null) 'resource_id': resourceId,
      if (dependencyClientOpId != null)
        'dependency_client_op_id': dependencyClientOpId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueRowsCompanion copyWith({
    Value<String>? clientOpId,
    Value<String>? opType,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attempts,
    Value<int>? priority,
    Value<String?>? lastError,
    Value<String?>? lastAttemptAt,
    Value<String?>? nextRetryAt,
    Value<String>? createdAt,
    Value<String?>? resourceId,
    Value<String?>? dependencyClientOpId,
    Value<int>? rowid,
  }) {
    return SyncQueueRowsCompanion(
      clientOpId: clientOpId ?? this.clientOpId,
      opType: opType ?? this.opType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      priority: priority ?? this.priority,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
      resourceId: resourceId ?? this.resourceId,
      dependencyClientOpId: dependencyClientOpId ?? this.dependencyClientOpId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<String>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<String>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    if (dependencyClientOpId.present) {
      map['dependency_client_op_id'] = Variable<String>(
        dependencyClientOpId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueRowsCompanion(')
          ..write('clientOpId: $clientOpId, ')
          ..write('opType: $opType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('priority: $priority, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('resourceId: $resourceId, ')
          ..write('dependencyClientOpId: $dependencyClientOpId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncAttemptRowsTable extends SyncAttemptRows
    with TableInfo<$SyncAttemptRowsTable, SyncAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncAttemptRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<String> at = GeneratedColumn<String>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resourceIdMeta = const VerificationMeta(
    'resourceId',
  );
  @override
  late final GeneratedColumn<String> resourceId = GeneratedColumn<String>(
    'resource_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientOpId,
    attempt,
    at,
    outcome,
    reason,
    resourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_attempt_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncAttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('resource_id')) {
      context.handle(
        _resourceIdMeta,
        resourceId.isAcceptableOrUnknown(data['resource_id']!, _resourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncAttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}at'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      resourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource_id'],
      ),
    );
  }

  @override
  $SyncAttemptRowsTable createAlias(String alias) {
    return $SyncAttemptRowsTable(attachedDatabase, alias);
  }
}

class SyncAttemptRow extends DataClass implements Insertable<SyncAttemptRow> {
  final int id;
  final String clientOpId;
  final int attempt;
  final String at;
  final String outcome;
  final String? reason;
  final String? resourceId;
  const SyncAttemptRow({
    required this.id,
    required this.clientOpId,
    required this.attempt,
    required this.at,
    required this.outcome,
    this.reason,
    this.resourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_op_id'] = Variable<String>(clientOpId);
    map['attempt'] = Variable<int>(attempt);
    map['at'] = Variable<String>(at);
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || resourceId != null) {
      map['resource_id'] = Variable<String>(resourceId);
    }
    return map;
  }

  SyncAttemptRowsCompanion toCompanion(bool nullToAbsent) {
    return SyncAttemptRowsCompanion(
      id: Value(id),
      clientOpId: Value(clientOpId),
      attempt: Value(attempt),
      at: Value(at),
      outcome: Value(outcome),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      resourceId: resourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(resourceId),
    );
  }

  factory SyncAttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncAttemptRow(
      id: serializer.fromJson<int>(json['id']),
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      attempt: serializer.fromJson<int>(json['attempt']),
      at: serializer.fromJson<String>(json['at']),
      outcome: serializer.fromJson<String>(json['outcome']),
      reason: serializer.fromJson<String?>(json['reason']),
      resourceId: serializer.fromJson<String?>(json['resourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientOpId': serializer.toJson<String>(clientOpId),
      'attempt': serializer.toJson<int>(attempt),
      'at': serializer.toJson<String>(at),
      'outcome': serializer.toJson<String>(outcome),
      'reason': serializer.toJson<String?>(reason),
      'resourceId': serializer.toJson<String?>(resourceId),
    };
  }

  SyncAttemptRow copyWith({
    int? id,
    String? clientOpId,
    int? attempt,
    String? at,
    String? outcome,
    Value<String?> reason = const Value.absent(),
    Value<String?> resourceId = const Value.absent(),
  }) => SyncAttemptRow(
    id: id ?? this.id,
    clientOpId: clientOpId ?? this.clientOpId,
    attempt: attempt ?? this.attempt,
    at: at ?? this.at,
    outcome: outcome ?? this.outcome,
    reason: reason.present ? reason.value : this.reason,
    resourceId: resourceId.present ? resourceId.value : this.resourceId,
  );
  SyncAttemptRow copyWithCompanion(SyncAttemptRowsCompanion data) {
    return SyncAttemptRow(
      id: data.id.present ? data.id.value : this.id,
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      at: data.at.present ? data.at.value : this.at,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      reason: data.reason.present ? data.reason.value : this.reason,
      resourceId: data.resourceId.present
          ? data.resourceId.value
          : this.resourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncAttemptRow(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('attempt: $attempt, ')
          ..write('at: $at, ')
          ..write('outcome: $outcome, ')
          ..write('reason: $reason, ')
          ..write('resourceId: $resourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientOpId, attempt, at, outcome, reason, resourceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncAttemptRow &&
          other.id == this.id &&
          other.clientOpId == this.clientOpId &&
          other.attempt == this.attempt &&
          other.at == this.at &&
          other.outcome == this.outcome &&
          other.reason == this.reason &&
          other.resourceId == this.resourceId);
}

class SyncAttemptRowsCompanion extends UpdateCompanion<SyncAttemptRow> {
  final Value<int> id;
  final Value<String> clientOpId;
  final Value<int> attempt;
  final Value<String> at;
  final Value<String> outcome;
  final Value<String?> reason;
  final Value<String?> resourceId;
  const SyncAttemptRowsCompanion({
    this.id = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.attempt = const Value.absent(),
    this.at = const Value.absent(),
    this.outcome = const Value.absent(),
    this.reason = const Value.absent(),
    this.resourceId = const Value.absent(),
  });
  SyncAttemptRowsCompanion.insert({
    this.id = const Value.absent(),
    required String clientOpId,
    required int attempt,
    required String at,
    required String outcome,
    this.reason = const Value.absent(),
    this.resourceId = const Value.absent(),
  }) : clientOpId = Value(clientOpId),
       attempt = Value(attempt),
       at = Value(at),
       outcome = Value(outcome);
  static Insertable<SyncAttemptRow> custom({
    Expression<int>? id,
    Expression<String>? clientOpId,
    Expression<int>? attempt,
    Expression<String>? at,
    Expression<String>? outcome,
    Expression<String>? reason,
    Expression<String>? resourceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (attempt != null) 'attempt': attempt,
      if (at != null) 'at': at,
      if (outcome != null) 'outcome': outcome,
      if (reason != null) 'reason': reason,
      if (resourceId != null) 'resource_id': resourceId,
    });
  }

  SyncAttemptRowsCompanion copyWith({
    Value<int>? id,
    Value<String>? clientOpId,
    Value<int>? attempt,
    Value<String>? at,
    Value<String>? outcome,
    Value<String?>? reason,
    Value<String?>? resourceId,
  }) {
    return SyncAttemptRowsCompanion(
      id: id ?? this.id,
      clientOpId: clientOpId ?? this.clientOpId,
      attempt: attempt ?? this.attempt,
      at: at ?? this.at,
      outcome: outcome ?? this.outcome,
      reason: reason ?? this.reason,
      resourceId: resourceId ?? this.resourceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (at.present) {
      map['at'] = Variable<String>(at.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (resourceId.present) {
      map['resource_id'] = Variable<String>(resourceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncAttemptRowsCompanion(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('attempt: $attempt, ')
          ..write('at: $at, ')
          ..write('outcome: $outcome, ')
          ..write('reason: $reason, ')
          ..write('resourceId: $resourceId')
          ..write(')'))
        .toString();
  }
}

class $DraftRowsTable extends DraftRows
    with TableInfo<$DraftRowsTable, DraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientDraftIdMeta = const VerificationMeta(
    'clientDraftId',
  );
  @override
  late final GeneratedColumn<String> clientDraftId = GeneratedColumn<String>(
    'client_draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientDraftId,
    payloadJson,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_draft_id')) {
      context.handle(
        _clientDraftIdMeta,
        clientDraftId.isAcceptableOrUnknown(
          data['client_draft_id']!,
          _clientDraftIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientDraftIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientDraftId};
  @override
  DraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftRow(
      clientDraftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_draft_id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $DraftRowsTable createAlias(String alias) {
    return $DraftRowsTable(attachedDatabase, alias);
  }
}

class DraftRow extends DataClass implements Insertable<DraftRow> {
  final String clientDraftId;
  final String payloadJson;
  final String updatedAt;
  final String? deletedAt;
  const DraftRow({
    required this.clientDraftId,
    required this.payloadJson,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_draft_id'] = Variable<String>(clientDraftId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  DraftRowsCompanion toCompanion(bool nullToAbsent) {
    return DraftRowsCompanion(
      clientDraftId: Value(clientDraftId),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftRow(
      clientDraftId: serializer.fromJson<String>(json['clientDraftId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientDraftId': serializer.toJson<String>(clientDraftId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  DraftRow copyWith({
    String? clientDraftId,
    String? payloadJson,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
  }) => DraftRow(
    clientDraftId: clientDraftId ?? this.clientDraftId,
    payloadJson: payloadJson ?? this.payloadJson,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DraftRow copyWithCompanion(DraftRowsCompanion data) {
    return DraftRow(
      clientDraftId: data.clientDraftId.present
          ? data.clientDraftId.value
          : this.clientDraftId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftRow(')
          ..write('clientDraftId: $clientDraftId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(clientDraftId, payloadJson, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftRow &&
          other.clientDraftId == this.clientDraftId &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DraftRowsCompanion extends UpdateCompanion<DraftRow> {
  final Value<String> clientDraftId;
  final Value<String> payloadJson;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const DraftRowsCompanion({
    this.clientDraftId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftRowsCompanion.insert({
    required String clientDraftId,
    required String payloadJson,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientDraftId = Value(clientDraftId),
       payloadJson = Value(payloadJson),
       updatedAt = Value(updatedAt);
  static Insertable<DraftRow> custom({
    Expression<String>? clientDraftId,
    Expression<String>? payloadJson,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientDraftId != null) 'client_draft_id': clientDraftId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftRowsCompanion copyWith({
    Value<String>? clientDraftId,
    Value<String>? payloadJson,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DraftRowsCompanion(
      clientDraftId: clientDraftId ?? this.clientDraftId,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientDraftId.present) {
      map['client_draft_id'] = Variable<String>(clientDraftId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftRowsCompanion(')
          ..write('clientDraftId: $clientDraftId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftMediaRowsTable extends DraftMediaRows
    with TableInfo<$DraftMediaRowsTable, DraftMediaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftMediaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientRefIdMeta = const VerificationMeta(
    'clientRefId',
  );
  @override
  late final GeneratedColumn<String> clientRefId = GeneratedColumn<String>(
    'client_ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientDraftIdMeta = const VerificationMeta(
    'clientDraftId',
  );
  @override
  late final GeneratedColumn<String> clientDraftId = GeneratedColumn<String>(
    'client_draft_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<String> capturedAt = GeneratedColumn<String>(
    'captured_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('QUEUED'),
  );
  static const VerificationMeta _serverMediaIdMeta = const VerificationMeta(
    'serverMediaId',
  );
  @override
  late final GeneratedColumn<String> serverMediaId = GeneratedColumn<String>(
    'server_media_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientRefId,
    clientDraftId,
    localPath,
    contentType,
    sizeBytes,
    sha256,
    capturedAt,
    state,
    serverMediaId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'draft_media_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DraftMediaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_ref_id')) {
      context.handle(
        _clientRefIdMeta,
        clientRefId.isAcceptableOrUnknown(
          data['client_ref_id']!,
          _clientRefIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRefIdMeta);
    }
    if (data.containsKey('client_draft_id')) {
      context.handle(
        _clientDraftIdMeta,
        clientDraftId.isAcceptableOrUnknown(
          data['client_draft_id']!,
          _clientDraftIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientDraftIdMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('server_media_id')) {
      context.handle(
        _serverMediaIdMeta,
        serverMediaId.isAcceptableOrUnknown(
          data['server_media_id']!,
          _serverMediaIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientRefId};
  @override
  DraftMediaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DraftMediaRow(
      clientRefId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_ref_id'],
      )!,
      clientDraftId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_draft_id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      ),
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}captured_at'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      serverMediaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_media_id'],
      ),
    );
  }

  @override
  $DraftMediaRowsTable createAlias(String alias) {
    return $DraftMediaRowsTable(attachedDatabase, alias);
  }
}

class DraftMediaRow extends DataClass implements Insertable<DraftMediaRow> {
  final String clientRefId;
  final String clientDraftId;
  final String localPath;
  final String? contentType;
  final int? sizeBytes;
  final String? sha256;
  final String? capturedAt;

  /// QUEUED | UPLOADING | UPLOADED | FAILED — drives the UI badge.
  final String state;

  /// Server-side media id once uploaded.
  final String? serverMediaId;
  const DraftMediaRow({
    required this.clientRefId,
    required this.clientDraftId,
    required this.localPath,
    this.contentType,
    this.sizeBytes,
    this.sha256,
    this.capturedAt,
    required this.state,
    this.serverMediaId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_ref_id'] = Variable<String>(clientRefId);
    map['client_draft_id'] = Variable<String>(clientDraftId);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || contentType != null) {
      map['content_type'] = Variable<String>(contentType);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    if (!nullToAbsent || capturedAt != null) {
      map['captured_at'] = Variable<String>(capturedAt);
    }
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || serverMediaId != null) {
      map['server_media_id'] = Variable<String>(serverMediaId);
    }
    return map;
  }

  DraftMediaRowsCompanion toCompanion(bool nullToAbsent) {
    return DraftMediaRowsCompanion(
      clientRefId: Value(clientRefId),
      clientDraftId: Value(clientDraftId),
      localPath: Value(localPath),
      contentType: contentType == null && nullToAbsent
          ? const Value.absent()
          : Value(contentType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      capturedAt: capturedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(capturedAt),
      state: Value(state),
      serverMediaId: serverMediaId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverMediaId),
    );
  }

  factory DraftMediaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DraftMediaRow(
      clientRefId: serializer.fromJson<String>(json['clientRefId']),
      clientDraftId: serializer.fromJson<String>(json['clientDraftId']),
      localPath: serializer.fromJson<String>(json['localPath']),
      contentType: serializer.fromJson<String?>(json['contentType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      capturedAt: serializer.fromJson<String?>(json['capturedAt']),
      state: serializer.fromJson<String>(json['state']),
      serverMediaId: serializer.fromJson<String?>(json['serverMediaId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientRefId': serializer.toJson<String>(clientRefId),
      'clientDraftId': serializer.toJson<String>(clientDraftId),
      'localPath': serializer.toJson<String>(localPath),
      'contentType': serializer.toJson<String?>(contentType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'sha256': serializer.toJson<String?>(sha256),
      'capturedAt': serializer.toJson<String?>(capturedAt),
      'state': serializer.toJson<String>(state),
      'serverMediaId': serializer.toJson<String?>(serverMediaId),
    };
  }

  DraftMediaRow copyWith({
    String? clientRefId,
    String? clientDraftId,
    String? localPath,
    Value<String?> contentType = const Value.absent(),
    Value<int?> sizeBytes = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    Value<String?> capturedAt = const Value.absent(),
    String? state,
    Value<String?> serverMediaId = const Value.absent(),
  }) => DraftMediaRow(
    clientRefId: clientRefId ?? this.clientRefId,
    clientDraftId: clientDraftId ?? this.clientDraftId,
    localPath: localPath ?? this.localPath,
    contentType: contentType.present ? contentType.value : this.contentType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    sha256: sha256.present ? sha256.value : this.sha256,
    capturedAt: capturedAt.present ? capturedAt.value : this.capturedAt,
    state: state ?? this.state,
    serverMediaId: serverMediaId.present
        ? serverMediaId.value
        : this.serverMediaId,
  );
  DraftMediaRow copyWithCompanion(DraftMediaRowsCompanion data) {
    return DraftMediaRow(
      clientRefId: data.clientRefId.present
          ? data.clientRefId.value
          : this.clientRefId,
      clientDraftId: data.clientDraftId.present
          ? data.clientDraftId.value
          : this.clientDraftId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      state: data.state.present ? data.state.value : this.state,
      serverMediaId: data.serverMediaId.present
          ? data.serverMediaId.value
          : this.serverMediaId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DraftMediaRow(')
          ..write('clientRefId: $clientRefId, ')
          ..write('clientDraftId: $clientDraftId, ')
          ..write('localPath: $localPath, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('state: $state, ')
          ..write('serverMediaId: $serverMediaId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientRefId,
    clientDraftId,
    localPath,
    contentType,
    sizeBytes,
    sha256,
    capturedAt,
    state,
    serverMediaId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DraftMediaRow &&
          other.clientRefId == this.clientRefId &&
          other.clientDraftId == this.clientDraftId &&
          other.localPath == this.localPath &&
          other.contentType == this.contentType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.capturedAt == this.capturedAt &&
          other.state == this.state &&
          other.serverMediaId == this.serverMediaId);
}

class DraftMediaRowsCompanion extends UpdateCompanion<DraftMediaRow> {
  final Value<String> clientRefId;
  final Value<String> clientDraftId;
  final Value<String> localPath;
  final Value<String?> contentType;
  final Value<int?> sizeBytes;
  final Value<String?> sha256;
  final Value<String?> capturedAt;
  final Value<String> state;
  final Value<String?> serverMediaId;
  final Value<int> rowid;
  const DraftMediaRowsCompanion({
    this.clientRefId = const Value.absent(),
    this.clientDraftId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.serverMediaId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftMediaRowsCompanion.insert({
    required String clientRefId,
    required String clientDraftId,
    required String localPath,
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.state = const Value.absent(),
    this.serverMediaId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientRefId = Value(clientRefId),
       clientDraftId = Value(clientDraftId),
       localPath = Value(localPath);
  static Insertable<DraftMediaRow> custom({
    Expression<String>? clientRefId,
    Expression<String>? clientDraftId,
    Expression<String>? localPath,
    Expression<String>? contentType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<String>? capturedAt,
    Expression<String>? state,
    Expression<String>? serverMediaId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientRefId != null) 'client_ref_id': clientRefId,
      if (clientDraftId != null) 'client_draft_id': clientDraftId,
      if (localPath != null) 'local_path': localPath,
      if (contentType != null) 'content_type': contentType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (state != null) 'state': state,
      if (serverMediaId != null) 'server_media_id': serverMediaId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftMediaRowsCompanion copyWith({
    Value<String>? clientRefId,
    Value<String>? clientDraftId,
    Value<String>? localPath,
    Value<String?>? contentType,
    Value<int?>? sizeBytes,
    Value<String?>? sha256,
    Value<String?>? capturedAt,
    Value<String>? state,
    Value<String?>? serverMediaId,
    Value<int>? rowid,
  }) {
    return DraftMediaRowsCompanion(
      clientRefId: clientRefId ?? this.clientRefId,
      clientDraftId: clientDraftId ?? this.clientDraftId,
      localPath: localPath ?? this.localPath,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      capturedAt: capturedAt ?? this.capturedAt,
      state: state ?? this.state,
      serverMediaId: serverMediaId ?? this.serverMediaId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientRefId.present) {
      map['client_ref_id'] = Variable<String>(clientRefId.value);
    }
    if (clientDraftId.present) {
      map['client_draft_id'] = Variable<String>(clientDraftId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<String>(capturedAt.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (serverMediaId.present) {
      map['server_media_id'] = Variable<String>(serverMediaId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftMediaRowsCompanion(')
          ..write('clientRefId: $clientRefId, ')
          ..write('clientDraftId: $clientDraftId, ')
          ..write('localPath: $localPath, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('state: $state, ')
          ..write('serverMediaId: $serverMediaId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocationRowsTable extends LocationRows
    with TableInfo<$LocationRowsTable, LocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMMeta = const VerificationMeta(
    'altitudeM',
  );
  @override
  late final GeneratedColumn<double> altitudeM = GeneratedColumn<double>(
    'altitude_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headingDegMeta = const VerificationMeta(
    'headingDeg',
  );
  @override
  late final GeneratedColumn<double> headingDeg = GeneratedColumn<double>(
    'heading_deg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lat,
    lon,
    accuracyM,
    altitudeM,
    speedMps,
    headingDeg,
    timestamp,
    source,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    }
    if (data.containsKey('altitude_m')) {
      context.handle(
        _altitudeMMeta,
        altitudeM.isAcceptableOrUnknown(data['altitude_m']!, _altitudeMMeta),
      );
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    }
    if (data.containsKey('heading_deg')) {
      context.handle(
        _headingDegMeta,
        headingDeg.isAcceptableOrUnknown(data['heading_deg']!, _headingDegMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      ),
      altitudeM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude_m'],
      ),
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      ),
      headingDeg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading_deg'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocationRowsTable createAlias(String alias) {
    return $LocationRowsTable(attachedDatabase, alias);
  }
}

class LocationRow extends DataClass implements Insertable<LocationRow> {
  /// Single-row table keyed by a fixed id. Phase 3 only persists one
  /// device's last fix; multi-device is out of scope.
  final String id;
  final double lat;
  final double lon;
  final double? accuracyM;
  final double? altitudeM;
  final double? speedMps;
  final double? headingDeg;
  final String timestamp;
  final String? source;
  final String updatedAt;
  const LocationRow({
    required this.id,
    required this.lat,
    required this.lon,
    this.accuracyM,
    this.altitudeM,
    this.speedMps,
    this.headingDeg,
    required this.timestamp,
    this.source,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || accuracyM != null) {
      map['accuracy_m'] = Variable<double>(accuracyM);
    }
    if (!nullToAbsent || altitudeM != null) {
      map['altitude_m'] = Variable<double>(altitudeM);
    }
    if (!nullToAbsent || speedMps != null) {
      map['speed_mps'] = Variable<double>(speedMps);
    }
    if (!nullToAbsent || headingDeg != null) {
      map['heading_deg'] = Variable<double>(headingDeg);
    }
    map['timestamp'] = Variable<String>(timestamp);
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocationRowsCompanion toCompanion(bool nullToAbsent) {
    return LocationRowsCompanion(
      id: Value(id),
      lat: Value(lat),
      lon: Value(lon),
      accuracyM: accuracyM == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyM),
      altitudeM: altitudeM == null && nullToAbsent
          ? const Value.absent()
          : Value(altitudeM),
      speedMps: speedMps == null && nullToAbsent
          ? const Value.absent()
          : Value(speedMps),
      headingDeg: headingDeg == null && nullToAbsent
          ? const Value.absent()
          : Value(headingDeg),
      timestamp: Value(timestamp),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationRow(
      id: serializer.fromJson<String>(json['id']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracyM: serializer.fromJson<double?>(json['accuracyM']),
      altitudeM: serializer.fromJson<double?>(json['altitudeM']),
      speedMps: serializer.fromJson<double?>(json['speedMps']),
      headingDeg: serializer.fromJson<double?>(json['headingDeg']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      source: serializer.fromJson<String?>(json['source']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracyM': serializer.toJson<double?>(accuracyM),
      'altitudeM': serializer.toJson<double?>(altitudeM),
      'speedMps': serializer.toJson<double?>(speedMps),
      'headingDeg': serializer.toJson<double?>(headingDeg),
      'timestamp': serializer.toJson<String>(timestamp),
      'source': serializer.toJson<String?>(source),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocationRow copyWith({
    String? id,
    double? lat,
    double? lon,
    Value<double?> accuracyM = const Value.absent(),
    Value<double?> altitudeM = const Value.absent(),
    Value<double?> speedMps = const Value.absent(),
    Value<double?> headingDeg = const Value.absent(),
    String? timestamp,
    Value<String?> source = const Value.absent(),
    String? updatedAt,
  }) => LocationRow(
    id: id ?? this.id,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracyM: accuracyM.present ? accuracyM.value : this.accuracyM,
    altitudeM: altitudeM.present ? altitudeM.value : this.altitudeM,
    speedMps: speedMps.present ? speedMps.value : this.speedMps,
    headingDeg: headingDeg.present ? headingDeg.value : this.headingDeg,
    timestamp: timestamp ?? this.timestamp,
    source: source.present ? source.value : this.source,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocationRow copyWithCompanion(LocationRowsCompanion data) {
    return LocationRow(
      id: data.id.present ? data.id.value : this.id,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      altitudeM: data.altitudeM.present ? data.altitudeM.value : this.altitudeM,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      headingDeg: data.headingDeg.present
          ? data.headingDeg.value
          : this.headingDeg,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      source: data.source.present ? data.source.value : this.source,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationRow(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('timestamp: $timestamp, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lat,
    lon,
    accuracyM,
    altitudeM,
    speedMps,
    headingDeg,
    timestamp,
    source,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationRow &&
          other.id == this.id &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracyM == this.accuracyM &&
          other.altitudeM == this.altitudeM &&
          other.speedMps == this.speedMps &&
          other.headingDeg == this.headingDeg &&
          other.timestamp == this.timestamp &&
          other.source == this.source &&
          other.updatedAt == this.updatedAt);
}

class LocationRowsCompanion extends UpdateCompanion<LocationRow> {
  final Value<String> id;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> accuracyM;
  final Value<double?> altitudeM;
  final Value<double?> speedMps;
  final Value<double?> headingDeg;
  final Value<String> timestamp;
  final Value<String?> source;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocationRowsCompanion({
    this.id = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.headingDeg = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.source = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationRowsCompanion.insert({
    this.id = const Value.absent(),
    required double lat,
    required double lon,
    this.accuracyM = const Value.absent(),
    this.altitudeM = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.headingDeg = const Value.absent(),
    required String timestamp,
    this.source = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : lat = Value(lat),
       lon = Value(lon),
       timestamp = Value(timestamp),
       updatedAt = Value(updatedAt);
  static Insertable<LocationRow> custom({
    Expression<String>? id,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracyM,
    Expression<double>? altitudeM,
    Expression<double>? speedMps,
    Expression<double>? headingDeg,
    Expression<String>? timestamp,
    Expression<String>? source,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (altitudeM != null) 'altitude_m': altitudeM,
      if (speedMps != null) 'speed_mps': speedMps,
      if (headingDeg != null) 'heading_deg': headingDeg,
      if (timestamp != null) 'timestamp': timestamp,
      if (source != null) 'source': source,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationRowsCompanion copyWith({
    Value<String>? id,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? accuracyM,
    Value<double?>? altitudeM,
    Value<double?>? speedMps,
    Value<double?>? headingDeg,
    Value<String>? timestamp,
    Value<String?>? source,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocationRowsCompanion(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracyM: accuracyM ?? this.accuracyM,
      altitudeM: altitudeM ?? this.altitudeM,
      speedMps: speedMps ?? this.speedMps,
      headingDeg: headingDeg ?? this.headingDeg,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (altitudeM.present) {
      map['altitude_m'] = Variable<double>(altitudeM.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (headingDeg.present) {
      map['heading_deg'] = Variable<double>(headingDeg.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationRowsCompanion(')
          ..write('id: $id, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('altitudeM: $altitudeM, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDeg: $headingDeg, ')
          ..write('timestamp: $timestamp, ')
          ..write('source: $source, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MapTileRowsTable extends MapTileRows
    with TableInfo<$MapTileRowsTable, MapTileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MapTileRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _zMeta = const VerificationMeta('z');
  @override
  late final GeneratedColumn<int> z = GeneratedColumn<int>(
    'z',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<int> x = GeneratedColumn<int>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<int> y = GeneratedColumn<int>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateHashMeta = const VerificationMeta(
    'templateHash',
  );
  @override
  late final GeneratedColumn<String> templateHash = GeneratedColumn<String>(
    'template_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<String> cachedAt = GeneratedColumn<String>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<String> lastAccessedAt = GeneratedColumn<String>(
    'last_accessed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    z,
    x,
    y,
    templateHash,
    bytes,
    contentType,
    sizeBytes,
    sha256,
    cachedAt,
    lastAccessedAt,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'map_tile_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<MapTileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('z')) {
      context.handle(_zMeta, z.isAcceptableOrUnknown(data['z']!, _zMeta));
    } else if (isInserting) {
      context.missing(_zMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('template_hash')) {
      context.handle(
        _templateHashMeta,
        templateHash.isAcceptableOrUnknown(
          data['template_hash']!,
          _templateHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateHashMeta);
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    } else if (isInserting) {
      context.missing(_bytesMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {z, x, y, templateHash};
  @override
  MapTileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MapTileRow(
      z: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}z'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y'],
      )!,
      templateHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_hash'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cached_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_accessed_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $MapTileRowsTable createAlias(String alias) {
    return $MapTileRowsTable(attachedDatabase, alias);
  }
}

class MapTileRow extends DataClass implements Insertable<MapTileRow> {
  final int z;
  final int x;
  final int y;

  /// sha256 of the URL template, so two providers never collide.
  final String templateHash;
  final Uint8List bytes;

  /// Captured MIME type ("image/png" / "image/jpeg") for header validation.
  final String contentType;
  final int sizeBytes;

  /// SHA-256 of [bytes] for corruption detection (Phase 4 §4.3).
  final String sha256;

  /// Wall-clock instant this tile was first written. Drives LRU eviction.
  final String cachedAt;

  /// Wall-clock instant this tile was last used. Updated on every read.
  final String lastAccessedAt;

  /// Schema version of the cache row (allows future migrations without
  /// dropping the table).
  final int version;
  const MapTileRow({
    required this.z,
    required this.x,
    required this.y,
    required this.templateHash,
    required this.bytes,
    required this.contentType,
    required this.sizeBytes,
    required this.sha256,
    required this.cachedAt,
    required this.lastAccessedAt,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['z'] = Variable<int>(z);
    map['x'] = Variable<int>(x);
    map['y'] = Variable<int>(y);
    map['template_hash'] = Variable<String>(templateHash);
    map['bytes'] = Variable<Uint8List>(bytes);
    map['content_type'] = Variable<String>(contentType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['sha256'] = Variable<String>(sha256);
    map['cached_at'] = Variable<String>(cachedAt);
    map['last_accessed_at'] = Variable<String>(lastAccessedAt);
    map['version'] = Variable<int>(version);
    return map;
  }

  MapTileRowsCompanion toCompanion(bool nullToAbsent) {
    return MapTileRowsCompanion(
      z: Value(z),
      x: Value(x),
      y: Value(y),
      templateHash: Value(templateHash),
      bytes: Value(bytes),
      contentType: Value(contentType),
      sizeBytes: Value(sizeBytes),
      sha256: Value(sha256),
      cachedAt: Value(cachedAt),
      lastAccessedAt: Value(lastAccessedAt),
      version: Value(version),
    );
  }

  factory MapTileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MapTileRow(
      z: serializer.fromJson<int>(json['z']),
      x: serializer.fromJson<int>(json['x']),
      y: serializer.fromJson<int>(json['y']),
      templateHash: serializer.fromJson<String>(json['templateHash']),
      bytes: serializer.fromJson<Uint8List>(json['bytes']),
      contentType: serializer.fromJson<String>(json['contentType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      sha256: serializer.fromJson<String>(json['sha256']),
      cachedAt: serializer.fromJson<String>(json['cachedAt']),
      lastAccessedAt: serializer.fromJson<String>(json['lastAccessedAt']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'z': serializer.toJson<int>(z),
      'x': serializer.toJson<int>(x),
      'y': serializer.toJson<int>(y),
      'templateHash': serializer.toJson<String>(templateHash),
      'bytes': serializer.toJson<Uint8List>(bytes),
      'contentType': serializer.toJson<String>(contentType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'sha256': serializer.toJson<String>(sha256),
      'cachedAt': serializer.toJson<String>(cachedAt),
      'lastAccessedAt': serializer.toJson<String>(lastAccessedAt),
      'version': serializer.toJson<int>(version),
    };
  }

  MapTileRow copyWith({
    int? z,
    int? x,
    int? y,
    String? templateHash,
    Uint8List? bytes,
    String? contentType,
    int? sizeBytes,
    String? sha256,
    String? cachedAt,
    String? lastAccessedAt,
    int? version,
  }) => MapTileRow(
    z: z ?? this.z,
    x: x ?? this.x,
    y: y ?? this.y,
    templateHash: templateHash ?? this.templateHash,
    bytes: bytes ?? this.bytes,
    contentType: contentType ?? this.contentType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    sha256: sha256 ?? this.sha256,
    cachedAt: cachedAt ?? this.cachedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    version: version ?? this.version,
  );
  MapTileRow copyWithCompanion(MapTileRowsCompanion data) {
    return MapTileRow(
      z: data.z.present ? data.z.value : this.z,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      templateHash: data.templateHash.present
          ? data.templateHash.value
          : this.templateHash,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MapTileRow(')
          ..write('z: $z, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('templateHash: $templateHash, ')
          ..write('bytes: $bytes, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    z,
    x,
    y,
    templateHash,
    $driftBlobEquality.hash(bytes),
    contentType,
    sizeBytes,
    sha256,
    cachedAt,
    lastAccessedAt,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapTileRow &&
          other.z == this.z &&
          other.x == this.x &&
          other.y == this.y &&
          other.templateHash == this.templateHash &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.contentType == this.contentType &&
          other.sizeBytes == this.sizeBytes &&
          other.sha256 == this.sha256 &&
          other.cachedAt == this.cachedAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.version == this.version);
}

class MapTileRowsCompanion extends UpdateCompanion<MapTileRow> {
  final Value<int> z;
  final Value<int> x;
  final Value<int> y;
  final Value<String> templateHash;
  final Value<Uint8List> bytes;
  final Value<String> contentType;
  final Value<int> sizeBytes;
  final Value<String> sha256;
  final Value<String> cachedAt;
  final Value<String> lastAccessedAt;
  final Value<int> version;
  final Value<int> rowid;
  const MapTileRowsCompanion({
    this.z = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.templateHash = const Value.absent(),
    this.bytes = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MapTileRowsCompanion.insert({
    required int z,
    required int x,
    required int y,
    required String templateHash,
    required Uint8List bytes,
    required String contentType,
    required int sizeBytes,
    required String sha256,
    required String cachedAt,
    required String lastAccessedAt,
    this.version = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : z = Value(z),
       x = Value(x),
       y = Value(y),
       templateHash = Value(templateHash),
       bytes = Value(bytes),
       contentType = Value(contentType),
       sizeBytes = Value(sizeBytes),
       sha256 = Value(sha256),
       cachedAt = Value(cachedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<MapTileRow> custom({
    Expression<int>? z,
    Expression<int>? x,
    Expression<int>? y,
    Expression<String>? templateHash,
    Expression<Uint8List>? bytes,
    Expression<String>? contentType,
    Expression<int>? sizeBytes,
    Expression<String>? sha256,
    Expression<String>? cachedAt,
    Expression<String>? lastAccessedAt,
    Expression<int>? version,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (z != null) 'z': z,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (templateHash != null) 'template_hash': templateHash,
      if (bytes != null) 'bytes': bytes,
      if (contentType != null) 'content_type': contentType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (sha256 != null) 'sha256': sha256,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (version != null) 'version': version,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MapTileRowsCompanion copyWith({
    Value<int>? z,
    Value<int>? x,
    Value<int>? y,
    Value<String>? templateHash,
    Value<Uint8List>? bytes,
    Value<String>? contentType,
    Value<int>? sizeBytes,
    Value<String>? sha256,
    Value<String>? cachedAt,
    Value<String>? lastAccessedAt,
    Value<int>? version,
    Value<int>? rowid,
  }) {
    return MapTileRowsCompanion(
      z: z ?? this.z,
      x: x ?? this.x,
      y: y ?? this.y,
      templateHash: templateHash ?? this.templateHash,
      bytes: bytes ?? this.bytes,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      cachedAt: cachedAt ?? this.cachedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      version: version ?? this.version,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (z.present) {
      map['z'] = Variable<int>(z.value);
    }
    if (x.present) {
      map['x'] = Variable<int>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<int>(y.value);
    }
    if (templateHash.present) {
      map['template_hash'] = Variable<String>(templateHash.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<String>(cachedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<String>(lastAccessedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MapTileRowsCompanion(')
          ..write('z: $z, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('templateHash: $templateHash, ')
          ..write('bytes: $bytes, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('sha256: $sha256, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('version: $version, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineGraphSegmentRowsTable extends OfflineGraphSegmentRows
    with TableInfo<$OfflineGraphSegmentRowsTable, OfflineGraphSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineGraphSegmentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roadCodeMeta = const VerificationMeta(
    'roadCode',
  );
  @override
  late final GeneratedColumn<String> roadCode = GeneratedColumn<String>(
    'road_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _x1Meta = const VerificationMeta('x1');
  @override
  late final GeneratedColumn<double> x1 = GeneratedColumn<double>(
    'x1',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y1Meta = const VerificationMeta('y1');
  @override
  late final GeneratedColumn<double> y1 = GeneratedColumn<double>(
    'y1',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _x2Meta = const VerificationMeta('x2');
  @override
  late final GeneratedColumn<double> x2 = GeneratedColumn<double>(
    'x2',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _y2Meta = const VerificationMeta('y2');
  @override
  late final GeneratedColumn<double> y2 = GeneratedColumn<double>(
    'y2',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lengthKmMeta = const VerificationMeta(
    'lengthKm',
  );
  @override
  late final GeneratedColumn<double> lengthKm = GeneratedColumn<double>(
    'length_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessibilityMeta = const VerificationMeta(
    'accessibility',
  );
  @override
  late final GeneratedColumn<double> accessibility = GeneratedColumn<double>(
    'accessibility',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _riskPctMeta = const VerificationMeta(
    'riskPct',
  );
  @override
  late final GeneratedColumn<double> riskPct = GeneratedColumn<double>(
    'risk_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    segmentId,
    roadCode,
    seq,
    x1,
    y1,
    x2,
    y2,
    lengthKm,
    accessibility,
    riskPct,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_graph_segment_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineGraphSegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('road_code')) {
      context.handle(
        _roadCodeMeta,
        roadCode.isAcceptableOrUnknown(data['road_code']!, _roadCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roadCodeMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('x1')) {
      context.handle(_x1Meta, x1.isAcceptableOrUnknown(data['x1']!, _x1Meta));
    } else if (isInserting) {
      context.missing(_x1Meta);
    }
    if (data.containsKey('y1')) {
      context.handle(_y1Meta, y1.isAcceptableOrUnknown(data['y1']!, _y1Meta));
    } else if (isInserting) {
      context.missing(_y1Meta);
    }
    if (data.containsKey('x2')) {
      context.handle(_x2Meta, x2.isAcceptableOrUnknown(data['x2']!, _x2Meta));
    } else if (isInserting) {
      context.missing(_x2Meta);
    }
    if (data.containsKey('y2')) {
      context.handle(_y2Meta, y2.isAcceptableOrUnknown(data['y2']!, _y2Meta));
    } else if (isInserting) {
      context.missing(_y2Meta);
    }
    if (data.containsKey('length_km')) {
      context.handle(
        _lengthKmMeta,
        lengthKm.isAcceptableOrUnknown(data['length_km']!, _lengthKmMeta),
      );
    } else if (isInserting) {
      context.missing(_lengthKmMeta);
    }
    if (data.containsKey('accessibility')) {
      context.handle(
        _accessibilityMeta,
        accessibility.isAcceptableOrUnknown(
          data['accessibility']!,
          _accessibilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessibilityMeta);
    }
    if (data.containsKey('risk_pct')) {
      context.handle(
        _riskPctMeta,
        riskPct.isAcceptableOrUnknown(data['risk_pct']!, _riskPctMeta),
      );
    } else if (isInserting) {
      context.missing(_riskPctMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {segmentId};
  @override
  OfflineGraphSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineGraphSegmentRow(
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      roadCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_code'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      x1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x1'],
      )!,
      y1: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y1'],
      )!,
      x2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x2'],
      )!,
      y2: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y2'],
      )!,
      lengthKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}length_km'],
      )!,
      accessibility: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accessibility'],
      )!,
      riskPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_pct'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OfflineGraphSegmentRowsTable createAlias(String alias) {
    return $OfflineGraphSegmentRowsTable(attachedDatabase, alias);
  }
}

class OfflineGraphSegmentRow extends DataClass
    implements Insertable<OfflineGraphSegmentRow> {
  final String segmentId;
  final String roadCode;
  final int seq;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double lengthKm;

  /// Accessibility goodness 0-100 (latest score or server-derived fallback).
  final double accessibility;

  /// Disruption risk 0-100 (latest prediction or server-derived fallback).
  final double riskPct;

  /// OPEN | CLOSED — CLOSED rows are informational only (never routable).
  final String status;
  const OfflineGraphSegmentRow({
    required this.segmentId,
    required this.roadCode,
    required this.seq,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.lengthKm,
    required this.accessibility,
    required this.riskPct,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['segment_id'] = Variable<String>(segmentId);
    map['road_code'] = Variable<String>(roadCode);
    map['seq'] = Variable<int>(seq);
    map['x1'] = Variable<double>(x1);
    map['y1'] = Variable<double>(y1);
    map['x2'] = Variable<double>(x2);
    map['y2'] = Variable<double>(y2);
    map['length_km'] = Variable<double>(lengthKm);
    map['accessibility'] = Variable<double>(accessibility);
    map['risk_pct'] = Variable<double>(riskPct);
    map['status'] = Variable<String>(status);
    return map;
  }

  OfflineGraphSegmentRowsCompanion toCompanion(bool nullToAbsent) {
    return OfflineGraphSegmentRowsCompanion(
      segmentId: Value(segmentId),
      roadCode: Value(roadCode),
      seq: Value(seq),
      x1: Value(x1),
      y1: Value(y1),
      x2: Value(x2),
      y2: Value(y2),
      lengthKm: Value(lengthKm),
      accessibility: Value(accessibility),
      riskPct: Value(riskPct),
      status: Value(status),
    );
  }

  factory OfflineGraphSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineGraphSegmentRow(
      segmentId: serializer.fromJson<String>(json['segmentId']),
      roadCode: serializer.fromJson<String>(json['roadCode']),
      seq: serializer.fromJson<int>(json['seq']),
      x1: serializer.fromJson<double>(json['x1']),
      y1: serializer.fromJson<double>(json['y1']),
      x2: serializer.fromJson<double>(json['x2']),
      y2: serializer.fromJson<double>(json['y2']),
      lengthKm: serializer.fromJson<double>(json['lengthKm']),
      accessibility: serializer.fromJson<double>(json['accessibility']),
      riskPct: serializer.fromJson<double>(json['riskPct']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'segmentId': serializer.toJson<String>(segmentId),
      'roadCode': serializer.toJson<String>(roadCode),
      'seq': serializer.toJson<int>(seq),
      'x1': serializer.toJson<double>(x1),
      'y1': serializer.toJson<double>(y1),
      'x2': serializer.toJson<double>(x2),
      'y2': serializer.toJson<double>(y2),
      'lengthKm': serializer.toJson<double>(lengthKm),
      'accessibility': serializer.toJson<double>(accessibility),
      'riskPct': serializer.toJson<double>(riskPct),
      'status': serializer.toJson<String>(status),
    };
  }

  OfflineGraphSegmentRow copyWith({
    String? segmentId,
    String? roadCode,
    int? seq,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? lengthKm,
    double? accessibility,
    double? riskPct,
    String? status,
  }) => OfflineGraphSegmentRow(
    segmentId: segmentId ?? this.segmentId,
    roadCode: roadCode ?? this.roadCode,
    seq: seq ?? this.seq,
    x1: x1 ?? this.x1,
    y1: y1 ?? this.y1,
    x2: x2 ?? this.x2,
    y2: y2 ?? this.y2,
    lengthKm: lengthKm ?? this.lengthKm,
    accessibility: accessibility ?? this.accessibility,
    riskPct: riskPct ?? this.riskPct,
    status: status ?? this.status,
  );
  OfflineGraphSegmentRow copyWithCompanion(
    OfflineGraphSegmentRowsCompanion data,
  ) {
    return OfflineGraphSegmentRow(
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      roadCode: data.roadCode.present ? data.roadCode.value : this.roadCode,
      seq: data.seq.present ? data.seq.value : this.seq,
      x1: data.x1.present ? data.x1.value : this.x1,
      y1: data.y1.present ? data.y1.value : this.y1,
      x2: data.x2.present ? data.x2.value : this.x2,
      y2: data.y2.present ? data.y2.value : this.y2,
      lengthKm: data.lengthKm.present ? data.lengthKm.value : this.lengthKm,
      accessibility: data.accessibility.present
          ? data.accessibility.value
          : this.accessibility,
      riskPct: data.riskPct.present ? data.riskPct.value : this.riskPct,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineGraphSegmentRow(')
          ..write('segmentId: $segmentId, ')
          ..write('roadCode: $roadCode, ')
          ..write('seq: $seq, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('x2: $x2, ')
          ..write('y2: $y2, ')
          ..write('lengthKm: $lengthKm, ')
          ..write('accessibility: $accessibility, ')
          ..write('riskPct: $riskPct, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    segmentId,
    roadCode,
    seq,
    x1,
    y1,
    x2,
    y2,
    lengthKm,
    accessibility,
    riskPct,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineGraphSegmentRow &&
          other.segmentId == this.segmentId &&
          other.roadCode == this.roadCode &&
          other.seq == this.seq &&
          other.x1 == this.x1 &&
          other.y1 == this.y1 &&
          other.x2 == this.x2 &&
          other.y2 == this.y2 &&
          other.lengthKm == this.lengthKm &&
          other.accessibility == this.accessibility &&
          other.riskPct == this.riskPct &&
          other.status == this.status);
}

class OfflineGraphSegmentRowsCompanion
    extends UpdateCompanion<OfflineGraphSegmentRow> {
  final Value<String> segmentId;
  final Value<String> roadCode;
  final Value<int> seq;
  final Value<double> x1;
  final Value<double> y1;
  final Value<double> x2;
  final Value<double> y2;
  final Value<double> lengthKm;
  final Value<double> accessibility;
  final Value<double> riskPct;
  final Value<String> status;
  final Value<int> rowid;
  const OfflineGraphSegmentRowsCompanion({
    this.segmentId = const Value.absent(),
    this.roadCode = const Value.absent(),
    this.seq = const Value.absent(),
    this.x1 = const Value.absent(),
    this.y1 = const Value.absent(),
    this.x2 = const Value.absent(),
    this.y2 = const Value.absent(),
    this.lengthKm = const Value.absent(),
    this.accessibility = const Value.absent(),
    this.riskPct = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineGraphSegmentRowsCompanion.insert({
    required String segmentId,
    required String roadCode,
    this.seq = const Value.absent(),
    required double x1,
    required double y1,
    required double x2,
    required double y2,
    required double lengthKm,
    required double accessibility,
    required double riskPct,
    required String status,
    this.rowid = const Value.absent(),
  }) : segmentId = Value(segmentId),
       roadCode = Value(roadCode),
       x1 = Value(x1),
       y1 = Value(y1),
       x2 = Value(x2),
       y2 = Value(y2),
       lengthKm = Value(lengthKm),
       accessibility = Value(accessibility),
       riskPct = Value(riskPct),
       status = Value(status);
  static Insertable<OfflineGraphSegmentRow> custom({
    Expression<String>? segmentId,
    Expression<String>? roadCode,
    Expression<int>? seq,
    Expression<double>? x1,
    Expression<double>? y1,
    Expression<double>? x2,
    Expression<double>? y2,
    Expression<double>? lengthKm,
    Expression<double>? accessibility,
    Expression<double>? riskPct,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (segmentId != null) 'segment_id': segmentId,
      if (roadCode != null) 'road_code': roadCode,
      if (seq != null) 'seq': seq,
      if (x1 != null) 'x1': x1,
      if (y1 != null) 'y1': y1,
      if (x2 != null) 'x2': x2,
      if (y2 != null) 'y2': y2,
      if (lengthKm != null) 'length_km': lengthKm,
      if (accessibility != null) 'accessibility': accessibility,
      if (riskPct != null) 'risk_pct': riskPct,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineGraphSegmentRowsCompanion copyWith({
    Value<String>? segmentId,
    Value<String>? roadCode,
    Value<int>? seq,
    Value<double>? x1,
    Value<double>? y1,
    Value<double>? x2,
    Value<double>? y2,
    Value<double>? lengthKm,
    Value<double>? accessibility,
    Value<double>? riskPct,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return OfflineGraphSegmentRowsCompanion(
      segmentId: segmentId ?? this.segmentId,
      roadCode: roadCode ?? this.roadCode,
      seq: seq ?? this.seq,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      lengthKm: lengthKm ?? this.lengthKm,
      accessibility: accessibility ?? this.accessibility,
      riskPct: riskPct ?? this.riskPct,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (roadCode.present) {
      map['road_code'] = Variable<String>(roadCode.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (x1.present) {
      map['x1'] = Variable<double>(x1.value);
    }
    if (y1.present) {
      map['y1'] = Variable<double>(y1.value);
    }
    if (x2.present) {
      map['x2'] = Variable<double>(x2.value);
    }
    if (y2.present) {
      map['y2'] = Variable<double>(y2.value);
    }
    if (lengthKm.present) {
      map['length_km'] = Variable<double>(lengthKm.value);
    }
    if (accessibility.present) {
      map['accessibility'] = Variable<double>(accessibility.value);
    }
    if (riskPct.present) {
      map['risk_pct'] = Variable<double>(riskPct.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineGraphSegmentRowsCompanion(')
          ..write('segmentId: $segmentId, ')
          ..write('roadCode: $roadCode, ')
          ..write('seq: $seq, ')
          ..write('x1: $x1, ')
          ..write('y1: $y1, ')
          ..write('x2: $x2, ')
          ..write('y2: $y2, ')
          ..write('lengthKm: $lengthKm, ')
          ..write('accessibility: $accessibility, ')
          ..write('riskPct: $riskPct, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineGraphMetaRowsTable extends OfflineGraphMetaRows
    with TableInfo<$OfflineGraphMetaRowsTable, OfflineGraphMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineGraphMetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentCountMeta = const VerificationMeta(
    'segmentCount',
  );
  @override
  late final GeneratedColumn<int> segmentCount = GeneratedColumn<int>(
    'segment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, segmentCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_graph_meta_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineGraphMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('segment_count')) {
      context.handle(
        _segmentCountMeta,
        segmentCount.isAcceptableOrUnknown(
          data['segment_count']!,
          _segmentCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineGraphMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineGraphMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fetched_at'],
      )!,
      segmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_count'],
      )!,
    );
  }

  @override
  $OfflineGraphMetaRowsTable createAlias(String alias) {
    return $OfflineGraphMetaRowsTable(attachedDatabase, alias);
  }
}

class OfflineGraphMetaRow extends DataClass
    implements Insertable<OfflineGraphMetaRow> {
  final String id;
  final String fetchedAt;
  final int segmentCount;
  const OfflineGraphMetaRow({
    required this.id,
    required this.fetchedAt,
    required this.segmentCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fetched_at'] = Variable<String>(fetchedAt);
    map['segment_count'] = Variable<int>(segmentCount);
    return map;
  }

  OfflineGraphMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return OfflineGraphMetaRowsCompanion(
      id: Value(id),
      fetchedAt: Value(fetchedAt),
      segmentCount: Value(segmentCount),
    );
  }

  factory OfflineGraphMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineGraphMetaRow(
      id: serializer.fromJson<String>(json['id']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
      segmentCount: serializer.fromJson<int>(json['segmentCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
      'segmentCount': serializer.toJson<int>(segmentCount),
    };
  }

  OfflineGraphMetaRow copyWith({
    String? id,
    String? fetchedAt,
    int? segmentCount,
  }) => OfflineGraphMetaRow(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    segmentCount: segmentCount ?? this.segmentCount,
  );
  OfflineGraphMetaRow copyWithCompanion(OfflineGraphMetaRowsCompanion data) {
    return OfflineGraphMetaRow(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      segmentCount: data.segmentCount.present
          ? data.segmentCount.value
          : this.segmentCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineGraphMetaRow(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('segmentCount: $segmentCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, segmentCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineGraphMetaRow &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.segmentCount == this.segmentCount);
}

class OfflineGraphMetaRowsCompanion
    extends UpdateCompanion<OfflineGraphMetaRow> {
  final Value<String> id;
  final Value<String> fetchedAt;
  final Value<int> segmentCount;
  final Value<int> rowid;
  const OfflineGraphMetaRowsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.segmentCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineGraphMetaRowsCompanion.insert({
    this.id = const Value.absent(),
    required String fetchedAt,
    this.segmentCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fetchedAt = Value(fetchedAt);
  static Insertable<OfflineGraphMetaRow> custom({
    Expression<String>? id,
    Expression<String>? fetchedAt,
    Expression<int>? segmentCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (segmentCount != null) 'segment_count': segmentCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineGraphMetaRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? fetchedAt,
    Value<int>? segmentCount,
    Value<int>? rowid,
  }) {
    return OfflineGraphMetaRowsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      segmentCount: segmentCount ?? this.segmentCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (segmentCount.present) {
      map['segment_count'] = Variable<int>(segmentCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineGraphMetaRowsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('segmentCount: $segmentCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RiskSnapshotRowsTable extends RiskSnapshotRows
    with TableInfo<$RiskSnapshotRowsTable, RiskSnapshotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RiskSnapshotRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _segmentIdMeta = const VerificationMeta(
    'segmentId',
  );
  @override
  late final GeneratedColumn<String> segmentId = GeneratedColumn<String>(
    'segment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtCodeMeta = const VerificationMeta(
    'districtCode',
  );
  @override
  late final GeneratedColumn<String> districtCode = GeneratedColumn<String>(
    'district_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roadCodeMeta = const VerificationMeta(
    'roadCode',
  );
  @override
  late final GeneratedColumn<String> roadCode = GeneratedColumn<String>(
    'road_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _riskCurrentMeta = const VerificationMeta(
    'riskCurrent',
  );
  @override
  late final GeneratedColumn<double> riskCurrent = GeneratedColumn<double>(
    'risk_current',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _risk6hMeta = const VerificationMeta('risk6h');
  @override
  late final GeneratedColumn<double> risk6h = GeneratedColumn<double>(
    'risk6h',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _risk12hMeta = const VerificationMeta(
    'risk12h',
  );
  @override
  late final GeneratedColumn<double> risk12h = GeneratedColumn<double>(
    'risk12h',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _risk24hMeta = const VerificationMeta(
    'risk24h',
  );
  @override
  late final GeneratedColumn<double> risk24h = GeneratedColumn<double>(
    'risk24h',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _risk72hMeta = const VerificationMeta(
    'risk72h',
  );
  @override
  late final GeneratedColumn<double> risk72h = GeneratedColumn<double>(
    'risk72h',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overallLabelMeta = const VerificationMeta(
    'overallLabel',
  );
  @override
  late final GeneratedColumn<String> overallLabel = GeneratedColumn<String>(
    'overall_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topFactorsJsonMeta = const VerificationMeta(
    'topFactorsJson',
  );
  @override
  late final GeneratedColumn<String> topFactorsJson = GeneratedColumn<String>(
    'top_factors_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summarySentenceMeta = const VerificationMeta(
    'summarySentence',
  );
  @override
  late final GeneratedColumn<String> summarySentence = GeneratedColumn<String>(
    'summary_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseValueMeta = const VerificationMeta(
    'baseValue',
  );
  @override
  late final GeneratedColumn<double> baseValue = GeneratedColumn<double>(
    'base_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelNameMeta = const VerificationMeta(
    'modelName',
  );
  @override
  late final GeneratedColumn<String> modelName = GeneratedColumn<String>(
    'model_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelVersionMeta = const VerificationMeta(
    'modelVersion',
  );
  @override
  late final GeneratedColumn<String> modelVersion = GeneratedColumn<String>(
    'model_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<String> computedAt = GeneratedColumn<String>(
    'computed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    segmentId,
    districtCode,
    roadCode,
    riskCurrent,
    risk6h,
    risk12h,
    risk24h,
    risk72h,
    overallLabel,
    severity,
    topFactorsJson,
    summarySentence,
    baseValue,
    mode,
    modelName,
    modelVersion,
    computedAt,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'risk_snapshot_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RiskSnapshotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('segment_id')) {
      context.handle(
        _segmentIdMeta,
        segmentId.isAcceptableOrUnknown(data['segment_id']!, _segmentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentIdMeta);
    }
    if (data.containsKey('district_code')) {
      context.handle(
        _districtCodeMeta,
        districtCode.isAcceptableOrUnknown(
          data['district_code']!,
          _districtCodeMeta,
        ),
      );
    }
    if (data.containsKey('road_code')) {
      context.handle(
        _roadCodeMeta,
        roadCode.isAcceptableOrUnknown(data['road_code']!, _roadCodeMeta),
      );
    }
    if (data.containsKey('risk_current')) {
      context.handle(
        _riskCurrentMeta,
        riskCurrent.isAcceptableOrUnknown(
          data['risk_current']!,
          _riskCurrentMeta,
        ),
      );
    }
    if (data.containsKey('risk6h')) {
      context.handle(
        _risk6hMeta,
        risk6h.isAcceptableOrUnknown(data['risk6h']!, _risk6hMeta),
      );
    }
    if (data.containsKey('risk12h')) {
      context.handle(
        _risk12hMeta,
        risk12h.isAcceptableOrUnknown(data['risk12h']!, _risk12hMeta),
      );
    }
    if (data.containsKey('risk24h')) {
      context.handle(
        _risk24hMeta,
        risk24h.isAcceptableOrUnknown(data['risk24h']!, _risk24hMeta),
      );
    }
    if (data.containsKey('risk72h')) {
      context.handle(
        _risk72hMeta,
        risk72h.isAcceptableOrUnknown(data['risk72h']!, _risk72hMeta),
      );
    }
    if (data.containsKey('overall_label')) {
      context.handle(
        _overallLabelMeta,
        overallLabel.isAcceptableOrUnknown(
          data['overall_label']!,
          _overallLabelMeta,
        ),
      );
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    if (data.containsKey('top_factors_json')) {
      context.handle(
        _topFactorsJsonMeta,
        topFactorsJson.isAcceptableOrUnknown(
          data['top_factors_json']!,
          _topFactorsJsonMeta,
        ),
      );
    }
    if (data.containsKey('summary_sentence')) {
      context.handle(
        _summarySentenceMeta,
        summarySentence.isAcceptableOrUnknown(
          data['summary_sentence']!,
          _summarySentenceMeta,
        ),
      );
    }
    if (data.containsKey('base_value')) {
      context.handle(
        _baseValueMeta,
        baseValue.isAcceptableOrUnknown(data['base_value']!, _baseValueMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('model_name')) {
      context.handle(
        _modelNameMeta,
        modelName.isAcceptableOrUnknown(data['model_name']!, _modelNameMeta),
      );
    }
    if (data.containsKey('model_version')) {
      context.handle(
        _modelVersionMeta,
        modelVersion.isAcceptableOrUnknown(
          data['model_version']!,
          _modelVersionMeta,
        ),
      );
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {segmentId};
  @override
  RiskSnapshotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RiskSnapshotRow(
      segmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_id'],
      )!,
      districtCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_code'],
      ),
      roadCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}road_code'],
      ),
      riskCurrent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk_current'],
      ),
      risk6h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk6h'],
      ),
      risk12h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk12h'],
      ),
      risk24h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk24h'],
      ),
      risk72h: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}risk72h'],
      ),
      overallLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overall_label'],
      ),
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      ),
      topFactorsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}top_factors_json'],
      ),
      summarySentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary_sentence'],
      ),
      baseValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}base_value'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      ),
      modelName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_name'],
      ),
      modelVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_version'],
      ),
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computed_at'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $RiskSnapshotRowsTable createAlias(String alias) {
    return $RiskSnapshotRowsTable(attachedDatabase, alias);
  }
}

class RiskSnapshotRow extends DataClass implements Insertable<RiskSnapshotRow> {
  final String segmentId;
  final String? districtCode;
  final String? roadCode;
  final double? riskCurrent;
  final double? risk6h;
  final double? risk12h;
  final double? risk24h;
  final double? risk72h;
  final String? overallLabel;
  final String? severity;
  final String? topFactorsJson;
  final String? summarySentence;
  final double? baseValue;
  final String? mode;
  final String? modelName;
  final String? modelVersion;

  /// Server-side model run instant (ISO-8601) — the feature snapshot age.
  final String? computedAt;

  /// Local fetch instant (ISO-8601) — when it was last synchronised.
  final String fetchedAt;
  const RiskSnapshotRow({
    required this.segmentId,
    this.districtCode,
    this.roadCode,
    this.riskCurrent,
    this.risk6h,
    this.risk12h,
    this.risk24h,
    this.risk72h,
    this.overallLabel,
    this.severity,
    this.topFactorsJson,
    this.summarySentence,
    this.baseValue,
    this.mode,
    this.modelName,
    this.modelVersion,
    this.computedAt,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['segment_id'] = Variable<String>(segmentId);
    if (!nullToAbsent || districtCode != null) {
      map['district_code'] = Variable<String>(districtCode);
    }
    if (!nullToAbsent || roadCode != null) {
      map['road_code'] = Variable<String>(roadCode);
    }
    if (!nullToAbsent || riskCurrent != null) {
      map['risk_current'] = Variable<double>(riskCurrent);
    }
    if (!nullToAbsent || risk6h != null) {
      map['risk6h'] = Variable<double>(risk6h);
    }
    if (!nullToAbsent || risk12h != null) {
      map['risk12h'] = Variable<double>(risk12h);
    }
    if (!nullToAbsent || risk24h != null) {
      map['risk24h'] = Variable<double>(risk24h);
    }
    if (!nullToAbsent || risk72h != null) {
      map['risk72h'] = Variable<double>(risk72h);
    }
    if (!nullToAbsent || overallLabel != null) {
      map['overall_label'] = Variable<String>(overallLabel);
    }
    if (!nullToAbsent || severity != null) {
      map['severity'] = Variable<String>(severity);
    }
    if (!nullToAbsent || topFactorsJson != null) {
      map['top_factors_json'] = Variable<String>(topFactorsJson);
    }
    if (!nullToAbsent || summarySentence != null) {
      map['summary_sentence'] = Variable<String>(summarySentence);
    }
    if (!nullToAbsent || baseValue != null) {
      map['base_value'] = Variable<double>(baseValue);
    }
    if (!nullToAbsent || mode != null) {
      map['mode'] = Variable<String>(mode);
    }
    if (!nullToAbsent || modelName != null) {
      map['model_name'] = Variable<String>(modelName);
    }
    if (!nullToAbsent || modelVersion != null) {
      map['model_version'] = Variable<String>(modelVersion);
    }
    if (!nullToAbsent || computedAt != null) {
      map['computed_at'] = Variable<String>(computedAt);
    }
    map['fetched_at'] = Variable<String>(fetchedAt);
    return map;
  }

  RiskSnapshotRowsCompanion toCompanion(bool nullToAbsent) {
    return RiskSnapshotRowsCompanion(
      segmentId: Value(segmentId),
      districtCode: districtCode == null && nullToAbsent
          ? const Value.absent()
          : Value(districtCode),
      roadCode: roadCode == null && nullToAbsent
          ? const Value.absent()
          : Value(roadCode),
      riskCurrent: riskCurrent == null && nullToAbsent
          ? const Value.absent()
          : Value(riskCurrent),
      risk6h: risk6h == null && nullToAbsent
          ? const Value.absent()
          : Value(risk6h),
      risk12h: risk12h == null && nullToAbsent
          ? const Value.absent()
          : Value(risk12h),
      risk24h: risk24h == null && nullToAbsent
          ? const Value.absent()
          : Value(risk24h),
      risk72h: risk72h == null && nullToAbsent
          ? const Value.absent()
          : Value(risk72h),
      overallLabel: overallLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(overallLabel),
      severity: severity == null && nullToAbsent
          ? const Value.absent()
          : Value(severity),
      topFactorsJson: topFactorsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(topFactorsJson),
      summarySentence: summarySentence == null && nullToAbsent
          ? const Value.absent()
          : Value(summarySentence),
      baseValue: baseValue == null && nullToAbsent
          ? const Value.absent()
          : Value(baseValue),
      mode: mode == null && nullToAbsent ? const Value.absent() : Value(mode),
      modelName: modelName == null && nullToAbsent
          ? const Value.absent()
          : Value(modelName),
      modelVersion: modelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(modelVersion),
      computedAt: computedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(computedAt),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RiskSnapshotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RiskSnapshotRow(
      segmentId: serializer.fromJson<String>(json['segmentId']),
      districtCode: serializer.fromJson<String?>(json['districtCode']),
      roadCode: serializer.fromJson<String?>(json['roadCode']),
      riskCurrent: serializer.fromJson<double?>(json['riskCurrent']),
      risk6h: serializer.fromJson<double?>(json['risk6h']),
      risk12h: serializer.fromJson<double?>(json['risk12h']),
      risk24h: serializer.fromJson<double?>(json['risk24h']),
      risk72h: serializer.fromJson<double?>(json['risk72h']),
      overallLabel: serializer.fromJson<String?>(json['overallLabel']),
      severity: serializer.fromJson<String?>(json['severity']),
      topFactorsJson: serializer.fromJson<String?>(json['topFactorsJson']),
      summarySentence: serializer.fromJson<String?>(json['summarySentence']),
      baseValue: serializer.fromJson<double?>(json['baseValue']),
      mode: serializer.fromJson<String?>(json['mode']),
      modelName: serializer.fromJson<String?>(json['modelName']),
      modelVersion: serializer.fromJson<String?>(json['modelVersion']),
      computedAt: serializer.fromJson<String?>(json['computedAt']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'segmentId': serializer.toJson<String>(segmentId),
      'districtCode': serializer.toJson<String?>(districtCode),
      'roadCode': serializer.toJson<String?>(roadCode),
      'riskCurrent': serializer.toJson<double?>(riskCurrent),
      'risk6h': serializer.toJson<double?>(risk6h),
      'risk12h': serializer.toJson<double?>(risk12h),
      'risk24h': serializer.toJson<double?>(risk24h),
      'risk72h': serializer.toJson<double?>(risk72h),
      'overallLabel': serializer.toJson<String?>(overallLabel),
      'severity': serializer.toJson<String?>(severity),
      'topFactorsJson': serializer.toJson<String?>(topFactorsJson),
      'summarySentence': serializer.toJson<String?>(summarySentence),
      'baseValue': serializer.toJson<double?>(baseValue),
      'mode': serializer.toJson<String?>(mode),
      'modelName': serializer.toJson<String?>(modelName),
      'modelVersion': serializer.toJson<String?>(modelVersion),
      'computedAt': serializer.toJson<String?>(computedAt),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
    };
  }

  RiskSnapshotRow copyWith({
    String? segmentId,
    Value<String?> districtCode = const Value.absent(),
    Value<String?> roadCode = const Value.absent(),
    Value<double?> riskCurrent = const Value.absent(),
    Value<double?> risk6h = const Value.absent(),
    Value<double?> risk12h = const Value.absent(),
    Value<double?> risk24h = const Value.absent(),
    Value<double?> risk72h = const Value.absent(),
    Value<String?> overallLabel = const Value.absent(),
    Value<String?> severity = const Value.absent(),
    Value<String?> topFactorsJson = const Value.absent(),
    Value<String?> summarySentence = const Value.absent(),
    Value<double?> baseValue = const Value.absent(),
    Value<String?> mode = const Value.absent(),
    Value<String?> modelName = const Value.absent(),
    Value<String?> modelVersion = const Value.absent(),
    Value<String?> computedAt = const Value.absent(),
    String? fetchedAt,
  }) => RiskSnapshotRow(
    segmentId: segmentId ?? this.segmentId,
    districtCode: districtCode.present ? districtCode.value : this.districtCode,
    roadCode: roadCode.present ? roadCode.value : this.roadCode,
    riskCurrent: riskCurrent.present ? riskCurrent.value : this.riskCurrent,
    risk6h: risk6h.present ? risk6h.value : this.risk6h,
    risk12h: risk12h.present ? risk12h.value : this.risk12h,
    risk24h: risk24h.present ? risk24h.value : this.risk24h,
    risk72h: risk72h.present ? risk72h.value : this.risk72h,
    overallLabel: overallLabel.present ? overallLabel.value : this.overallLabel,
    severity: severity.present ? severity.value : this.severity,
    topFactorsJson: topFactorsJson.present
        ? topFactorsJson.value
        : this.topFactorsJson,
    summarySentence: summarySentence.present
        ? summarySentence.value
        : this.summarySentence,
    baseValue: baseValue.present ? baseValue.value : this.baseValue,
    mode: mode.present ? mode.value : this.mode,
    modelName: modelName.present ? modelName.value : this.modelName,
    modelVersion: modelVersion.present ? modelVersion.value : this.modelVersion,
    computedAt: computedAt.present ? computedAt.value : this.computedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RiskSnapshotRow copyWithCompanion(RiskSnapshotRowsCompanion data) {
    return RiskSnapshotRow(
      segmentId: data.segmentId.present ? data.segmentId.value : this.segmentId,
      districtCode: data.districtCode.present
          ? data.districtCode.value
          : this.districtCode,
      roadCode: data.roadCode.present ? data.roadCode.value : this.roadCode,
      riskCurrent: data.riskCurrent.present
          ? data.riskCurrent.value
          : this.riskCurrent,
      risk6h: data.risk6h.present ? data.risk6h.value : this.risk6h,
      risk12h: data.risk12h.present ? data.risk12h.value : this.risk12h,
      risk24h: data.risk24h.present ? data.risk24h.value : this.risk24h,
      risk72h: data.risk72h.present ? data.risk72h.value : this.risk72h,
      overallLabel: data.overallLabel.present
          ? data.overallLabel.value
          : this.overallLabel,
      severity: data.severity.present ? data.severity.value : this.severity,
      topFactorsJson: data.topFactorsJson.present
          ? data.topFactorsJson.value
          : this.topFactorsJson,
      summarySentence: data.summarySentence.present
          ? data.summarySentence.value
          : this.summarySentence,
      baseValue: data.baseValue.present ? data.baseValue.value : this.baseValue,
      mode: data.mode.present ? data.mode.value : this.mode,
      modelName: data.modelName.present ? data.modelName.value : this.modelName,
      modelVersion: data.modelVersion.present
          ? data.modelVersion.value
          : this.modelVersion,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RiskSnapshotRow(')
          ..write('segmentId: $segmentId, ')
          ..write('districtCode: $districtCode, ')
          ..write('roadCode: $roadCode, ')
          ..write('riskCurrent: $riskCurrent, ')
          ..write('risk6h: $risk6h, ')
          ..write('risk12h: $risk12h, ')
          ..write('risk24h: $risk24h, ')
          ..write('risk72h: $risk72h, ')
          ..write('overallLabel: $overallLabel, ')
          ..write('severity: $severity, ')
          ..write('topFactorsJson: $topFactorsJson, ')
          ..write('summarySentence: $summarySentence, ')
          ..write('baseValue: $baseValue, ')
          ..write('mode: $mode, ')
          ..write('modelName: $modelName, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('computedAt: $computedAt, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    segmentId,
    districtCode,
    roadCode,
    riskCurrent,
    risk6h,
    risk12h,
    risk24h,
    risk72h,
    overallLabel,
    severity,
    topFactorsJson,
    summarySentence,
    baseValue,
    mode,
    modelName,
    modelVersion,
    computedAt,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RiskSnapshotRow &&
          other.segmentId == this.segmentId &&
          other.districtCode == this.districtCode &&
          other.roadCode == this.roadCode &&
          other.riskCurrent == this.riskCurrent &&
          other.risk6h == this.risk6h &&
          other.risk12h == this.risk12h &&
          other.risk24h == this.risk24h &&
          other.risk72h == this.risk72h &&
          other.overallLabel == this.overallLabel &&
          other.severity == this.severity &&
          other.topFactorsJson == this.topFactorsJson &&
          other.summarySentence == this.summarySentence &&
          other.baseValue == this.baseValue &&
          other.mode == this.mode &&
          other.modelName == this.modelName &&
          other.modelVersion == this.modelVersion &&
          other.computedAt == this.computedAt &&
          other.fetchedAt == this.fetchedAt);
}

class RiskSnapshotRowsCompanion extends UpdateCompanion<RiskSnapshotRow> {
  final Value<String> segmentId;
  final Value<String?> districtCode;
  final Value<String?> roadCode;
  final Value<double?> riskCurrent;
  final Value<double?> risk6h;
  final Value<double?> risk12h;
  final Value<double?> risk24h;
  final Value<double?> risk72h;
  final Value<String?> overallLabel;
  final Value<String?> severity;
  final Value<String?> topFactorsJson;
  final Value<String?> summarySentence;
  final Value<double?> baseValue;
  final Value<String?> mode;
  final Value<String?> modelName;
  final Value<String?> modelVersion;
  final Value<String?> computedAt;
  final Value<String> fetchedAt;
  final Value<int> rowid;
  const RiskSnapshotRowsCompanion({
    this.segmentId = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.roadCode = const Value.absent(),
    this.riskCurrent = const Value.absent(),
    this.risk6h = const Value.absent(),
    this.risk12h = const Value.absent(),
    this.risk24h = const Value.absent(),
    this.risk72h = const Value.absent(),
    this.overallLabel = const Value.absent(),
    this.severity = const Value.absent(),
    this.topFactorsJson = const Value.absent(),
    this.summarySentence = const Value.absent(),
    this.baseValue = const Value.absent(),
    this.mode = const Value.absent(),
    this.modelName = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RiskSnapshotRowsCompanion.insert({
    required String segmentId,
    this.districtCode = const Value.absent(),
    this.roadCode = const Value.absent(),
    this.riskCurrent = const Value.absent(),
    this.risk6h = const Value.absent(),
    this.risk12h = const Value.absent(),
    this.risk24h = const Value.absent(),
    this.risk72h = const Value.absent(),
    this.overallLabel = const Value.absent(),
    this.severity = const Value.absent(),
    this.topFactorsJson = const Value.absent(),
    this.summarySentence = const Value.absent(),
    this.baseValue = const Value.absent(),
    this.mode = const Value.absent(),
    this.modelName = const Value.absent(),
    this.modelVersion = const Value.absent(),
    this.computedAt = const Value.absent(),
    required String fetchedAt,
    this.rowid = const Value.absent(),
  }) : segmentId = Value(segmentId),
       fetchedAt = Value(fetchedAt);
  static Insertable<RiskSnapshotRow> custom({
    Expression<String>? segmentId,
    Expression<String>? districtCode,
    Expression<String>? roadCode,
    Expression<double>? riskCurrent,
    Expression<double>? risk6h,
    Expression<double>? risk12h,
    Expression<double>? risk24h,
    Expression<double>? risk72h,
    Expression<String>? overallLabel,
    Expression<String>? severity,
    Expression<String>? topFactorsJson,
    Expression<String>? summarySentence,
    Expression<double>? baseValue,
    Expression<String>? mode,
    Expression<String>? modelName,
    Expression<String>? modelVersion,
    Expression<String>? computedAt,
    Expression<String>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (segmentId != null) 'segment_id': segmentId,
      if (districtCode != null) 'district_code': districtCode,
      if (roadCode != null) 'road_code': roadCode,
      if (riskCurrent != null) 'risk_current': riskCurrent,
      if (risk6h != null) 'risk6h': risk6h,
      if (risk12h != null) 'risk12h': risk12h,
      if (risk24h != null) 'risk24h': risk24h,
      if (risk72h != null) 'risk72h': risk72h,
      if (overallLabel != null) 'overall_label': overallLabel,
      if (severity != null) 'severity': severity,
      if (topFactorsJson != null) 'top_factors_json': topFactorsJson,
      if (summarySentence != null) 'summary_sentence': summarySentence,
      if (baseValue != null) 'base_value': baseValue,
      if (mode != null) 'mode': mode,
      if (modelName != null) 'model_name': modelName,
      if (modelVersion != null) 'model_version': modelVersion,
      if (computedAt != null) 'computed_at': computedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RiskSnapshotRowsCompanion copyWith({
    Value<String>? segmentId,
    Value<String?>? districtCode,
    Value<String?>? roadCode,
    Value<double?>? riskCurrent,
    Value<double?>? risk6h,
    Value<double?>? risk12h,
    Value<double?>? risk24h,
    Value<double?>? risk72h,
    Value<String?>? overallLabel,
    Value<String?>? severity,
    Value<String?>? topFactorsJson,
    Value<String?>? summarySentence,
    Value<double?>? baseValue,
    Value<String?>? mode,
    Value<String?>? modelName,
    Value<String?>? modelVersion,
    Value<String?>? computedAt,
    Value<String>? fetchedAt,
    Value<int>? rowid,
  }) {
    return RiskSnapshotRowsCompanion(
      segmentId: segmentId ?? this.segmentId,
      districtCode: districtCode ?? this.districtCode,
      roadCode: roadCode ?? this.roadCode,
      riskCurrent: riskCurrent ?? this.riskCurrent,
      risk6h: risk6h ?? this.risk6h,
      risk12h: risk12h ?? this.risk12h,
      risk24h: risk24h ?? this.risk24h,
      risk72h: risk72h ?? this.risk72h,
      overallLabel: overallLabel ?? this.overallLabel,
      severity: severity ?? this.severity,
      topFactorsJson: topFactorsJson ?? this.topFactorsJson,
      summarySentence: summarySentence ?? this.summarySentence,
      baseValue: baseValue ?? this.baseValue,
      mode: mode ?? this.mode,
      modelName: modelName ?? this.modelName,
      modelVersion: modelVersion ?? this.modelVersion,
      computedAt: computedAt ?? this.computedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (segmentId.present) {
      map['segment_id'] = Variable<String>(segmentId.value);
    }
    if (districtCode.present) {
      map['district_code'] = Variable<String>(districtCode.value);
    }
    if (roadCode.present) {
      map['road_code'] = Variable<String>(roadCode.value);
    }
    if (riskCurrent.present) {
      map['risk_current'] = Variable<double>(riskCurrent.value);
    }
    if (risk6h.present) {
      map['risk6h'] = Variable<double>(risk6h.value);
    }
    if (risk12h.present) {
      map['risk12h'] = Variable<double>(risk12h.value);
    }
    if (risk24h.present) {
      map['risk24h'] = Variable<double>(risk24h.value);
    }
    if (risk72h.present) {
      map['risk72h'] = Variable<double>(risk72h.value);
    }
    if (overallLabel.present) {
      map['overall_label'] = Variable<String>(overallLabel.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (topFactorsJson.present) {
      map['top_factors_json'] = Variable<String>(topFactorsJson.value);
    }
    if (summarySentence.present) {
      map['summary_sentence'] = Variable<String>(summarySentence.value);
    }
    if (baseValue.present) {
      map['base_value'] = Variable<double>(baseValue.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (modelName.present) {
      map['model_name'] = Variable<String>(modelName.value);
    }
    if (modelVersion.present) {
      map['model_version'] = Variable<String>(modelVersion.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<String>(computedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RiskSnapshotRowsCompanion(')
          ..write('segmentId: $segmentId, ')
          ..write('districtCode: $districtCode, ')
          ..write('roadCode: $roadCode, ')
          ..write('riskCurrent: $riskCurrent, ')
          ..write('risk6h: $risk6h, ')
          ..write('risk12h: $risk12h, ')
          ..write('risk24h: $risk24h, ')
          ..write('risk72h: $risk72h, ')
          ..write('overallLabel: $overallLabel, ')
          ..write('severity: $severity, ')
          ..write('topFactorsJson: $topFactorsJson, ')
          ..write('summarySentence: $summarySentence, ')
          ..write('baseValue: $baseValue, ')
          ..write('mode: $mode, ')
          ..write('modelName: $modelName, ')
          ..write('modelVersion: $modelVersion, ')
          ..write('computedAt: $computedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RiskSnapshotMetaRowsTable extends RiskSnapshotMetaRows
    with TableInfo<$RiskSnapshotMetaRowsTable, RiskSnapshotMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RiskSnapshotMetaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('singleton'),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountMeta = const VerificationMeta(
    'rowCount',
  );
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
    'row_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _districtCodeMeta = const VerificationMeta(
    'districtCode',
  );
  @override
  late final GeneratedColumn<String> districtCode = GeneratedColumn<String>(
    'district_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, fetchedAt, rowCount, districtCode];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'risk_snapshot_meta_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RiskSnapshotMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(
        _rowCountMeta,
        rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta),
      );
    }
    if (data.containsKey('district_code')) {
      context.handle(
        _districtCodeMeta,
        districtCode.isAcceptableOrUnknown(
          data['district_code']!,
          _districtCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RiskSnapshotMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RiskSnapshotMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fetched_at'],
      )!,
      rowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_count'],
      )!,
      districtCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_code'],
      ),
    );
  }

  @override
  $RiskSnapshotMetaRowsTable createAlias(String alias) {
    return $RiskSnapshotMetaRowsTable(attachedDatabase, alias);
  }
}

class RiskSnapshotMetaRow extends DataClass
    implements Insertable<RiskSnapshotMetaRow> {
  final String id;
  final String fetchedAt;
  final int rowCount;
  final String? districtCode;
  const RiskSnapshotMetaRow({
    required this.id,
    required this.fetchedAt,
    required this.rowCount,
    this.districtCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['fetched_at'] = Variable<String>(fetchedAt);
    map['row_count'] = Variable<int>(rowCount);
    if (!nullToAbsent || districtCode != null) {
      map['district_code'] = Variable<String>(districtCode);
    }
    return map;
  }

  RiskSnapshotMetaRowsCompanion toCompanion(bool nullToAbsent) {
    return RiskSnapshotMetaRowsCompanion(
      id: Value(id),
      fetchedAt: Value(fetchedAt),
      rowCount: Value(rowCount),
      districtCode: districtCode == null && nullToAbsent
          ? const Value.absent()
          : Value(districtCode),
    );
  }

  factory RiskSnapshotMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RiskSnapshotMetaRow(
      id: serializer.fromJson<String>(json['id']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
      districtCode: serializer.fromJson<String?>(json['districtCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
      'rowCount': serializer.toJson<int>(rowCount),
      'districtCode': serializer.toJson<String?>(districtCode),
    };
  }

  RiskSnapshotMetaRow copyWith({
    String? id,
    String? fetchedAt,
    int? rowCount,
    Value<String?> districtCode = const Value.absent(),
  }) => RiskSnapshotMetaRow(
    id: id ?? this.id,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    rowCount: rowCount ?? this.rowCount,
    districtCode: districtCode.present ? districtCode.value : this.districtCode,
  );
  RiskSnapshotMetaRow copyWithCompanion(RiskSnapshotMetaRowsCompanion data) {
    return RiskSnapshotMetaRow(
      id: data.id.present ? data.id.value : this.id,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      districtCode: data.districtCode.present
          ? data.districtCode.value
          : this.districtCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RiskSnapshotMetaRow(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowCount: $rowCount, ')
          ..write('districtCode: $districtCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fetchedAt, rowCount, districtCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RiskSnapshotMetaRow &&
          other.id == this.id &&
          other.fetchedAt == this.fetchedAt &&
          other.rowCount == this.rowCount &&
          other.districtCode == this.districtCode);
}

class RiskSnapshotMetaRowsCompanion
    extends UpdateCompanion<RiskSnapshotMetaRow> {
  final Value<String> id;
  final Value<String> fetchedAt;
  final Value<int> rowCount;
  final Value<String?> districtCode;
  final Value<int> rowid;
  const RiskSnapshotMetaRowsCompanion({
    this.id = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RiskSnapshotMetaRowsCompanion.insert({
    this.id = const Value.absent(),
    required String fetchedAt,
    this.rowCount = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fetchedAt = Value(fetchedAt);
  static Insertable<RiskSnapshotMetaRow> custom({
    Expression<String>? id,
    Expression<String>? fetchedAt,
    Expression<int>? rowCount,
    Expression<String>? districtCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowCount != null) 'row_count': rowCount,
      if (districtCode != null) 'district_code': districtCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RiskSnapshotMetaRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? fetchedAt,
    Value<int>? rowCount,
    Value<String?>? districtCode,
    Value<int>? rowid,
  }) {
    return RiskSnapshotMetaRowsCompanion(
      id: id ?? this.id,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowCount: rowCount ?? this.rowCount,
      districtCode: districtCode ?? this.districtCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (districtCode.present) {
      map['district_code'] = Variable<String>(districtCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RiskSnapshotMetaRowsCompanion(')
          ..write('id: $id, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowCount: $rowCount, ')
          ..write('districtCode: $districtCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncQueueDatabase extends GeneratedDatabase {
  _$SyncQueueDatabase(QueryExecutor e) : super(e);
  $SyncQueueDatabaseManager get managers => $SyncQueueDatabaseManager(this);
  late final $SyncQueueRowsTable syncQueueRows = $SyncQueueRowsTable(this);
  late final $SyncAttemptRowsTable syncAttemptRows = $SyncAttemptRowsTable(
    this,
  );
  late final $DraftRowsTable draftRows = $DraftRowsTable(this);
  late final $DraftMediaRowsTable draftMediaRows = $DraftMediaRowsTable(this);
  late final $LocationRowsTable locationRows = $LocationRowsTable(this);
  late final $MapTileRowsTable mapTileRows = $MapTileRowsTable(this);
  late final $OfflineGraphSegmentRowsTable offlineGraphSegmentRows =
      $OfflineGraphSegmentRowsTable(this);
  late final $OfflineGraphMetaRowsTable offlineGraphMetaRows =
      $OfflineGraphMetaRowsTable(this);
  late final $RiskSnapshotRowsTable riskSnapshotRows = $RiskSnapshotRowsTable(
    this,
  );
  late final $RiskSnapshotMetaRowsTable riskSnapshotMetaRows =
      $RiskSnapshotMetaRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncQueueRows,
    syncAttemptRows,
    draftRows,
    draftMediaRows,
    locationRows,
    mapTileRows,
    offlineGraphSegmentRows,
    offlineGraphMetaRows,
    riskSnapshotRows,
    riskSnapshotMetaRows,
  ];
}

typedef $$SyncQueueRowsTableCreateCompanionBuilder =
    SyncQueueRowsCompanion Function({
      required String clientOpId,
      required String opType,
      Value<String?> entityType,
      Value<String?> entityId,
      required String payloadJson,
      required String status,
      Value<int> attempts,
      Value<int> priority,
      Value<String?> lastError,
      Value<String?> lastAttemptAt,
      Value<String?> nextRetryAt,
      required String createdAt,
      Value<String?> resourceId,
      Value<String?> dependencyClientOpId,
      Value<int> rowid,
    });
typedef $$SyncQueueRowsTableUpdateCompanionBuilder =
    SyncQueueRowsCompanion Function({
      Value<String> clientOpId,
      Value<String> opType,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attempts,
      Value<int> priority,
      Value<String?> lastError,
      Value<String?> lastAttemptAt,
      Value<String?> nextRetryAt,
      Value<String> createdAt,
      Value<String?> resourceId,
      Value<String?> dependencyClientOpId,
      Value<int> rowid,
    });

class $$SyncQueueRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dependencyClientOpId => $composableBuilder(
    column: $table.dependencyClientOpId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opType => $composableBuilder(
    column: $table.opType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dependencyClientOpId => $composableBuilder(
    column: $table.dependencyClientOpId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $SyncQueueRowsTable> {
  $$SyncQueueRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get opType =>
      $composableBuilder(column: $table.opType, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dependencyClientOpId => $composableBuilder(
    column: $table.dependencyClientOpId,
    builder: (column) => column,
  );
}

class $$SyncQueueRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $SyncQueueRowsTable,
          SyncQueueRow,
          $$SyncQueueRowsTableFilterComposer,
          $$SyncQueueRowsTableOrderingComposer,
          $$SyncQueueRowsTableAnnotationComposer,
          $$SyncQueueRowsTableCreateCompanionBuilder,
          $$SyncQueueRowsTableUpdateCompanionBuilder,
          (
            SyncQueueRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $SyncQueueRowsTable,
              SyncQueueRow
            >,
          ),
          SyncQueueRow,
          PrefetchHooks Function()
        > {
  $$SyncQueueRowsTableTableManager(
    _$SyncQueueDatabase db,
    $SyncQueueRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientOpId = const Value.absent(),
                Value<String> opType = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastAttemptAt = const Value.absent(),
                Value<String?> nextRetryAt = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
                Value<String?> dependencyClientOpId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueRowsCompanion(
                clientOpId: clientOpId,
                opType: opType,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                status: status,
                attempts: attempts,
                priority: priority,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                resourceId: resourceId,
                dependencyClientOpId: dependencyClientOpId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOpId,
                required String opType,
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                required String payloadJson,
                required String status,
                Value<int> attempts = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> lastAttemptAt = const Value.absent(),
                Value<String?> nextRetryAt = const Value.absent(),
                required String createdAt,
                Value<String?> resourceId = const Value.absent(),
                Value<String?> dependencyClientOpId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueRowsCompanion.insert(
                clientOpId: clientOpId,
                opType: opType,
                entityType: entityType,
                entityId: entityId,
                payloadJson: payloadJson,
                status: status,
                attempts: attempts,
                priority: priority,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
                resourceId: resourceId,
                dependencyClientOpId: dependencyClientOpId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueRowsTable, SyncQueueRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $SyncQueueRowsTable,
                    SyncQueueRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $SyncQueueRowsTable,
      SyncQueueRow,
      $$SyncQueueRowsTableFilterComposer,
      $$SyncQueueRowsTableOrderingComposer,
      $$SyncQueueRowsTableAnnotationComposer,
      $$SyncQueueRowsTableCreateCompanionBuilder,
      $$SyncQueueRowsTableUpdateCompanionBuilder,
      (
        SyncQueueRow,
        BaseReferences<_$SyncQueueDatabase, $SyncQueueRowsTable, SyncQueueRow>,
      ),
      SyncQueueRow,
      PrefetchHooks Function()
    >;
typedef $$SyncAttemptRowsTableCreateCompanionBuilder =
    SyncAttemptRowsCompanion Function({
      Value<int> id,
      required String clientOpId,
      required int attempt,
      required String at,
      required String outcome,
      Value<String?> reason,
      Value<String?> resourceId,
    });
typedef $$SyncAttemptRowsTableUpdateCompanionBuilder =
    SyncAttemptRowsCompanion Function({
      Value<int> id,
      Value<String> clientOpId,
      Value<int> attempt,
      Value<String> at,
      Value<String> outcome,
      Value<String?> reason,
      Value<String?> resourceId,
    });

class $$SyncAttemptRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $SyncAttemptRowsTable> {
  $$SyncAttemptRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncAttemptRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $SyncAttemptRowsTable> {
  $$SyncAttemptRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncAttemptRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $SyncAttemptRowsTable> {
  $$SyncAttemptRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<String> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get resourceId => $composableBuilder(
    column: $table.resourceId,
    builder: (column) => column,
  );
}

class $$SyncAttemptRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $SyncAttemptRowsTable,
          SyncAttemptRow,
          $$SyncAttemptRowsTableFilterComposer,
          $$SyncAttemptRowsTableOrderingComposer,
          $$SyncAttemptRowsTableAnnotationComposer,
          $$SyncAttemptRowsTableCreateCompanionBuilder,
          $$SyncAttemptRowsTableUpdateCompanionBuilder,
          (
            SyncAttemptRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $SyncAttemptRowsTable,
              SyncAttemptRow
            >,
          ),
          SyncAttemptRow,
          PrefetchHooks Function()
        > {
  $$SyncAttemptRowsTableTableManager(
    _$SyncQueueDatabase db,
    $SyncAttemptRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncAttemptRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncAttemptRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncAttemptRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientOpId = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<String> at = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
              }) => SyncAttemptRowsCompanion(
                id: id,
                clientOpId: clientOpId,
                attempt: attempt,
                at: at,
                outcome: outcome,
                reason: reason,
                resourceId: resourceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientOpId,
                required int attempt,
                required String at,
                required String outcome,
                Value<String?> reason = const Value.absent(),
                Value<String?> resourceId = const Value.absent(),
              }) => SyncAttemptRowsCompanion.insert(
                id: id,
                clientOpId: clientOpId,
                attempt: attempt,
                at: at,
                outcome: outcome,
                reason: reason,
                resourceId: resourceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncAttemptRowsTable, SyncAttemptRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $SyncAttemptRowsTable,
                    SyncAttemptRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncAttemptRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $SyncAttemptRowsTable,
      SyncAttemptRow,
      $$SyncAttemptRowsTableFilterComposer,
      $$SyncAttemptRowsTableOrderingComposer,
      $$SyncAttemptRowsTableAnnotationComposer,
      $$SyncAttemptRowsTableCreateCompanionBuilder,
      $$SyncAttemptRowsTableUpdateCompanionBuilder,
      (
        SyncAttemptRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $SyncAttemptRowsTable,
          SyncAttemptRow
        >,
      ),
      SyncAttemptRow,
      PrefetchHooks Function()
    >;
typedef $$DraftRowsTableCreateCompanionBuilder = DraftRowsCompanion Function({
  required String clientDraftId,
  required String payloadJson,
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$DraftRowsTableUpdateCompanionBuilder = DraftRowsCompanion Function({
  Value<String> clientDraftId,
  Value<String> payloadJson,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

class $$DraftRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $DraftRowsTable> {
  $$DraftRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $DraftRowsTable> {
  $$DraftRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $DraftRowsTable> {
  $$DraftRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DraftRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $DraftRowsTable,
          DraftRow,
          $$DraftRowsTableFilterComposer,
          $$DraftRowsTableOrderingComposer,
          $$DraftRowsTableAnnotationComposer,
          $$DraftRowsTableCreateCompanionBuilder,
          $$DraftRowsTableUpdateCompanionBuilder,
          (
            DraftRow,
            BaseReferences<_$SyncQueueDatabase, $DraftRowsTable, DraftRow>,
          ),
          DraftRow,
          PrefetchHooks Function()
        > {
  $$DraftRowsTableTableManager(_$SyncQueueDatabase db, $DraftRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientDraftId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftRowsCompanion(
                clientDraftId: clientDraftId,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientDraftId,
                required String payloadJson,
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftRowsCompanion.insert(
                clientDraftId: clientDraftId,
                payloadJson: payloadJson,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftRowsTable, DraftRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $DraftRowsTable,
                    DraftRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $DraftRowsTable,
      DraftRow,
      $$DraftRowsTableFilterComposer,
      $$DraftRowsTableOrderingComposer,
      $$DraftRowsTableAnnotationComposer,
      $$DraftRowsTableCreateCompanionBuilder,
      $$DraftRowsTableUpdateCompanionBuilder,
      (
        DraftRow,
        BaseReferences<_$SyncQueueDatabase, $DraftRowsTable, DraftRow>,
      ),
      DraftRow,
      PrefetchHooks Function()
    >;
typedef $$DraftMediaRowsTableCreateCompanionBuilder =
    DraftMediaRowsCompanion Function({
      required String clientRefId,
      required String clientDraftId,
      required String localPath,
      Value<String?> contentType,
      Value<int?> sizeBytes,
      Value<String?> sha256,
      Value<String?> capturedAt,
      Value<String> state,
      Value<String?> serverMediaId,
      Value<int> rowid,
    });
typedef $$DraftMediaRowsTableUpdateCompanionBuilder =
    DraftMediaRowsCompanion Function({
      Value<String> clientRefId,
      Value<String> clientDraftId,
      Value<String> localPath,
      Value<String?> contentType,
      Value<int?> sizeBytes,
      Value<String?> sha256,
      Value<String?> capturedAt,
      Value<String> state,
      Value<String?> serverMediaId,
      Value<int> rowid,
    });

class $$DraftMediaRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $DraftMediaRowsTable> {
  $$DraftMediaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientRefId => $composableBuilder(
    column: $table.clientRefId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftMediaRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $DraftMediaRowsTable> {
  $$DraftMediaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientRefId => $composableBuilder(
    column: $table.clientRefId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftMediaRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $DraftMediaRowsTable> {
  $$DraftMediaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientRefId => $composableBuilder(
    column: $table.clientRefId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientDraftId => $composableBuilder(
    column: $table.clientDraftId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get serverMediaId => $composableBuilder(
    column: $table.serverMediaId,
    builder: (column) => column,
  );
}

class $$DraftMediaRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $DraftMediaRowsTable,
          DraftMediaRow,
          $$DraftMediaRowsTableFilterComposer,
          $$DraftMediaRowsTableOrderingComposer,
          $$DraftMediaRowsTableAnnotationComposer,
          $$DraftMediaRowsTableCreateCompanionBuilder,
          $$DraftMediaRowsTableUpdateCompanionBuilder,
          (
            DraftMediaRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $DraftMediaRowsTable,
              DraftMediaRow
            >,
          ),
          DraftMediaRow,
          PrefetchHooks Function()
        > {
  $$DraftMediaRowsTableTableManager(
    _$SyncQueueDatabase db,
    $DraftMediaRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftMediaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftMediaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftMediaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientRefId = const Value.absent(),
                Value<String> clientDraftId = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> contentType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> capturedAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> serverMediaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftMediaRowsCompanion(
                clientRefId: clientRefId,
                clientDraftId: clientDraftId,
                localPath: localPath,
                contentType: contentType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                capturedAt: capturedAt,
                state: state,
                serverMediaId: serverMediaId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientRefId,
                required String clientDraftId,
                required String localPath,
                Value<String?> contentType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> capturedAt = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> serverMediaId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftMediaRowsCompanion.insert(
                clientRefId: clientRefId,
                clientDraftId: clientDraftId,
                localPath: localPath,
                contentType: contentType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                capturedAt: capturedAt,
                state: state,
                serverMediaId: serverMediaId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DraftMediaRowsTable, DraftMediaRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $DraftMediaRowsTable,
                    DraftMediaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftMediaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $DraftMediaRowsTable,
      DraftMediaRow,
      $$DraftMediaRowsTableFilterComposer,
      $$DraftMediaRowsTableOrderingComposer,
      $$DraftMediaRowsTableAnnotationComposer,
      $$DraftMediaRowsTableCreateCompanionBuilder,
      $$DraftMediaRowsTableUpdateCompanionBuilder,
      (
        DraftMediaRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $DraftMediaRowsTable,
          DraftMediaRow
        >,
      ),
      DraftMediaRow,
      PrefetchHooks Function()
    >;
typedef $$LocationRowsTableCreateCompanionBuilder =
    LocationRowsCompanion Function({
      Value<String> id,
      required double lat,
      required double lon,
      Value<double?> accuracyM,
      Value<double?> altitudeM,
      Value<double?> speedMps,
      Value<double?> headingDeg,
      required String timestamp,
      Value<String?> source,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$LocationRowsTableUpdateCompanionBuilder =
    LocationRowsCompanion Function({
      Value<String> id,
      Value<double> lat,
      Value<double> lon,
      Value<double?> accuracyM,
      Value<double?> altitudeM,
      Value<double?> speedMps,
      Value<double?> headingDeg,
      Value<String> timestamp,
      Value<String?> source,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$LocationRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $LocationRowsTable> {
  $$LocationRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $LocationRowsTable> {
  $$LocationRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitudeM => $composableBuilder(
    column: $table.altitudeM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $LocationRowsTable> {
  $$LocationRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<double> get altitudeM =>
      $composableBuilder(column: $table.altitudeM, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get headingDeg => $composableBuilder(
    column: $table.headingDeg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocationRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $LocationRowsTable,
          LocationRow,
          $$LocationRowsTableFilterComposer,
          $$LocationRowsTableOrderingComposer,
          $$LocationRowsTableAnnotationComposer,
          $$LocationRowsTableCreateCompanionBuilder,
          $$LocationRowsTableUpdateCompanionBuilder,
          (
            LocationRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $LocationRowsTable,
              LocationRow
            >,
          ),
          LocationRow,
          PrefetchHooks Function()
        > {
  $$LocationRowsTableTableManager(
    _$SyncQueueDatabase db,
    $LocationRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> headingDeg = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationRowsCompanion(
                id: id,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
                speedMps: speedMps,
                headingDeg: headingDeg,
                timestamp: timestamp,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required double lat,
                required double lon,
                Value<double?> accuracyM = const Value.absent(),
                Value<double?> altitudeM = const Value.absent(),
                Value<double?> speedMps = const Value.absent(),
                Value<double?> headingDeg = const Value.absent(),
                required String timestamp,
                Value<String?> source = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocationRowsCompanion.insert(
                id: id,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                altitudeM: altitudeM,
                speedMps: speedMps,
                headingDeg: headingDeg,
                timestamp: timestamp,
                source: source,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationRowsTable, LocationRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $LocationRowsTable,
                    LocationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $LocationRowsTable,
      LocationRow,
      $$LocationRowsTableFilterComposer,
      $$LocationRowsTableOrderingComposer,
      $$LocationRowsTableAnnotationComposer,
      $$LocationRowsTableCreateCompanionBuilder,
      $$LocationRowsTableUpdateCompanionBuilder,
      (
        LocationRow,
        BaseReferences<_$SyncQueueDatabase, $LocationRowsTable, LocationRow>,
      ),
      LocationRow,
      PrefetchHooks Function()
    >;
typedef $$MapTileRowsTableCreateCompanionBuilder =
    MapTileRowsCompanion Function({
      required int z,
      required int x,
      required int y,
      required String templateHash,
      required Uint8List bytes,
      required String contentType,
      required int sizeBytes,
      required String sha256,
      required String cachedAt,
      required String lastAccessedAt,
      Value<int> version,
      Value<int> rowid,
    });
typedef $$MapTileRowsTableUpdateCompanionBuilder =
    MapTileRowsCompanion Function({
      Value<int> z,
      Value<int> x,
      Value<int> y,
      Value<String> templateHash,
      Value<Uint8List> bytes,
      Value<String> contentType,
      Value<int> sizeBytes,
      Value<String> sha256,
      Value<String> cachedAt,
      Value<String> lastAccessedAt,
      Value<int> version,
      Value<int> rowid,
    });

class $$MapTileRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $MapTileRowsTable> {
  $$MapTileRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateHash => $composableBuilder(
    column: $table.templateHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MapTileRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $MapTileRowsTable> {
  $$MapTileRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get z => $composableBuilder(
    column: $table.z,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateHash => $composableBuilder(
    column: $table.templateHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MapTileRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $MapTileRowsTable> {
  $$MapTileRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get z =>
      $composableBuilder(column: $table.z, builder: (column) => column);

  GeneratedColumn<int> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<int> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<String> get templateHash => $composableBuilder(
    column: $table.templateHash,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);

  GeneratedColumn<String> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);
}

class $$MapTileRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $MapTileRowsTable,
          MapTileRow,
          $$MapTileRowsTableFilterComposer,
          $$MapTileRowsTableOrderingComposer,
          $$MapTileRowsTableAnnotationComposer,
          $$MapTileRowsTableCreateCompanionBuilder,
          $$MapTileRowsTableUpdateCompanionBuilder,
          (
            MapTileRow,
            BaseReferences<_$SyncQueueDatabase, $MapTileRowsTable, MapTileRow>,
          ),
          MapTileRow,
          PrefetchHooks Function()
        > {
  $$MapTileRowsTableTableManager(
    _$SyncQueueDatabase db,
    $MapTileRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MapTileRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MapTileRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MapTileRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> z = const Value.absent(),
                Value<int> x = const Value.absent(),
                Value<int> y = const Value.absent(),
                Value<String> templateHash = const Value.absent(),
                Value<Uint8List> bytes = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String> cachedAt = const Value.absent(),
                Value<String> lastAccessedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MapTileRowsCompanion(
                z: z,
                x: x,
                y: y,
                templateHash: templateHash,
                bytes: bytes,
                contentType: contentType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                cachedAt: cachedAt,
                lastAccessedAt: lastAccessedAt,
                version: version,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int z,
                required int x,
                required int y,
                required String templateHash,
                required Uint8List bytes,
                required String contentType,
                required int sizeBytes,
                required String sha256,
                required String cachedAt,
                required String lastAccessedAt,
                Value<int> version = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MapTileRowsCompanion.insert(
                z: z,
                x: x,
                y: y,
                templateHash: templateHash,
                bytes: bytes,
                contentType: contentType,
                sizeBytes: sizeBytes,
                sha256: sha256,
                cachedAt: cachedAt,
                lastAccessedAt: lastAccessedAt,
                version: version,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MapTileRowsTable, MapTileRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $MapTileRowsTable,
                    MapTileRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MapTileRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $MapTileRowsTable,
      MapTileRow,
      $$MapTileRowsTableFilterComposer,
      $$MapTileRowsTableOrderingComposer,
      $$MapTileRowsTableAnnotationComposer,
      $$MapTileRowsTableCreateCompanionBuilder,
      $$MapTileRowsTableUpdateCompanionBuilder,
      (
        MapTileRow,
        BaseReferences<_$SyncQueueDatabase, $MapTileRowsTable, MapTileRow>,
      ),
      MapTileRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineGraphSegmentRowsTableCreateCompanionBuilder =
    OfflineGraphSegmentRowsCompanion Function({
      required String segmentId,
      required String roadCode,
      Value<int> seq,
      required double x1,
      required double y1,
      required double x2,
      required double y2,
      required double lengthKm,
      required double accessibility,
      required double riskPct,
      required String status,
      Value<int> rowid,
    });
typedef $$OfflineGraphSegmentRowsTableUpdateCompanionBuilder =
    OfflineGraphSegmentRowsCompanion Function({
      Value<String> segmentId,
      Value<String> roadCode,
      Value<int> seq,
      Value<double> x1,
      Value<double> y1,
      Value<double> x2,
      Value<double> y2,
      Value<double> lengthKm,
      Value<double> accessibility,
      Value<double> riskPct,
      Value<String> status,
      Value<int> rowid,
    });

class $$OfflineGraphSegmentRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphSegmentRowsTable> {
  $$OfflineGraphSegmentRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadCode => $composableBuilder(
    column: $table.roadCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x2 => $composableBuilder(
    column: $table.x2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y2 => $composableBuilder(
    column: $table.y2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lengthKm => $composableBuilder(
    column: $table.lengthKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accessibility => $composableBuilder(
    column: $table.accessibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskPct => $composableBuilder(
    column: $table.riskPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineGraphSegmentRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphSegmentRowsTable> {
  $$OfflineGraphSegmentRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadCode => $composableBuilder(
    column: $table.roadCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x1 => $composableBuilder(
    column: $table.x1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y1 => $composableBuilder(
    column: $table.y1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x2 => $composableBuilder(
    column: $table.x2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y2 => $composableBuilder(
    column: $table.y2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lengthKm => $composableBuilder(
    column: $table.lengthKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accessibility => $composableBuilder(
    column: $table.accessibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskPct => $composableBuilder(
    column: $table.riskPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineGraphSegmentRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphSegmentRowsTable> {
  $$OfflineGraphSegmentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<String> get roadCode =>
      $composableBuilder(column: $table.roadCode, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<double> get x1 =>
      $composableBuilder(column: $table.x1, builder: (column) => column);

  GeneratedColumn<double> get y1 =>
      $composableBuilder(column: $table.y1, builder: (column) => column);

  GeneratedColumn<double> get x2 =>
      $composableBuilder(column: $table.x2, builder: (column) => column);

  GeneratedColumn<double> get y2 =>
      $composableBuilder(column: $table.y2, builder: (column) => column);

  GeneratedColumn<double> get lengthKm =>
      $composableBuilder(column: $table.lengthKm, builder: (column) => column);

  GeneratedColumn<double> get accessibility => $composableBuilder(
    column: $table.accessibility,
    builder: (column) => column,
  );

  GeneratedColumn<double> get riskPct =>
      $composableBuilder(column: $table.riskPct, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OfflineGraphSegmentRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $OfflineGraphSegmentRowsTable,
          OfflineGraphSegmentRow,
          $$OfflineGraphSegmentRowsTableFilterComposer,
          $$OfflineGraphSegmentRowsTableOrderingComposer,
          $$OfflineGraphSegmentRowsTableAnnotationComposer,
          $$OfflineGraphSegmentRowsTableCreateCompanionBuilder,
          $$OfflineGraphSegmentRowsTableUpdateCompanionBuilder,
          (
            OfflineGraphSegmentRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $OfflineGraphSegmentRowsTable,
              OfflineGraphSegmentRow
            >,
          ),
          OfflineGraphSegmentRow,
          PrefetchHooks Function()
        > {
  $$OfflineGraphSegmentRowsTableTableManager(
    _$SyncQueueDatabase db,
    $OfflineGraphSegmentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineGraphSegmentRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$OfflineGraphSegmentRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineGraphSegmentRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> segmentId = const Value.absent(),
                Value<String> roadCode = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<double> x1 = const Value.absent(),
                Value<double> y1 = const Value.absent(),
                Value<double> x2 = const Value.absent(),
                Value<double> y2 = const Value.absent(),
                Value<double> lengthKm = const Value.absent(),
                Value<double> accessibility = const Value.absent(),
                Value<double> riskPct = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineGraphSegmentRowsCompanion(
                segmentId: segmentId,
                roadCode: roadCode,
                seq: seq,
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                lengthKm: lengthKm,
                accessibility: accessibility,
                riskPct: riskPct,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String segmentId,
                required String roadCode,
                Value<int> seq = const Value.absent(),
                required double x1,
                required double y1,
                required double x2,
                required double y2,
                required double lengthKm,
                required double accessibility,
                required double riskPct,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => OfflineGraphSegmentRowsCompanion.insert(
                segmentId: segmentId,
                roadCode: roadCode,
                seq: seq,
                x1: x1,
                y1: y1,
                x2: x2,
                y2: y2,
                lengthKm: lengthKm,
                accessibility: accessibility,
                riskPct: riskPct,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $OfflineGraphSegmentRowsTable,
                    OfflineGraphSegmentRow
                  >(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $OfflineGraphSegmentRowsTable,
                    OfflineGraphSegmentRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineGraphSegmentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $OfflineGraphSegmentRowsTable,
      OfflineGraphSegmentRow,
      $$OfflineGraphSegmentRowsTableFilterComposer,
      $$OfflineGraphSegmentRowsTableOrderingComposer,
      $$OfflineGraphSegmentRowsTableAnnotationComposer,
      $$OfflineGraphSegmentRowsTableCreateCompanionBuilder,
      $$OfflineGraphSegmentRowsTableUpdateCompanionBuilder,
      (
        OfflineGraphSegmentRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $OfflineGraphSegmentRowsTable,
          OfflineGraphSegmentRow
        >,
      ),
      OfflineGraphSegmentRow,
      PrefetchHooks Function()
    >;
typedef $$OfflineGraphMetaRowsTableCreateCompanionBuilder =
    OfflineGraphMetaRowsCompanion Function({
      Value<String> id,
      required String fetchedAt,
      Value<int> segmentCount,
      Value<int> rowid,
    });
typedef $$OfflineGraphMetaRowsTableUpdateCompanionBuilder =
    OfflineGraphMetaRowsCompanion Function({
      Value<String> id,
      Value<String> fetchedAt,
      Value<int> segmentCount,
      Value<int> rowid,
    });

class $$OfflineGraphMetaRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphMetaRowsTable> {
  $$OfflineGraphMetaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineGraphMetaRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphMetaRowsTable> {
  $$OfflineGraphMetaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineGraphMetaRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $OfflineGraphMetaRowsTable> {
  $$OfflineGraphMetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get segmentCount => $composableBuilder(
    column: $table.segmentCount,
    builder: (column) => column,
  );
}

class $$OfflineGraphMetaRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $OfflineGraphMetaRowsTable,
          OfflineGraphMetaRow,
          $$OfflineGraphMetaRowsTableFilterComposer,
          $$OfflineGraphMetaRowsTableOrderingComposer,
          $$OfflineGraphMetaRowsTableAnnotationComposer,
          $$OfflineGraphMetaRowsTableCreateCompanionBuilder,
          $$OfflineGraphMetaRowsTableUpdateCompanionBuilder,
          (
            OfflineGraphMetaRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $OfflineGraphMetaRowsTable,
              OfflineGraphMetaRow
            >,
          ),
          OfflineGraphMetaRow,
          PrefetchHooks Function()
        > {
  $$OfflineGraphMetaRowsTableTableManager(
    _$SyncQueueDatabase db,
    $OfflineGraphMetaRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineGraphMetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineGraphMetaRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$OfflineGraphMetaRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fetchedAt = const Value.absent(),
                Value<int> segmentCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineGraphMetaRowsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                segmentCount: segmentCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String fetchedAt,
                Value<int> segmentCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineGraphMetaRowsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                segmentCount: segmentCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OfflineGraphMetaRowsTable, OfflineGraphMetaRow>(
                    table,
                  ),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $OfflineGraphMetaRowsTable,
                    OfflineGraphMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineGraphMetaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $OfflineGraphMetaRowsTable,
      OfflineGraphMetaRow,
      $$OfflineGraphMetaRowsTableFilterComposer,
      $$OfflineGraphMetaRowsTableOrderingComposer,
      $$OfflineGraphMetaRowsTableAnnotationComposer,
      $$OfflineGraphMetaRowsTableCreateCompanionBuilder,
      $$OfflineGraphMetaRowsTableUpdateCompanionBuilder,
      (
        OfflineGraphMetaRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $OfflineGraphMetaRowsTable,
          OfflineGraphMetaRow
        >,
      ),
      OfflineGraphMetaRow,
      PrefetchHooks Function()
    >;
typedef $$RiskSnapshotRowsTableCreateCompanionBuilder =
    RiskSnapshotRowsCompanion Function({
      required String segmentId,
      Value<String?> districtCode,
      Value<String?> roadCode,
      Value<double?> riskCurrent,
      Value<double?> risk6h,
      Value<double?> risk12h,
      Value<double?> risk24h,
      Value<double?> risk72h,
      Value<String?> overallLabel,
      Value<String?> severity,
      Value<String?> topFactorsJson,
      Value<String?> summarySentence,
      Value<double?> baseValue,
      Value<String?> mode,
      Value<String?> modelName,
      Value<String?> modelVersion,
      Value<String?> computedAt,
      required String fetchedAt,
      Value<int> rowid,
    });
typedef $$RiskSnapshotRowsTableUpdateCompanionBuilder =
    RiskSnapshotRowsCompanion Function({
      Value<String> segmentId,
      Value<String?> districtCode,
      Value<String?> roadCode,
      Value<double?> riskCurrent,
      Value<double?> risk6h,
      Value<double?> risk12h,
      Value<double?> risk24h,
      Value<double?> risk72h,
      Value<String?> overallLabel,
      Value<String?> severity,
      Value<String?> topFactorsJson,
      Value<String?> summarySentence,
      Value<double?> baseValue,
      Value<String?> mode,
      Value<String?> modelName,
      Value<String?> modelVersion,
      Value<String?> computedAt,
      Value<String> fetchedAt,
      Value<int> rowid,
    });

class $$RiskSnapshotRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotRowsTable> {
  $$RiskSnapshotRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roadCode => $composableBuilder(
    column: $table.roadCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riskCurrent => $composableBuilder(
    column: $table.riskCurrent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get risk6h => $composableBuilder(
    column: $table.risk6h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get risk12h => $composableBuilder(
    column: $table.risk12h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get risk24h => $composableBuilder(
    column: $table.risk24h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get risk72h => $composableBuilder(
    column: $table.risk72h,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overallLabel => $composableBuilder(
    column: $table.overallLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topFactorsJson => $composableBuilder(
    column: $table.topFactorsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summarySentence => $composableBuilder(
    column: $table.summarySentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get baseValue => $composableBuilder(
    column: $table.baseValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RiskSnapshotRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotRowsTable> {
  $$RiskSnapshotRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get segmentId => $composableBuilder(
    column: $table.segmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roadCode => $composableBuilder(
    column: $table.roadCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riskCurrent => $composableBuilder(
    column: $table.riskCurrent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get risk6h => $composableBuilder(
    column: $table.risk6h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get risk12h => $composableBuilder(
    column: $table.risk12h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get risk24h => $composableBuilder(
    column: $table.risk24h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get risk72h => $composableBuilder(
    column: $table.risk72h,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overallLabel => $composableBuilder(
    column: $table.overallLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topFactorsJson => $composableBuilder(
    column: $table.topFactorsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summarySentence => $composableBuilder(
    column: $table.summarySentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get baseValue => $composableBuilder(
    column: $table.baseValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelName => $composableBuilder(
    column: $table.modelName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RiskSnapshotRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotRowsTable> {
  $$RiskSnapshotRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get segmentId =>
      $composableBuilder(column: $table.segmentId, builder: (column) => column);

  GeneratedColumn<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get roadCode =>
      $composableBuilder(column: $table.roadCode, builder: (column) => column);

  GeneratedColumn<double> get riskCurrent => $composableBuilder(
    column: $table.riskCurrent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get risk6h =>
      $composableBuilder(column: $table.risk6h, builder: (column) => column);

  GeneratedColumn<double> get risk12h =>
      $composableBuilder(column: $table.risk12h, builder: (column) => column);

  GeneratedColumn<double> get risk24h =>
      $composableBuilder(column: $table.risk24h, builder: (column) => column);

  GeneratedColumn<double> get risk72h =>
      $composableBuilder(column: $table.risk72h, builder: (column) => column);

  GeneratedColumn<String> get overallLabel => $composableBuilder(
    column: $table.overallLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get topFactorsJson => $composableBuilder(
    column: $table.topFactorsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get summarySentence => $composableBuilder(
    column: $table.summarySentence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get baseValue =>
      $composableBuilder(column: $table.baseValue, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get modelName =>
      $composableBuilder(column: $table.modelName, builder: (column) => column);

  GeneratedColumn<String> get modelVersion => $composableBuilder(
    column: $table.modelVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get computedAt => $composableBuilder(
    column: $table.computedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$RiskSnapshotRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $RiskSnapshotRowsTable,
          RiskSnapshotRow,
          $$RiskSnapshotRowsTableFilterComposer,
          $$RiskSnapshotRowsTableOrderingComposer,
          $$RiskSnapshotRowsTableAnnotationComposer,
          $$RiskSnapshotRowsTableCreateCompanionBuilder,
          $$RiskSnapshotRowsTableUpdateCompanionBuilder,
          (
            RiskSnapshotRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $RiskSnapshotRowsTable,
              RiskSnapshotRow
            >,
          ),
          RiskSnapshotRow,
          PrefetchHooks Function()
        > {
  $$RiskSnapshotRowsTableTableManager(
    _$SyncQueueDatabase db,
    $RiskSnapshotRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RiskSnapshotRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RiskSnapshotRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RiskSnapshotRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> segmentId = const Value.absent(),
                Value<String?> districtCode = const Value.absent(),
                Value<String?> roadCode = const Value.absent(),
                Value<double?> riskCurrent = const Value.absent(),
                Value<double?> risk6h = const Value.absent(),
                Value<double?> risk12h = const Value.absent(),
                Value<double?> risk24h = const Value.absent(),
                Value<double?> risk72h = const Value.absent(),
                Value<String?> overallLabel = const Value.absent(),
                Value<String?> severity = const Value.absent(),
                Value<String?> topFactorsJson = const Value.absent(),
                Value<String?> summarySentence = const Value.absent(),
                Value<double?> baseValue = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<String?> computedAt = const Value.absent(),
                Value<String> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RiskSnapshotRowsCompanion(
                segmentId: segmentId,
                districtCode: districtCode,
                roadCode: roadCode,
                riskCurrent: riskCurrent,
                risk6h: risk6h,
                risk12h: risk12h,
                risk24h: risk24h,
                risk72h: risk72h,
                overallLabel: overallLabel,
                severity: severity,
                topFactorsJson: topFactorsJson,
                summarySentence: summarySentence,
                baseValue: baseValue,
                mode: mode,
                modelName: modelName,
                modelVersion: modelVersion,
                computedAt: computedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String segmentId,
                Value<String?> districtCode = const Value.absent(),
                Value<String?> roadCode = const Value.absent(),
                Value<double?> riskCurrent = const Value.absent(),
                Value<double?> risk6h = const Value.absent(),
                Value<double?> risk12h = const Value.absent(),
                Value<double?> risk24h = const Value.absent(),
                Value<double?> risk72h = const Value.absent(),
                Value<String?> overallLabel = const Value.absent(),
                Value<String?> severity = const Value.absent(),
                Value<String?> topFactorsJson = const Value.absent(),
                Value<String?> summarySentence = const Value.absent(),
                Value<double?> baseValue = const Value.absent(),
                Value<String?> mode = const Value.absent(),
                Value<String?> modelName = const Value.absent(),
                Value<String?> modelVersion = const Value.absent(),
                Value<String?> computedAt = const Value.absent(),
                required String fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => RiskSnapshotRowsCompanion.insert(
                segmentId: segmentId,
                districtCode: districtCode,
                roadCode: roadCode,
                riskCurrent: riskCurrent,
                risk6h: risk6h,
                risk12h: risk12h,
                risk24h: risk24h,
                risk72h: risk72h,
                overallLabel: overallLabel,
                severity: severity,
                topFactorsJson: topFactorsJson,
                summarySentence: summarySentence,
                baseValue: baseValue,
                mode: mode,
                modelName: modelName,
                modelVersion: modelVersion,
                computedAt: computedAt,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RiskSnapshotRowsTable, RiskSnapshotRow>(table),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $RiskSnapshotRowsTable,
                    RiskSnapshotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RiskSnapshotRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $RiskSnapshotRowsTable,
      RiskSnapshotRow,
      $$RiskSnapshotRowsTableFilterComposer,
      $$RiskSnapshotRowsTableOrderingComposer,
      $$RiskSnapshotRowsTableAnnotationComposer,
      $$RiskSnapshotRowsTableCreateCompanionBuilder,
      $$RiskSnapshotRowsTableUpdateCompanionBuilder,
      (
        RiskSnapshotRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $RiskSnapshotRowsTable,
          RiskSnapshotRow
        >,
      ),
      RiskSnapshotRow,
      PrefetchHooks Function()
    >;
typedef $$RiskSnapshotMetaRowsTableCreateCompanionBuilder =
    RiskSnapshotMetaRowsCompanion Function({
      Value<String> id,
      required String fetchedAt,
      Value<int> rowCount,
      Value<String?> districtCode,
      Value<int> rowid,
    });
typedef $$RiskSnapshotMetaRowsTableUpdateCompanionBuilder =
    RiskSnapshotMetaRowsCompanion Function({
      Value<String> id,
      Value<String> fetchedAt,
      Value<int> rowCount,
      Value<String?> districtCode,
      Value<int> rowid,
    });

class $$RiskSnapshotMetaRowsTableFilterComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotMetaRowsTable> {
  $$RiskSnapshotMetaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RiskSnapshotMetaRowsTableOrderingComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotMetaRowsTable> {
  $$RiskSnapshotMetaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RiskSnapshotMetaRowsTableAnnotationComposer
    extends Composer<_$SyncQueueDatabase, $RiskSnapshotMetaRowsTable> {
  $$RiskSnapshotMetaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => column,
  );
}

class $$RiskSnapshotMetaRowsTableTableManager
    extends
        RootTableManager<
          _$SyncQueueDatabase,
          $RiskSnapshotMetaRowsTable,
          RiskSnapshotMetaRow,
          $$RiskSnapshotMetaRowsTableFilterComposer,
          $$RiskSnapshotMetaRowsTableOrderingComposer,
          $$RiskSnapshotMetaRowsTableAnnotationComposer,
          $$RiskSnapshotMetaRowsTableCreateCompanionBuilder,
          $$RiskSnapshotMetaRowsTableUpdateCompanionBuilder,
          (
            RiskSnapshotMetaRow,
            BaseReferences<
              _$SyncQueueDatabase,
              $RiskSnapshotMetaRowsTable,
              RiskSnapshotMetaRow
            >,
          ),
          RiskSnapshotMetaRow,
          PrefetchHooks Function()
        > {
  $$RiskSnapshotMetaRowsTableTableManager(
    _$SyncQueueDatabase db,
    $RiskSnapshotMetaRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RiskSnapshotMetaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RiskSnapshotMetaRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RiskSnapshotMetaRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> fetchedAt = const Value.absent(),
                Value<int> rowCount = const Value.absent(),
                Value<String?> districtCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RiskSnapshotMetaRowsCompanion(
                id: id,
                fetchedAt: fetchedAt,
                rowCount: rowCount,
                districtCode: districtCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String fetchedAt,
                Value<int> rowCount = const Value.absent(),
                Value<String?> districtCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RiskSnapshotMetaRowsCompanion.insert(
                id: id,
                fetchedAt: fetchedAt,
                rowCount: rowCount,
                districtCode: districtCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RiskSnapshotMetaRowsTable, RiskSnapshotMetaRow>(
                    table,
                  ),
                  BaseReferences<
                    _$SyncQueueDatabase,
                    $RiskSnapshotMetaRowsTable,
                    RiskSnapshotMetaRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RiskSnapshotMetaRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncQueueDatabase,
      $RiskSnapshotMetaRowsTable,
      RiskSnapshotMetaRow,
      $$RiskSnapshotMetaRowsTableFilterComposer,
      $$RiskSnapshotMetaRowsTableOrderingComposer,
      $$RiskSnapshotMetaRowsTableAnnotationComposer,
      $$RiskSnapshotMetaRowsTableCreateCompanionBuilder,
      $$RiskSnapshotMetaRowsTableUpdateCompanionBuilder,
      (
        RiskSnapshotMetaRow,
        BaseReferences<
          _$SyncQueueDatabase,
          $RiskSnapshotMetaRowsTable,
          RiskSnapshotMetaRow
        >,
      ),
      RiskSnapshotMetaRow,
      PrefetchHooks Function()
    >;

class $SyncQueueDatabaseManager {
  final _$SyncQueueDatabase _db;
  $SyncQueueDatabaseManager(this._db);
  $$SyncQueueRowsTableTableManager get syncQueueRows =>
      $$SyncQueueRowsTableTableManager(_db, _db.syncQueueRows);
  $$SyncAttemptRowsTableTableManager get syncAttemptRows =>
      $$SyncAttemptRowsTableTableManager(_db, _db.syncAttemptRows);
  $$DraftRowsTableTableManager get draftRows =>
      $$DraftRowsTableTableManager(_db, _db.draftRows);
  $$DraftMediaRowsTableTableManager get draftMediaRows =>
      $$DraftMediaRowsTableTableManager(_db, _db.draftMediaRows);
  $$LocationRowsTableTableManager get locationRows =>
      $$LocationRowsTableTableManager(_db, _db.locationRows);
  $$MapTileRowsTableTableManager get mapTileRows =>
      $$MapTileRowsTableTableManager(_db, _db.mapTileRows);
  $$OfflineGraphSegmentRowsTableTableManager get offlineGraphSegmentRows =>
      $$OfflineGraphSegmentRowsTableTableManager(
        _db,
        _db.offlineGraphSegmentRows,
      );
  $$OfflineGraphMetaRowsTableTableManager get offlineGraphMetaRows =>
      $$OfflineGraphMetaRowsTableTableManager(_db, _db.offlineGraphMetaRows);
  $$RiskSnapshotRowsTableTableManager get riskSnapshotRows =>
      $$RiskSnapshotRowsTableTableManager(_db, _db.riskSnapshotRows);
  $$RiskSnapshotMetaRowsTableTableManager get riskSnapshotMetaRows =>
      $$RiskSnapshotMetaRowsTableTableManager(_db, _db.riskSnapshotMetaRows);
}

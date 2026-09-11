// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_queue_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncQueueEntry {

 String get clientOpId; String get opType; Map<String, dynamic> get payload; SyncQueueStatus get status; int get attempts; String? get lastError; String? get lastAttemptAt; String? get createdAt; String? get resourceId;/// Logical entity kind ("FIELD_REPORT", "MEDIA", "GPS_PING", ...).
/// Lets the UI/flush policy reason about the queue without parsing
/// opType. Optional so existing call-sites are not broken.
 String? get entityType;/// Server-side ID of the entity once the server has acknowledged it
/// (different from [resourceId] which records the op-result id).
 String? get entityId;/// Higher = should flush first. 0 is the default; 100 = critical
/// (e.g. CRITICAL_FIELD_REPORT).
 int get priority;/// ISO-8601 wall-clock instant when this entry becomes eligible for
/// the next flush attempt. NULL = ready now.
 String? get nextRetryAt;/// client_op_id of the op that must succeed BEFORE this one. Used to
/// attach a media op to its parent field-report submission, etc.
 String? get dependencyClientOpId;
/// Create a copy of SyncQueueEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncQueueEntryCopyWith<SyncQueueEntry> get copyWith => _$SyncQueueEntryCopyWithImpl<SyncQueueEntry>(this as SyncQueueEntry, _$identity);

  /// Serializes this SyncQueueEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncQueueEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncQueueEntry&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.opType, _this.opType) || other.opType == _this.opType)&&const DeepCollectionEquality().equals(other.payload, _this.payload)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.attempts, _this.attempts) || other.attempts == _this.attempts)&&(identical(other.lastError, _this.lastError) || other.lastError == _this.lastError)&&(identical(other.lastAttemptAt, _this.lastAttemptAt) || other.lastAttemptAt == _this.lastAttemptAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId)&&(identical(other.entityType, _this.entityType) || other.entityType == _this.entityType)&&(identical(other.entityId, _this.entityId) || other.entityId == _this.entityId)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.nextRetryAt, _this.nextRetryAt) || other.nextRetryAt == _this.nextRetryAt)&&(identical(other.dependencyClientOpId, _this.dependencyClientOpId) || other.dependencyClientOpId == _this.dependencyClientOpId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncQueueEntry;
  return Object.hash(runtimeType,_this.clientOpId,_this.opType,const DeepCollectionEquality().hash(_this.payload),_this.status,_this.attempts,_this.lastError,_this.lastAttemptAt,_this.createdAt,_this.resourceId,_this.entityType,_this.entityId,_this.priority,_this.nextRetryAt,_this.dependencyClientOpId);
}

@override
String toString() {
  final _this = this as SyncQueueEntry;
  return 'SyncQueueEntry(clientOpId: ${_this.clientOpId}, opType: ${_this.opType}, payload: ${_this.payload}, status: ${_this.status}, attempts: ${_this.attempts}, lastError: ${_this.lastError}, lastAttemptAt: ${_this.lastAttemptAt}, createdAt: ${_this.createdAt}, resourceId: ${_this.resourceId}, entityType: ${_this.entityType}, entityId: ${_this.entityId}, priority: ${_this.priority}, nextRetryAt: ${_this.nextRetryAt}, dependencyClientOpId: ${_this.dependencyClientOpId})';
}


}

/// @nodoc
abstract mixin class $SyncQueueEntryCopyWith<$Res>  {
  factory $SyncQueueEntryCopyWith(SyncQueueEntry value, $Res Function(SyncQueueEntry) _then) = _$SyncQueueEntryCopyWithImpl;
@useResult
$Res call({
 String clientOpId, String opType, Map<String, dynamic> payload, SyncQueueStatus status, int attempts, String? lastError, String? lastAttemptAt, String? createdAt, String? resourceId, String? entityType, String? entityId, int priority, String? nextRetryAt, String? dependencyClientOpId
});




}
/// @nodoc
class _$SyncQueueEntryCopyWithImpl<$Res>
    implements $SyncQueueEntryCopyWith<$Res> {
  _$SyncQueueEntryCopyWithImpl(this._self, this._then);

  final SyncQueueEntry _self;
  final $Res Function(SyncQueueEntry) _then;

/// Create a copy of SyncQueueEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? opType = null,Object? payload = null,Object? status = null,Object? attempts = null,Object? lastError = freezed,Object? lastAttemptAt = freezed,Object? createdAt = freezed,Object? resourceId = freezed,Object? entityType = freezed,Object? entityId = freezed,Object? priority = null,Object? nextRetryAt = freezed,Object? dependencyClientOpId = freezed,}) {
  return _then(SyncQueueEntry(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,opType: null == opType ? _self.opType : opType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncQueueStatus,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as String?,dependencyClientOpId: freezed == dependencyClientOpId ? _self.dependencyClientOpId : dependencyClientOpId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncQueueEntry].
extension SyncQueueEntryPatterns on SyncQueueEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncQueueEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncQueueEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncQueueEntry value)  $default,){
final _that = this;
switch (_that) {
case _SyncQueueEntry():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncQueueEntry value)?  $default,){
final _that = this;
switch (_that) {
case _SyncQueueEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  String opType,  Map<String, dynamic> payload,  SyncQueueStatus status,  int attempts,  String? lastError,  String? lastAttemptAt,  String? createdAt,  String? resourceId,  String? entityType,  String? entityId,  int priority,  String? nextRetryAt,  String? dependencyClientOpId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncQueueEntry() when $default != null:
return $default(_that.clientOpId,_that.opType,_that.payload,_that.status,_that.attempts,_that.lastError,_that.lastAttemptAt,_that.createdAt,_that.resourceId,_that.entityType,_that.entityId,_that.priority,_that.nextRetryAt,_that.dependencyClientOpId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  String opType,  Map<String, dynamic> payload,  SyncQueueStatus status,  int attempts,  String? lastError,  String? lastAttemptAt,  String? createdAt,  String? resourceId,  String? entityType,  String? entityId,  int priority,  String? nextRetryAt,  String? dependencyClientOpId)  $default,) {final _that = this;
switch (_that) {
case _SyncQueueEntry():
return $default(_that.clientOpId,_that.opType,_that.payload,_that.status,_that.attempts,_that.lastError,_that.lastAttemptAt,_that.createdAt,_that.resourceId,_that.entityType,_that.entityId,_that.priority,_that.nextRetryAt,_that.dependencyClientOpId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  String opType,  Map<String, dynamic> payload,  SyncQueueStatus status,  int attempts,  String? lastError,  String? lastAttemptAt,  String? createdAt,  String? resourceId,  String? entityType,  String? entityId,  int priority,  String? nextRetryAt,  String? dependencyClientOpId)?  $default,) {final _that = this;
switch (_that) {
case _SyncQueueEntry() when $default != null:
return $default(_that.clientOpId,_that.opType,_that.payload,_that.status,_that.attempts,_that.lastError,_that.lastAttemptAt,_that.createdAt,_that.resourceId,_that.entityType,_that.entityId,_that.priority,_that.nextRetryAt,_that.dependencyClientOpId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncQueueEntry extends SyncQueueEntry {
  const _SyncQueueEntry({required this.clientOpId, required this.opType, required  Map<String, dynamic> payload, required this.status, this.attempts = 0, this.lastError, this.lastAttemptAt, this.createdAt, this.resourceId, this.entityType, this.entityId, this.priority = 0, this.nextRetryAt, this.dependencyClientOpId}): _payload = payload,super._();
  factory _SyncQueueEntry.fromJson(Map<String, dynamic> json) => _$SyncQueueEntryFromJson(json);

@override final  String clientOpId;
@override final  String opType;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  SyncQueueStatus status;
@override@JsonKey() final  int attempts;
@override final  String? lastError;
@override final  String? lastAttemptAt;
@override final  String? createdAt;
@override final  String? resourceId;
/// Logical entity kind ("FIELD_REPORT", "MEDIA", "GPS_PING", ...).
/// Lets the UI/flush policy reason about the queue without parsing
/// opType. Optional so existing call-sites are not broken.
@override final  String? entityType;
/// Server-side ID of the entity once the server has acknowledged it
/// (different from [resourceId] which records the op-result id).
@override final  String? entityId;
/// Higher = should flush first. 0 is the default; 100 = critical
/// (e.g. CRITICAL_FIELD_REPORT).
@override@JsonKey() final  int priority;
/// ISO-8601 wall-clock instant when this entry becomes eligible for
/// the next flush attempt. NULL = ready now.
@override final  String? nextRetryAt;
/// client_op_id of the op that must succeed BEFORE this one. Used to
/// attach a media op to its parent field-report submission, etc.
@override final  String? dependencyClientOpId;

/// Create a copy of SyncQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncQueueEntryCopyWith<_SyncQueueEntry> get copyWith => __$SyncQueueEntryCopyWithImpl<_SyncQueueEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncQueueEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncQueueEntry&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.opType, opType) || other.opType == opType)&&const DeepCollectionEquality().equals(other.payload, _payload)&&(identical(other.status, status) || other.status == status)&&(identical(other.attempts, attempts) || other.attempts == attempts)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.nextRetryAt, nextRetryAt) || other.nextRetryAt == nextRetryAt)&&(identical(other.dependencyClientOpId, dependencyClientOpId) || other.dependencyClientOpId == dependencyClientOpId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,opType,const DeepCollectionEquality().hash(_payload),status,attempts,lastError,lastAttemptAt,createdAt,resourceId,entityType,entityId,priority,nextRetryAt,dependencyClientOpId);
}

@override
String toString() {
    return 'SyncQueueEntry(clientOpId: $clientOpId, opType: $opType, payload: $payload, status: $status, attempts: $attempts, lastError: $lastError, lastAttemptAt: $lastAttemptAt, createdAt: $createdAt, resourceId: $resourceId, entityType: $entityType, entityId: $entityId, priority: $priority, nextRetryAt: $nextRetryAt, dependencyClientOpId: $dependencyClientOpId)';
}


}

/// @nodoc
abstract mixin class _$SyncQueueEntryCopyWith<$Res> implements $SyncQueueEntryCopyWith<$Res> {
  factory _$SyncQueueEntryCopyWith(_SyncQueueEntry value, $Res Function(_SyncQueueEntry) _then) = __$SyncQueueEntryCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, String opType, Map<String, dynamic> payload, SyncQueueStatus status, int attempts, String? lastError, String? lastAttemptAt, String? createdAt, String? resourceId, String? entityType, String? entityId, int priority, String? nextRetryAt, String? dependencyClientOpId
});




}
/// @nodoc
class __$SyncQueueEntryCopyWithImpl<$Res>
    implements _$SyncQueueEntryCopyWith<$Res> {
  __$SyncQueueEntryCopyWithImpl(this._self, this._then);

  final _SyncQueueEntry _self;
  final $Res Function(_SyncQueueEntry) _then;

/// Create a copy of SyncQueueEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? opType = null,Object? payload = null,Object? status = null,Object? attempts = null,Object? lastError = freezed,Object? lastAttemptAt = freezed,Object? createdAt = freezed,Object? resourceId = freezed,Object? entityType = freezed,Object? entityId = freezed,Object? priority = null,Object? nextRetryAt = freezed,Object? dependencyClientOpId = freezed,}) {
  return _then(_SyncQueueEntry(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,opType: null == opType ? _self.opType : opType // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SyncQueueStatus,attempts: null == attempts ? _self.attempts : attempts // ignore: cast_nullable_to_non_nullable
as int,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,entityType: freezed == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String?,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,nextRetryAt: freezed == nextRetryAt ? _self.nextRetryAt : nextRetryAt // ignore: cast_nullable_to_non_nullable
as String?,dependencyClientOpId: freezed == dependencyClientOpId ? _self.dependencyClientOpId : dependencyClientOpId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SyncAttempt {

 String get clientOpId; int get attempt; String get at; String get outcome; String? get reason; String? get resourceId;
/// Create a copy of SyncAttempt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncAttemptCopyWith<SyncAttempt> get copyWith => _$SyncAttemptCopyWithImpl<SyncAttempt>(this as SyncAttempt, _$identity);

  /// Serializes this SyncAttempt to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncAttempt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncAttempt&&(identical(other.clientOpId, _this.clientOpId) || other.clientOpId == _this.clientOpId)&&(identical(other.attempt, _this.attempt) || other.attempt == _this.attempt)&&(identical(other.at, _this.at) || other.at == _this.at)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.reason, _this.reason) || other.reason == _this.reason)&&(identical(other.resourceId, _this.resourceId) || other.resourceId == _this.resourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncAttempt;
  return Object.hash(runtimeType,_this.clientOpId,_this.attempt,_this.at,_this.outcome,_this.reason,_this.resourceId);
}

@override
String toString() {
  final _this = this as SyncAttempt;
  return 'SyncAttempt(clientOpId: ${_this.clientOpId}, attempt: ${_this.attempt}, at: ${_this.at}, outcome: ${_this.outcome}, reason: ${_this.reason}, resourceId: ${_this.resourceId})';
}


}

/// @nodoc
abstract mixin class $SyncAttemptCopyWith<$Res>  {
  factory $SyncAttemptCopyWith(SyncAttempt value, $Res Function(SyncAttempt) _then) = _$SyncAttemptCopyWithImpl;
@useResult
$Res call({
 String clientOpId, int attempt, String at, String outcome, String? reason, String? resourceId
});




}
/// @nodoc
class _$SyncAttemptCopyWithImpl<$Res>
    implements $SyncAttemptCopyWith<$Res> {
  _$SyncAttemptCopyWithImpl(this._self, this._then);

  final SyncAttempt _self;
  final $Res Function(SyncAttempt) _then;

/// Create a copy of SyncAttempt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientOpId = null,Object? attempt = null,Object? at = null,Object? outcome = null,Object? reason = freezed,Object? resourceId = freezed,}) {
  return _then(SyncAttempt(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncAttempt].
extension SyncAttemptPatterns on SyncAttempt {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncAttempt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncAttempt() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncAttempt value)  $default,){
final _that = this;
switch (_that) {
case _SyncAttempt():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncAttempt value)?  $default,){
final _that = this;
switch (_that) {
case _SyncAttempt() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientOpId,  int attempt,  String at,  String outcome,  String? reason,  String? resourceId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncAttempt() when $default != null:
return $default(_that.clientOpId,_that.attempt,_that.at,_that.outcome,_that.reason,_that.resourceId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientOpId,  int attempt,  String at,  String outcome,  String? reason,  String? resourceId)  $default,) {final _that = this;
switch (_that) {
case _SyncAttempt():
return $default(_that.clientOpId,_that.attempt,_that.at,_that.outcome,_that.reason,_that.resourceId);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientOpId,  int attempt,  String at,  String outcome,  String? reason,  String? resourceId)?  $default,) {final _that = this;
switch (_that) {
case _SyncAttempt() when $default != null:
return $default(_that.clientOpId,_that.attempt,_that.at,_that.outcome,_that.reason,_that.resourceId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncAttempt implements SyncAttempt {
  const _SyncAttempt({required this.clientOpId, required this.attempt, required this.at, required this.outcome, this.reason, this.resourceId});
  factory _SyncAttempt.fromJson(Map<String, dynamic> json) => _$SyncAttemptFromJson(json);

@override final  String clientOpId;
@override final  int attempt;
@override final  String at;
@override final  String outcome;
@override final  String? reason;
@override final  String? resourceId;

/// Create a copy of SyncAttempt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncAttemptCopyWith<_SyncAttempt> get copyWith => __$SyncAttemptCopyWithImpl<_SyncAttempt>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncAttemptToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncAttempt&&(identical(other.clientOpId, clientOpId) || other.clientOpId == clientOpId)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.at, at) || other.at == at)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.resourceId, resourceId) || other.resourceId == resourceId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,clientOpId,attempt,at,outcome,reason,resourceId);
}

@override
String toString() {
    return 'SyncAttempt(clientOpId: $clientOpId, attempt: $attempt, at: $at, outcome: $outcome, reason: $reason, resourceId: $resourceId)';
}


}

/// @nodoc
abstract mixin class _$SyncAttemptCopyWith<$Res> implements $SyncAttemptCopyWith<$Res> {
  factory _$SyncAttemptCopyWith(_SyncAttempt value, $Res Function(_SyncAttempt) _then) = __$SyncAttemptCopyWithImpl;
@override @useResult
$Res call({
 String clientOpId, int attempt, String at, String outcome, String? reason, String? resourceId
});




}
/// @nodoc
class __$SyncAttemptCopyWithImpl<$Res>
    implements _$SyncAttemptCopyWith<$Res> {
  __$SyncAttemptCopyWithImpl(this._self, this._then);

  final _SyncAttempt _self;
  final $Res Function(_SyncAttempt) _then;

/// Create a copy of SyncAttempt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientOpId = null,Object? attempt = null,Object? at = null,Object? outcome = null,Object? reason = freezed,Object? resourceId = freezed,}) {
  return _then(_SyncAttempt(
clientOpId: null == clientOpId ? _self.clientOpId : clientOpId // ignore: cast_nullable_to_non_nullable
as String,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,resourceId: freezed == resourceId ? _self.resourceId : resourceId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

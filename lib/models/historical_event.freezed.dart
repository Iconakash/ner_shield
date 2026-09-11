// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'historical_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoricalEvent {

 String get id; String? get title; String? get description; String? get eventType; String? get occurredAt; String? get districtCode; String? get stateCode;@JsonKey(name: 'data_quality') String? get dataQuality;@JsonKey(name: 'dataset_version') String? get datasetVersion;@JsonKey(name: 'observation_count') int? get observationCount;@JsonKey(name: 'latest_run') Map<String, dynamic>? get latestRun;
/// Create a copy of HistoricalEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoricalEventCopyWith<HistoricalEvent> get copyWith => _$HistoricalEventCopyWithImpl<HistoricalEvent>(this as HistoricalEvent, _$identity);

  /// Serializes this HistoricalEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HistoricalEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoricalEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.eventType, _this.eventType) || other.eventType == _this.eventType)&&(identical(other.occurredAt, _this.occurredAt) || other.occurredAt == _this.occurredAt)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.dataQuality, _this.dataQuality) || other.dataQuality == _this.dataQuality)&&(identical(other.datasetVersion, _this.datasetVersion) || other.datasetVersion == _this.datasetVersion)&&(identical(other.observationCount, _this.observationCount) || other.observationCount == _this.observationCount)&&const DeepCollectionEquality().equals(other.latestRun, _this.latestRun));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HistoricalEvent;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.eventType,_this.occurredAt,_this.districtCode,_this.stateCode,_this.dataQuality,_this.datasetVersion,_this.observationCount,const DeepCollectionEquality().hash(_this.latestRun));
}

@override
String toString() {
  final _this = this as HistoricalEvent;
  return 'HistoricalEvent(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, eventType: ${_this.eventType}, occurredAt: ${_this.occurredAt}, districtCode: ${_this.districtCode}, stateCode: ${_this.stateCode}, dataQuality: ${_this.dataQuality}, datasetVersion: ${_this.datasetVersion}, observationCount: ${_this.observationCount}, latestRun: ${_this.latestRun})';
}


}

/// @nodoc
abstract mixin class $HistoricalEventCopyWith<$Res>  {
  factory $HistoricalEventCopyWith(HistoricalEvent value, $Res Function(HistoricalEvent) _then) = _$HistoricalEventCopyWithImpl;
@useResult
$Res call({
 String id, String? title, String? description, String? eventType, String? occurredAt, String? districtCode, String? stateCode,@JsonKey(name: 'data_quality') String? dataQuality,@JsonKey(name: 'dataset_version') String? datasetVersion,@JsonKey(name: 'observation_count') int? observationCount,@JsonKey(name: 'latest_run') Map<String, dynamic>? latestRun
});




}
/// @nodoc
class _$HistoricalEventCopyWithImpl<$Res>
    implements $HistoricalEventCopyWith<$Res> {
  _$HistoricalEventCopyWithImpl(this._self, this._then);

  final HistoricalEvent _self;
  final $Res Function(HistoricalEvent) _then;

/// Create a copy of HistoricalEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? eventType = freezed,Object? occurredAt = freezed,Object? districtCode = freezed,Object? stateCode = freezed,Object? dataQuality = freezed,Object? datasetVersion = freezed,Object? observationCount = freezed,Object? latestRun = freezed,}) {
  return _then(HistoricalEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,dataQuality: freezed == dataQuality ? _self.dataQuality : dataQuality // ignore: cast_nullable_to_non_nullable
as String?,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,observationCount: freezed == observationCount ? _self.observationCount : observationCount // ignore: cast_nullable_to_non_nullable
as int?,latestRun: freezed == latestRun ? _self.latestRun : latestRun // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoricalEvent].
extension HistoricalEventPatterns on HistoricalEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoricalEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoricalEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoricalEvent value)  $default,){
final _that = this;
switch (_that) {
case _HistoricalEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoricalEvent value)?  $default,){
final _that = this;
switch (_that) {
case _HistoricalEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? eventType,  String? occurredAt,  String? districtCode,  String? stateCode, @JsonKey(name: 'data_quality')  String? dataQuality, @JsonKey(name: 'dataset_version')  String? datasetVersion, @JsonKey(name: 'observation_count')  int? observationCount, @JsonKey(name: 'latest_run')  Map<String, dynamic>? latestRun)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoricalEvent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.eventType,_that.occurredAt,_that.districtCode,_that.stateCode,_that.dataQuality,_that.datasetVersion,_that.observationCount,_that.latestRun);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? title,  String? description,  String? eventType,  String? occurredAt,  String? districtCode,  String? stateCode, @JsonKey(name: 'data_quality')  String? dataQuality, @JsonKey(name: 'dataset_version')  String? datasetVersion, @JsonKey(name: 'observation_count')  int? observationCount, @JsonKey(name: 'latest_run')  Map<String, dynamic>? latestRun)  $default,) {final _that = this;
switch (_that) {
case _HistoricalEvent():
return $default(_that.id,_that.title,_that.description,_that.eventType,_that.occurredAt,_that.districtCode,_that.stateCode,_that.dataQuality,_that.datasetVersion,_that.observationCount,_that.latestRun);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? title,  String? description,  String? eventType,  String? occurredAt,  String? districtCode,  String? stateCode, @JsonKey(name: 'data_quality')  String? dataQuality, @JsonKey(name: 'dataset_version')  String? datasetVersion, @JsonKey(name: 'observation_count')  int? observationCount, @JsonKey(name: 'latest_run')  Map<String, dynamic>? latestRun)?  $default,) {final _that = this;
switch (_that) {
case _HistoricalEvent() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.eventType,_that.occurredAt,_that.districtCode,_that.stateCode,_that.dataQuality,_that.datasetVersion,_that.observationCount,_that.latestRun);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoricalEvent extends HistoricalEvent {
  const _HistoricalEvent({required this.id, this.title, this.description, this.eventType, this.occurredAt, this.districtCode, this.stateCode, @JsonKey(name: 'data_quality') this.dataQuality, @JsonKey(name: 'dataset_version') this.datasetVersion, @JsonKey(name: 'observation_count') this.observationCount, @JsonKey(name: 'latest_run')  Map<String, dynamic>? latestRun}): _latestRun = latestRun,super._();
  factory _HistoricalEvent.fromJson(Map<String, dynamic> json) => _$HistoricalEventFromJson(json);

@override final  String id;
@override final  String? title;
@override final  String? description;
@override final  String? eventType;
@override final  String? occurredAt;
@override final  String? districtCode;
@override final  String? stateCode;
@override@JsonKey(name: 'data_quality') final  String? dataQuality;
@override@JsonKey(name: 'dataset_version') final  String? datasetVersion;
@override@JsonKey(name: 'observation_count') final  int? observationCount;
 final  Map<String, dynamic>? _latestRun;
@override@JsonKey(name: 'latest_run') Map<String, dynamic>? get latestRun {
  final value = _latestRun;
  if (value == null) return null;
  if (_latestRun is EqualUnmodifiableMapView) return _latestRun;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of HistoricalEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoricalEventCopyWith<_HistoricalEvent> get copyWith => __$HistoricalEventCopyWithImpl<_HistoricalEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoricalEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoricalEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.dataQuality, dataQuality) || other.dataQuality == dataQuality)&&(identical(other.datasetVersion, datasetVersion) || other.datasetVersion == datasetVersion)&&(identical(other.observationCount, observationCount) || other.observationCount == observationCount)&&const DeepCollectionEquality().equals(other.latestRun, _latestRun));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,description,eventType,occurredAt,districtCode,stateCode,dataQuality,datasetVersion,observationCount,const DeepCollectionEquality().hash(_latestRun));
}

@override
String toString() {
    return 'HistoricalEvent(id: $id, title: $title, description: $description, eventType: $eventType, occurredAt: $occurredAt, districtCode: $districtCode, stateCode: $stateCode, dataQuality: $dataQuality, datasetVersion: $datasetVersion, observationCount: $observationCount, latestRun: $latestRun)';
}


}

/// @nodoc
abstract mixin class _$HistoricalEventCopyWith<$Res> implements $HistoricalEventCopyWith<$Res> {
  factory _$HistoricalEventCopyWith(_HistoricalEvent value, $Res Function(_HistoricalEvent) _then) = __$HistoricalEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String? title, String? description, String? eventType, String? occurredAt, String? districtCode, String? stateCode,@JsonKey(name: 'data_quality') String? dataQuality,@JsonKey(name: 'dataset_version') String? datasetVersion,@JsonKey(name: 'observation_count') int? observationCount,@JsonKey(name: 'latest_run') Map<String, dynamic>? latestRun
});




}
/// @nodoc
class __$HistoricalEventCopyWithImpl<$Res>
    implements _$HistoricalEventCopyWith<$Res> {
  __$HistoricalEventCopyWithImpl(this._self, this._then);

  final _HistoricalEvent _self;
  final $Res Function(_HistoricalEvent) _then;

/// Create a copy of HistoricalEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = freezed,Object? description = freezed,Object? eventType = freezed,Object? occurredAt = freezed,Object? districtCode = freezed,Object? stateCode = freezed,Object? dataQuality = freezed,Object? datasetVersion = freezed,Object? observationCount = freezed,Object? latestRun = freezed,}) {
  return _then(_HistoricalEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,eventType: freezed == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,dataQuality: freezed == dataQuality ? _self.dataQuality : dataQuality // ignore: cast_nullable_to_non_nullable
as String?,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,observationCount: freezed == observationCount ? _self.observationCount : observationCount // ignore: cast_nullable_to_non_nullable
as int?,latestRun: freezed == latestRun ? _self._latestRun : latestRun // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$HistoricalValidationRun {

 String get id;@JsonKey(name: 'event_id') String? get eventId;@JsonKey(name: 'model_name') String? get modelName;@JsonKey(name: 'model_version') String? get modelVersion;@JsonKey(name: 'dataset_version') String? get datasetVersion; Map<String, dynamic>? get metrics;@JsonKey(name: 'ran_at') String? get ranAt;
/// Create a copy of HistoricalValidationRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoricalValidationRunCopyWith<HistoricalValidationRun> get copyWith => _$HistoricalValidationRunCopyWithImpl<HistoricalValidationRun>(this as HistoricalValidationRun, _$identity);

  /// Serializes this HistoricalValidationRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HistoricalValidationRun;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoricalValidationRun&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.eventId, _this.eventId) || other.eventId == _this.eventId)&&(identical(other.modelName, _this.modelName) || other.modelName == _this.modelName)&&(identical(other.modelVersion, _this.modelVersion) || other.modelVersion == _this.modelVersion)&&(identical(other.datasetVersion, _this.datasetVersion) || other.datasetVersion == _this.datasetVersion)&&const DeepCollectionEquality().equals(other.metrics, _this.metrics)&&(identical(other.ranAt, _this.ranAt) || other.ranAt == _this.ranAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HistoricalValidationRun;
  return Object.hash(runtimeType,_this.id,_this.eventId,_this.modelName,_this.modelVersion,_this.datasetVersion,const DeepCollectionEquality().hash(_this.metrics),_this.ranAt);
}

@override
String toString() {
  final _this = this as HistoricalValidationRun;
  return 'HistoricalValidationRun(id: ${_this.id}, eventId: ${_this.eventId}, modelName: ${_this.modelName}, modelVersion: ${_this.modelVersion}, datasetVersion: ${_this.datasetVersion}, metrics: ${_this.metrics}, ranAt: ${_this.ranAt})';
}


}

/// @nodoc
abstract mixin class $HistoricalValidationRunCopyWith<$Res>  {
  factory $HistoricalValidationRunCopyWith(HistoricalValidationRun value, $Res Function(HistoricalValidationRun) _then) = _$HistoricalValidationRunCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'model_name') String? modelName,@JsonKey(name: 'model_version') String? modelVersion,@JsonKey(name: 'dataset_version') String? datasetVersion, Map<String, dynamic>? metrics,@JsonKey(name: 'ran_at') String? ranAt
});




}
/// @nodoc
class _$HistoricalValidationRunCopyWithImpl<$Res>
    implements $HistoricalValidationRunCopyWith<$Res> {
  _$HistoricalValidationRunCopyWithImpl(this._self, this._then);

  final HistoricalValidationRun _self;
  final $Res Function(HistoricalValidationRun) _then;

/// Create a copy of HistoricalValidationRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventId = freezed,Object? modelName = freezed,Object? modelVersion = freezed,Object? datasetVersion = freezed,Object? metrics = freezed,Object? ranAt = freezed,}) {
  return _then(HistoricalValidationRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,ranAt: freezed == ranAt ? _self.ranAt : ranAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoricalValidationRun].
extension HistoricalValidationRunPatterns on HistoricalValidationRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoricalValidationRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoricalValidationRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoricalValidationRun value)  $default,){
final _that = this;
switch (_that) {
case _HistoricalValidationRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoricalValidationRun value)?  $default,){
final _that = this;
switch (_that) {
case _HistoricalValidationRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'model_name')  String? modelName, @JsonKey(name: 'model_version')  String? modelVersion, @JsonKey(name: 'dataset_version')  String? datasetVersion,  Map<String, dynamic>? metrics, @JsonKey(name: 'ran_at')  String? ranAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoricalValidationRun() when $default != null:
return $default(_that.id,_that.eventId,_that.modelName,_that.modelVersion,_that.datasetVersion,_that.metrics,_that.ranAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'model_name')  String? modelName, @JsonKey(name: 'model_version')  String? modelVersion, @JsonKey(name: 'dataset_version')  String? datasetVersion,  Map<String, dynamic>? metrics, @JsonKey(name: 'ran_at')  String? ranAt)  $default,) {final _that = this;
switch (_that) {
case _HistoricalValidationRun():
return $default(_that.id,_that.eventId,_that.modelName,_that.modelVersion,_that.datasetVersion,_that.metrics,_that.ranAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'event_id')  String? eventId, @JsonKey(name: 'model_name')  String? modelName, @JsonKey(name: 'model_version')  String? modelVersion, @JsonKey(name: 'dataset_version')  String? datasetVersion,  Map<String, dynamic>? metrics, @JsonKey(name: 'ran_at')  String? ranAt)?  $default,) {final _that = this;
switch (_that) {
case _HistoricalValidationRun() when $default != null:
return $default(_that.id,_that.eventId,_that.modelName,_that.modelVersion,_that.datasetVersion,_that.metrics,_that.ranAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoricalValidationRun implements HistoricalValidationRun {
  const _HistoricalValidationRun({required this.id, @JsonKey(name: 'event_id') this.eventId, @JsonKey(name: 'model_name') this.modelName, @JsonKey(name: 'model_version') this.modelVersion, @JsonKey(name: 'dataset_version') this.datasetVersion,  Map<String, dynamic>? metrics, @JsonKey(name: 'ran_at') this.ranAt}): _metrics = metrics;
  factory _HistoricalValidationRun.fromJson(Map<String, dynamic> json) => _$HistoricalValidationRunFromJson(json);

@override final  String id;
@override@JsonKey(name: 'event_id') final  String? eventId;
@override@JsonKey(name: 'model_name') final  String? modelName;
@override@JsonKey(name: 'model_version') final  String? modelVersion;
@override@JsonKey(name: 'dataset_version') final  String? datasetVersion;
 final  Map<String, dynamic>? _metrics;
@override Map<String, dynamic>? get metrics {
  final value = _metrics;
  if (value == null) return null;
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(name: 'ran_at') final  String? ranAt;

/// Create a copy of HistoricalValidationRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoricalValidationRunCopyWith<_HistoricalValidationRun> get copyWith => __$HistoricalValidationRunCopyWithImpl<_HistoricalValidationRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoricalValidationRunToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoricalValidationRun&&(identical(other.id, id) || other.id == id)&&(identical(other.eventId, eventId) || other.eventId == eventId)&&(identical(other.modelName, modelName) || other.modelName == modelName)&&(identical(other.modelVersion, modelVersion) || other.modelVersion == modelVersion)&&(identical(other.datasetVersion, datasetVersion) || other.datasetVersion == datasetVersion)&&const DeepCollectionEquality().equals(other.metrics, _metrics)&&(identical(other.ranAt, ranAt) || other.ranAt == ranAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,eventId,modelName,modelVersion,datasetVersion,const DeepCollectionEquality().hash(_metrics),ranAt);
}

@override
String toString() {
    return 'HistoricalValidationRun(id: $id, eventId: $eventId, modelName: $modelName, modelVersion: $modelVersion, datasetVersion: $datasetVersion, metrics: $metrics, ranAt: $ranAt)';
}


}

/// @nodoc
abstract mixin class _$HistoricalValidationRunCopyWith<$Res> implements $HistoricalValidationRunCopyWith<$Res> {
  factory _$HistoricalValidationRunCopyWith(_HistoricalValidationRun value, $Res Function(_HistoricalValidationRun) _then) = __$HistoricalValidationRunCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'event_id') String? eventId,@JsonKey(name: 'model_name') String? modelName,@JsonKey(name: 'model_version') String? modelVersion,@JsonKey(name: 'dataset_version') String? datasetVersion, Map<String, dynamic>? metrics,@JsonKey(name: 'ran_at') String? ranAt
});




}
/// @nodoc
class __$HistoricalValidationRunCopyWithImpl<$Res>
    implements _$HistoricalValidationRunCopyWith<$Res> {
  __$HistoricalValidationRunCopyWithImpl(this._self, this._then);

  final _HistoricalValidationRun _self;
  final $Res Function(_HistoricalValidationRun) _then;

/// Create a copy of HistoricalValidationRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventId = freezed,Object? modelName = freezed,Object? modelVersion = freezed,Object? datasetVersion = freezed,Object? metrics = freezed,Object? ranAt = freezed,}) {
  return _then(_HistoricalValidationRun(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,eventId: freezed == eventId ? _self.eventId : eventId // ignore: cast_nullable_to_non_nullable
as String?,modelName: freezed == modelName ? _self.modelName : modelName // ignore: cast_nullable_to_non_nullable
as String?,modelVersion: freezed == modelVersion ? _self.modelVersion : modelVersion // ignore: cast_nullable_to_non_nullable
as String?,datasetVersion: freezed == datasetVersion ? _self.datasetVersion : datasetVersion // ignore: cast_nullable_to_non_nullable
as String?,metrics: freezed == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,ranAt: freezed == ranAt ? _self.ranAt : ranAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'responder.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Responder {

 String get id; String? get name;@JsonKey(name: 'responder_type') String? get responderType;@JsonKey(name: 'operational_status') String? get operationalStatus;@JsonKey(name: 'district_code') String? get districtCode;@JsonKey(name: 'state_code') String? get stateCode;@JsonKey(name: 'contact_method') String? get contactMethod;@JsonKey(name: 'is_demo') bool? get isDemo;@JsonKey(name: 'escalation_priority') int? get escalationPriority; Map<String, dynamic>? get geo;
/// Create a copy of Responder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResponderCopyWith<Responder> get copyWith => _$ResponderCopyWithImpl<Responder>(this as Responder, _$identity);

  /// Serializes this Responder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Responder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Responder&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.responderType, _this.responderType) || other.responderType == _this.responderType)&&(identical(other.operationalStatus, _this.operationalStatus) || other.operationalStatus == _this.operationalStatus)&&(identical(other.districtCode, _this.districtCode) || other.districtCode == _this.districtCode)&&(identical(other.stateCode, _this.stateCode) || other.stateCode == _this.stateCode)&&(identical(other.contactMethod, _this.contactMethod) || other.contactMethod == _this.contactMethod)&&(identical(other.isDemo, _this.isDemo) || other.isDemo == _this.isDemo)&&(identical(other.escalationPriority, _this.escalationPriority) || other.escalationPriority == _this.escalationPriority)&&const DeepCollectionEquality().equals(other.geo, _this.geo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Responder;
  return Object.hash(runtimeType,_this.id,_this.name,_this.responderType,_this.operationalStatus,_this.districtCode,_this.stateCode,_this.contactMethod,_this.isDemo,_this.escalationPriority,const DeepCollectionEquality().hash(_this.geo));
}

@override
String toString() {
  final _this = this as Responder;
  return 'Responder(id: ${_this.id}, name: ${_this.name}, responderType: ${_this.responderType}, operationalStatus: ${_this.operationalStatus}, districtCode: ${_this.districtCode}, stateCode: ${_this.stateCode}, contactMethod: ${_this.contactMethod}, isDemo: ${_this.isDemo}, escalationPriority: ${_this.escalationPriority}, geo: ${_this.geo})';
}


}

/// @nodoc
abstract mixin class $ResponderCopyWith<$Res>  {
  factory $ResponderCopyWith(Responder value, $Res Function(Responder) _then) = _$ResponderCopyWithImpl;
@useResult
$Res call({
 String id, String? name,@JsonKey(name: 'responder_type') String? responderType,@JsonKey(name: 'operational_status') String? operationalStatus,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'contact_method') String? contactMethod,@JsonKey(name: 'is_demo') bool? isDemo,@JsonKey(name: 'escalation_priority') int? escalationPriority, Map<String, dynamic>? geo
});




}
/// @nodoc
class _$ResponderCopyWithImpl<$Res>
    implements $ResponderCopyWith<$Res> {
  _$ResponderCopyWithImpl(this._self, this._then);

  final Responder _self;
  final $Res Function(Responder) _then;

/// Create a copy of Responder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? responderType = freezed,Object? operationalStatus = freezed,Object? districtCode = freezed,Object? stateCode = freezed,Object? contactMethod = freezed,Object? isDemo = freezed,Object? escalationPriority = freezed,Object? geo = freezed,}) {
  return _then(Responder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,responderType: freezed == responderType ? _self.responderType : responderType // ignore: cast_nullable_to_non_nullable
as String?,operationalStatus: freezed == operationalStatus ? _self.operationalStatus : operationalStatus // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,contactMethod: freezed == contactMethod ? _self.contactMethod : contactMethod // ignore: cast_nullable_to_non_nullable
as String?,isDemo: freezed == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool?,escalationPriority: freezed == escalationPriority ? _self.escalationPriority : escalationPriority // ignore: cast_nullable_to_non_nullable
as int?,geo: freezed == geo ? _self.geo : geo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [Responder].
extension ResponderPatterns on Responder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Responder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Responder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Responder value)  $default,){
final _that = this;
switch (_that) {
case _Responder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Responder value)?  $default,){
final _that = this;
switch (_that) {
case _Responder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name, @JsonKey(name: 'responder_type')  String? responderType, @JsonKey(name: 'operational_status')  String? operationalStatus, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'contact_method')  String? contactMethod, @JsonKey(name: 'is_demo')  bool? isDemo, @JsonKey(name: 'escalation_priority')  int? escalationPriority,  Map<String, dynamic>? geo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Responder() when $default != null:
return $default(_that.id,_that.name,_that.responderType,_that.operationalStatus,_that.districtCode,_that.stateCode,_that.contactMethod,_that.isDemo,_that.escalationPriority,_that.geo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name, @JsonKey(name: 'responder_type')  String? responderType, @JsonKey(name: 'operational_status')  String? operationalStatus, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'contact_method')  String? contactMethod, @JsonKey(name: 'is_demo')  bool? isDemo, @JsonKey(name: 'escalation_priority')  int? escalationPriority,  Map<String, dynamic>? geo)  $default,) {final _that = this;
switch (_that) {
case _Responder():
return $default(_that.id,_that.name,_that.responderType,_that.operationalStatus,_that.districtCode,_that.stateCode,_that.contactMethod,_that.isDemo,_that.escalationPriority,_that.geo);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name, @JsonKey(name: 'responder_type')  String? responderType, @JsonKey(name: 'operational_status')  String? operationalStatus, @JsonKey(name: 'district_code')  String? districtCode, @JsonKey(name: 'state_code')  String? stateCode, @JsonKey(name: 'contact_method')  String? contactMethod, @JsonKey(name: 'is_demo')  bool? isDemo, @JsonKey(name: 'escalation_priority')  int? escalationPriority,  Map<String, dynamic>? geo)?  $default,) {final _that = this;
switch (_that) {
case _Responder() when $default != null:
return $default(_that.id,_that.name,_that.responderType,_that.operationalStatus,_that.districtCode,_that.stateCode,_that.contactMethod,_that.isDemo,_that.escalationPriority,_that.geo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Responder extends Responder {
  const _Responder({required this.id, this.name, @JsonKey(name: 'responder_type') this.responderType, @JsonKey(name: 'operational_status') this.operationalStatus, @JsonKey(name: 'district_code') this.districtCode, @JsonKey(name: 'state_code') this.stateCode, @JsonKey(name: 'contact_method') this.contactMethod, @JsonKey(name: 'is_demo') this.isDemo, @JsonKey(name: 'escalation_priority') this.escalationPriority,  Map<String, dynamic>? geo}): _geo = geo,super._();
  factory _Responder.fromJson(Map<String, dynamic> json) => _$ResponderFromJson(json);

@override final  String id;
@override final  String? name;
@override@JsonKey(name: 'responder_type') final  String? responderType;
@override@JsonKey(name: 'operational_status') final  String? operationalStatus;
@override@JsonKey(name: 'district_code') final  String? districtCode;
@override@JsonKey(name: 'state_code') final  String? stateCode;
@override@JsonKey(name: 'contact_method') final  String? contactMethod;
@override@JsonKey(name: 'is_demo') final  bool? isDemo;
@override@JsonKey(name: 'escalation_priority') final  int? escalationPriority;
 final  Map<String, dynamic>? _geo;
@override Map<String, dynamic>? get geo {
  final value = _geo;
  if (value == null) return null;
  if (_geo is EqualUnmodifiableMapView) return _geo;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of Responder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResponderCopyWith<_Responder> get copyWith => __$ResponderCopyWithImpl<_Responder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResponderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Responder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.responderType, responderType) || other.responderType == responderType)&&(identical(other.operationalStatus, operationalStatus) || other.operationalStatus == operationalStatus)&&(identical(other.districtCode, districtCode) || other.districtCode == districtCode)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.contactMethod, contactMethod) || other.contactMethod == contactMethod)&&(identical(other.isDemo, isDemo) || other.isDemo == isDemo)&&(identical(other.escalationPriority, escalationPriority) || other.escalationPriority == escalationPriority)&&const DeepCollectionEquality().equals(other.geo, _geo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,responderType,operationalStatus,districtCode,stateCode,contactMethod,isDemo,escalationPriority,const DeepCollectionEquality().hash(_geo));
}

@override
String toString() {
    return 'Responder(id: $id, name: $name, responderType: $responderType, operationalStatus: $operationalStatus, districtCode: $districtCode, stateCode: $stateCode, contactMethod: $contactMethod, isDemo: $isDemo, escalationPriority: $escalationPriority, geo: $geo)';
}


}

/// @nodoc
abstract mixin class _$ResponderCopyWith<$Res> implements $ResponderCopyWith<$Res> {
  factory _$ResponderCopyWith(_Responder value, $Res Function(_Responder) _then) = __$ResponderCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name,@JsonKey(name: 'responder_type') String? responderType,@JsonKey(name: 'operational_status') String? operationalStatus,@JsonKey(name: 'district_code') String? districtCode,@JsonKey(name: 'state_code') String? stateCode,@JsonKey(name: 'contact_method') String? contactMethod,@JsonKey(name: 'is_demo') bool? isDemo,@JsonKey(name: 'escalation_priority') int? escalationPriority, Map<String, dynamic>? geo
});




}
/// @nodoc
class __$ResponderCopyWithImpl<$Res>
    implements _$ResponderCopyWith<$Res> {
  __$ResponderCopyWithImpl(this._self, this._then);

  final _Responder _self;
  final $Res Function(_Responder) _then;

/// Create a copy of Responder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? responderType = freezed,Object? operationalStatus = freezed,Object? districtCode = freezed,Object? stateCode = freezed,Object? contactMethod = freezed,Object? isDemo = freezed,Object? escalationPriority = freezed,Object? geo = freezed,}) {
  return _then(_Responder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,responderType: freezed == responderType ? _self.responderType : responderType // ignore: cast_nullable_to_non_nullable
as String?,operationalStatus: freezed == operationalStatus ? _self.operationalStatus : operationalStatus // ignore: cast_nullable_to_non_nullable
as String?,districtCode: freezed == districtCode ? _self.districtCode : districtCode // ignore: cast_nullable_to_non_nullable
as String?,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,contactMethod: freezed == contactMethod ? _self.contactMethod : contactMethod // ignore: cast_nullable_to_non_nullable
as String?,isDemo: freezed == isDemo ? _self.isDemo : isDemo // ignore: cast_nullable_to_non_nullable
as bool?,escalationPriority: freezed == escalationPriority ? _self.escalationPriority : escalationPriority // ignore: cast_nullable_to_non_nullable
as int?,geo: freezed == geo ? _self._geo : geo // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$ResponseTask {

 String get id;@JsonKey(name: 'responder_id') String? get responderId;@JsonKey(name: 'responder_name') String? get responderName; String? get priority; String? get status; String? get title; String? get description;@JsonKey(name: 'related_alert_id') String? get relatedAlertId;@JsonKey(name: 'related_shipment_id') String? get relatedShipmentId;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'completed_at') String? get completedAt;
/// Create a copy of ResponseTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResponseTaskCopyWith<ResponseTask> get copyWith => _$ResponseTaskCopyWithImpl<ResponseTask>(this as ResponseTask, _$identity);

  /// Serializes this ResponseTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ResponseTask;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResponseTask&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.responderId, _this.responderId) || other.responderId == _this.responderId)&&(identical(other.responderName, _this.responderName) || other.responderName == _this.responderName)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.relatedAlertId, _this.relatedAlertId) || other.relatedAlertId == _this.relatedAlertId)&&(identical(other.relatedShipmentId, _this.relatedShipmentId) || other.relatedShipmentId == _this.relatedShipmentId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.completedAt, _this.completedAt) || other.completedAt == _this.completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ResponseTask;
  return Object.hash(runtimeType,_this.id,_this.responderId,_this.responderName,_this.priority,_this.status,_this.title,_this.description,_this.relatedAlertId,_this.relatedShipmentId,_this.createdAt,_this.completedAt);
}

@override
String toString() {
  final _this = this as ResponseTask;
  return 'ResponseTask(id: ${_this.id}, responderId: ${_this.responderId}, responderName: ${_this.responderName}, priority: ${_this.priority}, status: ${_this.status}, title: ${_this.title}, description: ${_this.description}, relatedAlertId: ${_this.relatedAlertId}, relatedShipmentId: ${_this.relatedShipmentId}, createdAt: ${_this.createdAt}, completedAt: ${_this.completedAt})';
}


}

/// @nodoc
abstract mixin class $ResponseTaskCopyWith<$Res>  {
  factory $ResponseTaskCopyWith(ResponseTask value, $Res Function(ResponseTask) _then) = _$ResponseTaskCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'responder_id') String? responderId,@JsonKey(name: 'responder_name') String? responderName, String? priority, String? status, String? title, String? description,@JsonKey(name: 'related_alert_id') String? relatedAlertId,@JsonKey(name: 'related_shipment_id') String? relatedShipmentId,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class _$ResponseTaskCopyWithImpl<$Res>
    implements $ResponseTaskCopyWith<$Res> {
  _$ResponseTaskCopyWithImpl(this._self, this._then);

  final ResponseTask _self;
  final $Res Function(ResponseTask) _then;

/// Create a copy of ResponseTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? responderId = freezed,Object? responderName = freezed,Object? priority = freezed,Object? status = freezed,Object? title = freezed,Object? description = freezed,Object? relatedAlertId = freezed,Object? relatedShipmentId = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(ResponseTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,responderId: freezed == responderId ? _self.responderId : responderId // ignore: cast_nullable_to_non_nullable
as String?,responderName: freezed == responderName ? _self.responderName : responderName // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,relatedAlertId: freezed == relatedAlertId ? _self.relatedAlertId : relatedAlertId // ignore: cast_nullable_to_non_nullable
as String?,relatedShipmentId: freezed == relatedShipmentId ? _self.relatedShipmentId : relatedShipmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ResponseTask].
extension ResponseTaskPatterns on ResponseTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResponseTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResponseTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResponseTask value)  $default,){
final _that = this;
switch (_that) {
case _ResponseTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResponseTask value)?  $default,){
final _that = this;
switch (_that) {
case _ResponseTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'responder_id')  String? responderId, @JsonKey(name: 'responder_name')  String? responderName,  String? priority,  String? status,  String? title,  String? description, @JsonKey(name: 'related_alert_id')  String? relatedAlertId, @JsonKey(name: 'related_shipment_id')  String? relatedShipmentId, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResponseTask() when $default != null:
return $default(_that.id,_that.responderId,_that.responderName,_that.priority,_that.status,_that.title,_that.description,_that.relatedAlertId,_that.relatedShipmentId,_that.createdAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'responder_id')  String? responderId, @JsonKey(name: 'responder_name')  String? responderName,  String? priority,  String? status,  String? title,  String? description, @JsonKey(name: 'related_alert_id')  String? relatedAlertId, @JsonKey(name: 'related_shipment_id')  String? relatedShipmentId, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)  $default,) {final _that = this;
switch (_that) {
case _ResponseTask():
return $default(_that.id,_that.responderId,_that.responderName,_that.priority,_that.status,_that.title,_that.description,_that.relatedAlertId,_that.relatedShipmentId,_that.createdAt,_that.completedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'responder_id')  String? responderId, @JsonKey(name: 'responder_name')  String? responderName,  String? priority,  String? status,  String? title,  String? description, @JsonKey(name: 'related_alert_id')  String? relatedAlertId, @JsonKey(name: 'related_shipment_id')  String? relatedShipmentId, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _ResponseTask() when $default != null:
return $default(_that.id,_that.responderId,_that.responderName,_that.priority,_that.status,_that.title,_that.description,_that.relatedAlertId,_that.relatedShipmentId,_that.createdAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResponseTask extends ResponseTask {
  const _ResponseTask({required this.id, @JsonKey(name: 'responder_id') this.responderId, @JsonKey(name: 'responder_name') this.responderName, this.priority, this.status, this.title, this.description, @JsonKey(name: 'related_alert_id') this.relatedAlertId, @JsonKey(name: 'related_shipment_id') this.relatedShipmentId, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'completed_at') this.completedAt}): super._();
  factory _ResponseTask.fromJson(Map<String, dynamic> json) => _$ResponseTaskFromJson(json);

@override final  String id;
@override@JsonKey(name: 'responder_id') final  String? responderId;
@override@JsonKey(name: 'responder_name') final  String? responderName;
@override final  String? priority;
@override final  String? status;
@override final  String? title;
@override final  String? description;
@override@JsonKey(name: 'related_alert_id') final  String? relatedAlertId;
@override@JsonKey(name: 'related_shipment_id') final  String? relatedShipmentId;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;

/// Create a copy of ResponseTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResponseTaskCopyWith<_ResponseTask> get copyWith => __$ResponseTaskCopyWithImpl<_ResponseTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResponseTaskToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResponseTask&&(identical(other.id, id) || other.id == id)&&(identical(other.responderId, responderId) || other.responderId == responderId)&&(identical(other.responderName, responderName) || other.responderName == responderName)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.relatedAlertId, relatedAlertId) || other.relatedAlertId == relatedAlertId)&&(identical(other.relatedShipmentId, relatedShipmentId) || other.relatedShipmentId == relatedShipmentId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,responderId,responderName,priority,status,title,description,relatedAlertId,relatedShipmentId,createdAt,completedAt);
}

@override
String toString() {
    return 'ResponseTask(id: $id, responderId: $responderId, responderName: $responderName, priority: $priority, status: $status, title: $title, description: $description, relatedAlertId: $relatedAlertId, relatedShipmentId: $relatedShipmentId, createdAt: $createdAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$ResponseTaskCopyWith<$Res> implements $ResponseTaskCopyWith<$Res> {
  factory _$ResponseTaskCopyWith(_ResponseTask value, $Res Function(_ResponseTask) _then) = __$ResponseTaskCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'responder_id') String? responderId,@JsonKey(name: 'responder_name') String? responderName, String? priority, String? status, String? title, String? description,@JsonKey(name: 'related_alert_id') String? relatedAlertId,@JsonKey(name: 'related_shipment_id') String? relatedShipmentId,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class __$ResponseTaskCopyWithImpl<$Res>
    implements _$ResponseTaskCopyWith<$Res> {
  __$ResponseTaskCopyWithImpl(this._self, this._then);

  final _ResponseTask _self;
  final $Res Function(_ResponseTask) _then;

/// Create a copy of ResponseTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? responderId = freezed,Object? responderName = freezed,Object? priority = freezed,Object? status = freezed,Object? title = freezed,Object? description = freezed,Object? relatedAlertId = freezed,Object? relatedShipmentId = freezed,Object? createdAt = freezed,Object? completedAt = freezed,}) {
  return _then(_ResponseTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,responderId: freezed == responderId ? _self.responderId : responderId // ignore: cast_nullable_to_non_nullable
as String?,responderName: freezed == responderName ? _self.responderName : responderName // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,relatedAlertId: freezed == relatedAlertId ? _self.relatedAlertId : relatedAlertId // ignore: cast_nullable_to_non_nullable
as String?,relatedShipmentId: freezed == relatedShipmentId ? _self.relatedShipmentId : relatedShipmentId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
